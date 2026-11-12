import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    show
        AlertDialog,
        BuildContext,
        Icon,
        Icons,
        FilledButton,
        Navigator,
        Text,
        TextButton,
        showDialog;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../firebase_options.dart';
import '../cloud/remote_config.dart';
import '../diagnostics/analytics.dart';
import '../diagnostics/env.dart';
import '../storage/repository.dart';

/// First occurrence of [minutes] since midnight at or after [from].
DateTime nextOccurrence(DateTime from, int minutes) {
  var t = DateTime(
    from.year,
    from.month,
    from.day,
    minutes ~/ 60,
    minutes % 60,
  );
  if (t.isBefore(from)) t = t.add(const Duration(days: 1));
  // Re-normalise across DST changes.
  return DateTime(t.year, t.month, t.day, minutes ~/ 60, minutes % 60);
}

/// When to remind about drills, or null if there is nothing to remind about.
/// Reminds at the next [minutes] slot if anything is already due then;
/// otherwise at the slot on/after the earliest upcoming due date.
DateTime? nextDrillReminder({
  required DateTime now,
  required int minutes,
  required List<int> dueMillis,
  required bool hasNew,
}) {
  final slot = nextOccurrence(now, minutes);
  if (hasNew) {
    return slot;
  }
  if (dueMillis.isEmpty) return null;
  final earliest = dueMillis.reduce((a, b) => a < b ? a : b);
  if (earliest <= slot.millisecondsSinceEpoch) {
    return slot;
  }
  return nextOccurrence(DateTime.fromMillisecondsSinceEpoch(earliest), minutes);
}

