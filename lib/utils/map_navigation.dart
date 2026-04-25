import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens turn-by-turn or place context in the platform maps app / browser (no Maps SDK).
class MapNavigationLauncher {
  MapNavigationLauncher._();

  static Future<bool> openExternalNavigation({
    required double latitude,
    required double longitude,
    required String label,
  }) async {
    final uri = _buildUri(latitude, longitude, label);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  static Uri _buildUri(double lat, double lng, String label) {
    final enc = Uri.encodeComponent(label);
    if (kIsWeb) {
      return Uri.parse(
        'https://www.openstreetmap.org/search?query=$lat%2C$lng#map=17/$lat/$lng',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return Uri.parse('http://maps.apple.com/?ll=$lat,$lng&q=$enc');
      case TargetPlatform.android:
        return Uri.parse('geo:$lat,$lng?q=$lat,$lng($enc)');
      default:
        return Uri.parse(
          'https://www.openstreetmap.org/search?query=$lat%2C$lng#map=17/$lat/$lng',
        );
    }
  }
}
