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
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
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
                const SizedBox(height: 20),
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
    padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
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
          Text(
            label,
            style: context.text.labelMedium?.copyWith(
              color: c,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
