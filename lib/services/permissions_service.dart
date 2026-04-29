import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:salat_pro/utils/platform_support.dart';

/// Requests Android runtime permissions needed for location and alerts.
Future<void> requestAndroidPrayerPermissions() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

  var loc = await Permission.location.status;
  if (!loc.isGranted) {
    loc = await Permission.location.request();
  }

  var notif = await Permission.notification.status;
  if (!notif.isGranted) {
    notif = await Permission.notification.request();
  }
}

/// Call once after first frame when [context] is valid (may open settings sheets).
Future<void> ensurePrayerPermissionsAfterLaunch(BuildContext context) async {
  if (!supportsPrayerNotifications) return;
  await requestAndroidPrayerPermissions();
}
