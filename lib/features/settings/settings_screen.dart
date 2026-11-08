import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/app_info.dart';
import '../../core/cloud/account.dart';
import '../../core/cloud/cloud_backup.dart';
import '../../core/diagnostics/analytics.dart';
import '../../core/diagnostics/crash.dart';
import '../../core/diagnostics/perf.dart';
import '../../core/engine/engine.dart';
import '../../core/storage/repository.dart';
import '../../core/ui/theme.dart';
import '../../core/ui/widgets.dart';
import 'diagnostics_screen.dart';
import 'notification_settings.dart';
import 'open_source_screen.dart';
import 'preferences_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.repo,
    required this.engine,
    required this.mode,
    required this.onTheme,
    required this.onBackup,
    required this.onRestoreFile,
    required this.onRestoreBytes,
    required this.guard,
  });
  final Repository repo;
  final EngineClient engine;
  final ThemeMode mode;
  final void Function(ThemeMode) onTheme;
  final Future<void> Function() onBackup, onRestoreFile;
  final Future<void> Function(Uint8List bytes) onRestoreBytes;
  final Future<void> Function(Future<void> Function()) guard;
  @override
  State<SettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsScreen> {
  late ThemeMode mode = widget.mode;
  bool crash = true,
      perf = true,
      analytics = true,
      cloud = true,
      loaded = false;
  int lastBackup = 0;
  bool busy = false;
  PackageInfo? info;
  final account = AccountService.instance;

  @override
  void initState() {
    super.initState();
    account.addListener(_refresh);
    CloudBackup.changed.addListener(_refresh);
    _load();
    PackageInfo.fromPlatform().then((i) {
      if (mounted) setState(() => info = i);
    });
    Analytics.screen('settings');
  }

  @override
  void dispose() {
    account.removeListener(_refresh);
    CloudBackup.changed.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    final r = widget.repo;
    crash = await r.preference('crashReports', true) as bool;
    perf = await r.preference('perfMonitoring', true) as bool;
    analytics = await r.preference('analytics', true) as bool;
    cloud = await r.preference('cloudBackup', true) as bool;
    lastBackup = await r.preference('lastCloudBackup', 0) as int;
    loaded = true;
    if (mounted) setState(() {});
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _run(Future<String?> Function() action, {String? ok}) async {
    setState(() => busy = true);
    final problem = await action();
    if (!mounted) return;
    setState(() => busy = false);
    if (problem != null) {
      _snack(problem);
    } else if (ok != null) {
      _snack(ok);
    }
  }

  String _ago(int ms) {
    if (ms == 0) return 'Never';
    final d = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(ms),
    );
    if (d.inMinutes < 1) return 'Just now';
    if (d.inHours < 1) return '${d.inMinutes} min ago';
    if (d.inDays < 1) return '${d.inHours} h ago';
    return '${d.inDays} d ago';
  }

  Future<void> _restoreFromCloud() async {
    setState(() => busy = true);
    List<CloudBackupEntry> entries;
    try {
      entries = await CloudBackup.list();
    } catch (_) {
      if (mounted) setState(() => busy = false);
      _snack('Could not reach cloud backups.');
      return;
    }
    if (!mounted) return;
    setState(() => busy = false);
    if (entries.isEmpty) {
      _snack('No cloud backups found for this account.');
      return;
    }
    final pick = await showModalBottomSheet<CloudBackupEntry>(
      context: context,
      builder: (c) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Text('Choose a backup', style: context.text.headlineSmall),
            const SizedBox(height: 8),
            for (final e in entries)
              ListTile(
                leading: const Icon(Icons.cloud_download_outlined),
                title: Text(e.created.toLocal().toString().substring(0, 16)),
                subtitle: Text(
                  '${e.games} games · ${(e.bytes / 1024).round()} KB',
                ),
                onTap: () => Navigator.pop(c, e),
              ),
          ],
        ),
      ),
    );
    if (pick == null) return;
    setState(() => busy = true);
    try {
      final bytes = await CloudBackup.download(pick);
      if (!mounted) return;
      setState(() => busy = false);
      await widget.onRestoreBytes(bytes);
    } catch (e) {
      if (mounted) setState(() => busy = false);
      _snack('Restore failed: $e');
    }
  }

  Future<void> _deleteAccount() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This deletes your sign-in and every cloud backup. Data on this device is kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    await _run(() async {
      try {
        await CloudBackup.deleteAll();
      } catch (_) {}
      final problem = await account.deleteAccount();
      if (problem == null) {
        await widget.repo.setPreference('lastCloudBackup', 0);
        await widget.repo.setPreference('cloudDirtySince', 0);
      }
      return problem;
    }, ok: 'Account deleted');
  }

  Widget _accountSection(BuildContext context) {
    if (!account.available) {
      return const FeedbackCard(
        'Accounts are not available in this build.',
        tone: Tone.info,
      );
    }
    if (!account.signedIn) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Back up your games', style: context.text.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Sign in to back up automatically and restore on a new phone. The app works fully without an account.',
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: busy
                    ? null
                    : () => _run(account.signInWithGoogle, ok: 'Signed in'),
                icon: const Icon(Icons.login_rounded),
                label: const Text('Continue with Google'),
              ),
              if (account.appleSupported) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () => _run(account.signInWithApple, ok: 'Signed in'),
                  icon: const Icon(Icons.apple),
                  label: const Text('Continue with Apple'),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return GroupCard(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: context.colors.primaryContainer,
            child: Icon(
              Icons.person_rounded,
              color: context.colors.onPrimaryContainer,
            ),
          ),
          title: Text(account.label),
          subtitle: const Text('Signed in'),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.cloud_sync_outlined),
          title: const Text('Automatic cloud backup'),
          subtitle: Text(
            'After finished games and daily, on Wi-Fi. Keeps the last ${CloudBackup.keep} versions. Last backup: ${_ago(lastBackup)}.',
          ),
          value: cloud,
          onChanged: (v) async {
            await widget.repo.setPreference('cloudBackup', v);
            Analytics.log('setting_changed', {
              'name': 'cloud_backup',
              'on': v ? 1 : 0,
            });
            _load();
          },
        ),
        ListTile(
          leading: const Icon(Icons.cloud_upload_outlined),
          title: const Text('Back up now'),
          enabled: !busy,
          onTap: () => _run(CloudBackup.backupNow, ok: 'Backup complete'),
        ),
        ListTile(
          leading: const Icon(Icons.cloud_download_outlined),
          title: const Text('Restore from cloud'),
          subtitle: const Text('Replaces data on this device'),
          enabled: !busy,
          onTap: _restoreFromCloud,
        ),
        ListTile(
          leading: const Icon(Icons.logout_rounded),
          title: const Text('Sign out'),
          enabled: !busy,
          onTap: () => _run(() async {
            await account.signOut();
            return null;
          }),
        ),
        ListTile(
          leading: Icon(
            Icons.delete_forever_outlined,
            color: context.colors.error,
          ),
          title: Text(
            'Delete account and cloud data',
            style: TextStyle(color: context.colors.error),
          ),
          enabled: !busy,
          onTap: _deleteAccount,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: ListView(
      padding: pagePadding(context),
      children: [
        if (busy) const LinearProgressIndicator(),
        const SectionLabel('Account'),
        _accountSection(context),
        const SectionLabel('Appearance'),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_outlined),
                label: Text('System'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined),
                label: Text('Light'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined),
                label: Text('Dark'),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (v) {
              setState(() => mode = v.first);
              widget.onTheme(mode);
              widget.repo.setPreference('theme', mode.name);
            },
          ),
        ),
        const SectionLabel('Practice'),
        ActionTile(
          title: 'Practice preferences',
          subtitle: 'Feedback, engine resources, and drill limits',
          icon: Icons.tune_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PreferencesScreen(repo: widget.repo, engine: widget.engine),
            ),
          ),
        ),
        ActionTile(
          title: 'Notifications',
          subtitle: 'Drill, daily puzzle and game reminders',
          icon: Icons.notifications_active_outlined,
          accent: context.colors.secondary,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NotificationSettingsScreen(repo: widget.repo),
            ),
          ),
        ),
        const SectionLabel('Your data'),
        ActionTile(
          title: 'Export backup file',
          subtitle: 'Unencrypted archive; store it privately',
          icon: Icons.backup_rounded,
          accent: context.colors.tertiary,
          onTap: () => widget.guard(widget.onBackup),
        ),
        ActionTile(
          title: 'Restore from file',
          subtitle: 'Validate, then replace local data',
          icon: Icons.restore_rounded,
          accent: context.colors.secondary,
          onTap: () => widget.guard(widget.onRestoreFile),
        ),
        const SectionLabel('Privacy and diagnostics'),
        GroupCard(
          children: [
            _switch(
              icon: Icons.bug_report_outlined,
              title: 'Crash reports',
              text: 'Anonymous crash diagnostics (app and engine version, error type, stack trace). Never your games, positions, comments or files.',
              available: CrashReporting.available,
              value: crash,
              onChanged: (v) async {
                await widget.repo.setPreference('crashReports', v);
                await CrashReporting.setEnabled(v);
                _load();
              },
            ),
            _switch(
              icon: Icons.speed_rounded,
              title: 'Performance monitoring',
              text: 'Anonymous timings (startup, engine speed, imports, frame rate) to find slow spots.',
              available: Perf.available,
              value: perf,
              onChanged: (v) async {
                await widget.repo.setPreference('perfMonitoring', v);
                await Perf.setEnabled(v);
                _load();
              },
            ),
            _switch(
              icon: Icons.insights_rounded,
              title: 'Usage analytics',
              text: 'Anonymous feature usage (screens, game results as categories) and in-app announcements. No positions, moves, comments or names.',
              available: Analytics.available,
              value: analytics,
              onChanged: (v) async {
                await widget.repo.setPreference('analytics', v);
                await Analytics.setEnabled(v);
                _load();
              },
            ),
            ListTile(
              leading: const Icon(Icons.fact_check_outlined),
              title: const Text('Diagnostics'),
              subtitle: const Text(
                'Review a snapshot of the data collected on this device and send it to the developer.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DiagnosticsScreen(repo: widget.repo),
                ),
              ),
            ),
          ],
        ),
        const SectionLabel('About'),
        GroupCard(
          children: [
            ListTile(
              leading: const Icon(Icons.castle_outlined),
              title: const Text('Castlei'),
              subtitle: Text(
                info == null
                    ? 'Chess engine: Stockfish 18'
                    : 'Version ${info!.version} (build ${displayBuild(info!.buildNumber)})\nChess engine: Stockfish 18',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.code_rounded),
              title: const Text('Open-source software'),
              subtitle: const Text('The projects Castlei is built on'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OpenSourceScreen()),
              ),
            ),
          ],
        ),
        if (!loaded) const SizedBox.shrink(),
      ],
    ),
  );

  Widget _switch({
    required IconData icon,
    required String title,
    required String text,
    required bool available,
    required bool value,
    required Future<void> Function(bool) onChanged,
  }) => SwitchListTile(
    secondary: Icon(icon),
    title: Text(title),
    subtitle: Text(
      available
          ? 'On by default. $text'
          : '$title is not available in this build.',
    ),
    value: value && available,
    onChanged: available ? (v) => widget.guard(() => onChanged(v)) : null,
  );
}
