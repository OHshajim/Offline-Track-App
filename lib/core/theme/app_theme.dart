import 'package:flutter/material.dart';

class AppTheme {
  // Dark Base
  static const Color bgDark         = Color(0xFF060B14);
  static const Color surfaceDark    = Color(0xFF0D1420);
  static const Color cardDark       = Color(0xFF111B2E);
  static const Color cardBorderDark = Color(0x18FFFFFF);

  // Cyan-first accent palette
  static const Color primaryCyan  = Color(0xFF00D4E8);
  static const Color cyanGlow     = Color(0xFF4DE8F5);
  static const Color cyanDark     = Color(0xFF0099AA);

  // Secondary accents
  static const Color accentViolet  = Color(0xFF7C6FF7);
  static const Color accentEmerald = Color(0xFF10D98A);
  static const Color accentAmber   = Color(0xFFF59E0B);
  static const Color accentRose    = Color(0xFFF43F5E);

  // Legacy aliases
  static const Color primaryViolet = accentViolet;
  static const Color primaryGlow   = cyanGlow;
  static const Color accentCyan    = primaryCyan;

  // Text
  static const Color textPrimary   = Color(0xFFF0FAFF);
  static const Color textSecondary = Color(0xFF8BA7C0);
  static const Color textMuted     = Color(0xFF4A6075);

  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':   return accentRose;
      case 'medium': return accentAmber;
      case 'low':
      default:       return primaryCyan;
    }
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'closed':        return accentEmerald;
      case 'in progress':
      case 'contacted':     return primaryCyan;
      case 'follow-up due':
      case 'overdue':       return accentRose;
      case 'pending':
      case 'new':
      default:              return accentViolet;
    }
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: primaryCyan,
      colorScheme: const ColorScheme.dark(
        primary: primaryCyan,
        secondary: accentViolet,
        surface: surfaceDark,
        error: accentRose,
        onPrimary: Color(0xFF060B14),
        onSurface: textPrimary,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: cardBorderDark, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: cardBorderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: cardBorderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryCyan, width: 1.8),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryCyan,
        foregroundColor: const Color(0xFF060B14),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryCyan,
          foregroundColor: const Color(0xFF060B14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceDark,
        contentTextStyle: const TextStyle(color: textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: primaryCyan, width: 0.8),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primaryCyan : textMuted),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? primaryCyan.withValues(alpha: 0.35)
                : textMuted.withValues(alpha: 0.2)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryCyan,
        inactiveTrackColor: textMuted.withValues(alpha: 0.25),
        thumbColor: primaryCyan,
        overlayColor: primaryCyan.withValues(alpha: 0.15),
        trackHeight: 3,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryCyan,
      ),
      dividerTheme: const DividerThemeData(
        color: cardBorderDark,
        thickness: 1,
      ),
    );
  }
}
