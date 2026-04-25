import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salat_pro/core/app_colors.dart';
import 'package:salat_pro/l10n/app_strings.dart';
import 'package:salat_pro/l10n/l10n.dart';
import 'package:salat_pro/models/walk_weather_snapshot.dart';
import 'package:salat_pro/providers/settings_provider.dart';
import 'package:salat_pro/services/open_meteo_weather_service.dart';
import 'package:salat_pro/utils/walk_weather_advice.dart';

/// Compact “walk to the mosque” weather on the home feed (not a separate screen).
class WalkWeatherHomeCard extends StatefulWidget {
  const WalkWeatherHomeCard({
    super.key,
    required this.latitude,
    required this.longitude,
    this.refreshTick = 0,
  });

  final double? latitude;
  final double? longitude;

  /// Increment on home pull-to-refresh to refetch the same coordinates.
  final int refreshTick;

  @override
  State<WalkWeatherHomeCard> createState() => _WalkWeatherHomeCardState();
}

class _WalkWeatherHomeCardState extends State<WalkWeatherHomeCard> {
  WalkWeatherSnapshot? _data;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.latitude != null && widget.longitude != null) {
      _fetch();
    } else {
      _loading = false;
    }
  }

  @override
  void didUpdateWidget(covariant WalkWeatherHomeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.latitude == null || widget.longitude == null) {
      if (oldWidget.latitude != null || oldWidget.longitude != null) {
        setState(() {
          _data = null;
          _loading = false;
          _failed = false;
        });
      }
      return;
    }

    final posChanged =
        widget.latitude != oldWidget.latitude || widget.longitude != oldWidget.longitude;
    final tickChanged = widget.refreshTick != oldWidget.refreshTick;
    if (posChanged || tickChanged) {
      setState(() {
        _loading = true;
        if (_data == null) _failed = false;
      });
      _fetch();
    }
  }

  Future<void> _fetch() async {
    final lat = widget.latitude;
    final lon = widget.longitude;
    if (lat == null || lon == null) return;

    setState(() {
      _loading = true;
      if (_data == null) _failed = false;
    });

    final r = await OpenMeteoWeatherService.fetchCurrent(latitude: lat, longitude: lon);
    if (!mounted) return;
    setState(() {
      if (r != null) {
        _data = r;
        _failed = false;
      } else if (_data == null) {
        _failed = true;
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.latitude == null || widget.longitude == null) {
      return const SizedBox.shrink();
    }

    final palette = context.palette;
    final s = context.strings;
    final lang = context.select<SettingsProvider, String>((st) => st.languageCode);
    final isArabic = lang == 'ar';
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(palette, s.walkWeatherHomeSection),
        const SizedBox(height: 12),
        if (_loading && _data == null)
          _skeletonCard(context, palette, isLight)
        else if (_failed && _data == null)
          _errorCard(context, palette, s, isLight)
        else if (_data != null)
          _loadedCard(
            context,
            palette,
            s,
            isArabic,
            isLight,
            _data!,
            dimmed: _loading,
          ),
      ],
    );
  }

  Widget _sectionHeader(AppPalette palette, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: palette.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: palette.textSecondary,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _skeletonCard(BuildContext context, AppPalette palette, bool isLight) {
    return _cardShell(
      palette,
      isLight,
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: palette.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                context.strings.walkWeatherLoading,
                style: TextStyle(color: palette.textSecondary, fontSize: 14, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorCard(BuildContext context, AppPalette palette, AppStrings s, bool isLight) {
    return _cardShell(
      palette,
      isLight,
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Row(
          children: [
            Icon(Icons.wifi_tethering_error_rounded, color: palette.textSecondary.withValues(alpha: 0.75)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                s.walkWeatherCouldNotLoad,
                style: TextStyle(color: palette.textPrimary, fontSize: 13, height: 1.4),
              ),
            ),
            IconButton(
              onPressed: _fetch,
              icon: Icon(Icons.refresh_rounded, color: palette.primary),
              tooltip: s.walkWeatherRetry,
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadedCard(
    BuildContext context,
    AppPalette palette,
    AppStrings s,
    bool isArabic,
    bool isLight,
    WalkWeatherSnapshot snapshot, {
    required bool dimmed,
  }) {
    final advice = WalkWeatherAdvice.fromSnapshot(snapshot, isArabic: isArabic);
    final tempStr = snapshot.temperatureC.round().toString();
    final feelStr = snapshot.apparentTemperatureC.round().toString();
    final uv = snapshot.isDay ? (snapshot.uvIndex ?? 0) : 0.0;
    final wind = snapshot.windSpeedMs;

    final metrics = Text(
      [
        '${s.walkWeatherWindLabel} ${wind.toStringAsFixed(1)} m/s',
        if (snapshot.isDay) '${s.walkWeatherUvLabel} ${uv.toStringAsFixed(1)}',
      ].join(' · '),
      textAlign: isArabic ? TextAlign.right : TextAlign.start,
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      style: TextStyle(
        color: palette.textSecondary.withValues(alpha: 0.88),
        fontSize: 11,
        letterSpacing: 0.2,
        height: 1.35,
      ),
    );

    final inner = Opacity(
      opacity: dimmed ? 0.5 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLight ? palette.primary.withValues(alpha: 0.12) : palette.primary.withValues(alpha: 0.14),
                  border: Border.all(color: palette.primary.withValues(alpha: 0.35)),
                ),
                child: Icon(advice.icon, color: palette.primary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      advice.conditionLabel,
                      style: TextStyle(
                        color: palette.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: isArabic ? 0 : 1.2,
                      ),
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.walkWeatherTempLine(tempStr, feelStr),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                        letterSpacing: -0.3,
                      ),
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    ),
                  ],
                ),
              ),
              if (dimmed)
                Padding(
                  padding: EdgeInsets.only(left: isArabic ? 0 : 4, right: isArabic ? 4 : 0),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: palette.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            advice.leadSentence,
            textAlign: isArabic ? TextAlign.right : TextAlign.start,
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 15,
              height: 1.5,
              fontWeight: isLight ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
          if (advice.supportingLines.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final line in advice.supportingLines.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 4, left: isArabic ? 8 : 0, right: isArabic ? 0 : 8),
                      child: Icon(Icons.circle, size: 5, color: palette.secondary),
                    ),
                    Expanded(
                      child: Text(
                        line,
                        textAlign: isArabic ? TextAlign.right : TextAlign.start,
                        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.textSecondary.withValues(alpha: 0.92),
                          fontSize: 12.5,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 12),
          metrics,
          const SizedBox(height: 8),
          Text(
            s.walkWeatherDataAttribution,
            textAlign: isArabic ? TextAlign.right : TextAlign.center,
            style: TextStyle(
              color: palette.textSecondary.withValues(alpha: 0.55),
              fontSize: 10,
              height: 1.3,
            ),
          ),
        ],
      ),
    );

    return _cardShell(
      palette,
      isLight,
      inner,
    );
  }

  Widget _cardShell(AppPalette palette, bool isLight, Widget child) {
    final body = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLight
              ? [
                  palette.surface.withValues(alpha: 0.97),
                  Color.lerp(palette.surface, palette.primary, 0.06)!,
                ]
              : [
                  palette.primary.withValues(alpha: 0.1),
                  palette.fillVerySubtle,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isLight ? Color.lerp(palette.strokeVerySubtle, palette.primary, 0.22)! : palette.strokeVerySubtle,
          width: isLight ? 1.5 : 1,
        ),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: palette.primaryDeep.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: child,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: isLight ? body : BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: body),
    );
  }
}
