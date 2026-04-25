import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';

class AdhanService {
  static PrayerTimes getPrayerTimes(Position position, CalculationMethod method) {
    final coordinates = Coordinates(position.latitude, position.longitude);
    final params = method.getParameters();
    // Default to Hanafi for Asr if method is Muslim World League or similar, 
    // but typically standard is preferred unless specified.
    params.madhab = Madhab.shafi; 

    return PrayerTimes.today(coordinates, params);
  }

  // Calculate for a specific date
  static PrayerTimes getPrayerTimesForDate(Position position, CalculationMethod method, DateTime date) {
    final coordinates = Coordinates(position.latitude, position.longitude);
    final params = method.getParameters();
    return PrayerTimes(coordinates, DateComponents.from(date), params);
  }
}
