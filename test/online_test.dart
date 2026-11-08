import 'package:castlei/core/cloud/cloud_backup.dart';
import 'package:castlei/core/cloud/remote_config.dart';
import 'package:castlei/core/diagnostics/analytics.dart';
import 'package:castlei/core/notifications/notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('reminder timing', () {
    final morning = DateTime(2026, 11, 8, 9, 0);
    final evening = DateTime(2026, 11, 8, 20, 0);

    test('next occurrence is today if still ahead, otherwise tomorrow', () {
      expect(nextOccurrence(morning, 18 * 60), DateTime(2026, 11, 8, 18));
      expect(nextOccurrence(evening, 18 * 60), DateTime(2026, 11, 9, 18));
      expect(
        nextOccurrence(DateTime(2026, 11, 8, 18), 18 * 60),
        DateTime(2026, 11, 8, 18),
      );
    });

    test('drill reminder fires at the next slot when something is due', () {
      final due = morning
          .subtract(const Duration(hours: 1))
          .millisecondsSinceEpoch;
      expect(
        nextDrillReminder(
          now: morning,
          minutes: 18 * 60,
          dueMillis: [due],
          hasNew: false,
        ),
        DateTime(2026, 11, 8, 18),
      );
    });

    test('new cards always remind at the next slot', () {
      expect(
        nextDrillReminder(
          now: evening,
          minutes: 18 * 60,
          dueMillis: [],
          hasNew: true,
        ),
        DateTime(2026, 11, 9, 18),
      );
    });

    test('nothing due soon waits for the slot on the due day; nothing at all means no reminder', () {
      final inThreeDays = DateTime(2026, 11, 11, 7).millisecondsSinceEpoch;
      expect(
        nextDrillReminder(
          now: morning,
          minutes: 18 * 60,
          dueMillis: [inThreeDays],
          hasNew: false,
        ),
        DateTime(2026, 11, 11, 18),
      );
      expect(
        nextDrillReminder(
          now: morning,
          minutes: 18 * 60,
          dueMillis: [],
          hasNew: false,
        ),
        isNull,
      );
    });

    test(
      'a due date later than the slot on the same day still lands on that slot',
      () {
        final laterToday = DateTime(2026, 11, 8, 19).millisecondsSinceEpoch;
        expect(
          nextDrillReminder(
            now: morning,
            minutes: 18 * 60,
            dueMillis: [laterToday],
            hasNew: false,
          ),
          DateTime(2026, 11, 9, 18),
        );
      },
    );
  });

  test('cloud backup keeps the newest five versions', () {
    final names = [for (var i = 1; i <= 8; i++) '${1000 + i}.zip'];
    expect(backupsToDelete(names), ['1003.zip', '1002.zip', '1001.zip']);
    expect(backupsToDelete(names.take(5).toList()), isEmpty);
    expect(backupsToDelete(['9.zip', '10.zip'], keep: 1), isNotEmpty);
  });

  test('analytics buckets counts and never reports exact values', () {
    expect(Analytics.bucket(0), '0');
    expect(Analytics.bucket(3), '1-5');
    expect(Analytics.bucket(20), '6-20');
    expect(Analytics.bucket(99), '21-100');
    expect(Analytics.bucket(5000), '100+');
    // Disabled in tests: logging is a safe no-op.
    expect(() => Analytics.log('x', {'a': 'b'}), returnsNormally);
  });

  test('remote config falls back to safe defaults and clamps engine caps', () {
    expect(RemoteSettings.available, isFalse);
    expect(RemoteSettings.engineMaxMsUntimed, 1000);
    expect(RemoteSettings.engineMaxMsTimed, 2000);
    expect(RemoteSettings.cloudBackupEnabled, isTrue);
    expect(RemoteSettings.remindersEnabled, isTrue);
    expect(RemoteSettings.announcementText, isEmpty);
  });
}
