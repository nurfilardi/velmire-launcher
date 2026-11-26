import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SampMark extends StatelessWidget {
  final double size;
  final String caption;
  final String word;

  const SampMark({
    super.key,
    this.size = 34,
    this.caption = '',
    this.word = 'Velmire',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(width: 4, height: size * 0.82, color: Palette.signal),
        const SizedBox(width: 9),
        Text(
          word,
          style: TextStyle(
            fontFamily: AppTheme.display,
            fontWeight: FontWeight.w700,
            fontSize: size,
            height: 0.9,
            letterSpacing: -0.5,
            color: Palette.ink,
          ),
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(
            caption,
            style: const TextStyle(
              fontFamily: AppTheme.body,
              fontSize: 11,
              color: Palette.muted,
            ),
          ),
        ],
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
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: AppTheme.display,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Palette.ink,
              ),
            ),
          ),
          if (trailing != null) trailing!,
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
        borderRadius: BorderRadius.circular(12),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTheme.body,
          fontSize: 10,
          fontWeight: FontWeight.w600,
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
    final color = ok ? Palette.online : Palette.muted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTheme.body,
              fontSize: 12.5,
              color: Palette.muted,
            ),
          ),
        ),
      ],
    );
  }
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
              fontWeight: FontWeight.w600,
              color: Palette.ink,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTheme.body,
              fontSize: 13,
              color: Palette.muted,
              height: 1.45,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}
