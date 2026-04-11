// ============================================================
// theme: app_theme.dart
// Global Material 3 theme — dark navy + emergency red palette.
// ============================================================

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ── colour palette ────────────────────────────────────────
  static const Color primary      = Color(0xFFE53935); // emergency red
  static const Color primaryDark  = Color(0xFFB71C1C);
  static const Color surface      = Color(0xFF0A0E1A); // deep navy black
  static const Color surfaceCard  = Color(0xFF131929);
  static const Color onSurface    = Color(0xFFEFEFEF);
  static const Color muted        = Color(0xFF8A97B0);
  static const Color success      = Color(0xFF43A047);
  static const Color warning      = Color(0xFFFB8C00);
  static const Color info         = Color(0xFF1E88E5);

  // Status → colour mapping
  static Color statusColor(String status) {
    switch (status) {
      case 'assigned':  return info;
      case 'onTheWay':  return warning;
      case 'arrived':   return success;
      case 'completed': return muted;
      default:          return primary; // pending
    }
  }

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: surface,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.white,
      secondary: Color(0xFF1E88E5),
      surface: surface,
      onSurface: onSurface,
      error: primary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceCard,
      foregroundColor: onSurface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: onSurface,
        letterSpacing: 0.5,
      ),
    ),
    cardTheme: CardThemeData(
      color: surfaceCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF1E2A40), width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: onSurface,
        side: const BorderSide(color: Color(0xFF1E2A40)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceCard,
      selectedColor: primary.withOpacity(0.25),
      labelStyle: const TextStyle(color: onSurface, fontWeight: FontWeight.w600),
      side: const BorderSide(color: Color(0xFF1E2A40)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: onSurface),
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: onSurface),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: onSurface),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface),
      bodyLarge: TextStyle(fontSize: 15, color: onSurface),
      bodyMedium: TextStyle(fontSize: 14, color: muted),
      labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: muted),
    ),
  );
}
