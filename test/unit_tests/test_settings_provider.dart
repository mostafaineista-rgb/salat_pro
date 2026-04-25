import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salat_pro/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsProvider Tests', () {
    test('Should initialize with correct default values', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsProvider();
      await settings.init();

      expect(settings.method, CalculationMethod.muslim_world_league);
      expect(settings.themePreference, AppThemePreference.system);
      expect(settings.themeMode, ThemeMode.system);
    });

    test('Should update calculation method and notify listeners', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsProvider();
      await settings.init();

      bool notified = false;
      settings.addListener(() => notified = true);

      settings.setMethod(CalculationMethod.north_america);

      expect(settings.method, CalculationMethod.north_america);
      expect(notified, true);
    });
  });
}
