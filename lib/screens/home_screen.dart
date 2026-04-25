import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adhan/adhan.dart';
import 'package:salat_pro/core/app_colors.dart';
import 'package:geolocator/geolocator.dart';
import 'package:salat_pro/providers/prayer_provider.dart';
import 'package:salat_pro/providers/settings_provider.dart';
import 'package:salat_pro/services/adhan_service.dart';
import 'package:salat_pro/l10n/app_strings.dart';
import 'package:salat_pro/l10n/l10n.dart';
import 'package:salat_pro/utils/daily_reflections.dart';
import 'package:salat_pro/screens/notification_history_screen.dart';
import 'package:salat_pro/widgets/walk_weather_home_card.dart';
import 'package:salat_pro/utils/platform_support.dart';
import 'package:salat_pro/models/hadith_moment.dart';
import 'package:salat_pro/services/hadith_service.dart';

/// After today's Isha, adhan reports [Prayer.none] and [PrayerTimes.timeForPrayer] returns null.
/// Resolve to tomorrow's Fajr so UI and countdowns do not crash on `!`.
({Prayer prayer, DateTime time})? _resolveNextPrayerAndTime(
  PrayerTimes times,
  Position? position,
  CalculationMethod method,
) {
  final next = times.nextPrayer();
  final at = times.timeForPrayer(next);
  if (at != null) {
    return (prayer: next, time: at);
  }
  if (position == null) return null;
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  final dayTimes = AdhanService.getPrayerTimesForDate(position, method, tomorrow);
  return (prayer: Prayer.fajr, time: dayTimes.fajr);
}

