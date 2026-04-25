
class PrayerInfo {
  final String name;
  final DateTime time;
  final bool isNext;

  PrayerInfo({required this.name, required this.time, this.isNext = false});
}

class PrayerDayInfo {
  final List<PrayerInfo> prayers;
  final PrayerInfo nextPrayer;
  final Duration timeToNext;

  PrayerDayInfo({
    required this.prayers,
    required this.nextPrayer,
    required this.timeToNext,
  });
}
