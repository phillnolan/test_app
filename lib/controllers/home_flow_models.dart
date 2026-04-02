import 'package:flutter/material.dart';

import '../models/event_attachment.dart';

class CredentialsResult {
  const CredentialsResult({required this.username, required this.password});

  final String username;
  final String password;
}

class TaskEditorResult {
  const TaskEditorResult({
    required this.title,
    required this.note,
    required this.date,
    required this.hour,
    this.attachments = const [],
  });

  final String title;
  final String note;
  final DateTime date;
  final TimeOfDay hour;
  final List<EventAttachment> attachments;
}

class NoteEditorResult {
  const NoteEditorResult({
    this.title,
    this.note = '',
    this.attachments = const [],
    this.deleteEvent = false,
  });

  final String? title;
  final String note;
  final List<EventAttachment> attachments;
  final bool deleteEvent;
}

enum EmailAuthMode { signIn, register }

class EmailAuthResult {
  const EmailAuthResult({
    required this.mode,
    required this.email,
    required this.password,
  });

  final EmailAuthMode mode;
  final String email;
  final String password;
}

enum HomeActionStatus { success, failure }

class HomeActionResult {
  const HomeActionResult.success([this.message])
    : status = HomeActionStatus.success;

  const HomeActionResult.failure(this.message)
    : status = HomeActionStatus.failure;

  final HomeActionStatus status;
  final String? message;

  bool get isSuccess => status == HomeActionStatus.success;
}

class AttachmentOpenResult {
  const AttachmentOpenResult({required this.didOpen, this.message});

  final bool didOpen;
  final String? message;
}

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
