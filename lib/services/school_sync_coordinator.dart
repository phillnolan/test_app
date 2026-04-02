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
    final syncedEvents = [...snapshot.events]
      ..sort((a, b) => a.start.compareTo(b.start));
    final personalEvents =
        isDifferentStudent
              ? <StudentEvent>[]
              : [...currentPayload.personalEvents]
          ..sort((a, b) => a.start.compareTo(b.start));

    return LocalCachePayload(
      profile: snapshot.profile,
      grades: snapshot.grades,
      curriculumSubjects: snapshot.curriculumSubjects,
      curriculumRawItems: snapshot.curriculumRawItems,
      syncedEvents: syncedEvents,
      personalEvents: personalEvents,
      lastSyncedAt: snapshot.syncedAt,
    );
  }

  DateTime _normalizedDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
