import 'package:flutter/material.dart';
import 'package:salat_pro/core/app_colors.dart';
import 'package:salat_pro/l10n/app_strings.dart';
import 'package:salat_pro/l10n/l10n.dart';

class AzkarScreen extends StatefulWidget {
  const AzkarScreen({super.key});

  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen> {
  int _counter = 0;
  final int _target = 33;

  static const List<Map<String, String>> _dailyAdhkar = [
    {
      'titleAr': 'آية الكرسي',
      'titleEn': 'Ayat al-Kursi',
      'ar': 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ …',
      'en':
          'Recite Ayat al-Kursi (Qur’an 2:255) after each obligatory prayer for protection until the next prayer.',
    },
    {
      'titleAr': 'الثلاث الخواتيم',
      'titleEn': 'Last three surahs (3× each)',
      'ar': 'قُلْ هُوَ اللَّهُ أَحَدٌ … قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ … قُلْ أَعُوذُ بِرَبِّ النَّاسِ',
      'en':
          'Surah al-Ikhlas, al-Falaq, and an-Nas — three times after Fajr and Maghrib, and once after other prayers (as is common in many communities).',
    },
    {
      'titleAr': 'تسبيح وتحميد وتكبير',
      'titleEn': 'Tasbih, Tahmid, Takbir',
      'ar': 'سُبْحَانَ اللَّهِ ، الْحَمْدُ لِلَّهِ ، اللَّهُ أَكْبَرُ',
      'en':
          'Say Subhan Allah, Alhamdulillah, and Allahu Akbar 33–33–34 after salah (common dhikr pattern). Use the counter below.',
    },
    {
      'titleAr': 'أذكار الصباح والمساء',
      'titleEn': 'Morning & evening',
      'ar': 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ …',
      'en':
          'Learn the authentic morning and evening adhkar from a scholar or booklet; say them once after Fajr and after Asr/Maghrib respectively.',
    },
  ];

  static const List<Map<String, String>> _tasbihPresets = [
    {
      'titleAr': 'سبحان الله',
      'titleEn': 'SubhanAllah',
      'subtitleAr': 'سبحان الله',
      'subtitleEn': 'Glory be to Allah',
    },
    {
      'titleAr': 'الحمد لله',
      'titleEn': 'Alhamdulillah',
      'subtitleAr': 'الحمد لله',
      'subtitleEn': 'Praise be to Allah',
    },
    {
      'titleAr': 'الله أكبر',
      'titleEn': 'Allahu Akbar',
      'subtitleAr': 'الله أكبر',
      'subtitleEn': 'Allah is the Greatest',
    },
    {
      'titleAr': 'أستغفر الله',
      'titleEn': 'Astaghfirullah',
      'subtitleAr': 'أستغفر الله',
      'subtitleEn': 'I seek forgiveness from Allah',
    },
  ];

  void _increment() {
    setState(() {
      _counter = (_counter + 1) % (_target + 1);
    });
  }

  void _reset() {
    setState(() {
      _counter = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.strings;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [p.background, p.surface],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTasbihHeader(context, s),
              _buildCounterSection(context, s),
              Expanded(child: _buildScrollContent(context, s)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTasbihHeader(BuildContext context, AppStrings s) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            s.tasbihAzkarTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: p.textPrimary,
            ),
          ),
          IconButton(
            onPressed: _reset,
            icon: Icon(Icons.refresh, color: p.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterSection(BuildContext context, AppStrings s) {
    final p = context.palette;
    return GestureDetector(
      onTap: _increment,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 250,
              height: 250,
              child: CircularProgressIndicator(
                value: _counter / _target,
                strokeWidth: 12,
                backgroundColor: p.primary.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(p.primary),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_counter',
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: p.textPrimary,
                  ),
                ),
                Text(
                  '${s.targetLabel}: $_target',
                  style: TextStyle(
                    fontSize: 12,
                    color: p.textSecondary,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollContent(BuildContext context, AppStrings s) {
    final ar = s.isArabic;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        _buildSectionLabel(context, s.dailyRemembrancesSection),
        const SizedBox(height: 12),
        ..._dailyAdhkar.map((m) => _buildDhikrCard(context, m, ar)),
        const SizedBox(height: 28),
        _buildSectionLabel(context, s.tasbihPresetsSection),
        const SizedBox(height: 12),
        ..._tasbihPresets.asMap().entries.map((e) => _buildPresetRow(context, e.key + 1, e.value, ar)),
      ],
    );
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
    final p = context.palette;
    return Text(
      text,
      style: TextStyle(
        color: p.primary,
        fontSize: 11,
        letterSpacing: 2,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDhikrCard(BuildContext context, Map<String, String> item, bool isArabic) {
    final p = context.palette;
    final title = isArabic ? item['titleAr']! : item['titleEn']!;
    final body = isArabic ? item['ar']! : item['en']!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.05)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: p.primary,
        collapsedIconColor: p.textSecondary,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: p.textPrimary,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: isArabic
                ? Text(
                    body,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.5,
                      color: p.textPrimary,
                    ),
                  )
                : Text(
                    body,
                    style: TextStyle(fontSize: 13, color: p.textSecondary, height: 1.4),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetRow(BuildContext context, int index, Map<String, String> row, bool isArabic) {
    final p = context.palette;
    final title = isArabic ? row['titleAr']! : row['titleEn']!;
    final subtitle = isArabic ? row['subtitleAr']! : row['subtitleEn']!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: TextStyle(color: p.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: p.textPrimary),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: p.textSecondary),
                ),
              ],
            ),
          ),
          Icon(Icons.touch_app_outlined, size: 20, color: p.textSecondary),
        ],
      ),
    );
  }
}
