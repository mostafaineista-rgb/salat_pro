import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';

/// Builds a readable place line (city, region, country) — not raw coordinates.
String? _formatPlacemark(Placemark p) {
  final parts = <String>[];
  void add(String? s) {
    final t = s?.trim();
    if (t == null || t.isEmpty) return;
    if (parts.any((e) => e.toLowerCase() == t.toLowerCase())) return;
    parts.add(t);
  }

  add(p.locality);
  add(p.subLocality);
  add(p.subAdministrativeArea);
  add(p.administrativeArea);
  add(p.country);
  if (parts.length < 2) {
    add(p.name);
    add(p.street);
    add(p.thoroughfare);
  }
  if (parts.isEmpty) return null;
  return parts.join(', ');
}

/// Why the app could not read GPS for features that require it (e.g. nearest mosque).
enum LocationAccessIssue {
  none,
  denied,
  deniedForever,
  serviceDisabled,
  error,
}

class LocationResolveResult {
  const LocationResolveResult({
    this.position,
    this.issue = LocationAccessIssue.none,
  });

  final Position? position;
  final LocationAccessIssue issue;

  bool get hasPosition => position != null;
}

class LocationService {
  static Future<Position?> getCurrentPosition() async {
    try {
      debugPrint('LocationService: Requesting position...');
      
      if (kIsWeb) {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          await Geolocator.requestPermission();
        }
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('LocationService: Location services are disabled.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('LocationService: Permission denied.');
          return null; 
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('LocationService: Permission denied forever.');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        debugPrint('LocationService: Timed out.');
        throw TimeoutException('Location request timed out');
      });

      debugPrint('LocationService: Success - ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('LocationService Error: $e');
      return null;
    }
  }

  /// Human-readable label for coordinates (city / region / country). No bare lat/lon in the string.
  static Future<String?> getCityName(double lat, double long) async {
    if (kIsWeb) {
      debugPrint('LocationService: Geocoding limited on web.');
      return 'Current location (web)';
    }
    try {
      debugPrint('LocationService: Reverse geocode for $lat, $long');
      final placemarks = await placemarkFromCoordinates(lat, long);
      if (placemarks.isEmpty) return null;
      final label = _formatPlacemark(placemarks.first);
      if (label != null) {
        debugPrint('LocationService: Place label — $label');
        return label;
      }
      return null;
    } catch (e) {
      debugPrint('LocationService Geocoding Error: $e');
      return null;
    }
  }

  static Future<Map<String, double>?> getCoordinatesFromAddress(String address) async {
    if (kIsWeb) {
      debugPrint('LocationService: Geocoding not supported on Web. Cannot lookup address.');
      return null;
    }
    try {
      debugPrint('LocationService: Looking up coordinates for $address');
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        debugPrint('LocationService: Coordinates found - ${loc.latitude}, ${loc.longitude}');
        return {
          'latitude': loc.latitude,
          'longitude': loc.longitude,
        };
      }
      return null;
    } catch (e) {
      debugPrint('LocationService Geocoding Error: $e');
      return null;
    }
  }

  /// One-shot flow for map features: checks services, requests permission if needed, returns [Position] or a specific [issue].
  static Future<LocationResolveResult> resolveCurrentPositionForMap() async {
    try {
      if (kIsWeb) {
        var p = await Geolocator.checkPermission();
        if (p == LocationPermission.denied) {
          p = await Geolocator.requestPermission();
        }
        if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
          return LocationResolveResult(
            issue: p == LocationPermission.deniedForever
                ? LocationAccessIssue.deniedForever
                : LocationAccessIssue.denied,
          );
        }
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('LocationService: Location services are disabled.');
        return const LocationResolveResult(issue: LocationAccessIssue.serviceDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        debugPrint('LocationService: Permission denied.');
        return const LocationResolveResult(issue: LocationAccessIssue.denied);
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint('LocationService: Permission denied forever.');
        return const LocationResolveResult(issue: LocationAccessIssue.deniedForever);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('LocationService: Timed out.');
          throw TimeoutException('Location request timed out');
        },
      );

      debugPrint('LocationService: resolve — ${position.latitude}, ${position.longitude}');
      return LocationResolveResult(position: position);
    } on TimeoutException {
      return const LocationResolveResult(issue: LocationAccessIssue.error);
    } catch (e) {
      debugPrint('LocationService.resolveCurrentPositionForMap: $e');
      return const LocationResolveResult(issue: LocationAccessIssue.error);
    }
  }
}

