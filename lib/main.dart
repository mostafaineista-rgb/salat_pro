import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:salat_pro/core/app_theme.dart';
import 'package:salat_pro/providers/prayer_provider.dart';
import 'package:salat_pro/providers/settings_provider.dart';
import 'package:salat_pro/screens/main_navigation_screen.dart';

import 'package:salat_pro/services/notification_service.dart';
import 'package:salat_pro/utils/platform_support.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('Salat Pro: App Starting...');

  final settings = SettingsProvider();
  await settings.init();
  if (supportsPrayerNotifications) {
    await NotificationService.init();
    await NotificationService.prepareAdhanForNotifications(
      languageCode: settings.languageCode,
      selectedAssetKey: settings.adhanAssetPath,
    );
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settings),
        ChangeNotifierProxyProvider<SettingsProvider, PrayerProvider>(
          create: (_) => PrayerProvider(),
          update: (_, s, p) => p!..updateWithSettings(s),
        ),
      ],
      child: const SalatProApp(),
    ),
  );
}

class SalatProApp extends StatelessWidget {
  const SalatProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) => MaterialApp(
        title: 'Salat Pro',
        debugShowCheckedModeBanner: false,
        locale: Locale(settings.languageCode),
        supportedLocales: const [
          Locale('ar'),
          Locale('en'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        localeResolutionCallback: (locale, supported) {
          if (locale != null) {
            for (final l in supported) {
              if (l.languageCode == locale.languageCode) return l;
            }
          }
          return const Locale('ar');
        },
        themeMode: settings.themeMode,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const MainNavigationScreen(),
      ),
    );
  }
}
