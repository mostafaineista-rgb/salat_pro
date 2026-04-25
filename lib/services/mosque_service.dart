import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:salat_pro/models/mosque_place.dart';

/// Fetches nearby Muslim places of worship from the public Overpass API (OpenStreetMap).
///
/// Only call from explicit user actions or screen open — do not poll.
class MosqueService {
  MosqueService._();

  /// Mirrors tried in order when one is overloaded or unreachable (fair-use community servers).
  static const List<String> _overpassInterpreterUrls = [
    'https://overpass-api.de/api/interpreter',
    'https://lz4.overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
  ];

  /// Identify the app to Overpass/OSM (recommended practice).
  static const String _userAgent = 'SalatPro/1.0 (Flutter prayer app; OSM data consumer)';

  /// Default search radius in meters (between 3–5 km as requested).
  static const double defaultRadiusMeters = 4000;

  static String _buildOverpassQuery(double lat, double lon, double radiusMeters) {
    final r = radiusMeters.round();
    // Nodes, ways, and relations tagged as Muslim place of worship within radius.
    return '''
[out:json][timeout:25];
(
  node["amenity"="place_of_worship"]["religion"="muslim"](around:$r,$lat,$lon);
  way["amenity"="place_of_worship"]["religion"="muslim"](around:$r,$lat,$lon);
  relation["amenity"="place_of_worship"]["religion"="muslim"](around:$r,$lat,$lon);
);
out center tags;
''';
  }

  /// Returns mosques sorted by ascending distance from [userLat], [userLon].
  /// Throws [MosqueServiceException] on HTTP or parse errors.
  static Future<List<MosquePlace>> fetchNearbyMosques({
    required double userLat,
    required double userLon,
    double radiusMeters = defaultRadiusMeters,
  }) async {
    final query = _buildOverpassQuery(userLat, userLon, radiusMeters);

    Object? lastFailure;
    http.Response? response;

    for (final url in _overpassInterpreterUrls) {
      try {
        final uri = Uri.parse(url);
        final r = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                'User-Agent': _userAgent,
              },
              body: {'data': query},
            )
            .timeout(const Duration(seconds: 40));

        if (r.statusCode == 200) {
          response = r;
          break;
        }
        lastFailure = 'HTTP ${r.statusCode}';
      } catch (e, st) {
        lastFailure = e;
        debugPrint('MosqueService: Overpass try failed ($url): $e\n$st');
      }
    }

    if (response == null) {
      throw MosqueServiceException(
        lastFailure == null
            ? 'Could not reach Overpass servers.'
            : 'Could not reach Overpass servers (${lastFailure.toString()})',
      );
    }

    final dynamic decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw MosqueServiceException('Invalid Overpass response');
    }

    final remark = decoded['remark'];
    if (remark != null && remark.toString().toLowerCase().contains('runtime error')) {
      throw MosqueServiceException('Overpass busy or query failed; try again shortly.');
    }

    final elements = decoded['elements'];
    if (elements is! List) {
      throw MosqueServiceException('Invalid Overpass elements');
    }

    final List<MosquePlace> list = [];

    for (final raw in elements) {
      if (raw is! Map<String, dynamic>) continue;
      final type = raw['type'] as String?;
      final id = raw['id'];
      if (type == null || id is! int) continue;

      double? lat;
      double? lon;

      if (raw['lat'] != null && raw['lon'] != null) {
        lat = (raw['lat'] as num).toDouble();
        lon = (raw['lon'] as num).toDouble();
      } else {
        final center = raw['center'];
        if (center is Map<String, dynamic> &&
            center['lat'] != null &&
            center['lon'] != null) {
          lat = (center['lat'] as num).toDouble();
          lon = (center['lon'] as num).toDouble();
        }
      }

      if (lat == null || lon == null) continue;

      final tags = raw['tags'];
      String? name;
      if (tags is Map<String, dynamic>) {
        final n = tags['name'];
        if (n is String && n.trim().isNotEmpty) {
          name = n.trim();
        } else {
          final nEn = tags['name:en'];
          if (nEn is String && nEn.trim().isNotEmpty) {
            name = nEn.trim();
          }
        }
      }

      final d = MosquePlace.distanceMetersBetween(userLat, userLon, lat, lon);
      list.add(
        MosquePlace(
          osmType: type,
          osmId: id,
          latitude: lat,
          longitude: lon,
          distanceMeters: d,
          rawName: name,
        ),
      );
    }

    list.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    // De-duplicate same OSM feature if returned twice
    final seen = <String>{};
    final deduped = <MosquePlace>[];
    for (final m in list) {
      final k = m.uniqueKey;
      if (seen.add(k)) deduped.add(m);
    }

    debugPrint('MosqueService: ${deduped.length} mosques within ${radiusMeters.round()} m');
    return deduped;
  }
}

class MosqueServiceException implements Exception {
  MosqueServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}
