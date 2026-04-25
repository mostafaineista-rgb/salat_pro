import 'dart:math' as math;

class LocationUtils {
  static const double meccaLat = 21.422487;
  static const double meccaLng = 39.826206;

  static const double _meccaPhiRad = meccaLat * 0.017453292519943295; // π/180

  /// Calculates the Qibla bearing (angle in degrees) from the current position.
  static double calculateQibla(double lat, double lng) {
    double phi1 = lat * (math.pi / 180);
    double lambda1 = lng * (math.pi / 180);
    double phi2 = meccaLat * (math.pi / 180);
    double lambda2 = meccaLng * (math.pi / 180);

    double dLambda = lambda2 - lambda1;

    double y = math.sin(dLambda);
    double x = math.cos(phi1) * math.tan(phi2) - math.sin(phi1) * math.cos(dLambda);

    double qiblaAngle = math.atan2(y, x);
    double qiblaDegree = qiblaAngle * (180 / math.pi);

    return (qiblaDegree + 360) % 360;
  }

  /// Great-circle distance to the Kaaba in kilometers (WGS84 sphere).
  static double distanceToKaabaKm(double lat, double lng) {
    const earthRadiusKm = 6371.0;
    final phi1 = lat * (math.pi / 180);
    final dPhi = (meccaLat - lat) * (math.pi / 180);
    final dLambda = (meccaLng - lng) * (math.pi / 180);

    final a = math.sin(dPhi / 2) * math.sin(dPhi / 2) +
        math.cos(phi1) * math.cos(_meccaPhiRad) * math.sin(dLambda / 2) * math.sin(dLambda / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }
}