Widget _homeAppBarCircleIcon(
  BuildContext context, {
  required AppPalette palette,
  required String tooltip,
  required VoidCallback onPressed,
  required IconData icon,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.light
          ? palette.surface.withValues(alpha: 0.9)
          : palette.fillVerySubtle,
      shape: BoxShape.circle,
      boxShadow: Theme.of(context).brightness == Brightness.light
          ? [
              // stitch/home_light_mode “spiritual-shadow”: teal at very low opacity
              BoxShadow(
                color: palette.primary.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ]
          : [
              // stitch/nocturnal_iman: tinted ambient lift, not pure black
              BoxShadow(
                color: palette.onSurface.withValues(alpha: 0.08),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: palette.primary.withValues(alpha: 0.1),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
    ),
    child: IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, color: palette.primary, size: 20),
    ),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late DailyReflection _reflection;
  AppLifecycleState? _lastLifecycle;
  HadithMoment? _hadith;
  bool _hadithBootstrapping = true;
  int _weatherRefreshTick = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reflection = DailyReflections.random();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapHadith());
  }

  Future<void> _bootstrapHadith() async {
    try {
      final first = await HadithService.loadCached();
      if (!mounted) return;
      setState(() => _hadith = first);

      final next = await HadithService.bootstrapFromCacheOrFetch();
      if (!mounted) return;
      setState(() => _hadith = next);
    } finally {
      if (mounted) setState(() => _hadithBootstrapping = false);
    }
  }

  Future<void> _syncHadithOnResume() async {
    final next = await HadithService.bootstrapFromCacheOrFetch();
    if (!mounted) return;
    setState(() => _hadith = next ?? _hadith);
  }

  Future<void> _refreshHadithOnUserPull() async {
    final w = await HadithService.fetchRandomNew(userInitiated: true);
    if (!mounted) return;
    if (w != null) setState(() => _hadith = w);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // New reflection when returning from background (counts as "opening" the app again).
    if (state == AppLifecycleState.resumed && _lastLifecycle == AppLifecycleState.paused) {
      setState(() {
        _reflection = DailyReflections.random();
      });
      unawaited(_syncHadithOnResume());
    }
    _lastLifecycle = state;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final times = context.select<PrayerProvider, PrayerTimes?>((p) => p.currentPrayerTimes);
    final position = context.select<PrayerProvider, Position?>((p) => p.currentPosition);
    final city = context.select<SettingsProvider, String>((s) => s.city);
    final palette = context.palette;
    final lang = context.select<SettingsProvider, String>((s) => s.languageCode);
    final s = context.strings;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        children: [
          // Isolate expensive backdrop painting from scrolling content updates.
          RepaintBoundary(
            child: isLight
                ? _buildLightHomeBackdrop(palette)
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      // Premium Background Image (decode at screen resolution to reduce work on load)
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final dpr = MediaQuery.devicePixelRatioOf(context);
                            final w = (constraints.maxWidth * dpr).round();
                            final h = (constraints.maxHeight * dpr).round();
                            return Image.asset(
                              'assets/images/mosque_bg.png',
                              fit: BoxFit.cover,
                              cacheWidth: w > 0 ? w : null,
                              cacheHeight: h > 0 ? h : null,
                              filterQuality: FilterQuality.medium,
                              errorBuilder: (ctx, error, stackTrace) {
                                final pa = ctx.palette;
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [pa.background, pa.surface],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      // Darker Overlay for Readability
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                palette.imageScrimTop,
                                palette.imageScrimBottom,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // stitch/salat_pro_home_screen: faint teal veil (keeps photo readable)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: const Alignment(0, -0.52),
                                radius: 1.05,
                                colors: [
                                  palette.primary.withValues(alpha: 0.07),
                                  palette.primary.withValues(alpha: 0.02),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.42, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          SafeArea(
            child: RefreshIndicator(
              color: palette.primary,
              onRefresh: () async {
                await Future.wait<void>([
                  context.read<PrayerProvider>().refreshPrayerTimes(context.read<SettingsProvider>()),
                  _refreshHadithOnUserPull(),
                ]);
                if (mounted) setState(() => _weatherRefreshTick++);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  _buildHeader(context, city, palette, s),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Column(
                        children: [
                          WalkWeatherHomeCard(
                            latitude: position?.latitude,
                            longitude: position?.longitude,
                            refreshTick: _weatherRefreshTick,
                          ),
                          const SizedBox(height: 24),
                          const _HomePrayerHero(),
                          const SizedBox(height: 40),
                          _buildSectionHeader(palette, s.prayerTimesSection),
                          const SizedBox(height: 16),
                          _buildPrayerList(
                            palette,
                            times,
                            s,
                            context.select<SettingsProvider, bool>((st) => st.use24HourClock),
                            isLight,
                          ),
                          const SizedBox(height: 32),
                          _buildDailyVerse(palette, lang, s, isLight),
                          const SizedBox(height: 24),
                          _buildHadithCard(palette, lang, s, isLight),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Light theme: Veil-style tonal layers (warm neutrals + soft teal wash), no photo.
  Widget _buildLightHomeBackdrop(AppPalette p) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.45, 1.0],
              colors: [
                Color.lerp(p.background, Colors.white, 0.38)!,
                p.background,
                Color.lerp(p.surfaceHighest, p.primary, 0.04)!,
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.48),
              radius: 1.02,
              colors: [
                p.primary.withValues(alpha: 0.07),
                p.primary.withValues(alpha: 0.02),
                Colors.transparent,
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(AppPalette palette, String title) {
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

  Widget _buildHeader(BuildContext context, String city, AppPalette palette, AppStrings s) {
    final fallbackWidth = MediaQuery.sizeOf(context).width - 88;
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      floating: true,
      centerTitle: false,
      title: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth.isFinite && constraints.maxWidth > 0
              ? constraints.maxWidth
              : fallbackWidth;
          return SizedBox(
            width: w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.formatCalendarDay(DateTime.now()),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: palette.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Tooltip(
                        message: city == 'Detecting...' ? s.detectingCity : city,
                        child: Text(
                          city == 'Detecting...' ? s.detectingCity : city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        if (supportsAdhanSettingsUi)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _homeAppBarCircleIcon(
              context,
              palette: palette,
              tooltip: s.homeAdhanAndAlerts,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationHistoryScreen()),
                );
              },
              icon: Icons.notifications_outlined,
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _homeAppBarCircleIcon(
            context,
            palette: palette,
            tooltip: s.homeRefreshTooltip,
            onPressed: () =>
                context.read<PrayerProvider>().refreshPrayerTimes(context.read<SettingsProvider>()),
            icon: Icons.refresh,
          ),
        ),
      ],
    );
  }

  Widget _buildPrayerList(
    AppPalette palette,
    PrayerTimes? times,
    AppStrings s,
    bool use24HourClock,
    bool isLight,
  ) {
    if (times == null) return const SizedBox.shrink();

    final next = times.nextPrayer();

    return Column(
      children: [
        _buildPrayerRow(
          palette,
          s,
          s.prayerName(Prayer.fajr),
          times.fajr,
          next == Prayer.fajr,
          use24HourClock,
          isLight,
        ),
        _buildPrayerRow(
          palette,
          s,
          s.prayerName(Prayer.sunrise),
          times.sunrise,
          next == Prayer.sunrise,
          use24HourClock,
          isLight,
        ),
        _buildPrayerRow(
          palette,
          s,
          s.prayerName(Prayer.dhuhr),
          times.dhuhr,
          next == Prayer.dhuhr,
          use24HourClock,
          isLight,
        ),
        _buildPrayerRow(
          palette,
          s,
          s.prayerName(Prayer.asr),
          times.asr,
          next == Prayer.asr,
          use24HourClock,
          isLight,
        ),
        _buildPrayerRow(
          palette,
          s,
          s.prayerName(Prayer.maghrib),
          times.maghrib,
          next == Prayer.maghrib,
          use24HourClock,
          isLight,
        ),
        _buildPrayerRow(
          palette,
          s,
          s.prayerName(Prayer.isha),
          times.isha,
          next == Prayer.isha,
          use24HourClock,
          isLight,
        ),
      ],
    );
  }

  Widget _buildPrayerRow(
    AppPalette palette,
    AppStrings s,
    String name,
    DateTime time,
    bool isNext,
    bool use24HourClock,
    bool isLight,
  ) {
    final fillColor = isLight
        ? (isNext ? palette.primary.withValues(alpha: 0.13) : palette.surface.withValues(alpha: 0.94))
        : (isNext ? palette.surfaceHigh : palette.surfaceLow);
    final borderColor = isLight
        ? (isNext
            ? palette.primary.withValues(alpha: 0.42)
            : Color.lerp(palette.strokeVerySubtle, palette.textPrimary, 0.12)!)
        : (isNext ? palette.primary.withValues(alpha: 0.3) : palette.strokeVerySubtle);

    final row = Container(
      padding: EdgeInsets.fromLTRB(
        isNext && !isLight ? 26 : 20,
        20,
        20,
        20,
      ),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(20),
        border: isLight
            ? Border.all(color: borderColor, width: isNext ? 1 : 1.5)
            : (isNext ? Border.all(color: borderColor, width: 1) : null),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: palette.primaryDeep.withValues(alpha: 0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                  spreadRadius: 0,
                ),
              ]
            : (isNext
                ? [
                    BoxShadow(
                      color: palette.primary.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: Offset.zero,
                    ),
                  ]
                : null),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isNext)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(Icons.auto_awesome, size: 16, color: palette.primary),
                ),
              Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  color: isNext
                      ? (isLight ? palette.primary : palette.textPrimary)
                      : (isLight ? palette.textPrimary : palette.textPrimary.withValues(alpha: 0.88)),
                  fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            s.formatTimeHm(time, use24HourClock: use24HourClock),
            style: TextStyle(
              fontSize: 16,
              color: isNext
                  ? palette.primary
                  : (isLight ? palette.textPrimary : palette.textSecondary),
              fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    final Widget content = (isNext && !isLight)
        ? Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              row,
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.primary,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          )
        : row;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: isLight
            ? BackdropFilter(filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), child: content)
            : content,
      ),
    );
  }

  Widget _buildDailyVerse(AppPalette palette, String lang, AppStrings s, bool isLight) {
    final verseBody = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLight
              ? [
                  palette.surface.withValues(alpha: 0.97),
                  Color.lerp(palette.surface, palette.primary, 0.07)!,
                ]
              : [
                  palette.surfaceHighest.withValues(alpha: 0.94),
                  Color.lerp(palette.surfaceHighest, palette.primary, 0.07)!,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLight ? Color.lerp(palette.strokeVerySubtle, palette.primary, 0.25)! : palette.strokeVerySubtle,
          width: isLight ? 1.5 : 1,
        ),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: palette.primaryDeep.withValues(alpha: 0.08),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ]
            : [
                BoxShadow(
                  color: palette.onSurface.withValues(alpha: 0.06),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          lang == 'ar'
              ? Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(
                      child: Text(
                        s.spiritualReflection,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          color: palette.primary,
                          letterSpacing: 0,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.format_quote_rounded, color: palette.primary, size: 28),
                  ],
                )
              : Row(
                  children: [
                    Icon(Icons.format_quote_rounded, color: palette.primary, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s.spiritualReflection,
                        style: TextStyle(
                          color: palette.primary,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 20),
          Text(
            _reflection.quoteForLocale(lang),
            textAlign: lang == 'ar' ? TextAlign.right : TextAlign.start,
            textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            style: TextStyle(
              fontSize: 20,
              fontStyle: FontStyle.italic,
              color: palette.textPrimary,
              height: 1.6,
              fontWeight: isLight ? FontWeight.w400 : FontWeight.w300,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: lang == 'ar' ? Alignment.bottomLeft : Alignment.bottomRight,
            child: Text(
              _reflection.citationForLocale(lang),
              style: TextStyle(
                color: isLight ? palette.textSecondary.withValues(alpha: 0.88) : palette.textSecondary.withValues(alpha: 0.7),
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: isLight
          ? verseBody
          : BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: verseBody),
    );
  }

  Widget _buildHadithCard(AppPalette palette, String lang, AppStrings s, bool isLight) {
    if (_hadithBootstrapping && _hadith == null) {
      return _hadithCardShell(
        palette,
        isLight,
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2, color: palette.primary),
            ),
          ),
        ),
      );
    }

    final h = _hadith ??
        HadithMoment.bundledFallback(dayKey: HadithMoment.dayKeyLocal(DateTime.now()));
    final body = h.bodyForLocale(lang);
    final chapter = h.chapterForLocale(lang);
    final bodyRtl = lang == 'ar' && h.hadithArabic.trim().isNotEmpty;
    final chapterRtl = bodyRtl;

    final inner = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        lang == 'ar'
            ? Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: Text(
                      s.dailyHadith,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: palette.primary,
                        letterSpacing: 0,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.menu_book_rounded, color: palette.primary, size: 28),
                ],
              )
            : Row(
                children: [
                  Icon(Icons.menu_book_rounded, color: palette.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.dailyHadith,
                      style: TextStyle(
                        color: palette.primary,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
        if (h.fromBundledFallback) ...[
          const SizedBox(height: 10),
          Text(
            s.hadithBundledHint,
            textAlign: lang == 'ar' ? TextAlign.right : TextAlign.start,
            textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            style: TextStyle(
              fontSize: 11,
              height: 1.35,
              color: palette.textSecondary.withValues(alpha: 0.85),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Directionality(
          textDirection: bodyRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Text(
            body,
            textAlign: bodyRtl ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              fontSize: 17,
              fontStyle: FontStyle.italic,
              color: palette.textPrimary,
              height: 1.55,
              fontWeight: isLight ? FontWeight.w400 : FontWeight.w300,
            ),
          ),
        ),
        if (chapter.isNotEmpty) ...[
          const SizedBox(height: 12),
          Directionality(
            textDirection: chapterRtl ? TextDirection.rtl : TextDirection.ltr,
            child: Text(
              chapter,
              textAlign: chapterRtl ? TextAlign.right : TextAlign.left,
              style: TextStyle(
                color: palette.textSecondary.withValues(alpha: isLight ? 0.88 : 0.75),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: lang == 'ar' ? Alignment.centerLeft : Alignment.centerRight,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              h.refLabel,
              textAlign: lang == 'ar' ? TextAlign.left : TextAlign.right,
              style: TextStyle(
                color: isLight ? palette.textSecondary.withValues(alpha: 0.88) : palette.textSecondary.withValues(alpha: 0.7),
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          h.fromBundledFallback ? s.hadithBundledFooter : s.hadithSourceLine,
          textAlign: lang == 'ar' ? TextAlign.right : TextAlign.start,
          textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          style: TextStyle(
            color: palette.textSecondary.withValues(alpha: 0.65),
            fontSize: 10,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );

    return _hadithCardShell(
      palette,
      isLight,
      inner,
    );
  }

  Widget _hadithCardShell(AppPalette palette, bool isLight, Widget child) {
    final verseBody = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLight
              ? [
                  palette.surface.withValues(alpha: 0.97),
                  Color.lerp(palette.surface, palette.primary, 0.05)!,
                ]
              : [
                  palette.surfaceHighest.withValues(alpha: 0.92),
                  Color.lerp(palette.surfaceHighest, palette.primary, 0.06)!,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLight ? Color.lerp(palette.strokeVerySubtle, palette.primary, 0.2)! : palette.strokeVerySubtle,
          width: isLight ? 1.5 : 1,
        ),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: palette.primaryDeep.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: palette.onSurface.withValues(alpha: 0.05),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: child,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: isLight
          ? verseBody
          : BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: verseBody),
    );
  }
}

/// Next-prayer ring, pulse, and ticking countdown — isolated so a 1s timer does not rebuild the whole home scroll view.
class _HomePrayerHero extends StatefulWidget {
  const _HomePrayerHero();

  @override
  State<_HomePrayerHero> createState() => _HomePrayerHeroState();
}

class _HomePrayerHeroState extends State<_HomePrayerHero> with SingleTickerProviderStateMixin {
  Timer? _timer;
  Duration _timeUntilNextPrayer = Duration.zero;
  late AnimationController _pulseController;
  PrayerProvider? _prayerProvider;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback(_attachPrayerListener);
  }

  void _attachPrayerListener(_) {
    if (!mounted) return;
    final p = context.read<PrayerProvider>();
    _prayerProvider?.removeListener(_onPrayerChanged);
    _prayerProvider = p;
    p.addListener(_onPrayerChanged);
    _onPrayerChanged();
  }

  void _onPrayerChanged() {
    if (!mounted) return;
    final t = _prayerProvider?.currentPrayerTimes;
    if (t != null && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (t == null && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _prayerProvider?.removeListener(_onPrayerChanged);
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    void tick() {
      if (!mounted) return;
      final provider = context.read<PrayerProvider>();
      final settings = context.read<SettingsProvider>();
      final times = provider.currentPrayerTimes;
      if (times != null) {
        final resolved = _resolveNextPrayerAndTime(times, provider.currentPosition, settings.method);
        if (resolved != null) {
          final until = resolved.time.difference(DateTime.now());
          setState(() {
            _timeUntilNextPrayer = until;
          });
          if (until.isNegative) {
            provider.refreshPrayerTimes(settings);
          }
        }
      }
    }

    tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  static String _formatDuration(Duration duration) {
    if (duration.isNegative) return '00:00:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    final twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<PrayerProvider, bool>((p) => p.isLoading);
    final times = context.select<PrayerProvider, PrayerTimes?>((p) => p.currentPrayerTimes);
    final palette = context.palette;
    final s = context.strings;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final use24HourClock =
        context.select<SettingsProvider, bool>((st) => st.use24HourClock);

    if (isLoading) {
      return SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator(color: palette.primary)),
      );
    }

    if (times == null) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Text(
            s.calculatingTimes,
            style: TextStyle(color: palette.textSecondary),
          ),
        ),
      );
    }

    final provider = context.read<PrayerProvider>();
    final settings = context.read<SettingsProvider>();
    final resolvedNext = _resolveNextPrayerAndTime(times, provider.currentPosition, settings.method);
    if (resolvedNext == null) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Text(
            s.calculatingTimes,
            style: TextStyle(color: palette.textSecondary),
          ),
        ),
      );
    }

    final nextPrayer = resolvedNext.prayer;
    final nextPrayerTime = resolvedNext.time;
    final currentPrayer = times.currentPrayer();
    final currentPrayerTime = times.timeForPrayer(currentPrayer);

    var progress = 1.0;
    if (currentPrayerTime != null) {
      final total = nextPrayerTime.difference(currentPrayerTime).inSeconds;
      if (total > 0) {
        final elapsed = DateTime.now().difference(currentPrayerTime).inSeconds;
        progress = (elapsed / total).clamp(0.0, 1.0);
      }
    }

    final heroDial = Container(
      width: 190,
      height: 190,
      decoration: BoxDecoration(
        color: isLight ? palette.surface.withValues(alpha: 0.98) : palette.fillVerySubtle,
        shape: BoxShape.circle,
        border: Border.all(
          color: isLight
              ? Color.lerp(palette.strokeVerySubtle, palette.primary, 0.35)!
              : palette.strokeVerySubtle,
          width: isLight ? 2 : 1,
        ),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: palette.primaryDeep.withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ]
            : [
                BoxShadow(
                  color: palette.onSurface.withValues(alpha: 0.1),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: palette.primary.withValues(alpha: 0.12),
                  blurRadius: 18,
                  spreadRadius: -6,
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            s.prayerNameHero(nextPrayer),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w300,
              letterSpacing: 6,
              color: isLight ? palette.primary : palette.accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.formatTimeHm(nextPrayerTime, use24HourClock: use24HourClock),
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
        ],
      ),
    );

    return Column(
      children: [
        const SizedBox(height: 20),
        Stack(
          alignment: Alignment.center,
          children: [
            if (!isLight)
              IgnorePointer(
                child: Opacity(
                  opacity: 0.1,
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.rotate(
                          angle: 0.785398,
                          child: Container(
                            width: 168,
                            height: 168,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: palette.primary, width: 1),
                            ),
                          ),
                        ),
                        Transform.rotate(
                          angle: -0.2,
                          child: Container(
                            width: 152,
                            height: 152,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: palette.primary, width: 1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 210 + (10 * _pulseController.value),
                  height: 210 + (10 * _pulseController.value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: palette.primary
                            .withValues(alpha: (isLight ? 0.16 : 0.1) * _pulseController.value),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(
              width: 220,
              height: 220,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: isLight
                      ? const <BoxShadow>[]
                      : [
                          BoxShadow(
                            color: palette.primary.withValues(alpha: 0.28),
                            blurRadius: 12,
                            spreadRadius: 0,
                          ),
                        ],
                ),
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: isLight
                      ? Color.lerp(palette.surface, palette.textPrimary, 0.12)!
                      : palette.progressTrack,
                  valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: isLight
                  ? heroDial
                  : BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: heroDial,
                    ),
            ),
          ],
        ),
        const SizedBox(height: 48),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: isLight
                ? palette.surface.withValues(alpha: 0.95)
                : palette.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color:
                  isLight ? Color.lerp(palette.strokeVerySubtle, palette.primary, 0.3)! : palette.strokeVerySubtle,
              width: isLight ? 1.5 : 0.5,
            ),
            boxShadow: isLight
                ? [
                    BoxShadow(
                      color: palette.primaryDeep.withValues(alpha: 0.07),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, size: 16, color: palette.primary),
              const SizedBox(width: 8),
              Text(
                s.timeToPrayer,
                style: TextStyle(
                  color: palette.textSecondary,
                  letterSpacing: 1.5,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatDuration(_timeUntilNextPrayer),
                style: TextStyle(
                  fontSize: 16,
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

