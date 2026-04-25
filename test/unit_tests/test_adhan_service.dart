import 'package:flutter_test/flutter_test.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:salat_pro/services/adhan_service.dart';

void main() {
  group('AdhanService Tests', () {
    test('Should calculate prayer times correctly for Makkah', () {
      final position = Position(
        latitude: 21.4225,
        longitude: 39.8262,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      final prayerTimes = AdhanService.getPrayerTimes(
        position,
        CalculationMethod.muslim_world_league,
      );

      expect(prayerTimes, isNotNull);
      expect(prayerTimes.fajr, isNotNull);
      expect(prayerTimes.dhuhr, isNotNull);
      expect(prayerTimes.asr, isNotNull);
      expect(prayerTimes.maghrib, isNotNull);
      expect(prayerTimes.isha, isNotNull);
    });
  });
}
