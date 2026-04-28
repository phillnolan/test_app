import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sinhvien_app/features/auth/data/auth_service.dart';
import 'package:sinhvien_app/features/auth/ui/account_auth_controller.dart';
import 'package:sinhvien_app/features/home/ui/home_controller.dart';
import 'package:sinhvien_app/features/home/domain/home_flow_models.dart';
import 'package:sinhvien_app/features/weather/data/weather_forecast.dart';
import 'package:sinhvien_app/features/weather/data/weather_service.dart';
import 'package:sinhvien_app/features/sync/data/cloud_sync_service.dart';
import 'package:sinhvien_app/features/sync/data/local_cache_service.dart';
import 'package:sinhvien_app/features/sync/data/school_api_service.dart';
import 'package:sinhvien_app/models/event_attachment.dart';
import 'package:sinhvien_app/models/local_cache_payload.dart';
import 'package:sinhvien_app/models/school_sync_snapshot.dart';
import 'package:sinhvien_app/models/student_event.dart';
import 'package:sinhvien_app/models/student_profile.dart';
import 'package:sinhvien_app/features/attachments/data/attachment_storage_service.dart';
import 'package:sinhvien_app/features/widget/data/widget_sync_service.dart';
import 'package:sinhvien_app/features/home/ui/home_shell.dart';

