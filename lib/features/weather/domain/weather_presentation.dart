import 'package:flutter/material.dart';

class WeatherPresentation {
  const WeatherPresentation({
    required this.locationLabel,
    required this.icon,
    required this.description,
    required this.temperatureMin,
    required this.temperatureMax,
    required this.precipitationProbabilityMax,
    required this.temperatureRangeLabel,
    required this.precipitationLabel,
    this.suggestions = const [],
  });

  final String locationLabel;
  final IconData icon;
  final String description;
  final int temperatureMin;
  final int temperatureMax;
  final int precipitationProbabilityMax;
  final String temperatureRangeLabel;
  final String precipitationLabel;
  final List<String> suggestions;
}
