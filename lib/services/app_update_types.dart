import 'dart:convert';

import 'package:flutter/foundation.dart';

@immutable
class UpdateManifest {
  const UpdateManifest({
    required this.build,
    required this.version,
    this.windowsInstallerUrl,
    this.iosAppStoreOrDownloadUrl,
    this.releaseNotes,
  });

  final int build;
  final String version;
  final String? windowsInstallerUrl;
  final String? iosAppStoreOrDownloadUrl;
  final String? releaseNotes;

  static UpdateManifest? tryParse(String body) {
    try {
      final m = jsonDecode(body) as Map<String, dynamic>?;
      if (m == null) return null;
      final b = m['build'];
      final v = m['version'];
      if (v is! String) return null;
      final int? buildNum = b is int
          ? b
          : b is String
              ? int.tryParse(b)
              : null;
      if (buildNum == null) return null;
      return UpdateManifest(
        build: buildNum,
        version: v,
        windowsInstallerUrl: m['windows_installer_url'] as String?,
        iosAppStoreOrDownloadUrl: m['ios_url'] as String?,
        releaseNotes: m['release_notes'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

@immutable
class AppUpdateState {
  const AppUpdateState({
    required this.currentBuild,
    required this.currentVersion,
    required this.hasUpdate,
    this.remote,
  });

  final int currentBuild;
  final String currentVersion;
  final bool hasUpdate;
  final UpdateManifest? remote;
}
