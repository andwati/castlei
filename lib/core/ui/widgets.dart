import 'package:flutter/material.dart';

import 'theme.dart';

/// Battlement (crenellation) strip — Castlei's signature motif.
class Battlements extends StatelessWidget {
  const Battlements({super.key, required this.color, this.height = 22});
  final Color color;
  final double height;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size(double.infinity, height),
      painter: _BattlementPainter(color),
    ),
  );
}

class _BattlementPainter extends CustomPainter {
  _BattlementPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final tooth = size.height * 1.15;
    final n = (size.width / (tooth * 2)).ceil();
    for (var i = 0; i < n; i++) {
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(i * tooth * 2, 0, tooth, size.height),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        paint,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * .62, size.width, size.height * .38),
      paint,
    );
  }

  @override
  bool shouldRepaint(_BattlementPainter old) => old.color != color;
}

/// Large hero card with a battlement crown along the bottom edge.
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.action,
    this.detail,
  });
  final String eyebrow, title;
  final String? detail;
  final Widget action;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: t.hero,
        borderRadius: BorderRadius.circular(Corner.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Battlements(color: t.onHero.withValues(alpha: .10)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: context.text.labelLarge?.copyWith(color: t.heroAccent),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: context.text.headlineMedium?.copyWith(
                    color: t.onHero,
                    height: 1.12,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    detail!,
                    style: context.text.bodyMedium?.copyWith(
                      color: t.onHero.withValues(alpha: .8),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                action,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill-style hero action (coral on pine).
class HeroButton extends StatelessWidget {
  const HeroButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => FilledButton.icon(
    style: FilledButton.styleFrom(
      backgroundColor: context.tokens.heroAccent,
      foregroundColor: const Color(0xff2a0d04),
    ),
    onPressed: onPressed,
    icon: Icon(icon),
    label: Text(label),
  );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
    child: Row(
      children: [
        Expanded(
          child: Text(text.toUpperCase(), style: context.text.labelLarge),
        ),
        ?trailing,
      ],
    ),
  );
}

/// Tappable feature tile with a tinted icon badge.
class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  final Color? accent;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tint = accent ?? c.primary;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: tint, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: context.text.bodyMedium?.copyWith(
                        color: c.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Consistent separation for stacked primary and secondary actions.
class ActionStack extends StatelessWidget {
  const ActionStack({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Column(
    spacing: 12,
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: children,
  );
}

/// Dialog actions retain a gap both side by side and when they overflow vertically.
class ActionDialog extends StatelessWidget {
  const ActionDialog({
    super.key,
    this.title,
    this.content,
    this.actions = const [],
  });
  final Widget? title, content;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: title,
    content: content,
    actionsPadding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
    buttonPadding: const EdgeInsets.all(6),
    actionsOverflowButtonSpacing: 8,
    actions: actions,
  );
}

/// Result/status chip — always icon + text, never color alone.
class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key, required this.icon, this.color});
  final String label;
  final IconData icon;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: context.text.labelMedium?.copyWith(
                color: c,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum Tone { neutral, good, bad, info }

/// Inline feedback banner: icon + text on a tinted surface (never color alone).
class FeedbackCard extends StatelessWidget {
  const FeedbackCard(
    this.text, {
    super.key,
    this.tone = Tone.neutral,
    this.icon,
    this.busy = false,
  });
  final String text;
  final Tone tone;
  final IconData? icon;
  final bool busy;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg, defaultIcon) = switch (tone) {
      Tone.good => (
        c.primaryContainer,
        c.onPrimaryContainer,
        Icons.check_circle_rounded,
      ),
      Tone.bad => (
        c.secondaryContainer,
        c.onSecondaryContainer,
        Icons.error_outline_rounded,
      ),
      Tone.info => (
        c.surfaceContainerHigh,
        c.onSurface,
        Icons.info_outline_rounded,
      ),
      Tone.neutral => (
        c.surfaceContainerHigh,
        c.onSurface,
        Icons.touch_app_outlined,
      ),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(Corner.md),
        ),
        child: Row(
          children: [
            if (busy)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            else
              Icon(icon ?? defaultIcon, color: fg),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Equal-height tool buttons with a real gap between their hit areas.
class ToolRow extends StatelessWidget {
  const ToolRow({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final child in children) Expanded(child: child)],
    ),
  );
}

/// Icon-over-label toolbar button.
class ToolButton extends StatelessWidget {
  const ToolButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;
  @override
  Widget build(BuildContext context) {
    final c = danger ? context.colors.error : context.colors.onSurface;
    final fg = onTap == null ? context.colors.outline : c;
    return Material(
      color: context.colors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(Corner.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(Corner.sm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: fg),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: context.text.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Big-number stat tile with optional progress.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.title,
    required this.value,
    required this.caption,
    this.progress,
    this.icon,
    this.accent,
  });
  final String title, value, caption;
  final double? progress;
  final IconData? icon;
  final Color? accent;
  @override
  Widget build(BuildContext context) {
    final tint = accent ?? context.colors.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: tint),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  value,
                  style: context.text.headlineMedium?.copyWith(color: tint),
                ),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  color: tint,
                  minHeight: 8,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              caption,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grouped settings card.
class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) Divider(height: 1, indent: 16, endIndent: 16),
          children[i],
        ],
      ],
    ),
  );
}

/// Move-list chip: highlights the current move, never looks disabled.
class MoveChip extends StatelessWidget {
  const MoveChip({
    super.key,
    required this.san,
    this.number,
    this.selected = false,
    this.onTap,
    this.badge = '',
  });
  final String badge;
  final String san;
  final String? number;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (number != null)
          Padding(
            padding: const EdgeInsets.only(left: 6, right: 2),
            child: Text(
              number!,
              style: context.text.bodyMedium?.copyWith(
                color: c.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Material(
          color: selected ? c.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text.rich(
                TextSpan(
                  text: san,
                  children: [
                    if (badge.isNotEmpty)
                      TextSpan(
                        text: badge,
                        style: TextStyle(
                          color: selected ? c.onPrimary : c.error,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? c.onPrimary : c.onSurface,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
