import 'dart:async';

import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:salat_pro/services/location_service.dart';
import 'package:salat_pro/services/adhan_service.dart';
import 'package:salat_pro/l10n/app_strings.dart';
import 'package:salat_pro/services/notification_service.dart';
import 'package:salat_pro/providers/settings_provider.dart';

class PrayerProvider with ChangeNotifier {
  PrayerTimes? _currentPrayerTimes;
  Position? _currentPosition;
  bool _isLoading = false;
  String? _error;

  PrayerTimes? get currentPrayerTimes => _currentPrayerTimes;
  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> refreshPrayerTimes(SettingsProvider settings) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Position? position;
      if (settings.useManualLocation) {
        position = Position(
          latitude: settings.manualLatitude,
          longitude: settings.manualLongitude,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
        final placeLabel = await LocationService.getCityName(settings.manualLatitude, settings.manualLongitude);
        if (placeLabel != null) {
          settings.setCity(placeLabel);
        }
      } else {
        position = await LocationService.getCurrentPosition();
        if (position != null) {
          final cityName = await LocationService.getCityName(position.latitude, position.longitude);
          if (cityName != null) {
            settings.setCity(cityName);
          }
        }
      }

      if (position != null) {
        _currentPosition = position;
        _currentPrayerTimes = AdhanService.getPrayerTimes(position, settings.method);

        // Schedule alerts off the critical path so UI clears loading immediately.
        if (_currentPrayerTimes != null) {
          unawaited(
            NotificationService.schedulePrayerNotifications(
              position,
              settings.method,
              languageCode: settings.languageCode,
              adhanAssetKey: settings.adhanAssetPath,
            ).catchError((Object e, StackTrace st) {
              debugPrint('PrayerProvider: notification schedule failed: $e\n$st');
            }),
          );
        }
      } else {
        _error = AppStrings.fromLanguageCode(settings.languageCode).couldNotRetrieveLocation;
      }
    } catch (e) {
      debugPrint('PrayerProvider Error: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update without full reload if just method changed
  void updateWithSettings(SettingsProvider settings) {
    if (_currentPosition != null) {
      _currentPrayerTimes = AdhanService.getPrayerTimes(_currentPosition!, settings.method);
      notifyListeners();
      unawaited(
        NotificationService.schedulePrayerNotifications(
          _currentPosition!,
          settings.method,
          languageCode: settings.languageCode,
          adhanAssetKey: settings.adhanAssetPath,
        ).catchError((Object e, StackTrace st) {
          debugPrint('PrayerProvider: notification schedule failed: $e\n$st');
        }),
      );
    }
  }
}
