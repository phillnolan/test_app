import 'package:flutter/material.dart';

import '../models/local_cache_payload.dart';
import '../models/school_sync_snapshot.dart';
import '../models/student_event.dart';
import 'school_api_service.dart';

class SchoolSyncResult {
  const SchoolSyncResult({required this.payload, required this.selectedDate});

  final LocalCachePayload payload;
  final DateTime selectedDate;
}

class SchoolSyncCoordinator {
  SchoolSyncCoordinator({SchoolApiService? schoolApiService})
    : _schoolApiService = schoolApiService ?? SchoolApiService();

  final SchoolApiService _schoolApiService;

  Future<SchoolSyncResult> sync({
    required String username,
    required String password,
    required LocalCachePayload currentPayload,
  }) async {
    final snapshot = await _schoolApiService.sync(
      username: username,
      password: password,
    );
    return SchoolSyncResult(
      payload: _payloadFromSnapshot(snapshot, currentPayload),
      selectedDate: _normalizedDate(snapshot.syncedAt),
    );
  }

  LocalCachePayload _payloadFromSnapshot(
    SchoolSyncSnapshot snapshot,
    LocalCachePayload currentPayload,
  ) {
    final currentUsername = currentPayload.profile?.username.trim();
    final nextUsername = snapshot.profile.username.trim();
    final isDifferentStudent =
        currentUsername != null &&
        currentUsername.isNotEmpty &&
        currentUsername != nextUsername;
    final personalEvents =
        isDifferentStudent
              ? <StudentEvent>[]
              : [...currentPayload.personalEvents]
          ..sort((a, b) => a.start.compareTo(b.start));

    final basePayload = LocalCachePayload(
      profile: snapshot.profile,
      grades: snapshot.grades,
      curriculumSubjects: snapshot.curriculumSubjects,
      curriculumRawItems: snapshot.curriculumRawItems,
      syncedEvents: [...snapshot.events]
        ..sort((a, b) => a.start.compareTo(b.start)),
      personalEvents: personalEvents,
      lastSyncedAt: snapshot.syncedAt,
    );

    if (isDifferentStudent) {
      return basePayload;
    }

    return mergeFetchedPayloadWithExistingData(
      fetchedPayload: basePayload,
      existingSyncedEvents: currentPayload.syncedEvents,
      existingPersonalEvents: currentPayload.personalEvents,
    );
  }

  LocalCachePayload mergeFetchedPayloadWithExistingData({
    required LocalCachePayload fetchedPayload,
    required List<StudentEvent> existingSyncedEvents,
    required List<StudentEvent> existingPersonalEvents,
  }) {
    final remainingExisting = [...existingSyncedEvents];
    final incomingSeriesKeys = fetchedPayload.syncedEvents
        .map(_eventSeriesKey)
        .toSet();
    final incomingCourseKeys = fetchedPayload.syncedEvents
        .map(_eventCourseKey)
        .toSet();

    final mergedSyncedEvents = <StudentEvent>[];
    for (final incoming in fetchedPayload.syncedEvents) {
      final existing =
          _takeFirstMatch(
            remainingExisting,
            (event) => _eventSignature(event) == _eventSignature(incoming),
          ) ??
          _takeBestSeriesMatch(remainingExisting, incoming);
      mergedSyncedEvents.add(_mergeIncomingSyncedEvent(incoming, existing));
    }

    final archivedEvents = <StudentEvent>[];
    final preservedExistingSyncedEvents = <StudentEvent>[];
    for (final existing in remainingExisting) {
      final courseKey = _eventCourseKey(existing);
      final seriesKey = _eventSeriesKey(existing);
      if (incomingCourseKeys.contains(courseKey) &&
          !incomingSeriesKeys.contains(seriesKey)) {
        archivedEvents.add(_archiveRemovedSyncedEvent(existing));
      } else {
        preservedExistingSyncedEvents.add(existing);
      }
    }

    final mergedPersonalEvents = _mergePersonalEvents([
      ...existingPersonalEvents,
      ...archivedEvents,
    ]);

    return fetchedPayload.copyWith(
      syncedEvents: [...mergedSyncedEvents, ...preservedExistingSyncedEvents]
        ..sort((a, b) => a.start.compareTo(b.start)),
      personalEvents: mergedPersonalEvents,
    );
  }

  DateTime _normalizedDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  StudentEvent _mergeIncomingSyncedEvent(
    StudentEvent incoming,
    StudentEvent? existing,
  ) {
    if (existing == null) {
      return incoming;
    }

    final preservedNote = _preservedUserNote(
      existing: existing,
      incomingSourceNote: incoming.sourceNote,
    );

    return incoming.copyWith(
      note: preservedNote,
      attachments: existing.attachments,
    );
  }