void main() {
  testWidgets('home shell renders tabs with injected controller', (
    WidgetTester tester,
  ) async {
    final controller = _buildController();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [homeControllerProvider.overrideWith(() => controller)],
        child: const MaterialApp(home: HomeShell()),
      ),
    );
    await tester.pump();

    expect(find.text('Lịch'), findsOneWidget);
    expect(find.text('Điểm'), findsOneWidget);
    expect(find.text('Học phí'), findsOneWidget);
    expect(find.text('Tài khoản'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('home shell lets the view own date selection wiring', (
    WidgetTester tester,
  ) async {
    final controller = _buildController();
    final tomorrow = controller.dateForIndex(HomeController.pastDayRange + 1);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [homeControllerProvider.overrideWith(() => controller)],
        child: const MaterialApp(home: HomeShell()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('${tomorrow.day}').first);
    await tester.pumpAndSettle();

    expect(
      controller.selectedDate,
      DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'syncSchoolData clears personal events when syncing another student',
    (WidgetTester tester) async {
      final personalTask = _personalTask(id: 'task-1');
      final localCache = FakeLocalCacheService(
        payload: LocalCachePayload(
          profile: const StudentProfile(
            username: 'old-user',
            displayName: 'Old User',
          ),
          personalEvents: [personalTask],
        ),
      );
      var controller = _buildController(
        localCacheService: localCache,
        schoolApiService: FakeSchoolApiService(
          snapshot: SchoolSyncSnapshot(
            profile: const StudentProfile(
              username: 'new-user',
              displayName: 'New User',
            ),
            currentTuition: null,
            grades: const [],
            curriculumSubjects: const [],
            curriculumRawItems: const [],
            events: [
              StudentEvent(
                id: 'exam-1',
                title: 'Giữa kỳ',
                start: DateTime(2026, 4, 10, 7, 0),
                end: DateTime(2026, 4, 10, 9, 0),
                type: StudentEventType.exam,
                color: const Color(0xFFFFDAD6),
              ),
            ],
            syncedAt: DateTime(2026, 4, 2, 10, 0),
          ),
        ),
      );

      controller = _attachController(controller);
      controller.initialize();
      await tester.pump();

      final result = await controller.syncSchoolData(
        const CredentialsResult(username: 'new-user', password: 'secret'),
      );

      expect(result.isSuccess, isFalse);
      expect(
        result.message,
        'Cần xác nhận liên kết tài khoản trước khi đồng bộ.',
      );
      expect(controller.payload.profile?.username, 'old-user');
      expect(controller.payload.personalEvents, hasLength(1));
      expect(controller.payload.syncedEvents, isEmpty);
      expect(controller.currentTab, 2);
      expect(localCache.savedPayloads, isEmpty);

      controller.disposeForTesting();
    },
  );

  testWidgets('deletePersonalEvent ignores non-personal events', (
    WidgetTester tester,
  ) async {
    final syncedExam = StudentEvent(
      id: 'exam-1',
      title: 'Thi cuối kỳ',
      start: DateTime(2026, 4, 12, 7, 0),
      end: DateTime(2026, 4, 12, 9, 0),
      type: StudentEventType.exam,
      color: const Color(0xFFFFDAD6),
    );
    final personalTask = _personalTask(id: 'task-1');
    var controller = _buildController(
      localCacheService: FakeLocalCacheService(
        payload: LocalCachePayload(
          profile: const StudentProfile(
            username: 'user-1',
            displayName: 'Student',
          ),
          syncedEvents: [syncedExam],
          personalEvents: [personalTask],
        ),
      ),
    );

    controller = _attachController(controller);
    controller.initialize();
    await tester.pump();
    await controller.deletePersonalEvent(syncedExam);

    expect(controller.payload.syncedEvents, [syncedExam]);
    expect(controller.payload.personalEvents, [personalTask]);

    controller.disposeForTesting();
  });

  test('account auth controller returns typed failure result', () async {
    final controller = AccountAuthController(
      authService: FakeAuthService(
        available: true,
        emailError: FirebaseAuthException(
          code: 'wrong-password',
          message: 'Sai mật khẩu.',
        ),
      ),
    );

    final result = await controller.submitEmailAuth(
      const EmailAuthResult(
        mode: EmailAuthMode.signIn,
        email: 'student@example.com',
        password: 'bad-pass',
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.message, 'Sai mật khẩu.');
  });

  test('account auth controller returns sign in success message', () async {
    final controller = AccountAuthController(
      authService: FakeAuthService(available: true),
    );

    final result = await controller.submitEmailAuth(
      const EmailAuthResult(
        mode: EmailAuthMode.signIn,
        email: 'student@example.com',
        password: 'secret-pass',
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(result.message, 'Đăng nhập tài khoản thành công.');
  });

  test('account auth controller returns sign up success message', () async {
    final controller = AccountAuthController(
      authService: FakeAuthService(available: true),
    );

    final result = await controller.submitEmailAuth(
      const EmailAuthResult(
        mode: EmailAuthMode.register,
        email: 'student@example.com',
        password: 'secret-pass',
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(result.message, 'Đăng ký tài khoản thành công.');
  });
}

HomeController _buildController({
  FakeLocalCacheService? localCacheService,
  FakeSchoolApiService? schoolApiService,
}) {
  return HomeController(
    schoolApiService: schoolApiService ?? FakeSchoolApiService(),
    localCacheService: localCacheService ?? FakeLocalCacheService(),
    attachmentStorageService: FakeAttachmentStorageService(),
    cloudSyncService: FakeCloudSyncService(),
    weatherService: FakeWeatherService(),
    widgetSyncService: FakeWidgetSyncService(),
  );
}

HomeController _attachController(HomeController controller) {
  final container = ProviderContainer(
    overrides: [homeControllerProvider.overrideWith(() => controller)],
  );
  final subscription = container.listen<HomeState>(
    homeControllerProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(container.dispose);
  addTearDown(subscription.close);
  return container.read(homeControllerProvider.notifier);
}

StudentEvent _personalTask({required String id}) {
  return StudentEvent(
    id: id,
    title: 'Ôn bài',
    start: DateTime(2026, 4, 3, 8, 0),
    end: DateTime(2026, 4, 3, 9, 0),
    type: StudentEventType.personalTask,
    color: const Color(0xFFDDF4E4),
  );
}

class FakeAuthService extends AuthService {
  FakeAuthService({this.available = false, this.emailError, this.googleError});

  final bool available;
  final FirebaseAuthException? emailError;
  final FirebaseAuthException? googleError;

  @override
  bool get isAvailable => available;

  @override
  User? get currentUser => null;

  @override
  Stream<User?> authStateChanges() => const Stream<User?>.empty();

  @override
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (emailError != null) throw emailError!;
    return FakeUserCredential();
  }

  @override
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    if (emailError != null) throw emailError!;
    return FakeUserCredential();
  }

  @override
  Future<UserCredential?> signInWithGoogle() async {
    if (googleError != null) throw googleError!;
    return FakeUserCredential();
  }

  @override
  Future<void> signOut() async {}
}

class FakeUserCredential extends Fake implements UserCredential {}

class FakeSchoolApiService extends SchoolApiService {
  FakeSchoolApiService({SchoolSyncSnapshot? snapshot})
    : _snapshot =
          snapshot ??
          SchoolSyncSnapshot(
            profile: const StudentProfile(
              username: 'user-1',
              displayName: 'Student',
            ),
            currentTuition: null,
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

class FakeLocalCacheService extends LocalCacheService {
  FakeLocalCacheService({this.payload});

  final LocalCachePayload? payload;
  final List<LocalCachePayload> savedPayloads = [];

  @override
  Future<LocalCachePayload?> load() async => payload;

  @override
  Future<void> save(LocalCachePayload payload) async {
    savedPayloads.add(payload);
  }
}

class FakeAttachmentStorageService extends AttachmentStorageService {
  @override
  Future<List<StudentEvent>> persistEvents(List<StudentEvent> events) async {
    return events;
  }

  @override
  Future<Uint8List?> readAttachmentBytes(EventAttachment attachment) async {
    return null;
  }

  @override
  Future<void> deleteUnusedAttachments({
    required List<StudentEvent> previousEvents,
    required List<StudentEvent> nextEvents,
  }) async {}
}

class FakeCloudSyncService extends CloudSyncService {
  @override
  Future<void> upsertNote(StudentEvent event) async {}

  @override
  Future<void> upsertTask(StudentEvent event) async {}

  @override
  Future<void> saveSyncCache(LocalCachePayload payload) async {}

  @override
  Future<LocalCachePayload?> fetchSyncCache({
    String snapshotKey = 'dashboard',
  }) async {
    return null;
  }

  @override
  Future<EventAttachment> uploadAttachment({
    required EventAttachment attachment,
    required String eventId,
  }) async {
    return attachment;
  }
}

class FakeWeatherService extends WeatherService {
  @override
  Future<WeatherForecast> fetchForecast() async {
    return WeatherForecast(
      locationLabel: 'Hà Nội',
      days: const [],
      fetchedAt: DateTime(2026, 4, 2, 8, 0),
    );
  }
}

class FakeWidgetSyncService extends WidgetSyncService {
  @override
  Future<void> updateTodayWidget({
    required StudentProfile? profile,
    required List<StudentEvent> events,
  }) async {}
}
