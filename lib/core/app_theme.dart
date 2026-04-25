import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salat_pro/core/app_colors.dart';

class AppTheme {
  static ThemeData _base(AppPalette p, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: p.background,
      extensions: <ThemeExtension<dynamic>>[p],
      textTheme: GoogleFonts.manropeTextTheme(
        base.textTheme.copyWith(
          displayLarge: GoogleFonts.notoSerif(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: p.onBackground,
          ),
          headlineMedium: GoogleFonts.notoSerif(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: p.onBackground,
          ),
          titleLarge: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          bodyLarge: GoogleFonts.manrope(
            fontSize: 16,
            height: 1.5,
          ),
          labelMedium: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: p.surfaceMedium,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? Colors.transparent : p.surfaceLow,
        indicatorColor:
            isDark ? p.accent.withValues(alpha: 0.22) : p.primary.withValues(alpha: 0.1),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (!isDark) {
            return const IconThemeData(size: 24);
          }
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: p.accent, size: 24);
          }
          return IconThemeData(color: p.onSurface.withValues(alpha: 0.4), size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          const base = TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
          if (!isDark) return base;
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(color: p.accent, letterSpacing: 0.2);
          }
          return base.copyWith(color: p.onSurface.withValues(alpha: 0.45));
        }),
      ),
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: p.primary,
              secondary: p.secondary,
              surface: p.background,
              onSurface: p.onSurface,
              error: p.error,
            )
          : ColorScheme.light(
              primary: p.primary,
              onPrimary: p.onPrimary,
              primaryContainer: const Color(0xFF00695C),
              onPrimaryContainer: const Color(0xFF94E5D5),
              secondary: p.secondary,
              onSecondary: Colors.white,
              secondaryContainer: const Color(0xFFFED488),
              onSecondaryContainer: const Color(0xFF785A1A),
              tertiary: const Color(0xFF464644),
              onTertiary: Colors.white,
              error: p.error,
              onError: Colors.white,
              surface: p.background,
              onSurface: p.onSurface,
              onSurfaceVariant: p.textSecondary,
              outline: const Color(0xFF6E7976),
              outlineVariant: const Color(0xFFBEC9C5),
            ),
    );
  }

  static ThemeData get darkTheme => _base(AppPalette.dark, Brightness.dark);
  static ThemeData get lightTheme => _base(AppPalette.light, Brightness.light);
}
