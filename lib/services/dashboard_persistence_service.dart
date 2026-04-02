import '../models/event_attachment.dart';
import '../models/local_cache_payload.dart';
import '../models/student_event.dart';
import 'cloud_sync_service.dart';
import 'device_effects_service.dart';
import 'local_cache_service.dart';

class DashboardRestoreResult {
  const DashboardRestoreResult({required this.payload, this.selectedDate});

  final LocalCachePayload payload;
  final DateTime? selectedDate;
}

class DashboardPersistenceService {
  DashboardPersistenceService({
    LocalCacheService? localCacheService,
    CloudSyncService? cloudSyncService,
    DeviceEffectsService? deviceEffectsService,
  }) : _localCacheService = localCacheService ?? LocalCacheService(),
       _cloudSyncService = cloudSyncService ?? CloudSyncService(),
       _deviceEffectsService = deviceEffectsService ?? DeviceEffectsService();

  final LocalCacheService _localCacheService;
  final CloudSyncService _cloudSyncService;
  final DeviceEffectsService _deviceEffectsService;

  Future<LocalCachePayload?> loadLocalCache() {
    return _localCacheService.load();
  }

  Future<DashboardRestoreResult> restoreAndSyncCloudState({
    required LocalCachePayload currentPayload,
    required DateTime fallbackSelectedDate,
  }) async {
    var nextPayload = currentPayload;
    DateTime? nextSelectedDate;

    try {
      final remotePayload = await _cloudSyncService.fetchSyncCache();
      if (shouldUseRemotePayload(currentPayload, remotePayload)) {
        nextPayload = remotePayload!;
        nextSelectedDate = selectedDateForPayload(
          nextPayload,
          fallbackSelectedDate,
        );
      }
    } catch (_) {
      // Keep local-first experience if cloud read fails.
    }

    final persistedPayload = await persistPayload(nextPayload);
    return DashboardRestoreResult(
      payload: persistedPayload,
      selectedDate: nextSelectedDate,
    );
  }

  Future<LocalCachePayload> persistPayload(LocalCachePayload payload) async {
    await _localCacheService.save(payload);
    await _deviceEffectsService.refreshDeviceState(payload);

    try {
      final syncedPayload = await _syncPayloadToCloud(payload);
      await _localCacheService.save(syncedPayload);
      return syncedPayload;
    } catch (_) {
      return payload;
    }
  }

  bool shouldUseRemotePayload(
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

  DateTime selectedDateForPayload(
    LocalCachePayload payload,
    DateTime fallback,
  ) {
    final lastSyncedAt = payload.lastSyncedAt;
    if (lastSyncedAt == null) {
      return _normalizedDate(fallback);
    }
    return _normalizedDate(lastSyncedAt);
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
      final uploadedAttachments = <EventAttachment>[];
      for (final attachment in event.attachments) {
        uploadedAttachments.add(
          await _cloudSyncService.uploadAttachment(
            attachment: attachment,
            eventId: event.id,
          ),
        );
      }
      updatedEvents.add(event.copyWith(attachments: uploadedAttachments));
    }
    return updatedEvents;
  }

  DateTime _normalizedDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
