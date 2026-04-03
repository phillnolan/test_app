import 'dart:async';

import 'package:flutter/foundation.dart';

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

class LocalPersistResult {
  const LocalPersistResult({
    required this.payload,
    required this.cloudSyncCompletion,
  });

  final LocalCachePayload payload;
  final Future<void> cloudSyncCompletion;
}

class CloudSyncDelta {
  const CloudSyncDelta({
    required this.payload,
    this.changedEvent,
    this.deletedEventId,
  });

  final LocalCachePayload payload;
  final StudentEvent? changedEvent;
  final String? deletedEventId;
}

class _PendingCloudSyncBatch {
  const _PendingCloudSyncBatch({
    required this.payload,
    required this.changedEventsById,
    required this.deletedEventIds,
  });

  final LocalCachePayload payload;
  final Map<String, StudentEvent> changedEventsById;
  final Set<String> deletedEventIds;

  _PendingCloudSyncBatch merge(CloudSyncDelta delta) {
    final nextChangedEvents = Map<String, StudentEvent>.from(changedEventsById);
    final nextDeletedEventIds = Set<String>.from(deletedEventIds);

    final changedEvent = delta.changedEvent;
    if (changedEvent != null) {
      nextChangedEvents[changedEvent.id] = changedEvent;
      nextDeletedEventIds.remove(changedEvent.id);
    }

    final deletedEventId = delta.deletedEventId;
    if (deletedEventId != null && deletedEventId.isNotEmpty) {
      nextChangedEvents.remove(deletedEventId);
      nextDeletedEventIds.add(deletedEventId);
    }

    return _PendingCloudSyncBatch(
      payload: delta.payload,
      changedEventsById: nextChangedEvents,
      deletedEventIds: nextDeletedEventIds,
    );
  }
}

class DashboardPersistenceService {
  static const Duration _syncCacheDebounce = Duration(milliseconds: 1200);
  static const Duration _cloudRetryDelay = Duration(seconds: 5);

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
  bool _isBackgroundCloudSyncRunning = false;
  _PendingCloudSyncBatch? _latestPendingCloudBatch;
  List<Completer<void>> _pendingCloudSyncCompleters = [];
  int _backgroundCloudSyncGeneration = 0;
  Timer? _debouncedSyncCacheTimer;
  LocalCachePayload? _latestPendingSyncCachePayload;
  Timer? _backgroundCloudRetryTimer;

  Future<LocalCachePayload?> loadLocalCache() {
    return _localCacheService.load();
  }

  Future<LocalCachePayload?> fetchRemotePayload() {
    return _cloudSyncService.fetchSyncCache();
  }

  Future<void> clearCloudAccountData() {
    return _cloudSyncService.clearAccountData();
  }

