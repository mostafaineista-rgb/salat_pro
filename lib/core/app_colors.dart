import 'package:flutter/material.dart';

/// Semantic colors for Salat Pro, provided per theme via [ThemeExtension].
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.surface,
    required this.surfaceLow,
    required this.surfaceMedium,
    required this.surfaceHigh,
    required this.surfaceHighest,
    required this.glassBase,
    required this.glassStroke,
    required this.textPrimary,
    required this.textSecondary,
    required this.onBackground,
    required this.onSurface,
    required this.onPrimary,
    required this.error,
    required this.imageScrimTop,
    required this.imageScrimBottom,
    required this.fillVerySubtle,
    required this.strokeVerySubtle,
    required this.progressTrack,
    required this.primaryDeep,
  });

  final Color background;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color surface;
  final Color surfaceLow;
  final Color surfaceMedium;
  final Color surfaceHigh;
  final Color surfaceHighest;
  final Color glassBase;
  final Color glassStroke;
  final Color textPrimary;
  final Color textSecondary;
  final Color onBackground;
  final Color onSurface;
  final Color onPrimary;
  final Color error;

  /// Gradient overlay on hero imagery (mosque background).
  final Color imageScrimTop;
  final Color imageScrimBottom;

  /// Glass / frosted fills and hairline borders (replaces hard-coded white alphas).
  final Color fillVerySubtle;
  final Color strokeVerySubtle;
  final Color progressTrack;
  final Color primaryDeep;

  LinearGradient get primaryGradient => LinearGradient(
        colors: [primary, primaryDeep],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get goldGradient => LinearGradient(
        colors: [secondary, accent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Dark — “Nocturnal Iman” ([stitch/nocturnal_iman], [stitch/salat_pro_home_screen]): deep
  /// teal base, gold accent, on-surface-variant for muted copy, ghost strokes from outline-variant.
  static const AppPalette dark = AppPalette(
    background: Color(0xFF0D1514),
    primary: Color(0xFF94D3C1),
    secondary: Color(0xFFC5A059),
    accent: Color(0xFFE9C176),
    surface: Color(0xFF151D1C),
    surfaceLow: Color(0xFF151D1C),
    surfaceMedium: Color(0xFF192120),
    surfaceHigh: Color(0xFF232C2A),
    surfaceHighest: Color(0xFF2E3635),
    glassBase: Color(0x662E3635),
    glassStroke: Color(0x26BFC9C4),
    textPrimary: Color(0xFFDCE4E2),
    textSecondary: Color(0xFFBFC9C4),
    onBackground: Color(0xFFDCE4E2),
    onSurface: Color(0xFFDCE4E2),
    onPrimary: Color(0xFF00382E),
    error: Color(0xFFFFB4AB),
    imageScrimTop: Color(0x59000000),
    imageScrimBottom: Color(0xB80D1514),
    fillVerySubtle: Color(0x0DFFFFFF),
    strokeVerySubtle: Color(0x263F4945),
    progressTrack: Color(0x14FFFFFF),
    primaryDeep: Color(0xFF004D40),
  );

  /// Light — “Veil Light” (stitch/home_light_mode, stitch/veil_light): warm vellum,
  /// deep teal primary, muted gold accents (Material-style tokens).
  static const AppPalette light = AppPalette(
    background: Color(0xFFFBF9F0),
    primary: Color(0xFF004F45),
    secondary: Color(0xFF775A19),
    accent: Color(0xFFE9C176),
    surface: Color(0xFFF5F4EB),
    surfaceLow: Color(0xFFF5F4EB),
    surfaceMedium: Color(0xFFF0EEE5),
    surfaceHigh: Color(0xFFEAE8DF),
    surfaceHighest: Color(0xFFE4E3DA),
    glassBase: Color(0xCCFFFFFF),
    glassStroke: Color(0x40BEC9C5),
    textPrimary: Color(0xFF1B1C17),
    textSecondary: Color(0xFF3E4946),
    onBackground: Color(0xFF1B1C17),
    onSurface: Color(0xFF1B1C17),
    onPrimary: Color(0xFFFFFFFF),
    error: Color(0xFFBA1A1A),
    imageScrimTop: Color(0x33004F45),
    imageScrimBottom: Color(0x72004F45),
    fillVerySubtle: Color(0x0D004F45),
    strokeVerySubtle: Color(0x33BEC9C5),
    progressTrack: Color(0xFFE4E3DA),
    primaryDeep: Color(0xFF005046),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? surface,
    Color? surfaceLow,
    Color? surfaceMedium,
    Color? surfaceHigh,
    Color? surfaceHighest,
    Color? glassBase,
    Color? glassStroke,
    Color? textPrimary,
    Color? textSecondary,
    Color? onBackground,
    Color? onSurface,
    Color? onPrimary,
    Color? error,
    Color? imageScrimTop,
    Color? imageScrimBottom,
    Color? fillVerySubtle,
    Color? strokeVerySubtle,
    Color? progressTrack,
    Color? primaryDeep,
  }) {
    return AppPalette(
      background: background ?? this.background,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      surface: surface ?? this.surface,
      surfaceLow: surfaceLow ?? this.surfaceLow,
      surfaceMedium: surfaceMedium ?? this.surfaceMedium,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      surfaceHighest: surfaceHighest ?? this.surfaceHighest,
      glassBase: glassBase ?? this.glassBase,
      glassStroke: glassStroke ?? this.glassStroke,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      onBackground: onBackground ?? this.onBackground,
      onSurface: onSurface ?? this.onSurface,
      onPrimary: onPrimary ?? this.onPrimary,
      error: error ?? this.error,
      imageScrimTop: imageScrimTop ?? this.imageScrimTop,
      imageScrimBottom: imageScrimBottom ?? this.imageScrimBottom,
      fillVerySubtle: fillVerySubtle ?? this.fillVerySubtle,
      strokeVerySubtle: strokeVerySubtle ?? this.strokeVerySubtle,
      progressTrack: progressTrack ?? this.progressTrack,
      primaryDeep: primaryDeep ?? this.primaryDeep,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceLow: Color.lerp(surfaceLow, other.surfaceLow, t)!,
      surfaceMedium: Color.lerp(surfaceMedium, other.surfaceMedium, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      surfaceHighest: Color.lerp(surfaceHighest, other.surfaceHighest, t)!,
      glassBase: Color.lerp(glassBase, other.glassBase, t)!,
      glassStroke: Color.lerp(glassStroke, other.glassStroke, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      onBackground: Color.lerp(onBackground, other.onBackground, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      error: Color.lerp(error, other.error, t)!,
      imageScrimTop: Color.lerp(imageScrimTop, other.imageScrimTop, t)!,
      imageScrimBottom: Color.lerp(imageScrimBottom, other.imageScrimBottom, t)!,
      fillVerySubtle: Color.lerp(fillVerySubtle, other.fillVerySubtle, t)!,
      strokeVerySubtle: Color.lerp(strokeVerySubtle, other.strokeVerySubtle, t)!,
      progressTrack: Color.lerp(progressTrack, other.progressTrack, t)!,
      primaryDeep: Color.lerp(primaryDeep, other.primaryDeep, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}
