import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

/// One Adhan clip shipped under [assetKey] (e.g. `assets/sounds/Mishary Rashid.mp3`).
class AdhanSoundOption {
  const AdhanSoundOption({
    required this.assetKey,
    required this.displayTitle,
    required this.rawResourceName,
  });

  final String assetKey;

  /// Human-readable title derived from the file name (without extension).
  final String displayTitle;

  /// Android raw resource identifier (`res/raw/<name>`) produced by the `syncAdhanSounds`
  /// Gradle task. Matches the sanitization in `android/app/build.gradle`.
  final String rawResourceName;
}

/// Discovers audio files under `assets/sounds/` from the asset manifest.
class AdhanSoundCatalog {
  AdhanSoundCatalog._();

  static const String _soundsPrefix = 'assets/sounds/';

  static const Set<String> _audioExtensions = {
    '.mp3',
    '.m4a',
    '.aac',
    '.wav',
    '.ogg',
  };

  static Future<List<AdhanSoundOption>> discover() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final all = manifest.listAssets();
    final audioKeys = all
        .where(
          (k) =>
              k.startsWith(_soundsPrefix) &&
              !_isIgnorable(k) &&
              _audioExtensions.contains(p.extension(k).toLowerCase()),
        )
        .toList();

    // Build a case-insensitive lookup of sibling `<base>.txt` files so the Arabic title
    // inside each text file can override the filename-derived title.
    final txtByBase = <String, String>{};
    for (final k in all) {
      if (!k.startsWith(_soundsPrefix)) continue;
      if (p.extension(k).toLowerCase() != '.txt') continue;
      txtByBase[p.basenameWithoutExtension(k).toLowerCase()] = k;
    }

    final options = <AdhanSoundOption>[];
    for (final k in audioKeys) {
      final base = p.basenameWithoutExtension(k).toLowerCase();
      final titleAssetKey = txtByBase[base];
      String title = _titleForKey(k);
      if (titleAssetKey != null) {
        final loaded = await _loadTitleFromAsset(titleAssetKey);
        if (loaded != null && loaded.isNotEmpty) title = loaded;
      }
      options.add(
        AdhanSoundOption(
          assetKey: k,
          displayTitle: title,
          rawResourceName: _rawResourceName(k),
        ),
      );
    }

    options.sort((a, b) => a.displayTitle.toLowerCase().compareTo(b.displayTitle.toLowerCase()));
    return options;
  }

  static Future<String?> _loadTitleFromAsset(String assetKey) async {
    try {
      final raw = await rootBundle.loadString(assetKey);
      // Use only the first non-empty line; strip UTF-8 BOM and surrounding whitespace so
      // editors that save with a BOM don't leak a stray U+FEFF into the UI.
      for (final line in const LineSplitter().convert(raw)) {
        var t = line;
        if (t.isNotEmpty && t.codeUnitAt(0) == 0xFEFF) t = t.substring(1);
        t = t.trim();
        if (t.isNotEmpty) return t;
      }
    } catch (_) {
      // Fall back to the filename-derived title on any I/O or decoding error.
    }
    return null;
  }

  static bool _isIgnorable(String key) {
    final name = p.basename(key).toLowerCase();
    return name == '.gitkeep' || name == '.ds_store';
  }

  static String _titleForKey(String assetKey) {
    final base = p.basenameWithoutExtension(assetKey);
    return base.replaceAll('_', ' ').replaceAll('-', ' ').trim();
  }

  /// Must match `sanitizeAdhanName` in `android/app/build.gradle` or notification sounds
  /// will fail to resolve on Android.
  static String _rawResourceName(String assetKey) {
    final base = p.basenameWithoutExtension(assetKey).toLowerCase();
    var s = base
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    if (s.isEmpty || !RegExp(r'^[a-z]').hasMatch(s)) {
      s = 'adhan_$s';
    }
    return s;
  }
}