  Future<void> clearLocalData() async {
    invalidatePendingCloudSyncs();
    await _localCacheService.clear();
    await _deviceEffectsService.refreshDeviceState(const LocalCachePayload());
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

  Future<LocalCachePayload> persistPayloadLocally(
    LocalCachePayload payload,
  ) async {
    await _localCacheService.save(payload);
    await _deviceEffectsService.refreshDeviceState(payload);
    return payload;
  }

  Future<LocalPersistResult> persistPayloadLocallyAndSyncInBackground(
    LocalCachePayload payload, {
    StudentEvent? changedEvent,
    String? deletedEventId,
  }) async {
    await _localCacheService.save(payload);
    await _deviceEffectsService.refreshDeviceState(payload);

    final cloudSyncCompletion = _scheduleCloudSync(
      CloudSyncDelta(
        payload: payload,
        changedEvent: changedEvent,
        deletedEventId: deletedEventId,
      ),
    );
    unawaited(cloudSyncCompletion);

    return LocalPersistResult(
      payload: payload,
      cloudSyncCompletion: cloudSyncCompletion,
    );
  }

  Future<void> queueCloudSyncForPayload(
    LocalCachePayload payload, {
    List<StudentEvent> changedEvents = const [],
    List<String> deletedEventIds = const [],
  }) async {
    if (changedEvents.isEmpty && deletedEventIds.isEmpty) {
      return;
    }

    final completions = <Future<void>>[];
    for (final event in changedEvents) {
      completions.add(
        _scheduleCloudSync(
          CloudSyncDelta(payload: payload, changedEvent: event),
        ),
      );
    }
    for (final deletedEventId in deletedEventIds) {
      completions.add(
        _scheduleCloudSync(
          CloudSyncDelta(payload: payload, deletedEventId: deletedEventId),
        ),
      );
    }
    await Future.wait(completions);
  }

  void invalidatePendingCloudSyncs() {
    _backgroundCloudSyncGeneration++;
    _latestPendingCloudBatch = null;
    _latestPendingSyncCachePayload = null;
    _debouncedSyncCacheTimer?.cancel();
    _debouncedSyncCacheTimer = null;
    _backgroundCloudRetryTimer?.cancel();
    _backgroundCloudRetryTimer = null;

    final completers = _pendingCloudSyncCompleters;
    _pendingCloudSyncCompleters = [];
    for (final completer in completers) {
      if (!completer.isCompleted) {
        completer.complete();
      }
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
    final totalStopwatch = Stopwatch()..start();
    _logTiming(
      'syncPayload start',
      extra:
          'synced=${payload.syncedEvents.length} personal=${payload.personalEvents.length}',
    );

    final attachmentsSyncedStopwatch = Stopwatch()..start();
    final updatedSyncedEvents = await _uploadMissingAttachments(
      payload.syncedEvents,
    );
    final updatedPersonalEvents = await _uploadMissingAttachments(
      payload.personalEvents,
    );
    _logTiming(
      'uploadMissingAttachments total',
      elapsedMs: attachmentsSyncedStopwatch.elapsedMilliseconds,
      extra:
          'synced=${updatedSyncedEvents.length} personal=${updatedPersonalEvents.length}',
    );
    final syncedPayload = payload.copyWith(
      syncedEvents: updatedSyncedEvents,
      personalEvents: updatedPersonalEvents,
    );

    final syncedNotesStopwatch = Stopwatch()..start();
    for (final event in updatedSyncedEvents) {
      await _cloudSyncService.upsertNote(event);
    }
    _logTiming(
      'upsert synced-event notes',
      elapsedMs: syncedNotesStopwatch.elapsedMilliseconds,
      extra: 'count=${updatedSyncedEvents.length}',
    );

    final personalEventsStopwatch = Stopwatch()..start();
    for (final event in updatedPersonalEvents) {
      await _cloudSyncService.upsertNote(event);
      await _cloudSyncService.upsertTask(event);
    }
    _logTiming(
      'upsert personal-event note/task',
      elapsedMs: personalEventsStopwatch.elapsedMilliseconds,
      extra: 'count=${updatedPersonalEvents.length}',
    );

    final saveSyncCacheStopwatch = Stopwatch()..start();
    await _cloudSyncService.saveSyncCache(syncedPayload);
    _logTiming(
      'saveSyncCache total',
      elapsedMs: saveSyncCacheStopwatch.elapsedMilliseconds,
    );
    _logTiming(
      'syncPayload complete',
      elapsedMs: totalStopwatch.elapsedMilliseconds,
      extra:
          'synced=${syncedPayload.syncedEvents.length} personal=${syncedPayload.personalEvents.length}',
    );
    return syncedPayload;
  }

  Future<LocalCachePayload> _syncDeltaToCloud(
    _PendingCloudSyncBatch batch, {
    required int generation,
  }) async {
    final totalStopwatch = Stopwatch()..start();
    _logTiming(
      'syncDelta start',
      extra:
          'changed=${batch.changedEventsById.length} deleted=${batch.deletedEventIds.length} synced=${batch.payload.syncedEvents.length} personal=${batch.payload.personalEvents.length}',
    );

    var syncedPayload = batch.payload;
    final changedEvents = batch.changedEventsById.values.toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    final changedEventsStopwatch = Stopwatch()..start();
    for (final event in changedEvents) {
      final eventStopwatch = Stopwatch()..start();
      final uploadedEvent = await _uploadMissingAttachmentsForEvent(event);
      syncedPayload = _replaceEventInPayload(syncedPayload, uploadedEvent);
      await _cloudSyncService.upsertNote(uploadedEvent);
      if (uploadedEvent.type == StudentEventType.personalTask) {
        await _cloudSyncService.upsertTask(uploadedEvent);
      }
      _logTiming(
        'sync changed event ${event.id}',
        elapsedMs: eventStopwatch.elapsedMilliseconds,
        extra: 'type=${event.type.name}',
      );
    }
    _logTiming(
      'sync changed events total',
      elapsedMs: changedEventsStopwatch.elapsedMilliseconds,
      extra: 'count=${changedEvents.length}',
    );

    _logTiming(
      'syncDelta complete',
      elapsedMs: totalStopwatch.elapsedMilliseconds,
      extra:
          'changed=${changedEvents.length} deleted=${batch.deletedEventIds.length}',
    );
    _scheduleDebouncedSyncCacheSave(
      syncedPayload,
      generation: generation,
      deletedCount: batch.deletedEventIds.length,
    );
    return syncedPayload;
  }

  Future<List<StudentEvent>> _uploadMissingAttachments(
    List<StudentEvent> events,
  ) async {
    final updatedEvents = <StudentEvent>[];
    for (final event in events) {
      final eventStopwatch = Stopwatch()..start();
      final uploadedAttachments = <EventAttachment>[];
      for (final attachment in event.attachments) {
        uploadedAttachments.add(
          await _cloudSyncService.uploadAttachment(
            attachment: attachment,
            eventId: event.id,
          ),
        );
      }
      _logTiming(
        'event attachments ${event.id}',
        elapsedMs: eventStopwatch.elapsedMilliseconds,
        extra: 'count=${event.attachments.length}',
      );
      updatedEvents.add(event.copyWith(attachments: uploadedAttachments));
    }
    return updatedEvents;
  }

  Future<StudentEvent> _uploadMissingAttachmentsForEvent(
    StudentEvent event,
  ) async {
    final eventStopwatch = Stopwatch()..start();
    final uploadedAttachments = <EventAttachment>[];
    for (final attachment in event.attachments) {
      uploadedAttachments.add(
        await _cloudSyncService.uploadAttachment(
          attachment: attachment,
          eventId: event.id,
        ),
      );
    }
    _logTiming(
      'event attachments ${event.id}',
      elapsedMs: eventStopwatch.elapsedMilliseconds,
      extra: 'count=${event.attachments.length}',
    );
    return event.copyWith(attachments: uploadedAttachments);
  }

  DateTime _normalizedDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  Future<void> _scheduleCloudSync(CloudSyncDelta delta) {
    final completer = Completer<void>();
    final baseBatch =
        _latestPendingCloudBatch ??
        _PendingCloudSyncBatch(
          payload: delta.payload,
          changedEventsById: <String, StudentEvent>{},
          deletedEventIds: <String>{},
        );
    _latestPendingCloudBatch = baseBatch.merge(delta);
    _pendingCloudSyncCompleters = [..._pendingCloudSyncCompleters, completer];
    _logTiming(
      'queue background sync',
      extra:
          'pendingCompleters=${_pendingCloudSyncCompleters.length} changed=${_latestPendingCloudBatch?.changedEventsById.length ?? 0} deleted=${_latestPendingCloudBatch?.deletedEventIds.length ?? 0}',
    );

    if (_isBackgroundCloudSyncRunning) {
      _logTiming('queue background sync coalesced');
      return completer.future;
    }

    _backgroundCloudRetryTimer?.cancel();
    _backgroundCloudRetryTimer = null;
    final generation = _backgroundCloudSyncGeneration;
    _isBackgroundCloudSyncRunning = true;
    unawaited(_drainLatestOnlyCloudSyncQueue(generation));
    return completer.future;
  }

  Future<void> _drainLatestOnlyCloudSyncQueue(int generation) async {
    try {
      while (generation == _backgroundCloudSyncGeneration) {
        final batch = _latestPendingCloudBatch;
        if (batch == null) {
          break;
        }

        final completers = _pendingCloudSyncCompleters;
        _latestPendingCloudBatch = null;
        _pendingCloudSyncCompleters = [];
        _logTiming(
          'drain latest-only sync batch',
          extra:
              'listeners=${completers.length} changed=${batch.changedEventsById.length} deleted=${batch.deletedEventIds.length} synced=${batch.payload.syncedEvents.length} personal=${batch.payload.personalEvents.length}',
        );
        var shouldRetryBatch = false;

        try {
          final syncedPayload = await _syncDeltaToCloud(
            batch,
            generation: generation,
          );
          if (generation == _backgroundCloudSyncGeneration) {
            await _localCacheService.save(syncedPayload);
          }
        } catch (_) {
          if (generation == _backgroundCloudSyncGeneration) {
            _latestPendingCloudBatch = _mergePendingCloudBatches(
              batch,
              _latestPendingCloudBatch,
            );
            _pendingCloudSyncCompleters = [
              ...completers,
              ..._pendingCloudSyncCompleters,
            ];
            _scheduleBackgroundCloudRetry(generation);
            shouldRetryBatch = true;
            break;
          }
        } finally {
          if (!shouldRetryBatch) {
            for (final completer in completers) {
              if (!completer.isCompleted) {
                completer.complete();
              }
            }
          }
        }
      }
    } finally {
      _isBackgroundCloudSyncRunning = false;
      if (generation == _backgroundCloudSyncGeneration &&
          _latestPendingCloudBatch != null) {
        _isBackgroundCloudSyncRunning = true;
        unawaited(_drainLatestOnlyCloudSyncQueue(generation));
      }
    }
  }

  LocalCachePayload _replaceEventInPayload(
    LocalCachePayload payload,
    StudentEvent updatedEvent,
  ) {
    final updatedSyncedEvents = payload.syncedEvents
        .map((event) => event.id == updatedEvent.id ? updatedEvent : event)
        .toList();
    final updatedPersonalEvents = payload.personalEvents
        .map((event) => event.id == updatedEvent.id ? updatedEvent : event)
        .toList();

    return payload.copyWith(
      syncedEvents: updatedSyncedEvents,
      personalEvents: updatedPersonalEvents,
    );
  }

  _PendingCloudSyncBatch _mergePendingCloudBatches(
    _PendingCloudSyncBatch primary,
    _PendingCloudSyncBatch? secondary,
  ) {
    if (secondary == null) {
      return primary;
    }

    final nextChangedEvents = Map<String, StudentEvent>.from(
      primary.changedEventsById,
    );
    final nextDeletedEventIds = Set<String>.from(primary.deletedEventIds);

    for (final event in secondary.changedEventsById.values) {
      nextChangedEvents[event.id] = event;
      nextDeletedEventIds.remove(event.id);
    }
    for (final deletedId in secondary.deletedEventIds) {
      nextChangedEvents.remove(deletedId);
      nextDeletedEventIds.add(deletedId);
    }

    return _PendingCloudSyncBatch(
      payload: secondary.payload,
      changedEventsById: nextChangedEvents,
      deletedEventIds: nextDeletedEventIds,
    );
  }

  void _scheduleBackgroundCloudRetry(int generation) {
    if (_backgroundCloudRetryTimer != null) {
      return;
    }

    _logTiming(
      'schedule background sync retry',
      extra: 'delayMs=${_cloudRetryDelay.inMilliseconds}',
    );
    _backgroundCloudRetryTimer = Timer(_cloudRetryDelay, () {
      _backgroundCloudRetryTimer = null;
      if (generation != _backgroundCloudSyncGeneration ||
          _latestPendingCloudBatch == null ||
          _isBackgroundCloudSyncRunning) {
        return;
      }

      _isBackgroundCloudSyncRunning = true;
      unawaited(_drainLatestOnlyCloudSyncQueue(generation));
    });
  }

  void _scheduleDebouncedSyncCacheSave(
    LocalCachePayload payload, {
    required int generation,
    required int deletedCount,
  }) {
    _latestPendingSyncCachePayload = payload;
    _debouncedSyncCacheTimer?.cancel();
    _logTiming(
      'debounce saveSyncCache scheduled',
      extra:
          'delayMs=${_syncCacheDebounce.inMilliseconds} deleted=$deletedCount synced=${payload.syncedEvents.length} personal=${payload.personalEvents.length}',
    );

    _debouncedSyncCacheTimer = Timer(_syncCacheDebounce, () async {
      if (generation != _backgroundCloudSyncGeneration) {
        return;
      }

      final pendingPayload = _latestPendingSyncCachePayload;
      if (pendingPayload == null) {
        return;
      }

      _latestPendingSyncCachePayload = null;
      _debouncedSyncCacheTimer = null;

      final saveSyncCacheStopwatch = Stopwatch()..start();
      try {
        await _cloudSyncService.saveSyncCache(pendingPayload);
        _logTiming(
          'saveSyncCache delta total',
          elapsedMs: saveSyncCacheStopwatch.elapsedMilliseconds,
          extra:
              'synced=${pendingPayload.syncedEvents.length} personal=${pendingPayload.personalEvents.length}',
        );
      } catch (_) {
        // Keep note/task sync successful even if snapshot refresh fails.
      }
    });
  }

  void _logTiming(String step, {int? elapsedMs, String? extra}) {
    if (!kDebugMode) {
      return;
    }

    debugPrint(
      '[CloudSyncTiming] $step'
      '${elapsedMs == null ? '' : ' took ${elapsedMs}ms'}'
      '${extra == null ? '' : ' | $extra'}',
    );
  }
}
