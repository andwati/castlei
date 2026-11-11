import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/cloud/feedback.dart';
import '../../core/diagnostics/analytics.dart';
import '../../core/diagnostics/snapshot.dart';
import '../../core/storage/repository.dart';
import '../../core/ui/theme.dart';
import '../../core/ui/widgets.dart';

/// Bug reports and feature ideas, with optional screenshots and diagnostics.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key, required this.repo});
  final Repository repo;
  @override
  State<FeedbackScreen> createState() => _FeedbackState();
}

class _FeedbackState extends State<FeedbackScreen> {
  final message = TextEditingController();
  final email = TextEditingController();
  FeedbackType type = FeedbackType.bug;
  final images = <Uint8List>[];
  bool withDiagnostics = false;
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    Analytics.screen('feedback');
  }

  @override
  void dispose() {
    message.dispose();
    email.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final room = FeedbackService.maxImages - images.length;
    if (room <= 0) return;
    setState(() => error = null);
    try {
      final files = await FilePicker.pickFiles(type: FileType.image);
      if (files.isEmpty) return;
      setState(() => busy = true);
      var skipped = 0;
      for (final f in files.take(room)) {
        final data = await f.readAsBytes();
        // Compression is CPU heavy; keep it off the UI isolate.
        final out = await compute(FeedbackService.compress, data);
        if (out == null) {
          skipped++;
        } else {
          images.add(out);
        }
      }
      if (skipped > 0) error = '$skipped image(s) could not be used.';
    } catch (_) {
      error = 'Could not open the image picker.';
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _send() async {
    setState(() {
      busy = true;
      error = null;
    });
    final diag = withDiagnostics ? await buildSnapshot(widget.repo) : '';
    final problem = await FeedbackService.submit(
      type: type,
      message: message.text,
      email: email.text,
      images: images,
      diagnostics: diag,
    );
    if (!mounted) return;
    setState(() => busy = false);
    if (problem != null) {
      setState(() => error = problem);
      return;
    }
    Analytics.log('feedback_sent', {
      'type': type.name,
      'images': images.length,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you! Your feedback was sent.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Send feedback')),
    body: ListView(
      padding: pagePadding(context),
      children: [
        SegmentedButton<FeedbackType>(
          segments: const [
            ButtonSegment(
              value: FeedbackType.bug,
              label: Text('Bug'),
              icon: Icon(Icons.bug_report_outlined),
            ),
            ButtonSegment(
              value: FeedbackType.idea,
              label: Text('Idea'),
              icon: Icon(Icons.lightbulb_outline),
            ),
            ButtonSegment(
              value: FeedbackType.other,
              label: Text('Other'),
              icon: Icon(Icons.chat_bubble_outline),
            ),
          ],
          selected: {type},
          onSelectionChanged: busy
              ? null
              : (v) => setState(() => type = v.first),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: message,
          enabled: !busy,
          minLines: 5,
          maxLines: 10,
          maxLength: FeedbackService.maxMessage,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: type == FeedbackType.bug
                ? 'What went wrong?'
                : 'What would you like to see?',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: email,
          enabled: !busy,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Your email (optional, if you want a reply)',
          ),
        ),
        const SizedBox(height: 16),
        Text('Screenshots', style: context.text.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < images.length; i++)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      images[i],
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton.filledTonal(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Remove',
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: busy
                          ? null
                          : () => setState(() => images.removeAt(i)),
                    ),
                  ),
                ],
              ),
            if (images.length < FeedbackService.maxImages)
              OutlinedButton.icon(
                onPressed: busy ? null : _pick,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(
                  'Add (${images.length}/${FeedbackService.maxImages})',
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Include diagnostics'),
          subtitle: const Text(
            'App version, device and settings, counts and recent events. No games, positions, names or e-mail. Review it under Settings → Diagnostics.',
          ),
          value: withDiagnostics,
          onChanged: busy ? null : (v) => setState(() => withDiagnostics = v),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          FeedbackCard(error!, tone: Tone.bad),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: busy ? null : _send,
          icon: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_rounded),
          label: const Text('Send'),
        ),
        const SizedBox(height: 8),
        Text(
          'Your report, optional email and screenshots are stored privately and only read by the developer. Screenshots can contain anything shown on screen, so check them before sending.',
          style: context.text.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
