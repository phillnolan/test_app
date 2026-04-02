import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/event_attachment.dart';
import '../models/school_sync_snapshot.dart';
import '../models/student_event.dart';
import '../models/weather_forecast.dart';
import '../services/attachment_opener.dart';
import '../services/attachment_storage_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/local_cache_service.dart';
import '../services/notification_service.dart';
import '../services/school_api_service.dart';
import '../services/weather_service.dart';
import '../services/widget_sync_service.dart';
import '../widgets/home/home_editors.dart';
import '../widgets/home/home_sheet_models.dart';

class HomeShellMutation {
  const HomeShellMutation({required this.payload, this.selectedDate});

  final LocalCachePayload payload;
  final DateTime? selectedDate;
}

class HomeShellController {
  HomeShellController({
    SchoolApiService? schoolApiService,
    LocalCacheService? localCacheService,
    AttachmentStorageService? attachmentStorageService,
    CloudSyncService? cloudSyncService,
    WeatherService? weatherService,
    WidgetSyncService? widgetSyncService,
  }) : _schoolApiService = schoolApiService ?? SchoolApiService(),
       _localCacheService = localCacheService ?? LocalCacheService(),
       _attachmentStorageService =
           attachmentStorageService ?? AttachmentStorageService(),
       _cloudSyncService = cloudSyncService ?? CloudSyncService(),
       _weatherService = weatherService ?? WeatherService(),
       _widgetSyncService = widgetSyncService ?? WidgetSyncService();

  final SchoolApiService _schoolApiService;
  final LocalCacheService _localCacheService;
  final AttachmentStorageService _attachmentStorageService;
  final CloudSyncService _cloudSyncService;
  final WeatherService _weatherService;
  final WidgetSyncService _widgetSyncService;

