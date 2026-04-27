class WeatherForecast {
  const WeatherForecast({
    required this.locationLabel,
    required this.days,
    required this.fetchedAt,
  });

  final String locationLabel;
  final List<WeatherDayForecast> days;
  final DateTime fetchedAt;

  WeatherDayForecast? dayForDate(DateTime date) {
    for (final day in days) {
      if (day.date.year == date.year &&
          day.date.month == date.month &&
          day.date.day == date.day) {
        return day;
      }
    }
    return null;
  }
}

class WeatherDayForecast {
  const WeatherDayForecast({
    required this.date,
    required this.weatherCode,
    required this.temperatureMin,
    required this.temperatureMax,
    required this.precipitationProbabilityMax,
    required this.windSpeedMax,
  });

  final DateTime date;
  final int weatherCode;
  final double temperatureMin;
  final double temperatureMax;
  final int precipitationProbabilityMax;
  final double windSpeedMax;
}
