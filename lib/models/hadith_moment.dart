/// Hadith snapshot from [fawazahmed0/hadith-api](https://github.com/fawazahmed0/hadith-api) (English + Arabic editions).
class HadithMoment {
  const HadithMoment({
    required this.hadithEnglish,
    required this.hadithArabic,
    required this.refLabel,
    required this.chapterEnglish,
    required this.chapterArabic,
    required this.fetchedOnDayKey,
    this.fromBundledFallback = false,
  });

  final String hadithEnglish;
  final String hadithArabic;
  final String refLabel;
  final String chapterEnglish;
  final String chapterArabic;

  /// Local calendar day (`yyyy-MM-dd`) when this snapshot was successfully stored.
  final String fetchedOnDayKey;

  /// Shown when the CDN is unreachable; not persisted as the API cache.
  final bool fromBundledFallback;

  /// Sahih al-Bukhari 1 — used only when the network cannot be reached.
  factory HadithMoment.bundledFallback({required String dayKey}) {
    return HadithMoment(
      hadithEnglish:
          'Narrated \'Umar bin Al-Khattab: I heard Allah\'s Messenger (ﷺ) saying, "The reward of deeds depends upon the intentions and every person will get the reward according to what he has intended."',
      hadithArabic:
          'حَدَّثَنَا الْحُمَيْدِيُّ عَبْدُ اللَّهِ بْنُ الزُّبَيْرِ ، قَالَ : حَدَّثَنَا سُفْيَانُ ، قَالَ : حَدَّثَنَا يَحْيَى بْنُ سَعِيدٍ الْأَنْصَارِيُّ ، قَالَ : أَخْبَرَنِي مُحَمَّدُ بْنُ إِبْرَاهِيمَ التَّيْمِيُّ ، أَنَّهُ سَمِعَ عَلْقَمَةَ بْنَ وَقَّاصٍ اللَّيْثِيَّ ، يَقُولُ : سَمِعْتُ عُمَرَ بْنَ الْخَطَّابِ رَضِيَ اللَّهُ عَنْهُ عَلَى الْمِنْبَرِ، قَالَ : سَمِعْتُ رَسُولَ اللَّهِ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ، يَقُولُ : " إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى، فَمَنْ كَانَتْ هِجْرَتُهُ إِلَى دُنْيَا يُصِيبُهَا أَوْ إِلَى امْرَأَةٍ يَنْكِحُهَا، فَهِجْرَتُهُ إِلَى مَا هَاجَرَ إِلَيْهِ',
      refLabel: 'Sahih al Bukhari · 1',
      chapterEnglish: 'Revelation',
      chapterArabic: 'كتاب بدء الوحي',
      fetchedOnDayKey: dayKey,
      fromBundledFallback: true,
    );
  }

  static String dayKeyLocal(DateTime d) {
    final l = d.toLocal();
    final y = l.year.toString().padLeft(4, '0');
    final m = l.month.toString().padLeft(2, '0');
    final day = l.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static String _collapseWs(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

  /// BCP 47 language code: `ar` shows Arabic when available, else English.
  String bodyForLocale(String languageCode) {
    if (languageCode == 'ar' && hadithArabic.trim().isNotEmpty) {
      return _collapseWs(hadithArabic);
    }
    if (hadithEnglish.trim().isNotEmpty) return _collapseWs(hadithEnglish);
    return _collapseWs(hadithArabic);
  }

  String chapterForLocale(String languageCode) {
    if (languageCode == 'ar' && chapterArabic.trim().isNotEmpty) {
      return _collapseWs(chapterArabic);
    }
    if (chapterEnglish.trim().isNotEmpty) return _collapseWs(chapterEnglish);
    return _collapseWs(chapterArabic);
  }

  factory HadithMoment.fromFawazPair({
    required Map<String, dynamic> englishRoot,
    required Map<String, dynamic>? arabicRoot,
    required String fetchedOnDayKey,
  }) {
    final en = _parseHadithBlock(englishRoot);
    if (en == null) {
      throw const FormatException('HadithMoment: missing English hadith payload');
    }
    final ar = arabicRoot != null ? _parseHadithBlock(arabicRoot) : null;

    final metaEn = englishRoot['metadata'];
    final metaAr = arabicRoot?['metadata'];
    final chapterEn = metaEn is Map<String, dynamic> ? _chapterForHadith(metaEn, en.hadithNumber) : '';
    final chapterAr = metaAr is Map<String, dynamic> ? _chapterForHadith(metaAr, en.hadithNumber) : '';

    final nameEn = metaEn is Map ? (metaEn['name']?.toString().trim() ?? '') : '';
    final ref = nameEn.isNotEmpty ? '$nameEn · ${en.hadithNumber}' : 'Hadith · ${en.hadithNumber}';

    return HadithMoment(
      hadithEnglish: en.text,
      hadithArabic: ar?.text ?? '',
      refLabel: ref,
      chapterEnglish: chapterEn,
      chapterArabic: chapterAr.isNotEmpty ? chapterAr : chapterEn,
      fetchedOnDayKey: fetchedOnDayKey,
      fromBundledFallback: false,
    );
  }

  static ({int hadithNumber, String text})? _parseHadithBlock(Map<String, dynamic> root) {
    final hadiths = root['hadiths'];
    if (hadiths is! List || hadiths.isEmpty) return null;
    final first = hadiths.first;
    if (first is! Map<String, dynamic>) return null;
    final n = first['hadithnumber'];
    final hadithNumber = n is int ? n : (n is num ? n.toInt() : int.tryParse(n?.toString() ?? '') ?? 0);
    final text = (first['text'] as String? ?? '').trim();
    if (hadithNumber <= 0 || text.isEmpty) return null;
    return (hadithNumber: hadithNumber, text: text);
  }

  static String _chapterForHadith(Map<String, dynamic> metadata, int hadithNumber) {
    final sectionDetail = metadata['section_detail'];
    final sections = metadata['section'];
    if (sectionDetail is! Map || sections is! Map) return '';

    for (final e in sectionDetail.entries) {
      final d = e.value;
      if (d is! Map<String, dynamic>) continue;
      final first = (d['hadithnumber_first'] as num?)?.toInt();
      final last = (d['hadithnumber_last'] as num?)?.toInt();
      if (first == null || last == null) continue;
      if (hadithNumber >= first && hadithNumber <= last) {
        final title = sections[e.key];
        if (title != null) return title.toString().trim();
      }
    }
    return '';
  }

  Map<String, dynamic> toStorageJson() => {
        'hadithEnglish': hadithEnglish,
        'hadithArabic': hadithArabic,
        'refLabel': refLabel,
        'chapterEnglish': chapterEnglish,
        'chapterArabic': chapterArabic,
        'fetchedOnDayKey': fetchedOnDayKey,
        'fromBundledFallback': fromBundledFallback,
      };

  factory HadithMoment.fromStorageJson(Map<String, dynamic> json) {
    return HadithMoment(
      hadithEnglish: (json['hadithEnglish'] as String? ?? '').trim(),
      hadithArabic: (json['hadithArabic'] as String? ?? '').trim(),
      refLabel: (json['refLabel'] as String? ?? '').trim(),
      chapterEnglish: (json['chapterEnglish'] as String? ?? '').trim(),
      chapterArabic: (json['chapterArabic'] as String? ?? '').trim(),
      fetchedOnDayKey: (json['fetchedOnDayKey'] as String? ?? '').trim(),
      fromBundledFallback: json['fromBundledFallback'] == true,
    );
  }
}
