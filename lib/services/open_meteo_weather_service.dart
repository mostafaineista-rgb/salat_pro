import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:salat_pro/models/walk_weather_snapshot.dart';

/// Free [Open-Meteo](https://open-meteo.com/) forecast — no API key.
class OpenMeteoWeatherService {
  OpenMeteoWeatherService._();

  static const _base = 'https://api.open-meteo.com/v1/forecast';
  static const _userAgent = 'SalatPro/1.0 (Flutter; Open-Meteo consumer)';
  static const _timeout = Duration(seconds: 18);

  static Future<WalkWeatherSnapshot?> fetchCurrent({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(_base).replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current': [
          'temperature_2m',
          'apparent_temperature',
          'precipitation',
          'weather_code',
          'uv_index',
          'wind_speed_10m',
          'is_day',
        ].join(','),
        'timezone': 'auto',
        'wind_speed_unit': 'ms',
      },
    );

    try {
      final res = await http
          .get(
            uri,
            headers: {'User-Agent': _userAgent},
          )
          .timeout(_timeout);

      if (res.statusCode != 200) {
        debugPrint('OpenMeteoWeatherService: HTTP ${res.statusCode}');
        return null;
      }

      final map = jsonDecode(res.body) as Map<String, dynamic>?;
      final current = map?['current'] as Map<String, dynamic>?;
      if (current == null) return null;

      double numOr(dynamic v, double fallback) {
        if (v is num) return v.toDouble();
        return fallback;
      }

      int intOr(dynamic v, int fallback) {
        if (v is int) return v;
        if (v is num) return v.round();
        return fallback;
      }

      final isDay = current['is_day'];
      final isDayBool = isDay == 1 || isDay == true;

      return WalkWeatherSnapshot(
        temperatureC: numOr(current['temperature_2m'], 0),
        apparentTemperatureC: numOr(current['apparent_temperature'], numOr(current['temperature_2m'], 0)),
        precipitationMmPerHour: numOr(current['precipitation'], 0),
        weatherCode: intOr(current['weather_code'], 0),
        uvIndex: () {
          final u = current['uv_index'];
          if (u == null) return null;
          if (u is num) return u.toDouble();
          return null;
        }(),
        windSpeedMs: numOr(current['wind_speed_10m'], 0),
        isDay: isDayBool,
      );
    } catch (e, st) {
      debugPrint('OpenMeteoWeatherService: $e\n$st');
      return null;
    }
  }
}
