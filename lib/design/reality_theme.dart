import 'package:flutter/material.dart';

/// Shared midnight palette for myReality.
abstract final class RealityTheme {
  static const background = Color(0xFF0B1426);
  static const surface = Color(0xFF14233D);
  static const elevated = Color(0xFF1B2D4A);
  static const text = Color(0xFFF5F7FB);
  static const muted = Color(0xFF99A9BF);
  static const accent = Color(0xFF91D9CE);
  static const border = Color(0xFF30415C);

  static ThemeData get dark {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
        ).copyWith(
          primary: accent,
          secondary: const Color(0xFFB9B3EB),
          surface: surface,
          onSurface: text,
          onSurfaceVariant: muted,
          outline: border,
          primaryContainer: elevated,
          onPrimaryContainer: text,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w700,
          letterSpacing: -.8,
          color: text,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        margin: const EdgeInsets.only(bottom: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: border, width: .6),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: background,
        indicatorColor: elevated,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevated,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: elevated,
        linearMinHeight: 7,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        showDragHandle: true,
        modalBackgroundColor: surface,
      ),
    );
  }
}
