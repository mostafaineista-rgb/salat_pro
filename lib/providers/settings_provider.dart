import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart';
import 'package:salat_pro/services/adhan_sound_catalog.dart';

enum AppThemePreference {
  system,
  light,
  dark;

  ThemeMode get themeMode => switch (this) {
        AppThemePreference.system => ThemeMode.system,
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
      };
}

class SettingsProvider with ChangeNotifier {
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // Defaults
  CalculationMethod _method = CalculationMethod.muslim_world_league;
  AppThemePreference _themePreference = AppThemePreference.system;
  String _languageCode = 'ar';
  String _city = 'Detecting...';

  bool _useManualLocation = false;
  double _manualLatitude = 0.0;
  double _manualLongitude = 0.0;

  /// When false (default), times use 12-hour AM/PM; when true, 24-hour format.
  bool _use24HourClock = false;

  /// Selected Adhan clip under `assets/sounds/`; null when no clips are bundled.
  String? _adhanAssetPath;

  CalculationMethod get method => _method;
  AppThemePreference get themePreference => _themePreference;
  ThemeMode get themeMode => _themePreference.themeMode;
  String get languageCode => _languageCode;
  String get city => _city;
  bool get useManualLocation => _useManualLocation;
  double get manualLatitude => _manualLatitude;
  double get manualLongitude => _manualLongitude;

  bool get use24HourClock => _use24HourClock;

  /// Asset key such as `assets/sounds/Mishary.mp3`, or null if no sounds are shipped.
  String? get adhanAssetPath => _adhanAssetPath;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Load stored values
    final savedMethod = _prefs.getString('calc_method');
    if (savedMethod != null) {
      _method = CalculationMethod.values.byName(savedMethod);
    }

    _loadThemePreference();
    _languageCode = _prefs.getString('language_code') ?? 'ar';
    _city = _prefs.getString('city') ?? 'Detecting...';
    _useManualLocation = _prefs.getBool('use_manual_location') ?? false;
    _manualLatitude = _prefs.getDouble('manual_lat') ?? 0.0;
    _manualLongitude = _prefs.getDouble('manual_lon') ?? 0.0;
    _use24HourClock = _prefs.getBool('use_24_hour_clock') ?? false;
    _adhanAssetPath = _prefs.getString('adhan_asset_path');
    await _normalizeAdhanSelection();

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _normalizeAdhanSelection() async {
    final options = await AdhanSoundCatalog.discover();
    if (options.isEmpty) {
      if (_adhanAssetPath != null) {
        _adhanAssetPath = null;
        await _prefs.remove('adhan_asset_path');
      }
      return;
    }
    final valid = options.any((o) => o.assetKey == _adhanAssetPath);
    if (_adhanAssetPath == null || !valid) {
      _adhanAssetPath = options.first.assetKey;
      await _prefs.setString('adhan_asset_path', _adhanAssetPath!);
    }
  }

  void _loadThemePreference() {
    final name = _prefs.getString('theme_pref');
    if (name != null) {
      for (final v in AppThemePreference.values) {
        if (v.name == name) {
          _themePreference = v;
          return;
        }
      }
    }
    final legacyDark = _prefs.getBool('is_dark_mode');
    if (legacyDark != null) {
      _themePreference = legacyDark ? AppThemePreference.dark : AppThemePreference.light;
    } else {
      _themePreference = AppThemePreference.system;
    }
  }

  void setMethod(CalculationMethod method) {
    if (_method == method) return;
    _method = method;
    _prefs.setString('calc_method', method.name);
    notifyListeners();
  }

  void setCity(String city) {
    if (_city == city) return;
    _city = city;
    _prefs.setString('city', city);
    notifyListeners();
  }

  void setThemePreference(AppThemePreference value) {
    if (_themePreference == value) return;
    _themePreference = value;
    _prefs.setString('theme_pref', value.name);
    notifyListeners();
  }

  void setUseManualLocation(bool value) {
    if (_useManualLocation == value) return;
    _useManualLocation = value;
    _prefs.setBool('use_manual_location', value);
    notifyListeners();
  }

  void setLanguageCode(String code) {
    final normalized = code == 'en' ? 'en' : 'ar';
    if (_languageCode == normalized) return;
    _languageCode = normalized;
    _prefs.setString('language_code', normalized);
    notifyListeners();
  }

  void setUse24HourClock(bool value) {
    if (_use24HourClock == value) return;
    _use24HourClock = value;
    _prefs.setBool('use_24_hour_clock', value);
    notifyListeners();
  }

  Future<void> setAdhanAssetPath(String assetKey) async {
    if (_adhanAssetPath == assetKey) return;
    _adhanAssetPath = assetKey;
    await _prefs.setString('adhan_asset_path', assetKey);
    notifyListeners();
  }

  void setManualLocation(String city, double lat, double lon) {
    final unchanged = _city == city &&
        _manualLatitude == lat &&
        _manualLongitude == lon;
    if (unchanged) return;
    _city = city;
    _manualLatitude = lat;
    _manualLongitude = lon;
    _prefs.setString('city', city);
    _prefs.setDouble('manual_lat', lat);
    _prefs.setDouble('manual_lon', lon);
    notifyListeners();
  }
}
