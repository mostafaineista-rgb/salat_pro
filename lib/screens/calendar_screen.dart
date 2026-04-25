import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:salat_pro/core/app_colors.dart';
import 'package:salat_pro/l10n/l10n.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = HijriCalendar.now();
    final now = DateTime.now();
    final p = context.palette;
    final s = context.strings;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [p.background, p.surface],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: p.background.withValues(alpha: 0.92),
                surfaceTintColor: Colors.transparent,
                title: Text(s.calendar),
                centerTitle: true,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _TodayCard(hijri: today, gregorian: now),
                    const SizedBox(height: 28),
                    Text(
                      s.upcomingEvents,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: p.textPrimary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: s.isArabic ? 0 : 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _UpcomingEventsCard(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.hijri, required this.gregorian});

  final HijriCalendar hijri;
  final DateTime gregorian;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.strings;
    final theme = Theme.of(context);

    final dayStr = s.localizeNumerals('${hijri.hDay}');
    final yearStr = s.localizeNumerals('${hijri.hYear}');
    final monthName = s.hijriMonthName(hijri.hMonth);
    final gregorianLine = s.localizeNumerals(s.formatGregorianFull(gregorian));
    final weekday = s.formatWeekday(gregorian);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.strokeVerySubtle),
        boxShadow: [
          BoxShadow(
            color: p.primary.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  dayStr,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: p.primary,
                    height: 1.05,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    monthName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$yearStr ${s.ahSuffix}',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: p.textSecondary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: p.strokeVerySubtle),
            ),
            Text(
              gregorianLine,
              style: theme.textTheme.titleSmall?.copyWith(
                color: p.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              weekday,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: p.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingEventsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.strings;
    final theme = Theme.of(context);
    final df = DateFormat.yMMMMd(s.localeCode);
    final events = <({String name, String date})>[
      (name: s.ramadan2026, date: df.format(DateTime(2026, 2, 18))),
      (name: s.eidFitr, date: df.format(DateTime(2026, 3, 20))),
      (name: s.hajjSeason, date: df.format(DateTime(2026, 5, 25))),
      (name: s.eidAdha, date: df.format(DateTime(2026, 6, 1))),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.strokeVerySubtle),
      ),
      child: Column(
        children: [
          for (var i = 0; i < events.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 16, endIndent: 16, color: p.strokeVerySubtle),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.event_rounded, size: 20, color: p.primary.withValues(alpha: 0.85)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.localizeNumerals(events[i].name),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: p.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.localizeNumerals(events[i].date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: p.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
