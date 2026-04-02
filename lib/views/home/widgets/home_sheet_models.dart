import 'package:flutter/material.dart';

import '../../../../models/event_attachment.dart';

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
