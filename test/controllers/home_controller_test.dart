import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinhvien_app/controllers/account_auth_controller.dart';
import 'package:sinhvien_app/controllers/home_controller.dart';
import 'package:sinhvien_app/controllers/home_flow_models.dart';
import 'package:sinhvien_app/models/event_attachment.dart';
import 'package:sinhvien_app/models/local_cache_payload.dart';
import 'package:sinhvien_app/models/school_sync_snapshot.dart';
import 'package:sinhvien_app/models/student_event.dart';
import 'package:sinhvien_app/models/student_profile.dart';
import 'package:sinhvien_app/models/weather_forecast.dart';
import 'package:sinhvien_app/services/attachment_storage_service.dart';
import 'package:sinhvien_app/services/auth_service.dart';
import 'package:sinhvien_app/services/cloud_sync_service.dart';
import 'package:sinhvien_app/services/dashboard_persistence_service.dart';
import 'package:sinhvien_app/services/device_effects_service.dart';
import 'package:sinhvien_app/services/event_mutation_service.dart';
import 'package:sinhvien_app/services/local_cache_service.dart';
import 'package:sinhvien_app/services/school_api_service.dart';
import 'package:sinhvien_app/services/school_sync_coordinator.dart';
import 'package:sinhvien_app/services/weather_service.dart';
import 'package:sinhvien_app/services/widget_sync_service.dart';

void main() {
  testWidgets(
    'HomeController exposes weather presentation for the selected day',
    (WidgetTester tester) async {
      final controller = _buildController();

      controller.initialize();
      await tester.pump();

      final weather = controller.selectedDayWeather;

      expect(weather, isNotNull);
      expect(weather!.description, 'Troi quang');
      expect(weather.temperatureRangeLabel, '24° - 31°');
      expect(weather.precipitationLabel, 'Mua 20%');
      expect(weather.suggestions, isNotEmpty);

      controller.dispose();
    },
  );

  testWidgets('syncSchoolData clears personal events for another student', (
    WidgetTester tester,
  ) async {
    final localCacheService = _MemoryLocalCacheService(
      initialPayload: LocalCachePayload(
        profile: const StudentProfile(
          username: 'old-user',
          displayName: 'Old User',
        ),
        personalEvents: [_personalTask(id: 'task-1')],
      ),
    );
    final controller = _buildController(
      localCacheService: localCacheService,
      schoolApiService: _FakeSchoolApiService(
        snapshot: SchoolSyncSnapshot(
          profile: const StudentProfile(
            username: 'new-user',
            displayName: 'New User',
          ),
          grades: const [],
          curriculumSubjects: const [],
          curriculumRawItems: const [],
          events: [
            StudentEvent(
              id: 'exam-1',
              title: 'Thi giua ky',
              start: DateTime(2026, 4, 10, 7, 0),
              end: DateTime(2026, 4, 10, 9, 0),
              type: StudentEventType.exam,
              color: const Color(0xFFFFDAD6),
            ),
          ],
          syncedAt: DateTime(2026, 4, 10, 9, 0),
        ),
      ),
    );

    controller.initialize();
    await tester.pump();

    final result = await controller.syncSchoolData(
      const CredentialsResult(username: 'new-user', password: 'secret'),
    );
    await tester.pump();

    expect(result.isSuccess, isTrue);
    expect(controller.payload.profile?.username, 'new-user');
    expect(controller.payload.personalEvents, isEmpty);
    expect(controller.payload.syncedEvents, hasLength(1));
    expect(controller.selectedDate, DateTime(2026, 4, 10));
    expect(localCacheService.savedPayloads, isNotEmpty);

    controller.dispose();
  });

  testWidgets('toggleDone persists updated personal task state', (
    WidgetTester tester,
  ) async {
    final localCacheService = _MemoryLocalCacheService(
      initialPayload: LocalCachePayload(
        profile: const StudentProfile(
          username: 'user-1',
          displayName: 'Student',
        ),
        personalEvents: [_personalTask(id: 'task-1', isDone: false)],
      ),
    );
    final controller = _buildController(localCacheService: localCacheService);

    controller.initialize();
    await tester.pump();
    await controller.toggleDone('task-1');

    expect(controller.payload.personalEvents.single.isDone, isTrue);
    expect(
      localCacheService.lastSavedPayload?.personalEvents.single.isDone,
      isTrue,
    );

    controller.dispose();
  });

  testWidgets('deletePersonalEvent ignores synced events', (
    WidgetTester tester,
  ) async {
    final syncedExam = StudentEvent(
      id: 'exam-1',
      title: 'Thi cuoi ky',
      start: DateTime(2026, 4, 12, 7, 0),
      end: DateTime(2026, 4, 12, 9, 0),
      type: StudentEventType.exam,
      color: const Color(0xFFFFDAD6),
    );
    final localCacheService = _MemoryLocalCacheService(
      initialPayload: LocalCachePayload(
        profile: const StudentProfile(
          username: 'user-1',
          displayName: 'Student',
        ),
        syncedEvents: [syncedExam],
        personalEvents: [_personalTask(id: 'task-1')],
      ),
    );
    final controller = _buildController(localCacheService: localCacheService);

    controller.initialize();
    await tester.pump();
    await controller.deletePersonalEvent(syncedExam);

    expect(controller.payload.syncedEvents, [syncedExam]);
    expect(controller.payload.personalEvents, hasLength(1));
    expect(localCacheService.savedPayloads, isEmpty);

    controller.dispose();
  });

  testWidgets('auth restore prefers newer remote payload', (
    WidgetTester tester,
  ) async {
    final localPayload = LocalCachePayload(
      profile: const StudentProfile(
        username: 'local-user',
        displayName: 'Local User',
      ),
      syncedEvents: [
        StudentEvent(
          id: 'local-event',
          title: 'Local',
          start: DateTime(2026, 4, 2, 8, 0),
          end: DateTime(2026, 4, 2, 10, 0),
          type: StudentEventType.classSchedule,
          color: const Color(0xFFDDE7FF),
        ),
      ],
      lastSyncedAt: DateTime(2026, 4, 2, 8, 0),
    );
    final remotePayload = LocalCachePayload(
      profile: const StudentProfile(
        username: 'remote-user',
        displayName: 'Remote User',
      ),
      syncedEvents: [
        StudentEvent(
          id: 'remote-event',
          title: 'Remote',
          start: DateTime(2026, 4, 5, 8, 0),
          end: DateTime(2026, 4, 5, 10, 0),
          type: StudentEventType.classSchedule,
          color: const Color(0xFFDDE7FF),
        ),
      ],
      lastSyncedAt: DateTime(2026, 4, 5, 8, 0),
    );
    final localCacheService = _MemoryLocalCacheService(
      initialPayload: localPayload,
    );
    final cloudSyncService = _FakeCloudSyncService(
      remotePayload: remotePayload,
    );
    final controller = _buildController(
      accountAuthController: AccountAuthController(
        authService: _StreamAuthService(
          currentUser: _FakeUser(),
          authStates: Stream<User?>.value(_FakeUser()),
        ),
      ),
      localCacheService: localCacheService,
      cloudSyncService: cloudSyncService,
    );

    controller.initialize();
    await tester.pump();
    await tester.pump();

    expect(controller.payload.profile?.username, 'remote-user');
    expect(controller.selectedDate, DateTime(2026, 4, 5));
    expect(
      localCacheService.lastSavedPayload?.profile?.username,
      'remote-user',
    );

    controller.dispose();
  });

  testWidgets('auth restore keeps local payload when cloud fetch fails', (
    WidgetTester tester,
  ) async {
    final localPayload = LocalCachePayload(
      profile: const StudentProfile(
        username: 'local-user',
        displayName: 'Local User',
      ),
      personalEvents: [_personalTask(id: 'task-1')],
      lastSyncedAt: DateTime(2026, 4, 2, 8, 0),
    );
    final controller = _buildController(
      accountAuthController: AccountAuthController(
        authService: _StreamAuthService(
          currentUser: _FakeUser(),
          authStates: Stream<User?>.value(_FakeUser()),
        ),
      ),
      localCacheService: _MemoryLocalCacheService(initialPayload: localPayload),
      cloudSyncService: _FakeCloudSyncService(throwOnFetch: true),
    );

    controller.initialize();
    await tester.pump();
    await tester.pump();

    expect(controller.payload.profile?.username, 'local-user');
    expect(controller.payload.personalEvents, hasLength(1));

    controller.dispose();
  });
}

