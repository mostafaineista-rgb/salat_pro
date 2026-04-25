import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:salat_pro/core/app_update_config.dart';
import 'package:salat_pro/services/app_update_types.dart';
import 'package:salat_pro/services/app_update_apply_stub.dart' if (dart.library.io) 'package:salat_pro/services/app_update_apply_io.dart' as apply;

/// Remote version check and install entry points.
class AppUpdateService {
  AppUpdateService._();

  static int _sessionNotified = 0;

  static bool get _canCheck =>
      !kIsWeb && kAppUpdateManifestUrl.isNotEmpty;

  /// Fetches the manifest, compares to [PackageInfo] build, returns state.
  static Future<AppUpdateState> check() async {
    if (!_canCheck) {
      final p = await PackageInfo.fromPlatform();
      return AppUpdateState(
        currentBuild: int.tryParse(p.buildNumber) ?? 0,
        currentVersion: p.version,
        hasUpdate: false,
        remote: null,
      );
    }
    final local = await PackageInfo.fromPlatform();
    final currentBuild = int.tryParse(local.buildNumber) ?? 0;
    final u = Uri.parse(kAppUpdateManifestUrl);
    final r = await http
        .get(u, headers: {'User-Agent': 'SalatPro/${local.version}'}).timeout(
      const Duration(seconds: 20),
    );
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('Check failed: HTTP ${r.statusCode}');
    }
    final remote = UpdateManifest.tryParse(r.body);
    if (remote == null) {
      throw Exception('Invalid update manifest');
    }
    return AppUpdateState(
      currentBuild: currentBuild,
      currentVersion: local.version,
      hasUpdate: remote.build > currentBuild,
      remote: remote,
    );
  }

  /// Whether we should show the optional startup snackbar (at most once per process).
  static bool shouldShowSessionNotice(AppUpdateState state) {
    if (!state.hasUpdate || state.remote == null) return false;
    if (_sessionNotified > 0) return false;
    _sessionNotified = 1;
    return true;
  }

  static Future<void> installLatest(UpdateManifest manifest) =>
      apply.installFromManifest(manifest);
}
