/// Current conditions from Open-Meteo for a short “walk to the mosque” hint.
class WalkWeatherSnapshot {
  const WalkWeatherSnapshot({
    required this.temperatureC,
    required this.apparentTemperatureC,
    required this.precipitationMmPerHour,
    required this.weatherCode,
    required this.uvIndex,
    required this.windSpeedMs,
    required this.isDay,
  });

  final double temperatureC;
  final double apparentTemperatureC;
  final double precipitationMmPerHour;
  final int weatherCode;
  final double? uvIndex;
  final double windSpeedMs;
  final bool isDay;
}
