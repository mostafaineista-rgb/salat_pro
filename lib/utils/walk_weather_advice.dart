import 'package:flutter/material.dart';
import 'package:salat_pro/models/walk_weather_snapshot.dart';

/// Human, mosque-walk-oriented copy derived from [WalkWeatherSnapshot].
@immutable
class WalkWeatherAdvice {
  const WalkWeatherAdvice({
    required this.conditionLabel,
    required this.leadSentence,
    required this.supportingLines,
    required this.icon,
  });

  final String conditionLabel;
  final String leadSentence;
  final List<String> supportingLines;
  final IconData icon;

  static WalkWeatherAdvice fromSnapshot(WalkWeatherSnapshot s, {required bool isArabic}) {
    final code = s.weatherCode;
    final feels = s.apparentTemperatureC;
    final rainMm = s.precipitationMmPerHour;
    final wind = s.windSpeedMs;
    final uv = s.isDay ? (s.uvIndex ?? 0) : 0.0;

    final precipHeavy = rainMm >= 2.5 || _isHeavyPrecipCode(code);
    final precipModerate = (rainMm >= 0.5 && rainMm < 2.5) || _isModeratePrecipCode(code);
    final precipLight = (rainMm > 0 && rainMm < 0.5) || _isLightPrecipCode(code);

    final thunder = code == 95 || code == 96 || code == 99;
    final fog = code == 45 || code == 48;
    final snow = _isSnowFamily(code);

    final hot = feels >= 32;
    final warmUncomfortable = feels >= 28 && feels < 32;
    final cold = feels <= 5;
    final chilly = feels > 5 && feels <= 12;

    final uvHigh = uv >= 6;
    final uvModerate = uv >= 3 && uv < 6;

    final windy = wind >= 10;
    final breezy = wind >= 6 && wind < 10;

    IconData iconFor() {
      if (thunder) return Icons.thunderstorm_outlined;
      if (snow) return Icons.ac_unit;
      if (precipHeavy || precipModerate) return Icons.umbrella;
      if (precipLight) return Icons.grain;
      if (fog) return Icons.cloud_queue;
      if (hot || warmUncomfortable) return Icons.wb_sunny_outlined;
      if (cold || chilly) return Icons.ac_unit;
      if (!s.isDay) return Icons.nightlight_round;
      return Icons.wb_cloudy_outlined;
    }

    String label() {
      if (isArabic) {
        if (thunder) return 'عواصف رعدية';
        if (snow) return 'ثلج';
        if (precipHeavy) return 'أمطار غزيرة';
        if (precipModerate) return 'مطر';
        if (precipLight) return 'زخات خفيفة';
        if (fog) return 'ضباب';
        if (hot) return 'حر شديد';
        if (warmUncomfortable) return 'حار';
        if (cold) return 'بارد';
        if (chilly) return 'لطيف بارد';
        if (windy) return 'رياح قوية';
        if (code == 0 || code == 1) return s.isDay ? 'صافٍ' : 'صافٍ ليلاً';
        if (code == 2 || code == 3) return 'غائم جزئياً';
        return 'الطقس';
      }
      if (thunder) return 'Thunderstorms';
      if (snow) return 'Snow';
      if (precipHeavy) return 'Heavy rain';
      if (precipModerate) return 'Rain';
      if (precipLight) return 'Light showers';
      if (fog) return 'Fog';
      if (hot) return 'Very hot';
      if (warmUncomfortable) return 'Warm';
      if (cold) return 'Cold';
      if (chilly) return 'Cool';
      if (windy) return 'Windy';
      if (code == 0 || code == 1) return s.isDay ? 'Clear' : 'Clear night';
      if (code == 2 || code == 3) return 'Mostly cloudy';
      return 'Conditions';
    }

    final lines = <String>[];

    String lead() {
      if (isArabic) {
        if (thunder) {
          return 'رعدٌ وبروق؛ إن أمكن أخّر المشي قليلاً، وإن خرجت فابتعد عن الأشجار والأسوار المعدنية وتمهل.';
        }
        if (snow || precipHeavy && _isSnowFamily(code)) {
          return 'الطرق قد تكون زلقة؛ خذ وقتك في المشي إلى المسجد، ولبسٌ دافئٌ يريحك في الطريق.';
        }
        if (precipHeavy || precipModerate) {
          return 'المطر يهطل الآن — شمسية أو معطف يقيانك في الطريق إلى الصلاة.';
        }
        if (precipLight) {
          return 'زخاتٌ خفيفة ممكنة؛ أحضر شمسيةً صغيرةً احتياطاً لطريقك إلى المسجد.';
        }
        if (fog) {
          return 'ضبابٌ يقلل الرؤية؛ سر على الرصيف بعناية وارتدِ ملابساً واضحة اللون إن استطعت.';
        }
        if (hot) {
          return 'الحرّ ملحوظ؛ امشِ في الظل قدر الإمكان، وشمسيةٌ تظلك بين الممرّات، وخذ رشفات ماءٍ قبل وبعد الصلاة.';
        }
        if (warmUncomfortable) {
          return 'الجو حارٌ نسبياً؛ أبطئ الخطوة في الشمس المباشرة، وشمسيةٌ للظل خيارٌ طيبٌ في الطريق.';
        }
        if (cold) {
          return 'الهواء بارٌ؛ دفءٌ خفيفٌ يحمي جسمك في ذهابك وإيابك من المسجد.';
        }
        if (chilly) {
          return 'لطيفٌ مع بردٍ خفيف؛ طبقةٌ إضافيةٌ قد تريحك في المشي.';
        }
        if (windy) {
          return 'رياحٌ قوية؛ ثبّت العمامة أو القبعة، وانتبه للأبواب والممرات المفتوحة.';
        }
        return 'طقسٌ مناسبٌ للمشي إلى المسجد؛ سلّم على من لقيتَ وثبّت النية.';
      }

      if (thunder) {
        return 'Thunder and lightning nearby — if you can delay your walk slightly, that is wise. If you go, avoid trees and metal fences, and take your time.';
      }
      if (snow || (precipHeavy && _isSnowFamily(code))) {
        return 'Snowy or icy surfaces are possible — walk carefully to the mosque, and dress warmly for the way there and back.';
      }
      if (precipHeavy || precipModerate) {
        return 'It is raining — an umbrella or a light rain jacket will keep your walk to prayer comfortable.';
      }
      if (precipLight) {
        return 'Light showers are possible — tuck a small umbrella in your bag just in case on the way to the mosque.';
      }
      if (fog) {
        return 'Fog is reducing visibility — stay on the pavement, walk a little slower, and wear something easy to see if you can.';
      }
      if (hot) {
        return 'It feels quite hot — walk in shade where you can, use an umbrella as a sun shade between stretches of sun, sip water, and pace yourself on the way to prayer.';
      }
      if (warmUncomfortable) {
        return 'Warm air today — if the sun is strong, an umbrella can give you portable shade on the walk, not only in rain.';
      }
      if (cold) {
        return 'The air is cold — a warm layer for your walk to the mosque will help you arrive settled and comfortable.';
      }
      if (chilly) {
        return 'Cool and crisp — a light jacket or shawl may feel pleasant on the walk there and back.';
      }
      if (windy) {
        return 'It is windy — secure your hat or scarf, and mind gusts when crossing open courtyards or bridges.';
      }
      return 'Conditions look gentle for walking to the mosque — may your steps be light and your heart at ease.';
    }

    void appendUv() {
      if (!s.isDay || uv < 3) return;
      if (uvHigh) {
        lines.add(isArabic
            ? 'مؤشر الأشعة فوق البنفسجية مرتفع (${uv.toStringAsFixed(1)}) — القبعة والظل والواقي يساعدان على المدى القصير تحت الشمس.'
            : 'UV is elevated (${uv.toStringAsFixed(1)}) — a hat, shade breaks, and sunscreen help on a sunny walk.');
      } else if (uvModerate) {
        lines.add(isArabic
            ? 'الأشعة فوق البنفسجية متوسطة (${uv.toStringAsFixed(1)}) — ظلٌ قصيرٌ قبل الدخول للصلاة فكرةٌ حسنةٌ.'
            : 'UV is moderate (${uv.toStringAsFixed(1)}) — a few minutes in shade before you enter is a kind care for your skin.');
      }
    }

    void appendWind() {
      if (breezy && !windy) {
        lines.add(isArabic
            ? 'نسيمٌ نشطٌ (${wind.toStringAsFixed(1)} م/ث) — قد يبرد الجو أثناء المشي.'
            : 'A lively breeze (${wind.toStringAsFixed(1)} m/s) — it may feel cooler as you walk.');
      }
    }

    appendWind();
    appendUv();

    return WalkWeatherAdvice(
      conditionLabel: label(),
      leadSentence: lead(),
      supportingLines: lines,
      icon: iconFor(),
    );
  }

  static bool _isHeavyPrecipCode(int c) =>
      c == 65 || c == 75 || c == 82 || c == 86 || c == 67 || c == 66;

  static bool _isModeratePrecipCode(int c) => c == 63 || c == 73 || c == 81;

  static bool _isLightPrecipCode(int c) =>
      c == 61 || c == 51 || c == 53 || c == 55 || c == 56 || c == 57 || c == 80 || c == 85;

  static bool _isSnowFamily(int c) =>
      c == 71 || c == 73 || c == 75 || c == 77 || c == 85 || c == 86;
}
