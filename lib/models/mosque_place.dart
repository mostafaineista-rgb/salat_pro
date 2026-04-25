import 'dart:math' as math;

/// A mosque (or Muslim place of worship) from OpenStreetMap via Overpass.
class MosquePlace {
  MosquePlace({
    required this.osmType,
    required this.osmId,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    this.rawName,
  });

  final String osmType;
  final int osmId;
  final double latitude;
  final double longitude;
  final double distanceMeters;
  final String? rawName;

  String get displayName {
    final n = rawName?.trim();
    if (n == null || n.isEmpty) return 'Mosque';
    return n;
  }

  /// Stable unique key for Flutter widgets.
  String get uniqueKey => '$osmType/$osmId';

  /// Haversine distance in meters between two WGS84 points.
  static double distanceMetersBetween(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusM = 6371000.0;
    const p = math.pi / 180;
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
    return earthRadiusM * 2 * math.asin(math.sqrt(math.min(1.0, math.max(0.0, a))));
  }

  MosquePlace copyWith({double? distanceMeters, String? rawName}) {
    return MosquePlace(
      osmType: osmType,
      osmId: osmId,
      latitude: latitude,
      longitude: longitude,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      rawName: rawName ?? this.rawName,
    );
  }
}