/// Local reminders (work offline) for due drills, the daily puzzle and an
/// unfinished game. Each is individually switchable. One pending drill
/// reminder at a time, so a user who stays away is never nagged repeatedly.
class Notifications {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static final taps = StreamController<String>.broadcast();
  static bool ready = false;
  static const drillId = 1, puzzleId = 2, resumeId = 3;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Reminders',
      channelDescription: 'Drill, puzzle and unfinished game reminders',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static Future<void> start(Repository repo) async {
    try {
      tzdata.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (r) => taps.add(r.payload ?? ''),
      );
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        final payload = launch!.notificationResponse?.payload;
        if (payload != null) {
          Future<void>.delayed(
            const Duration(seconds: 1),
            () => taps.add(payload),
          );
        }
      }
      ready = true;
      unawaited(reschedule(repo));
    } catch (e) {
      ready = false;
      debugPrint('Notifications unavailable');
    }
  }

  static Future<bool> permissionGranted() async {
    if (!ready) {
      return false;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final p = await ios?.checkPermissions();
    return p?.isEnabled ?? false;
  }

  /// Asks the OS for permission (shows the system prompt when needed).
  static Future<bool> ensurePermission() async {
    if (!ready) {
      return false;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }

  /// Whether it is time to offer reminders: notifications work here, the user
  /// has not been asked before and has not already allowed them.
  static Future<bool> shouldOffer(Repository repo) async {
    // A system permission dialog would stall automated test runs.
    if (!ready || runningUnderTest) return false;
    if (await repo.preference('notifPrompted', false) == true) return false;
    return !await permissionGranted();
  }

  /// One-time, contextual offer, e.g. after the first finished game or puzzle.
  /// Explains what the reminders are for before the system prompt appears, and
  /// never shows that prompt unless the user agrees.
  static Future<void> offerReminders(
    BuildContext context,
    Repository repo,
  ) async {
    if (!await shouldOffer(repo)) return;
    await repo.setPreference('notifPrompted', true);
    if (!context.mounted) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.notifications_active_outlined),
        title: const Text('Gentle reminders?'),
        content: const Text(
          'Castlei can nudge you when practice is due: a drill that is ready '
          'to review, the daily puzzle, or a game you left unfinished. At most '
          'one reminder at a time, and never while you are playing.\n\n'
          'You can change this any time in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Turn on'),
          ),
        ],
      ),
    );
    if (yes != true) {
      Analytics.log('notifications_permission', {'result': 'declined_offer'});
      return;
    }
    if (await ensurePermission()) {
      Analytics.log('notifications_permission', {'result': 'granted'});
      await reschedule(repo);
    } else {
      Analytics.log('notifications_permission', {'result': 'denied'});
    }
  }

  static tz.TZDateTime _tz(DateTime t) => tz.TZDateTime.from(t, tz.local);

  static Future<void> reschedule(Repository repo) async {
    if (!ready) {
      return;
    }
    try {
      await _plugin.cancel(id: drillId);
      await _plugin.cancel(id: puzzleId);
      if (!RemoteSettings.remindersEnabled || !await permissionGranted()) {
        return;
      }
      final now = DateTime.now();

      if (await repo.preference('remindDrills', true) == true) {
        final minutes = await repo.preference('drillMinutes', 18 * 60) as int;
        final rows = await repo.db.rows('SELECT stage,due FROM cards');
        final when = nextDrillReminder(
          now: now,
          minutes: minutes,
          dueMillis: [
            for (final r in rows)
              if ((r['stage'] as int) > 0) r['due'] as int,
          ],
          hasNew: rows.any((r) => (r['stage'] as int) == 0),
        );
        if (when != null) {
          final due = rows
              .where(
                (r) =>
                    (r['stage'] as int) == 0 ||
                    (r['due'] as int) <= when.millisecondsSinceEpoch,
              )
              .length;
          await _plugin.zonedSchedule(
            id: drillId,
            title: 'Opening drills are ready',
            body: due == 1
                ? '1 position to review.'
                : '$due positions to review.',
            scheduledDate: _tz(when),
            notificationDetails: _details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: 'drills',
          );
        }
      }

      if (await repo.preference('remindPuzzle', true) == true) {
        final minutes = await repo.preference('puzzleMinutes', 12 * 60) as int;
        await _plugin.zonedSchedule(
          id: puzzleId,
          title: 'Daily tactics',
          body: 'A fresh position is waiting.',
          scheduledDate: _tz(nextOccurrence(now, minutes)),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'puzzle',
        );
      }
    } catch (e) {
      debugPrint('Could not schedule reminders');
    }
  }

  /// Reminder 24 h after leaving an unfinished game.
  static Future<void> scheduleResume(Repository repo, String gameId) async {
    if (!ready || !RemoteSettings.remindersEnabled) {
      return;
    }
    if (await repo.preference('remindResume', true) != true) return;
    if (!await permissionGranted()) {
      return;
    }
    try {
      await _plugin.zonedSchedule(
        id: resumeId,
        title: 'Your game is waiting',
        body: 'Pick up where you left off.',
        scheduledDate: _tz(DateTime.now().add(const Duration(hours: 24))),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'resume:$gameId',
      );
    } catch (_) {}
  }

  static Future<void> cancelResume() async {
    if (ready) await _plugin.cancel(id: resumeId);
  }

  static Future<void> showNow(
    String title,
    String body, {
    String? payload,
  }) async {
    if (!ready) {
      return;
    }
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000 + 100,
      title: title,
      body: body,
      notificationDetails: _details,
      payload: payload,
    );
  }
}

/// Server announcements (Firebase Cloud Messaging) via the "announcements" topic.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!DefaultFirebaseOptions.isConfigured) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class Messaging {
  static bool available = false;
  static const topic = 'announcements';

  static Future<void> start(Repository repo) async {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      // Foreground messages are not shown by the OS; show them as local notifications.
      FirebaseMessaging.onMessage.listen((m) {
        final n = m.notification;
        if (n != null) {
          Notifications.showNow(
            n.title ?? 'Castlei',
            n.body ?? '',
            payload: 'announcement',
          );
        }
      });
      available = true;
      await applyPreference(repo);
    } catch (_) {
      available = false;
    }
  }

  static Future<void> applyPreference(Repository repo) async =>
      setAnnouncements(await repo.preference('announcements', true) as bool);

  static Future<void> setAnnouncements(bool on) async {
    if (!available) {
      return;
    }
    try {
      if (on) {
        await FirebaseMessaging.instance.subscribeToTopic(topic);
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      }
    } catch (_) {}
  }
}
