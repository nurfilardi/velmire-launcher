import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SampMark extends StatelessWidget {
  final double size;
  final String caption;
  final String word;

  const SampMark({
    super.key,
    this.size = 52,
    this.caption = 'SA-MP / INDONESIA',
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
                height: 0.82,
                letterSpacing: -0.8,
                color: Palette.ink,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 7, bottom: 4),
              padding: const EdgeInsets.fromLTRB(5, 3, 5, 2),
              decoration: const BoxDecoration(color: Palette.signal),
              child: Text(
                'SA',
                style: TextStyle(
                  fontFamily: AppTheme.display,
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w700,
                  color: Palette.bg,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Container(width: 18, height: 2, color: Palette.accent),
            const SizedBox(width: 8),
            Text(
              caption,
              style: const TextStyle(
                fontFamily: AppTheme.body,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.1,
                color: Palette.muted,
              ),
            ),
          ],
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
      padding: const EdgeInsets.only(bottom: 12, top: 6),
      child: Row(
        children: [
          Container(width: 6, height: 6, color: Palette.signal),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              fontFamily: AppTheme.body,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              color: Palette.muted,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: _DashRule()),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

class _DashRule extends StatelessWidget {
  const _DashRule();

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 1, child: CustomPaint(painter: _DashPainter()));
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Palette.line
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, 0), Offset(x + 4, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
    return Stack(
      children: [
        Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? Palette.surface,
            border: Border.all(color: Palette.line),
          ),
          child: child,
        ),
        const Positioned(left: 0, top: 0, child: _Corner()),
        const Positioned(right: 0, bottom: 0, child: _Corner(flip: true)),
      ],
    );
  }
}

class _Corner extends StatelessWidget {
  final bool flip;
  const _Corner({this.flip = false});

  @override
  Widget build(BuildContext context) {
    return Transform.flip(
      flipX: flip,
      flipY: flip,
      child: CustomPaint(size: const Size(12, 12), painter: _CornerPainter()),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Palette.signal
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, 0), const Offset(0, 10), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(10, 0), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Tag extends StatelessWidget {
  final String text;
  final Color color;

  const Tag(this.text, {super.key, this.color = Palette.muted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontFamily: AppTheme.body,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
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
        Container(width: 8, height: 5, color: color),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTheme.body,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
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
            child: CustomPaint(painter: _RoadMapPainter(), size: Size.infinite),
          ),
        ),
        child,
      ],
    );
  }
}

class _RoadMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Palette.ink.withValues(alpha: 0.028)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 44) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 44) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final road = Paint()
      ..color = Palette.signal.withValues(alpha: 0.055)
      ..strokeWidth = 46
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final center = Paint()
      ..color = Palette.bg.withValues(alpha: 0.55)
      ..strokeWidth = 1.4;
    final path = Path()
      ..moveTo(size.width * 0.75, -40)
      ..cubicTo(
        size.width * 0.55,
        size.height * 0.25,
        size.width * 0.95,
        size.height * 0.55,
        size.width * 0.62,
        size.height + 40,
      );
    canvas.drawPath(path, road);
    _dashPath(canvas, path, center);
  }

  void _dashPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + 10).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 22;
      }
    }
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
            style: const TextStyle(
              fontFamily: AppTheme.display,
              fontSize: 24,
              color: Palette.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTheme.body,
              fontSize: 13,
              color: Palette.muted,
              height: 1.5,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

class RouteShield extends StatelessWidget {
  final String value;
  final String caption;

  const RouteShield({super.key, required this.value, this.caption = ''});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: const BoxDecoration(
        color: Palette.signal,
        border: Border.fromBorderSide(BorderSide(color: Palette.bg, width: 2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppTheme.display,
              fontSize: 24,
              height: 0.95,
              fontWeight: FontWeight.w700,
              color: Palette.bg,
            ),
          ),
          if (caption.isNotEmpty)
            Text(
              caption,
              style: const TextStyle(
                fontFamily: AppTheme.body,
                fontSize: 7,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
                color: Palette.bg,
              ),
            ),
        ],
      ),
    );
  }
}
