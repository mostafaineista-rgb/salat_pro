import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salat_pro/core/app_update_config.dart';
import 'package:salat_pro/core/main_nav_scope.dart';
import 'package:salat_pro/services/app_update_service.dart';
import 'package:salat_pro/core/app_colors.dart';
import 'package:salat_pro/providers/prayer_provider.dart';
import 'package:salat_pro/providers/settings_provider.dart';
import 'home_screen.dart';
import 'qibla_screen.dart';
import 'calendar_screen.dart';
import 'azkar_screen.dart';
import 'settings_screen.dart';
import 'nearest_mosque_screen.dart';
import 'package:salat_pro/l10n/l10n.dart';
import 'package:salat_pro/services/permissions_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  /// Tabs are built on first visit so startup does not pay for every screen at once.
  final Set<int> _activated = {0};

  Widget _screenForIndex(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const QiblaScreen();
      case 2:
        return NearestMosqueScreen(isActiveTab: _selectedIndex == 2);
      case 3:
        return const CalendarScreen();
      case 4:
        return const AzkarScreen();
      case 5:
        return const SettingsScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  void initState() {
    super.initState();
    // Initial fetch of prayer times
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings = context.read<SettingsProvider>();
      await ensurePrayerPermissionsAfterLaunch(context);
      if (!mounted) return;
      context.read<PrayerProvider>().refreshPrayerTimes(settings);
      if (!kIsWeb && kAppUpdateManifestUrl.isNotEmpty) {
        try {
          final st = await AppUpdateService.check();
          if (!AppUpdateService.shouldShowSessionNotice(st) || st.remote == null) return;
          if (!mounted) return;
          final s = context.strings;
          final nav = MainNavScope.maybeOf(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.updateSessionSnack(st.remote!.version)),
              action: SnackBarAction(
                label: s.updateSettingsSnackbarAction,
                onPressed: () => nav?.selectTab(5),
              ),
            ),
          );
        } catch (_) {
          /* ignore failed optional update check */
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.strings;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MainNavScope(
      selectTab: (index) {
        setState(() {
          _activated.add(index);
          _selectedIndex = index;
        });
      },
      child: Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: List.generate(6, (i) {
          if (!_activated.contains(i)) {
            return const SizedBox.shrink();
          }
          final visible = i == _selectedIndex;
          return Offstage(
            offstage: !visible,
            child: TickerMode(
              enabled: visible,
              child: _screenForIndex(i),
            ),
          );
        }),
      ),
      bottomNavigationBar: isDark
          ? Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D1514).withValues(alpha: 0.45),
                    offset: const Offset(0, -4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: ColoredBox(
                  color: p.surfaceLow.withValues(alpha: 0.88),
                  child: NavigationBar(
                    selectedIndex: _selectedIndex,
                    backgroundColor: Colors.transparent,
                    onDestinationSelected: (index) {
                      setState(() {
                        _activated.add(index);
                        _selectedIndex = index;
                      });
                    },
                    destinations: [
                      NavigationDestination(
                        icon: const Icon(Icons.home_outlined),
                        selectedIcon: const Icon(Icons.home),
                        label: s.home,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.explore_outlined),
                        selectedIcon: const Icon(Icons.explore),
                        label: s.qibla,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.mosque_outlined),
                        selectedIcon: const Icon(Icons.mosque),
                        label: s.mosque,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.calendar_month_outlined),
                        selectedIcon: const Icon(Icons.calendar_month),
                        label: s.calendar,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.auto_stories_outlined),
                        selectedIcon: const Icon(Icons.auto_stories),
                        label: s.azkar,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.settings_outlined),
                        selectedIcon: const Icon(Icons.settings),
                        label: s.settings,
                      ),
                    ],
                  ),
                ),
              ),
            )
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _activated.add(index);
                  _selectedIndex = index;
                });
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home, color: p.primary),
                  label: s.home,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore, color: p.primary),
                  label: s.qibla,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.mosque_outlined),
                  selectedIcon: Icon(Icons.mosque, color: p.primary),
                  label: s.mosque,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month, color: p.primary),
                  label: s.calendar,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.auto_stories_outlined),
                  selectedIcon: Icon(Icons.auto_stories, color: p.primary),
                  label: s.azkar,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings, color: p.primary),
                  label: s.settings,
                ),
              ],
            ),
    ),
    );
  }
}