HomeController _buildController({
  AccountAuthController? accountAuthController,
  LocalCacheService? localCacheService,
  SchoolApiService? schoolApiService,
  CloudSyncService? cloudSyncService,
  AttachmentStorageService? attachmentStorageService,
  DeviceEffectsService? deviceEffectsService,
  WeatherService? weatherService,
}) {
  final resolvedCloudSyncService = cloudSyncService ?? _FakeCloudSyncService();
  final resolvedLocalCacheService =
      localCacheService ?? _MemoryLocalCacheService();
  final resolvedDeviceEffectsService =
      deviceEffectsService ?? _FakeDeviceEffectsService();
  final dashboardPersistenceService = DashboardPersistenceService(
    localCacheService: resolvedLocalCacheService,
    cloudSyncService: resolvedCloudSyncService,
    deviceEffectsService: resolvedDeviceEffectsService,
  );

  return HomeController(
    accountAuthController:
        accountAuthController ??
        AccountAuthController(authService: _FakeAuthService()),
    schoolSyncCoordinator: SchoolSyncCoordinator(
      schoolApiService: schoolApiService ?? _FakeSchoolApiService(),
    ),
    dashboardPersistenceService: dashboardPersistenceService,
    eventMutationService: EventMutationService(
      attachmentStorageService:
          attachmentStorageService ?? _FakeAttachmentStorageService(),
      cloudSyncService: resolvedCloudSyncService,
      dashboardPersistenceService: dashboardPersistenceService,
    ),
    weatherService: weatherService ?? _FixedWeatherService(),
  );
}

