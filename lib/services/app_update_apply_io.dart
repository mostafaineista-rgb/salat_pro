import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:salat_pro/services/app_update_types.dart';
import 'package:url_launcher/url_launcher.dart';

Future<String> _downloadToSupportDir(String downloadUrl) async {
  final dir = await getApplicationSupportDirectory();
  final updates = Directory(p.join(dir.path, 'updates'));
  if (!await updates.exists()) {
    await updates.create(recursive: true);
  }
  final u = Uri.parse(downloadUrl);
  String name = u.pathSegments.isNotEmpty ? u.pathSegments.last : 'update.bin';
  if (name.isEmpty) name = 'update.bin';
  if (!p.extension(name).contains('.')) {
    name = '$name.bin';
  }
  final out = File(p.join(updates.path, name));
  if (await out.exists()) {
    await out.delete();
  }
  final r = await http.get(u);
  if (r.statusCode < 200 || r.statusCode >= 300) {
    throw Exception('Download failed: HTTP ${r.statusCode}');
  }
  await out.writeAsBytes(r.bodyBytes);
  return out.path;
}

/// Opens an updated build for this platform. Android installs APK; Windows runs the
/// downloaded installer; iOS opens a browser/App Store [url] only.
Future<void> installFromManifest(UpdateManifest manifest) async {
  if (Platform.isAndroid) {
    final pkg = (await PackageInfo.fromPlatform()).packageName;
    final market = Uri.parse('market://details?id=$pkg');
    final web = Uri.parse('https://play.google.com/store/apps/details?id=$pkg');
    final ok = await launchUrl(market, mode: LaunchMode.externalApplication) ||
        await launchUrl(web, mode: LaunchMode.externalApplication);
    if (!ok) {
      throw StateError('Could not open Play Store listing');
    }
    return;
  }

  if (Platform.isWindows) {
    final u = manifest.windowsInstallerUrl;
    if (u == null || u.isEmpty) {
      throw StateError('windows_installer_url missing in update manifest');
    }
    final path = await _downloadToSupportDir(u);
    if (!File(path).existsSync()) {
      throw StateError('Installer not found after download');
    }
    final uri = Uri.file(path, windows: true);
    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!ok) {
      throw StateError('Could not start installer (launchUrl failed)');
    }
    return;
  }

  if (Platform.isIOS) {
    final u = manifest.iosAppStoreOrDownloadUrl;
    if (u == null || u.isEmpty) {
      throw StateError('ios_url missing in update manifest');
    }
    final ok = await launchUrl(
      Uri.parse(u),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) {
      throw StateError('Could not open update URL');
    }
    return;
  }

  throw UnsupportedError('In-app update is not set up for this platform.');
}
