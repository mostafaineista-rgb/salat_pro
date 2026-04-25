import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// One result from Nominatim (OpenStreetMap) search — free, no API key.
class PlaceSearchResult {
  const PlaceSearchResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  final String displayName;
  final double latitude;
  final double longitude;
}

/// Forward geocoding / autocomplete via Nominatim. Call sparingly (debounce in UI).
class PlaceSearchService {
  PlaceSearchService._();

  static const _userAgent = 'SalatPro/1.0 (Flutter prayer app; Nominatim search)';

  /// Minimum query length before hitting the network.
  static const int minQueryLength = 3;

  static Future<List<PlaceSearchResult>> search(String query) async {
    final q = query.trim();
    if (q.length < minQueryLength) return const [];

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': q,
      'format': 'json',
      'addressdetails': '1',
      'limit': '8',
    });

    final response = await http
        .get(
          uri,
          headers: {'User-Agent': _userAgent},
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      debugPrint('PlaceSearchService: HTTP ${response.statusCode}');
      return const [];
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) return const [];

    final out = <PlaceSearchResult>[];
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      final name = item['display_name'] as String?;
      final lat = item['lat'];
      final lon = item['lon'];
      if (name == null || lat == null || lon == null) continue;
      final la = double.tryParse(lat.toString());
      final lo = double.tryParse(lon.toString());
      if (la == null || lo == null) continue;
      out.add(PlaceSearchResult(displayName: name, latitude: la, longitude: lo));
    }
    return out;
  }
}
