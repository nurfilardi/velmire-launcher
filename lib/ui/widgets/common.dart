import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SampMark extends StatelessWidget {
  final double size;
  final String caption;
  final String word;

  const SampMark({
    super.key,
    this.size = 52,
    this.caption = 'SA-MP LAUNCHER / INDONESIA',
    this.word = 'VELMIRE',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              word,
              style: TextStyle(
                fontFamily: AppTheme.display,
                fontWeight: FontWeight.w700,
                fontSize: size,
                height: 0.85,
                letterSpacing: -1,
                color: Palette.ink,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 8, bottom: 6),
              width: 10,
              height: size * 0.5,
              color: Palette.accent,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          caption,
          style: const TextStyle(
            fontFamily: AppTheme.body,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.4,
            color: Palette.muted,
          ),
        ),
      ],
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              fontFamily: AppTheme.body,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: Palette.muted,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Divider(height: 1)),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;

  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Palette.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Palette.line),
      ),
      child: child,
    );
  }
}

class Tag extends StatelessWidget {
  final String text;
  final Color color;

  const Tag(this.text, {super.key, this.color = Palette.muted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontFamily: AppTheme.body,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          color: color,
        ),
      ),
    );
  }
}

class StatusDot extends StatelessWidget {
  final bool ok;
  final String label;

  const StatusDot({super.key, required this.ok, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = ok ? Palette.online : Palette.danger;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTheme.body,
            fontSize: 12,
            color: Palette.muted,
          ),
        ),
      ],
    );
  }
}

class ContourBackdrop extends StatelessWidget {
  final Widget child;
  const ContourBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _ContourPainter(), size: Size.infinite),
          ),
        ),
        child,
      ],
    );
  }
}

class _ContourPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Palette.ink.withValues(alpha: 0.045);
    final paths = <Path>[];
    for (var row = 0; row < 4; row++) {
      final path = Path();
      final base = size.height * (0.18 + row * 0.18);
      path.moveTo(-20, base);
      for (var x = -20.0; x <= size.width + 40; x += 40) {
        final y = base + 22 * (row.isEven ? 1 : -1) * _wave(x / size.width, row);
        path.lineTo(x, y);
      }
      paths.add(path);
    }
    for (final path in paths) {
      canvas.drawPath(path, paint);
    }
    final circle = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Palette.accent.withValues(alpha: 0.05);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.06), 90, circle);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.06), 130, circle);
  }

  double _wave(double t, int row) {
    final v = (t * 3.2 + row * 0.7) % 1.0;
    return (v * (1 - v)) * 2;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 12),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: AppTheme.display, fontSize: 24, color: Palette.ink),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: AppTheme.body, fontSize: 13, color: Palette.muted, height: 1.5),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}
