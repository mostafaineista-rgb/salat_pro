import 'dart:math';

/// Quranic reflections with Arabic and English wording and citations.
class DailyReflection {
  const DailyReflection({
    required this.quoteEn,
    required this.quoteAr,
    required this.citationEn,
    required this.citationAr,
  });

  final String quoteEn;
  final String quoteAr;
  final String citationEn;
  final String citationAr;

  String quoteForLocale(String languageCode) =>
      languageCode == 'ar' ? quoteAr : quoteEn;

  String citationForLocale(String languageCode) =>
      languageCode == 'ar' ? citationAr : citationEn;
}

/// Curated list for variety; not exhaustive of the Qur'an.
class DailyReflections {
  DailyReflections._();

  static const List<DailyReflection> _pool = [
    DailyReflection(
      quoteEn:
          '"So remember Me; I will remember you. And be grateful to Me and do not deny Me."',
      quoteAr: '«فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ»',
      citationEn: 'Qur\'an 2:152',
      citationAr: 'البقرة ١٥٢',
    ),
    DailyReflection(
      quoteEn:
          '"Unquestionably, by the remembrance of Allah hearts find rest."',
      quoteAr: '«أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ»',
      citationEn: 'Qur\'an 13:28',
      citationAr: 'الرعد ٢٨',
    ),
    DailyReflection(
      quoteEn: '"And He is with you wherever you are."',
      quoteAr: '«وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ»',
      citationEn: 'Qur\'an 57:4',
      citationAr: 'الحديد ٤',
    ),
    DailyReflection(
      quoteEn:
          '"Indeed, prayer prohibits immorality and wrongdoing, and the remembrance of Allah is greater."',
      quoteAr:
          '«إِنَّ الصَّلَاةَ تَنْهَى عَنِ الْفَحْشَاءِ وَالْمُنكَرِ ۗ وَلَذِكْرُ اللَّهِ أَكْبَرُ»',
      citationEn: 'Qur\'an 29:45',
      citationAr: 'العنكبوت ٤٥',
    ),
    DailyReflection(
      quoteEn: '"And whoever relies upon Allah — then He is sufficient for him."',
      quoteAr: '«وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ»',
      citationEn: 'Qur\'an 65:3',
      citationAr: 'الطلاق ٣',
    ),
    DailyReflection(
      quoteEn:
          '"So be patient. Indeed, the promise of Allah is truth."',
      quoteAr: '«فَاصْبِرْ إِنَّ وَعْدَ اللَّهِ حَقٌّ»',
      citationEn: 'Qur\'an 30:60',
      citationAr: 'الروم ٦٠',
    ),
    DailyReflection(
      quoteEn:
          '"And We have certainly created man and We know what his soul whispers to him, and We are closer to him than his jugular vein."',
      quoteAr:
          '«وَلَقَدْ خَلَقْنَا الْإِنسَانَ وَنَعْلَمُ مَا تُوَسْوِسُ بِهِ نَفْسُهُ وَنَحْنُ أَقْرَبُ إِلَيْهِ مِنْ حَبْلِ الْوَرِيدِ»',
      citationEn: 'Qur\'an 50:16',
      citationAr: 'ق ١٦',
    ),
    DailyReflection(
      quoteEn:
          '"Say, "He is Allah, the One — Allah, the Eternal Refuge.""',
      quoteAr: '«قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ»',
      citationEn: 'Qur\'an 112:1–2',
      citationAr: 'الإخلاص ١–٢',
    ),
    DailyReflection(
      quoteEn:
          '"And your Lord says, "Call upon Me; I will respond to you.""',
      quoteAr: '«وَقَالَ رَبُّكُمُ ادْعُونِي أَسْتَجِبْ لَكُمْ»',
      citationEn: 'Qur\'an 40:60',
      citationAr: 'غافر ٦٠',
    ),
    DailyReflection(
      quoteEn:
          '"Indeed, Allah is with those who fear Him and those who are doers of good."',
      quoteAr:
          '«إِنَّ اللَّهَ مَعَ الَّذِينَ اتَّقَوْا وَالَّذِينَ هُم مُّحْسِنُونَ»',
      citationEn: 'Qur\'an 16:128',
      citationAr: 'النحل ١٢٨',
    ),
    DailyReflection(
      quoteEn: '"And whoever does an atom\'s weight of good will see it."',
      quoteAr: '«فَمَن يَعْمَلْ مِثْقَالَ ذَرَّةٍ خَيْرًا يَرَهُ»',
      citationEn: 'Qur\'an 99:7',
      citationAr: 'الزلزلة ٧',
    ),
    DailyReflection(
      quoteEn:
          '"So which of the favors of your Lord will you deny?"',
      quoteAr: '«فَبِأَيِّ آلَاءِ رَبِّكُمَا تُكَذِّبَانِ»',
      citationEn: 'Qur\'an 55:13',
      citationAr: 'الرحمن ١٣',
    ),
    DailyReflection(
      quoteEn:
          '"And We send down of the Qur\'an that which is healing and mercy for the believers."',
      quoteAr:
          '«وَنُنَزِّلُ مِنَ الْقُرْآنِ مَا هُوَ شِفَاءٌ وَرَحْمَةٌ لِّلْمُؤْمِنِينَ»',
      citationEn: 'Qur\'an 17:82',
      citationAr: 'الإسراء ٨٢',
    ),
    DailyReflection(
      quoteEn: '"And seek help through patience and prayer."',
      quoteAr: '«وَاسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ»',
      citationEn: 'Qur\'an 2:45',
      citationAr: 'البقرة ٤٥',
    ),
    DailyReflection(
      quoteEn: '"Indeed, with hardship comes ease."',
      quoteAr: '«إِنَّ مَعَ الْعُسْرِ يُسْرًا»',
      citationEn: 'Qur\'an 94:6',
      citationAr: 'الشرح ٦',
    ),
    DailyReflection(
      quoteEn: '"And Allah is the best of planners."',
      quoteAr: '«وَاللَّهُ خَيْرُ الْمَاكِرِينَ»',
      citationEn: 'Qur\'an 8:30',
      citationAr: 'الأنفال ٣٠',
    ),
    DailyReflection(
      quoteEn:
          '"So remember the name of your Lord and devote yourself to Him with complete devotion."',
      quoteAr:
          '«وَاذْكُرِ اسْمَ رَبِّكَ وَتَبَتَّلْ إِلَيْهِ تَبْتِيلًا»',
      citationEn: 'Qur\'an 73:8',
      citationAr: 'المزمل ٨',
    ),
    DailyReflection(
      quoteEn:
          '"The patient will be given their reward without account."',
      quoteAr: '«إِنَّمَا يُوَفَّى الصَّابِرُونَ أَجْرَهُم بِغَيْرِ حِسَابٍ»',
      citationEn: 'Qur\'an 39:10',
      citationAr: 'الزمر ١٠',
    ),
  ];

  /// Picks a random reflection (uniform over [_pool]).
  static DailyReflection random() {
    final i = Random().nextInt(_pool.length);
    return _pool[i];
  }
}
