import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/weather_forecast.dart';

class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _forecastUrl =
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=21.0285'
      '&longitude=105.8542'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max'
      '&forecast_days=7'
      '&timezone=Asia%2FBangkok';

  Future<WeatherForecast> fetchForecast() async {
    final response = await _client
        .get(Uri.parse(_forecastUrl))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode >= 400) {
      throw const WeatherException('Không tải được dự báo thời tiết.');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const WeatherException('Dữ liệu thời tiết không hợp lệ.');
    }

    final daily = decoded['daily'];
    if (daily is! Map<String, dynamic>) {
      throw const WeatherException('Thiếu dữ liệu dự báo theo ngày.');
    }

    final times = (daily['time'] as List? ?? const []).map((e) => e.toString()).toList();
    final weatherCodes =
        (daily['weather_code'] as List? ?? const []).map((e) => e as num).toList();
    final maxTemps =
        (daily['temperature_2m_max'] as List? ?? const []).map((e) => e as num).toList();
    final minTemps =
        (daily['temperature_2m_min'] as List? ?? const []).map((e) => e as num).toList();
    final rainProbabilities = (daily['precipitation_probability_max'] as List? ?? const [])
        .map((e) => e as num)
        .toList();
    final windSpeeds =
        (daily['wind_speed_10m_max'] as List? ?? const []).map((e) => e as num).toList();

    final itemCount = [
      times.length,
      weatherCodes.length,
      maxTemps.length,
      minTemps.length,
      rainProbabilities.length,
      windSpeeds.length,
    ].reduce((value, element) => value < element ? value : element);

    final days = <WeatherDayForecast>[];
    for (var index = 0; index < itemCount; index++) {
      final date = DateTime.tryParse(times[index]);
      if (date == null) continue;
      days.add(
        WeatherDayForecast(
          date: date,
          weatherCode: weatherCodes[index].toInt(),
          temperatureMin: minTemps[index].toDouble(),
          temperatureMax: maxTemps[index].toDouble(),
          precipitationProbabilityMax: rainProbabilities[index].toInt(),
          windSpeedMax: windSpeeds[index].toDouble(),
        ),
      );
    }

    return WeatherForecast(
      locationLabel: 'Hà Nội',
      days: days,
      fetchedAt: DateTime.now(),
    );
  }

  IconData iconForCode(int code) {
    if (code == 0) return Icons.sunny;
    if (code == 1 || code == 2) return Icons.wb_cloudy_outlined;
    if (code == 3) return Icons.cloud_outlined;
    if (code == 45 || code == 48) return Icons.foggy;
    if ([51, 53, 55, 56, 57, 61, 63, 65, 80, 81, 82].contains(code)) {
      return Icons.umbrella_outlined;
    }
    if ([66, 67, 71, 73, 75, 77, 85, 86].contains(code)) {
      return Icons.ac_unit;
    }
    if ([95, 96, 99].contains(code)) return Icons.thunderstorm_outlined;
    return Icons.cloud_queue;
  }

  String descriptionForCode(int code) {
    return switch (code) {
      0 => 'Trời quang',
      1 || 2 => 'Ít mây',
      3 => 'Nhiều mây',
      45 || 48 => 'Sương mù',
      51 || 53 || 55 => 'Mưa phùn',
      56 || 57 => 'Mưa phùn lạnh',
      61 || 63 || 65 => 'Có mưa',
      66 || 67 => 'Mưa lạnh',
      71 || 73 || 75 || 77 => 'Lạnh, có thể có băng tuyết',
      80 || 81 || 82 => 'Mưa rào',
      85 || 86 => 'Tuyết rào',
      95 || 96 || 99 => 'Dông',
      _ => 'Thời tiết thay đổi',
    };
  }

  List<String> suggestionsForDay(WeatherDayForecast forecast) {
    final suggestions = <String>[];

    if (forecast.precipitationProbabilityMax >= 55) {
      suggestions.add('Nên mang ô hoặc áo mưa.');
    }
    if (forecast.temperatureMin <= 17) {
      suggestions.add('Buổi sáng khá lạnh, nên mặc đủ ấm.');
    }
    if (forecast.temperatureMax >= 33) {
      suggestions.add('Trời nóng, nên mang nước và mặc đồ thoáng.');
    }
    if (forecast.windSpeedMax >= 28) {
      suggestions.add('Gió khá mạnh, nên chuẩn bị áo khoác mỏng.');
    }
    if (forecast.weatherCode == 0 && forecast.temperatureMax >= 30) {
      suggestions.add('Nắng rõ, nên mang mũ hoặc tránh đứng ngoài trời lâu.');
    }
    if (suggestions.isEmpty) {
      suggestions.add('Thời tiết khá ổn, bạn có thể đi học như bình thường.');
    }

    return suggestions;
  }
}

class WeatherException implements Exception {
  const WeatherException(this.message);

  final String message;

  @override
  String toString() => message;
}
