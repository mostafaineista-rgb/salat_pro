import 'dart:math' as math;

class MoonPhaseData {
  final double illumination;
  final double ageInDays;
  final String phaseName;
  final double phasePercent; // 0.0 to 1.0

  MoonPhaseData({
    required this.illumination,
    required this.ageInDays,
    required this.phaseName,
    required this.phasePercent,
  });
}

class MoonUtils {
  static const double lunarCycle = 29.530588853;

  static MoonPhaseData getMoonPhase(DateTime date, bool isArabic) {
    // Reference date: Jan 6, 2000 (New Moon)
    final refNewMoon = DateTime(2000, 1, 6, 18, 14);
    final diff = date.difference(refNewMoon).inSeconds / 86400.0;
    
    double cycles = diff / lunarCycle;
    double phase = cycles - cycles.floor(); // 0.0 to 1.0
    double age = phase * lunarCycle;
    
    // Simple illumination calculation
    // Percent = 0.5 * (1 - cos(2 * pi * phase))
    double illumination = 0.5 * (1 - math.cos(2 * math.pi * phase)) * 100;
    
    String phaseName;
    if (phase < 0.03 || phase > 0.97) {
      phaseName = isArabic ? 'محاق' : 'New Moon';
    } else if (phase < 0.22) {
      phaseName = isArabic ? 'هلال متزايد' : 'Waxing Crescent';
    } else if (phase < 0.28) {
      phaseName = isArabic ? 'تربيع أول' : 'First Quarter';
    } else if (phase < 0.47) {
      phaseName = isArabic ? 'أحدب متزايد' : 'Waxing Gibbous';
    } else if (phase < 0.53) {
      phaseName = isArabic ? 'بدر' : 'Full Moon';
    } else if (phase < 0.72) {
      phaseName = isArabic ? 'أحدب متناقص' : 'Waning Gibbous';
    } else if (phase < 0.78) {
      phaseName = isArabic ? 'تربيع أخير' : 'Last Quarter';
    } else {
      phaseName = isArabic ? 'هلال متناقص' : 'Waning Crescent';
    }

    return MoonPhaseData(
      illumination: illumination,
      ageInDays: age,
      phaseName: phaseName,
      phasePercent: phase,
    );
  }
}
