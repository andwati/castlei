import 'package:flutter/material.dart';

import '../../core/diagnostics/analytics.dart';
import '../../core/notifications/notifications.dart';
import '../../core/storage/repository.dart';
import '../../core/ui/theme.dart';
import '../../core/ui/widgets.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key, required this.repo});
  final Repository repo;
  @override
  State<NotificationSettingsScreen> createState() => _NotifState();
}

class _NotifState extends State<NotificationSettingsScreen> {
  bool drills = true, puzzle = true, resume = true, announcements = true;
  int drillMinutes = 18 * 60, puzzleMinutes = 12 * 60;
  bool granted = false, ready = false;

  @override
  void initState() {
    super.initState();
    Analytics.screen('notification_settings');
    _load();
  }

  Future<void> _load() async {
    final r = widget.repo;
    drills = await r.preference('remindDrills', true) as bool;
    puzzle = await r.preference('remindPuzzle', true) as bool;
    resume = await r.preference('remindResume', true) as bool;
    announcements = await r.preference('announcements', true) as bool;
    drillMinutes = await r.preference('drillMinutes', 18 * 60) as int;
    puzzleMinutes = await r.preference('puzzleMinutes', 12 * 60) as int;
    granted = await Notifications.permissionGranted();
    ready = true;
    if (mounted) setState(() {});
  }

  Future<void> _set(String key, Object value) async {
    await widget.repo.setPreference(key, value);
    if (key == 'announcements') await Messaging.setAnnouncements(value as bool);
    if (value == true && !granted) {
      granted = await Notifications.ensurePermission();
    }
    await Notifications.reschedule(widget.repo);
    Analytics.log('setting_changed', {
      'name': key,
      'on': value == true ? 1 : 0,
    });
    await _load();
  }

  Future<void> _pickTime(String key, int minutes) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (t != null) await _set(key, t.hour * 60 + t.minute);
  }

  String _fmt(int m) =>
      TimeOfDay(hour: m ~/ 60, minute: m % 60).format(context);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notifications')),
    body: !ready
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: pagePadding(context),
            children: [
              if (!granted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FeedbackCard(
                        'Notifications are off for Castlei in system settings.',
                        tone: Tone.info,
                        icon: Icons.notifications_off_outlined,
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () async {
                          granted = await Notifications.ensurePermission();
                          await Notifications.reschedule(widget.repo);
                          await _load();
                        },
                        child: const Text('Allow notifications'),
                      ),
                    ],
                  ),
                ),
              const SectionLabel('Reminders'),
              GroupCard(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.account_tree_outlined),
                    title: const Text('Due opening drills'),
                    subtitle: Text(
                      'Only when positions are due. Reminder at ${_fmt(drillMinutes)}.',
                    ),
                    value: drills,
                    onChanged: (v) => _set('remindDrills', v),
                  ),
                  if (drills)
                    ListTile(
                      leading: const Icon(Icons.schedule_rounded),
                      title: const Text('Drill reminder time'),
                      trailing: Text(_fmt(drillMinutes)),
                      onTap: () => _pickTime('drillMinutes', drillMinutes),
                    ),
                  SwitchListTile(
                    secondary: const Icon(Icons.extension_outlined),
                    title: const Text('Daily puzzle'),
                    subtitle: Text('Every day at ${_fmt(puzzleMinutes)}.'),
                    value: puzzle,
                    onChanged: (v) => _set('remindPuzzle', v),
                  ),
                  if (puzzle)
                    ListTile(
                      leading: const Icon(Icons.schedule_rounded),
                      title: const Text('Puzzle reminder time'),
                      trailing: Text(_fmt(puzzleMinutes)),
                      onTap: () => _pickTime('puzzleMinutes', puzzleMinutes),
                    ),
                  SwitchListTile(
                    secondary: const Icon(Icons.play_circle_outline),
                    title: const Text('Unfinished game'),
                    subtitle: const Text(
                      'One reminder a day after you leave a game paused.',
                    ),
                    value: resume,
                    onChanged: (v) => _set('remindResume', v),
                  ),
                ],
              ),
              const SectionLabel('From Castlei'),
              GroupCard(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.campaign_outlined),
                    title: const Text('Announcements'),
                    subtitle: const Text(
                      'News, new puzzle packs and update notices sent by the developer.',
                    ),
                    value: announcements,
                    onChanged: (v) => _set('announcements', v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: granted
                    ? () => Notifications.showNow(
                        'Castlei',
                        'Notifications are working.',
                      )
                    : null,
                icon: const Icon(Icons.notifications_none_rounded),
                label: const Text('Send a test notification'),
              ),
            ],
          ),
  );
}
