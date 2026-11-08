import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/diagnostics/analytics.dart';
import '../../core/diagnostics/log.dart';
import '../../core/diagnostics/snapshot.dart';
import '../../core/storage/repository.dart';
import '../../core/ui/theme.dart';
import '../../core/ui/widgets.dart';

/// Shows exactly what a diagnostics report contains, and lets the user copy or
/// share it. Nothing is sent automatically.
class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key, required this.repo});
  final Repository repo;
  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsState();
}

class _DiagnosticsState extends State<DiagnosticsScreen> {
  String? report;
  String? error;

  @override
  void initState() {
    super.initState();
    Analytics.screen('diagnostics');
    _build();
  }

  Future<void> _build() async {
    try {
      final r = await buildSnapshot(widget.repo);
      if (mounted) setState(() => report = r);
    } catch (e) {
      if (mounted) setState(() => error = 'Could not build the report.');
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Diagnostics')),
    body: ListView(
      padding: pagePadding(context),
      children: [
        const FeedbackCard(
          'This is a snapshot of what Castlei knows on this device: versions, settings, counts and recent events. It has no games, positions, comments, names, e-mail address or file names. Nothing is sent unless you share it.',
          tone: Tone.info,
          icon: Icons.privacy_tip_outlined,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: report == null
                    ? null
                    : () {
                        Analytics.log('diagnostics_shared');
                        SharePlus.instance.share(
                          ShareParams(
                            text: report!,
                            subject: 'Castlei diagnostics',
                          ),
                        );
                      },
                icon: const Icon(Icons.ios_share),
                label: const Text('Send diagnostics'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Copy report',
              onPressed: report == null
                  ? null
                  : () async {
                      await Clipboard.setData(ClipboardData(text: report!));
                      if (mounted) _snack('Report copied');
                    },
              icon: const Icon(Icons.copy_rounded),
            ),
            IconButton.filledTonal(
              tooltip: 'Refresh',
              onPressed: () {
                setState(() => report = null);
                _build();
              },
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (error != null)
          FeedbackCard(error!, tone: Tone.bad)
        else if (report == null)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: SelectableText(
                report!,
                style: context.text.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
            ),
          ),
        if (DiagnosticsLog.entries.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () async {
                await DiagnosticsLog.clear();
                setState(() => report = null);
                _build();
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Clear recent events'),
            ),
          ),
      ],
    ),
  );
}