  Future<WeatherForecast?> loadWeatherForecast() async {
    try {
      return await _weatherService.fetchForecast();
    } on WeatherException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<LocalCachePayload?> loadLocalCache() {
    return _localCacheService.load();
  }

  Future<HomeShellMutation> syncSchool({
    required String username,
    required String password,
    required LocalCachePayload currentPayload,
  }) async {
    final snapshot = await _schoolApiService.sync(
      username: username,
      password: password,
    );
    final payload = await _persistPayload(
      _payloadFromSnapshot(snapshot, currentPayload),
    );

    return HomeShellMutation(
      payload: payload,
      selectedDate: _normalizedDate(snapshot.syncedAt),
    );
  }

  Future<HomeShellMutation> restoreAndSyncCloudState({
    required LocalCachePayload currentPayload,
    required DateTime fallbackSelectedDate,
  }) async {
    var nextPayload = currentPayload;
    DateTime? selectedDate;

    try {
      final remotePayload = await _cloudSyncService.fetchSyncCache();
      if (_shouldUseRemotePayload(currentPayload, remotePayload)) {
        nextPayload = remotePayload!;
        selectedDate = selectedDateForPayload(
          nextPayload,
          fallbackSelectedDate,
        );
      }
    } catch (_) {
      // Keep local-first experience if cloud read fails.
    }

    nextPayload = await _persistPayload(nextPayload);
    return HomeShellMutation(payload: nextPayload, selectedDate: selectedDate);
  }

  Future<HomeShellMutation?> addTask({
    required BuildContext context,
    required DateTime selectedDate,
    required LocalCachePayload currentPayload,
  }) async {
    final result = await showModalBottomSheet<TaskEditorResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => EnhancedTaskEditorSheet(initialDate: selectedDate),
    );

    if (result == null || !context.mounted) return null;

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
            subtitle: 'Việc cá nhân',
            start: start,
            end: start.add(const Duration(hours: 1)),
            type: StudentEventType.personalTask,
            color: const Color(0xFFDDF4E4),
            note: result.note.isEmpty ? null : result.note,
            attachments: result.attachments,
          ),
        ]);
    updatedPersonalEvents.sort((a, b) => a.start.compareTo(b.start));

    final payload = await _persistPayload(
      currentPayload.copyWith(personalEvents: updatedPersonalEvents),
    );

    return HomeShellMutation(
      payload: payload,
      selectedDate: _normalizedDate(result.date),
    );
  }

  Future<HomeShellMutation?> editEvent({
    required BuildContext context,
    required StudentEvent event,
    required LocalCachePayload currentPayload,
  }) async {
    final result = await showModalBottomSheet<NoteEditorResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => EnhancedNoteEditorSheet(event: event),
    );

    if (result == null || !context.mounted) return null;

    if (result.deleteEvent && event.type == StudentEventType.personalTask) {
      final payload = await _persistPayload(
        currentPayload.copyWith(
          personalEvents: currentPayload.personalEvents
              .where((item) => item.id != event.id)
              .toList(),
        ),
      );
      return HomeShellMutation(payload: payload);
    }

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

    final payload = await _persistPayload(
      currentPayload.copyWith(
        personalEvents: updatedPersonalEvents,
        syncedEvents: updatedSyncedEvents,
      ),
    );

    return HomeShellMutation(payload: payload);
  }

  Future<LocalCachePayload?> deletePersonalEvent({
    required BuildContext context,
    required StudentEvent event,
    required LocalCachePayload currentPayload,
  }) async {
    if (event.type != StudentEventType.personalTask) return null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ghi chú cá nhân?'),
        content: Text(
          'Ghi chú "${event.title}" sẽ bị xóa khỏi thiết bị và cloud.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return null;

    return _persistPayload(
      currentPayload.copyWith(
        personalEvents: currentPayload.personalEvents
            .where((item) => item.id != event.id)
            .toList(),
      ),
    );
  }

  Future<HomeShellMutation> toggleDone({
    required String id,
    required LocalCachePayload currentPayload,
  }) async {
    final payload = await _persistPayload(
      currentPayload.copyWith(
        personalEvents: currentPayload.personalEvents.map((event) {
          if (event.id != id) return event;
          return event.copyWith(isDone: !event.isDone);
        }).toList(),
      ),
    );

    return HomeShellMutation(payload: payload);
  }

  Future<bool> openAttachment(EventAttachment attachment) async {
    final localBytes = await _attachmentStorageService.readAttachmentBytes(
      attachment,
    );
    final bytes =
        localBytes ??
        (attachment.bytesBase64 == null
            ? await _cloudSyncService.downloadAttachmentBytes(attachment)
            : base64Decode(attachment.bytesBase64!));

    return openAttachmentFile(
      fileName: attachment.name,
      localPath: kIsWeb ? null : attachment.path,
      bytes: bytes,
    );
  }

  static DateTime selectedDateForPayload(
    LocalCachePayload payload,
    DateTime fallback,
  ) {
    final lastSyncedAt = payload.lastSyncedAt;
    if (lastSyncedAt == null) {
      return _normalizedDate(fallback);
    }
    return _normalizedDate(lastSyncedAt);
  }

  Future<LocalCachePayload> _persistPayload(LocalCachePayload payload) async {
    await _localCacheService.save(payload);
    await _refreshDeviceState(payload);

    final syncedPayload = await _syncPayloadToCloud(payload);
    await _localCacheService.save(syncedPayload);
    return syncedPayload;
  }

  Future<void> _refreshDeviceState(LocalCachePayload payload) async {
    final allEvents = _allEventsForPayload(payload);
    await NotificationService.instance.rescheduleForEvents(allEvents);
    await _widgetSyncService.updateTodayWidget(
      profile: payload.profile,
      events: allEvents,
    );
  }

  Future<LocalCachePayload> _syncPayloadToCloud(
    LocalCachePayload payload,
  ) async {
    final updatedSyncedEvents = await _uploadMissingAttachments(
      payload.syncedEvents,
    );
    final updatedPersonalEvents = await _uploadMissingAttachments(
      payload.personalEvents,
    );
    final syncedPayload = payload.copyWith(
      syncedEvents: updatedSyncedEvents,
      personalEvents: updatedPersonalEvents,
    );

    for (final event in updatedSyncedEvents) {
      await _cloudSyncService.upsertNote(event);
    }
    for (final event in updatedPersonalEvents) {
      await _cloudSyncService.upsertNote(event);
      await _cloudSyncService.upsertTask(event);
    }

    await _cloudSyncService.saveSyncCache(syncedPayload);
    return syncedPayload;
  }

  Future<List<StudentEvent>> _uploadMissingAttachments(
    List<StudentEvent> events,
  ) async {
    final updatedEvents = <StudentEvent>[];
    for (final event in events) {
      final uploaded = <EventAttachment>[];
      for (final attachment in event.attachments) {
        uploaded.add(
          await _cloudSyncService.uploadAttachment(
            attachment: attachment,
            eventId: event.id,
          ),
        );
      }
      updatedEvents.add(event.copyWith(attachments: uploaded));
    }
    return updatedEvents;
  }

  LocalCachePayload _payloadFromSnapshot(
    SchoolSyncSnapshot snapshot,
    LocalCachePayload currentPayload,
  ) {
    final currentUsername = currentPayload.profile?.username.trim();
    final isDifferentStudent =
        currentUsername != null &&
        currentUsername.isNotEmpty &&
        currentUsername != snapshot.profile.username.trim();

    return LocalCachePayload(
      profile: snapshot.profile,
      grades: snapshot.grades,
      curriculumSubjects: snapshot.curriculumSubjects,
      curriculumRawItems: snapshot.curriculumRawItems,
      syncedEvents: snapshot.events,
      personalEvents: isDifferentStudent
          ? const []
          : currentPayload.personalEvents,
      lastSyncedAt: snapshot.syncedAt,
    );
  }

  bool _shouldUseRemotePayload(
    LocalCachePayload localPayload,
    LocalCachePayload? remotePayload,
  ) {
    if (remotePayload == null) return false;
    if (!localPayload.hasData) return true;

    final remoteTime = remotePayload.lastSyncedAt;
    final localTime = localPayload.lastSyncedAt;
    if (remoteTime == null) return false;
    if (localTime == null) return true;
    return remoteTime.isAfter(localTime);
  }

  List<StudentEvent> _allEventsForPayload(LocalCachePayload payload) {
    final events = [...payload.syncedEvents, ...payload.personalEvents]
      ..sort((a, b) => a.start.compareTo(b.start));
    return events;
  }

  static DateTime _normalizedDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
