import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salat_pro/models/hadith_moment.dart';

/// Fetches hadiths from [fawazahmed0/hadith-api](https://github.com/fawazahmed0/hadith-api)
/// (jsDelivr CDN + raw GitHub fallback), merging **English** (`eng-*`) and **Arabic** (`ara-*`) editions.
class HadithService {
  HadithService._();

  static const _apiVersion = '1';
  static const _cdnEditions =
      'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@$_apiVersion/editions';
  static const _rawEditions =
      'https://raw.githubusercontent.com/fawazahmed0/hadith-api/$_apiVersion/editions';

  static const _prefsHadithKey = 'hadith_moment_cache_v2';
  static const _prefsLastAutoAttemptKey = 'hadith_last_auto_attempt_ms';

  static const _userAgent = 'SalatPro/1.0 (Flutter; fawazahmed0/hadith-api consumer)';

  /// `(bookSlug, inclusiveMaxHadithNumber)` — aligned with fawazahmed0 hadith numbering.
  static const List<({String book, int maxHadith})> _books = [
    (book: 'bukhari', maxHadith: 7563),
    (book: 'muslim', maxHadith: 7563),
    (book: 'abudawud', maxHadith: 5274),
    (book: 'ibnmajah', maxHadith: 4341),
    (book: 'tirmidhi', maxHadith: 3956),
    (book: 'nasai', maxHadith: 5758),
  ];

  static const _autoAttemptCooldown = Duration(minutes: 5);
  static const _noCacheRetryCooldown = Duration(seconds: 20);
  static const _httpTimeout = Duration(seconds: 25);

  static final _rand = Random();

  static Future<HadithMoment?> loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsHadithKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return HadithMoment.fromStorageJson(map);
    } catch (e, st) {
      debugPrint('HadithService: cache parse failed: $e\n$st');
      return null;
    }
  }

  static Future<void> _saveCached(HadithMoment h) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsHadithKey, jsonEncode(h.toStorageJson()));
  }

  static Future<void> _touchLastAutoAttempt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsLastAutoAttemptKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<int?> _lastAutoAttemptMs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefsLastAutoAttemptKey);
  }

  static Future<bool> shouldAttemptAutoFetch(HadithMoment? cache) async {
    final today = HadithMoment.dayKeyLocal(DateTime.now());
    if (cache != null && cache.fetchedOnDayKey == today) {
      return false;
    }
    final lastMs = await _lastAutoAttemptMs();
    if (lastMs != null) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
      final cooldown = cache == null ? _noCacheRetryCooldown : _autoAttemptCooldown;
      if (DateTime.now().difference(last) < cooldown) {
        return false;
      }
    }
    return true;
  }

  static Future<Map<String, dynamic>?> _getJson(Uri uri) async {
    try {
      final response = await http
          .get(
            uri,
            headers: {'User-Agent': _userAgent},
          )
          .timeout(_httpTimeout);

      if (response.statusCode != 200) {
        debugPrint('HadithService: HTTP ${response.statusCode} $uri');
        return null;
      }
      final map = jsonDecode(utf8.decode(response.bodyBytes));
      if (map is Map<String, dynamic>) return map;
    } catch (e, st) {
      debugPrint('HadithService: GET failed $uri: $e\n$st');
    }
    return null;
  }

  /// Tries `.min.json` then `.json` on CDN, then the same on raw.githubusercontent.com.
  static Future<Map<String, dynamic>?> fetchEditionHadith(String editionName, int hadithNumber) async {
    final bases = [_cdnEditions, _rawEditions];
    final suffixes = ['.min.json', '.json'];
    for (final base in bases) {
      for (final suf in suffixes) {
        final uri = Uri.parse('$base/$editionName/$hadithNumber$suf');
        final map = await _getJson(uri);
        if (map != null) return map;
      }
    }
    return null;
  }

  static Future<HadithMoment?> fetchRandomNew({
    required bool userInitiated,
    int maxBookAttempts = 14,
  }) async {
    if (!userInitiated) {
      await _touchLastAutoAttempt();
    }

    final today = HadithMoment.dayKeyLocal(DateTime.now());

    for (var attempt = 0; attempt < maxBookAttempts; attempt++) {
      final pick = _books[_rand.nextInt(_books.length)];
      final id = 1 + _rand.nextInt(pick.maxHadith);
      final engEdition = 'eng-${pick.book}';
      final araEdition = 'ara-${pick.book}';

      try {
        final pair = await Future.wait([
          fetchEditionHadith(engEdition, id),
          fetchEditionHadith(araEdition, id),
        ]);
        final en = pair[0];
        if (en == null) continue;

        final ar = pair[1];

        final moment = HadithMoment.fromFawazPair(
          englishRoot: en,
          arabicRoot: ar,
          fetchedOnDayKey: today,
        );

        await _saveCached(moment);
        return moment;
      } catch (e, st) {
        debugPrint('HadithService: parse/build failed (${pick.book}/$id): $e\n$st');
        continue;
      }
    }

    return null;
  }

  static Future<HadithMoment?> bootstrapFromCacheOrFetch() async {
    final cached = await loadCached();
    final due = await shouldAttemptAutoFetch(cached);
    if (!due) return cached;
    final fresh = await fetchRandomNew(userInitiated: false);
    return fresh ?? cached;
  }
}
