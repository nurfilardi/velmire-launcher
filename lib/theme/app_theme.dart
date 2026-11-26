import 'package:flutter/material.dart';

class Palette {
  static const bg = Color(0xFF0B0C0E);
  static const surface = Color(0xFF141619);
  static const surfaceHi = Color(0xFF1D2025);
  static const line = Color(0xFF2A2E35);
  static const ink = Color(0xFFF2F3F5);
  static const muted = Color(0xFF8A9099);
  static const accent = Color(0xFFFFB020);
  static const accentInk = Color(0xFF1A1200);
  static const online = Color(0xFF37D67A);
  static const danger = Color(0xFFFF5C5C);
}

class AppTheme {
  static const display = 'SampDisplay';
  static const body = 'SampBody';

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final text = base.textTheme.copyWith(
      displayLarge: const TextStyle(
        fontFamily: display,
        fontSize: 56,
        fontWeight: FontWeight.w700,
        height: 0.95,
        letterSpacing: -0.5,
        color: Palette.ink,
      ),
      displayMedium: const TextStyle(
        fontFamily: display,
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1,
        letterSpacing: -0.3,
        color: Palette.ink,
      ),
      titleLarge: const TextStyle(
        fontFamily: display,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: Palette.ink,
      ),
      titleMedium: const TextStyle(
        fontFamily: body,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Palette.ink,
      ),
      bodyMedium: const TextStyle(
        fontFamily: body,
        fontSize: 14,
        height: 1.45,
        color: Palette.ink,
      ),
      bodySmall: const TextStyle(
        fontFamily: body,
        fontSize: 12.5,
        height: 1.4,
        color: Palette.muted,
      ),
      labelLarge: const TextStyle(
        fontFamily: body,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: Palette.bg,
      colorScheme: const ColorScheme.dark(
        primary: Palette.accent,
        onPrimary: Palette.accentInk,
        secondary: Palette.online,
        surface: Palette.surface,
        onSurface: Palette.ink,
        error: Palette.danger,
      ),
      textTheme: text,
      dividerColor: Palette.line,
      appBarTheme: const AppBarTheme(
        backgroundColor: Palette.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: display,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: Palette.ink,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Palette.accent,
          foregroundColor: Palette.accentInk,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(
            fontFamily: SampFont.w600,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Palette.surface,
        hintStyle: const TextStyle(color: Palette.muted, fontFamily: body),
        labelStyle: const TextStyle(color: Palette.muted, fontFamily: body),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Palette.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Palette.accent, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Palette.danger),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Palette.surfaceHi,
        contentTextStyle: TextStyle(fontFamily: body, color: Palette.ink),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Palette.accent,
        linearTrackColor: Palette.line,
      ),
    );
  }
}

class SampFont {
  static const w600 = 'SampBody';
}

String two(int n) => n.toString().padLeft(2, '0');