  String? _preservedUserNote({
    required StudentEvent existing,
    required String? incomingSourceNote,
  }) {
    final note = existing.note?.trim();
    if (note == null || note.isEmpty) {
      return null;
    }

    final normalizedIncomingSource = incomingSourceNote?.trim();
    if (normalizedIncomingSource != null &&
        normalizedIncomingSource.isNotEmpty &&
        normalizedIncomingSource == note) {
      return null;
    }

    return note;
  }

  StudentEvent _archiveRemovedSyncedEvent(StudentEvent event) {
    final archivedDetails = <String>[
      'Mục này được giữ lại từ ${event.type == StudentEventType.exam ? 'lịch thi' : 'lịch học'} cũ để tránh mất dữ liệu khi đồng bộ.',
      'Thời gian cũ: ${_formatDateTime(event.start)} - ${_formatTime(event.end)}',
      if ((event.location ?? '').trim().isNotEmpty)
        'Địa điểm cũ: ${event.location!.trim()}',
      if ((event.referenceCode ?? '').trim().isNotEmpty)
        'Mã/SBD cũ: ${event.referenceCode!.trim()}',
      if ((event.sourceNote ?? '').trim().isNotEmpty)
        'Thông tin đồng bộ cũ: ${event.sourceNote!.trim()}',
      if ((event.note ?? '').trim().isNotEmpty)
        'Ghi chú: ${event.note!.trim()}',
    ];

    return StudentEvent(
      id: 'archived-${event.id}-${event.start.microsecondsSinceEpoch}',
      title: '[Lịch cũ] ${event.title}',
      subtitle: event.type == StudentEventType.exam
          ? 'Lịch thi cũ'
          : 'Lịch học cũ',
      start: event.start,
      end: event.end,
      type: StudentEventType.personalTask,
      color: const Color(0xFFFFF1C2),
      note: archivedDetails.join('\n'),
      attachments: event.attachments,
      referenceCode: event.referenceCode,
    );
  }

  List<StudentEvent> _mergePersonalEvents(List<StudentEvent> events) {
    final merged = <String, StudentEvent>{};
    for (final event in events) {
      merged[event.id] = event;
    }
    return merged.values.toList()..sort((a, b) => a.start.compareTo(b.start));
  }

  String _eventSignature(StudentEvent event) {
    return [
      event.type.name,
      event.title.trim(),
      event.start.toIso8601String(),
      event.end.toIso8601String(),
      event.location?.trim() ?? '',
      event.referenceCode?.trim() ?? '',
    ].join('|');
  }

  String _eventCourseKey(StudentEvent event) {
    return [
      event.type.name,
      event.title.trim().toLowerCase(),
      event.referenceCode?.trim().toLowerCase() ?? '',
      event.subtitle?.trim().toLowerCase() ?? '',
    ].join('|');
  }

  String _eventSeriesKey(StudentEvent event) {
    return [
      _eventCourseKey(event),
      event.start.weekday.toString(),
      _formatTime(event.start),
      _formatTime(event.end),
      event.location?.trim().toLowerCase() ?? '',
    ].join('|');
  }

  StudentEvent? _takeFirstMatch(
    List<StudentEvent> events,
    bool Function(StudentEvent event) predicate,
  ) {
    for (var index = 0; index < events.length; index++) {
      final event = events[index];
      if (!predicate(event)) {
        continue;
      }
      events.removeAt(index);
      return event;
    }
    return null;
  }

  StudentEvent? _takeBestSeriesMatch(
    List<StudentEvent> events,
    StudentEvent incoming,
  ) {
    final targetSeriesKey = _eventSeriesKey(incoming);
    const maxSeriesShift = Duration(days: 2);
    var bestIndex = -1;
    Duration? bestGap;

    for (var index = 0; index < events.length; index++) {
      final existing = events[index];
      if (_eventSeriesKey(existing) != targetSeriesKey) {
        continue;
      }

      final gap = existing.start.difference(incoming.start).abs();
      if (gap > maxSeriesShift) {
        continue;
      }
      if (bestGap == null || gap < bestGap) {
        bestGap = gap;
        bestIndex = index;
      }
    }

    if (bestIndex == -1) {
      return null;
    }

    final match = events[bestIndex];
    events.removeAt(bestIndex);
    return match;
  }

  String _formatDateTime(DateTime value) {
    return '${value.day}/${value.month}/${value.year} ${_formatTime(value)}';
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
