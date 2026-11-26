import 'package:flutter/material.dart';

class Palette {
  static const bg = Color(0xFF12100C);
  static const surface = Color(0xFF1C1812);
  static const surfaceHi = Color(0xFF262015);
  static const line = Color(0xFF3A3225);
  static const ink = Color(0xFFF2E9D6);
  static const muted = Color(0xFFA2967F);
  static const accent = Color(0xFF2F7D5B);
  static const accentInk = Color(0xFFF5EEDC);
  static const signal = Color(0xFFE0A83E);
  static const online = Color(0xFF8FBF6A);
  static const danger = Color(0xFFC2543D);
}

class AppTheme {
  static const display = 'SampDisplay';
  static const body = 'SampBody';

  static const plate = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(10)),
  );

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final text = base.textTheme.copyWith(
      displayLarge: const TextStyle(
        fontFamily: display,
        fontSize: 58,
        fontWeight: FontWeight.w700,
        height: 0.88,
        letterSpacing: -0.6,
        color: Palette.ink,
      ),
      displayMedium: const TextStyle(
        fontFamily: display,
        fontSize: 38,
        fontWeight: FontWeight.w700,
        height: 0.94,
        color: Palette.ink,
      ),
      titleLarge: const TextStyle(
        fontFamily: display,
        fontSize: 24,
        fontWeight: FontWeight.w600,
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
        height: 1.45,
        color: Palette.muted,
      ),
      labelLarge: const TextStyle(
        fontFamily: body,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: Palette.bg,
      colorScheme: const ColorScheme.dark(
        primary: Palette.accent,
        onPrimary: Palette.accentInk,
        secondary: Palette.signal,
        onSecondary: Palette.bg,
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
          color: Palette.ink,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Palette.signal,
          foregroundColor: Palette.bg,
          minimumSize: const Size.fromHeight(54),
          shape: plate,
          textStyle: const TextStyle(
            fontFamily: AppTheme.body,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Palette.ink,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: Palette.line, width: 1.4),
          shape: plate,
          textStyle: const TextStyle(
            fontFamily: AppTheme.body,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Palette.surface,
        hintStyle: const TextStyle(color: Palette.muted, fontFamily: body),
        labelStyle: const TextStyle(color: Palette.muted, fontFamily: body),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: Palette.line),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: Palette.accent, width: 1.6),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: Palette.danger),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Palette.surfaceHi,
        contentTextStyle: TextStyle(fontFamily: body, color: Palette.ink),
        behavior: SnackBarBehavior.floating,
        shape: plate,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Palette.signal,
        linearTrackColor: Palette.line,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Palette.signal,
        foregroundColor: Palette.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    );
  }
}