StudentEvent _personalTask({required String id, bool isDone = false}) {
  return StudentEvent(
    id: id,
    title: 'On bai',
    start: DateTime(2026, 4, 3, 8, 0),
    end: DateTime(2026, 4, 3, 9, 0),
    type: StudentEventType.personalTask,
    color: const Color(0xFFDDF4E4),
    isDone: isDone,
  );
}

class _FakeAuthService extends AuthService {
  @override
  bool get isAvailable => false;

  @override
  User? get currentUser => null;

  @override
  Stream<User?> authStateChanges() => const Stream<User?>.empty();
}

class _StreamAuthService extends AuthService {
  _StreamAuthService({required this.currentUser, required this.authStates});

  @override
  final User? currentUser;

  final Stream<User?> authStates;

  @override
  bool get isAvailable => true;

  @override
  Stream<User?> authStateChanges() => authStates;
}

class _FakeUser extends Fake implements User {}

class _MemoryLocalCacheService extends LocalCacheService {
  _MemoryLocalCacheService({LocalCachePayload? initialPayload})
    : _payload = initialPayload;

  LocalCachePayload? _payload;
  final List<LocalCachePayload> savedPayloads = [];

  LocalCachePayload? get lastSavedPayload =>
      savedPayloads.isEmpty ? null : savedPayloads.last;

  @override
  Future<LocalCachePayload?> load() async => _payload;

  @override
  Future<void> save(LocalCachePayload payload) async {
    _payload = payload;
    savedPayloads.add(payload);
  }
}

class _FakeSchoolApiService extends SchoolApiService {
  _FakeSchoolApiService({SchoolSyncSnapshot? snapshot})
    : _snapshot =
          snapshot ??
          SchoolSyncSnapshot(
            profile: const StudentProfile(
              username: 'user-1',
              displayName: 'Student',
            ),
            grades: const [],
            curriculumSubjects: const [],
            curriculumRawItems: const [],
            events: const [],
            syncedAt: DateTime(2026, 4, 2, 8, 0),
          );

  final SchoolSyncSnapshot _snapshot;

  @override
  Future<SchoolSyncSnapshot> sync({
    required String username,
    required String password,
  }) async {
    return _snapshot;
  }
}

class _FakeAttachmentStorageService extends AttachmentStorageService {
  @override
  Future<List<StudentEvent>> persistEvents(List<StudentEvent> events) async {
    return events;
  }

  @override
  Future<Uint8List?> readAttachmentBytes(EventAttachment attachment) async {
    return null;
  }
}

class _FakeCloudSyncService extends CloudSyncService {
  _FakeCloudSyncService({this.remotePayload, this.throwOnFetch = false});

  final LocalCachePayload? remotePayload;
  final bool throwOnFetch;

  @override
  Future<LocalCachePayload?> fetchSyncCache({
    String snapshotKey = 'dashboard',
  }) async {
    if (throwOnFetch) throw Exception('cloud fetch failed');
    return remotePayload;
  }

  @override
  Future<void> upsertNote(StudentEvent event) async {}

  @override
  Future<void> upsertTask(StudentEvent event) async {}

  @override
  Future<void> saveSyncCache(LocalCachePayload payload) async {}

  @override
  Future<EventAttachment> uploadAttachment({
    required EventAttachment attachment,
    required String eventId,
  }) async {
    if (attachment.remoteKey != null) return attachment;
    return attachment.copyWith(remoteKey: 'remote/$eventId/${attachment.id}');
  }
}

class _FakeDeviceEffectsService extends DeviceEffectsService {
  _FakeDeviceEffectsService()
    : super(
        widgetSyncService: _FakeWidgetSyncService(),
        rescheduleNotifications: (_) async {},
      );

  final List<LocalCachePayload> refreshedPayloads = [];

  @override
  Future<void> refreshDeviceState(LocalCachePayload payload) async {
    refreshedPayloads.add(payload);
  }
}

class _FakeWidgetSyncService extends WidgetSyncService {
  @override
  Future<void> updateTodayWidget({
    required StudentProfile? profile,
    required List<StudentEvent> events,
  }) async {}
}

class _FixedWeatherService extends WeatherService {
  @override
  Future<WeatherForecast> fetchForecast() async {
    final now = DateTime.now();
    return WeatherForecast(
      locationLabel: 'Ha Noi',
      days: [
        WeatherDayForecast(
          date: DateTime(now.year, now.month, now.day),
          weatherCode: 0,
          temperatureMin: 24,
          temperatureMax: 31,
          precipitationProbabilityMax: 20,
          windSpeedMax: 12,
        ),
      ],
      fetchedAt: now,
    );
  }

  @override
  String descriptionForCode(int code) => 'Troi quang';

  @override
  List<String> suggestionsForDay(WeatherDayForecast forecast) {
    return const ['Thoi tiet on, co the di hoc binh thuong.'];
  }
}
