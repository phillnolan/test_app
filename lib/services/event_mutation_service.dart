import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../controllers/home_flow_models.dart';
import '../models/event_attachment.dart';
import '../models/home_action_result.dart';
import '../models/local_cache_payload.dart';
import '../models/student_event.dart';
import 'attachment_opener.dart';
import 'attachment_storage_service.dart';
import 'cloud_sync_service.dart';
import 'dashboard_persistence_service.dart';

class EventMutationService {
  EventMutationService({
    AttachmentStorageService? attachmentStorageService,
    CloudSyncService? cloudSyncService,
    DashboardPersistenceService? dashboardPersistenceService,
  }) : _attachmentStorageService =
           attachmentStorageService ?? AttachmentStorageService(),
       _cloudSyncService = cloudSyncService ?? CloudSyncService(),
       _dashboardPersistenceService =
           dashboardPersistenceService ?? DashboardPersistenceService();

  final AttachmentStorageService _attachmentStorageService;
  final CloudSyncService _cloudSyncService;
  final DashboardPersistenceService _dashboardPersistenceService;

  Future<LocalCachePayload> addTask({
    required LocalCachePayload currentPayload,
    required TaskEditorResult result,
  }) async {
    final start = DateTime(
      result.date.year,
      result.date.month,
      result.date.day,
      result.hour.hour,
      result.hour.minute,
    );
    final updatedPersonalEvents = await _attachmentStorageService
        .persistEvents([
          ...currentPayload.personalEvents,
          StudentEvent(
            id: 'task-${DateTime.now().microsecondsSinceEpoch}',
            title: result.title,
            subtitle: 'Viec ca nhan',
            start: start,
            end: start.add(const Duration(hours: 1)),
            type: StudentEventType.personalTask,
            color: const Color(0xFFDDF4E4),
            note: result.note.isEmpty ? null : result.note,
            attachments: result.attachments,
          ),
        ]);

    return _dashboardPersistenceService.persistPayload(
      currentPayload.copyWith(
        personalEvents: _sortedEvents(updatedPersonalEvents),
      ),
    );
  }

  Future<LocalCachePayload> editEvent({
    required LocalCachePayload currentPayload,
    required StudentEvent event,
    required NoteEditorResult result,
  }) async {
    final trimmed = result.note.trim();
    final updatedPersonalEvents = await _attachmentStorageService.persistEvents(
      currentPayload.personalEvents.map((item) {
        if (item.id != event.id) return item;
        return item.copyWith(
          title: item.type == StudentEventType.personalTask
              ? result.title?.trim()
              : item.title,
          note: trimmed.isEmpty ? null : trimmed,
          attachments: result.attachments,
        );
      }).toList(),
    );
    final updatedSyncedEvents = await _attachmentStorageService.persistEvents(
      currentPayload.syncedEvents.map((item) {
        if (item.id != event.id) return item;
        return item.copyWith(
          note: trimmed.isEmpty ? null : trimmed,
          attachments: result.attachments,
        );
      }).toList(),
    );

    return _dashboardPersistenceService.persistPayload(
      currentPayload.copyWith(
        personalEvents: _sortedEvents(updatedPersonalEvents),
        syncedEvents: _sortedEvents(updatedSyncedEvents),
      ),
    );
  }

  Future<LocalCachePayload> deletePersonalEvent({
    required LocalCachePayload currentPayload,
    required StudentEvent event,
  }) async {
    if (event.type != StudentEventType.personalTask) return currentPayload;

    return _dashboardPersistenceService.persistPayload(
      currentPayload.copyWith(
        personalEvents: _sortedEvents(
          currentPayload.personalEvents
              .where((item) => item.id != event.id)
              .toList(),
        ),
      ),
    );
  }

  Future<LocalCachePayload> toggleDone({
    required LocalCachePayload currentPayload,
    required String id,
  }) async {
    return _dashboardPersistenceService.persistPayload(
      currentPayload.copyWith(
        personalEvents: _sortedEvents(
          currentPayload.personalEvents.map((event) {
            if (event.id != id) return event;
            return event.copyWith(isDone: !event.isDone);
          }).toList(),
        ),
      ),
    );
  }

  Future<AttachmentOpenResult> openAttachment(
    EventAttachment attachment,
  ) async {
    try {
      final localBytes = await _attachmentStorageService.readAttachmentBytes(
        attachment,
      );
      final bytes =
          localBytes ??
          (attachment.bytesBase64 == null
              ? await _cloudSyncService.downloadAttachmentBytes(attachment)
              : base64Decode(attachment.bytesBase64!));
      final opened = await openAttachmentFile(
        fileName: attachment.name,
        localPath: kIsWeb ? null : attachment.path,
        bytes: bytes,
      );
      if (opened) {
        return const AttachmentOpenResult(didOpen: true);
      }
    } catch (_) {
      // Fall through to a friendly failure result below.
    }

    return const AttachmentOpenResult(
      didOpen: false,
      message: 'Khong the mo tep dinh kem. Vui long thu lai.',
    );
  }

  List<StudentEvent> _sortedEvents(List<StudentEvent> events) {
    return [...events]..sort((a, b) => a.start.compareTo(b.start));
  }
}
