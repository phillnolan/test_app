import 'package:flutter/material.dart';

import '../models/event_attachment.dart';
import '../models/local_cache_payload.dart';

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

enum AccountLinkAction { none, linkStudent, relinkStudent }

class AccountLinkDecision {
  const AccountLinkDecision({
    this.action = AccountLinkAction.none,
    this.targetStudentUsername,
    this.currentLinkedStudentUsername,
  });

  final AccountLinkAction action;
  final String? targetStudentUsername;
  final String? currentLinkedStudentUsername;

  bool get requiresConfirmation => action != AccountLinkAction.none;
}

class AuthFlowResult {
  const AuthFlowResult.success({
    this.message,
    this.decision = const AccountLinkDecision(),
  }) : isSuccess = true;

  const AuthFlowResult.failure(this.message)
    : isSuccess = false,
      decision = const AccountLinkDecision();

  final bool isSuccess;
  final String? message;
  final AccountLinkDecision decision;
}

class PreparedSyncPlan {
  const PreparedSyncPlan({
    required this.payload,
    required this.selectedDate,
    this.decision = const AccountLinkDecision(),
    this.requiresLocalReplacementConfirmation = false,
    this.currentLocalStudentUsername,
  });

  final LocalCachePayload payload;
  final DateTime selectedDate;
  final AccountLinkDecision decision;
  final bool requiresLocalReplacementConfirmation;
  final String? currentLocalStudentUsername;
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
