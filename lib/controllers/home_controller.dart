import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/event_attachment.dart';
import '../models/home_action_result.dart';
import '../models/local_cache_payload.dart';
import '../models/student_event.dart';
import '../models/student_sync_credentials.dart';
import '../models/weather_forecast.dart';
import '../models/weather_presentation.dart';
import '../services/attachment_storage_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/dashboard_persistence_service.dart';
import '../services/device_effects_service.dart';
import '../services/event_mutation_service.dart';
import '../services/local_cache_service.dart';
import '../services/school_api_service.dart';
import '../services/school_sync_coordinator.dart';
import '../services/student_sync_credentials_service.dart';
import '../services/weather_service.dart';
import '../services/widget_sync_service.dart';
import '../utils/home_calendar_utils.dart';
import 'account_auth_controller.dart';
import 'home_flow_models.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    AccountAuthController? accountAuthController,
    SchoolApiService? schoolApiService,
    LocalCacheService? localCacheService,
    AttachmentStorageService? attachmentStorageService,
    CloudSyncService? cloudSyncService,
    WeatherService? weatherService,
    WidgetSyncService? widgetSyncService,
    DeviceEffectsService? deviceEffectsService,
    DashboardPersistenceService? dashboardPersistenceService,
    SchoolSyncCoordinator? schoolSyncCoordinator,
    EventMutationService? eventMutationService,
    StudentSyncCredentialsService? studentSyncCredentialsService,
  }) : _accountAuthController =
           accountAuthController ?? AccountAuthController(),
       _weatherService = weatherService ?? WeatherService() {
    final resolvedLocalCacheService = localCacheService ?? LocalCacheService();
    final resolvedCloudSyncService = cloudSyncService ?? CloudSyncService();
    final resolvedWidgetSyncService = widgetSyncService ?? WidgetSyncService();
    final resolvedDeviceEffectsService =
        deviceEffectsService ??
        DeviceEffectsService(widgetSyncService: resolvedWidgetSyncService);
    final resolvedAttachmentStorageService =
        attachmentStorageService ?? AttachmentStorageService();
    final resolvedDashboardPersistenceService =
        dashboardPersistenceService ??
        DashboardPersistenceService(
          localCacheService: resolvedLocalCacheService,
          cloudSyncService: resolvedCloudSyncService,
          deviceEffectsService: resolvedDeviceEffectsService,
        );

    _attachmentStorageService = resolvedAttachmentStorageService;
    _dashboardPersistenceService = resolvedDashboardPersistenceService;
    _schoolSyncCoordinator =
        schoolSyncCoordinator ??
        SchoolSyncCoordinator(
          schoolApiService: schoolApiService ?? SchoolApiService(),
        );
    _studentSyncCredentialsService =
        studentSyncCredentialsService ?? StudentSyncCredentialsService();
    _eventMutationService =
        eventMutationService ??
        EventMutationService(
          attachmentStorageService: resolvedAttachmentStorageService,
          cloudSyncService: resolvedCloudSyncService,
          dashboardPersistenceService: resolvedDashboardPersistenceService,
        );

    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _selectedDate = _today;
  }

  static const int pastDayRange = 365;
  static const int futureDayRange = 365;

  final AccountAuthController _accountAuthController;
  final WeatherService _weatherService;
  late final AttachmentStorageService _attachmentStorageService;
  late final DashboardPersistenceService _dashboardPersistenceService;
  late final SchoolSyncCoordinator _schoolSyncCoordinator;
  late final EventMutationService _eventMutationService;
  late final StudentSyncCredentialsService _studentSyncCredentialsService;

  late final DateTime _today;
  late DateTime _selectedDate;

  LocalCachePayload _payload = const LocalCachePayload();
  WeatherForecast? _weatherForecast;

  bool _isSyncing = false;
  bool _isLoadingLocalCache = true;
  bool _isLoadingWeather = true;
  bool _isLinkingStudent = false;
  bool _isRestoringCloudData = false;
  bool _isSigningOut = false;
  bool _showCloudRestoreWarning = false;
  bool _showSyncReminder = true;
  int _currentTab = 0;
  User? _signedInUser;
  String? _linkedStudentUsername;
  StudentSyncCredentials? _savedSyncCredentials;
  int _localMutationVersion = 0;
  final Map<String, _PendingEventSyncEntry> _pendingEventSyncs = {};

  Timer? _syncReminderTimer;
  StreamSubscription<User?>? _authSubscription;
  Future<void>? _initialCloudRestoreFuture;
  int _cloudRestoreGeneration = 0;
  bool _isDisposed = false;

  DateTime get today => _today;
  DateTime get selectedDate => _selectedDate;
  LocalCachePayload get payload => _payload;
  WeatherForecast? get weatherForecast => _weatherForecast;
  WeatherPresentation? get selectedDayWeather {
    final forecast = _weatherForecast?.dayForDate(_selectedDate);
    if (forecast == null) return null;

    return WeatherPresentation(
      locationLabel: _weatherForecast?.locationLabel ?? 'Ha Noi',
      icon: _weatherService.iconForCode(forecast.weatherCode),
      description: _weatherService.descriptionForCode(forecast.weatherCode),
      temperatureMin: forecast.temperatureMin.round(),
      temperatureMax: forecast.temperatureMax.round(),
      precipitationProbabilityMax: forecast.precipitationProbabilityMax,
      temperatureRangeLabel:
          '${forecast.temperatureMin.round()}° - ${forecast.temperatureMax.round()}°',
      precipitationLabel: 'Mưa ${forecast.precipitationProbabilityMax}%',
      suggestions: _weatherService.suggestionsForDay(forecast).take(2).toList(),
    );
  }

  bool get isSyncing => _isSyncing;
  bool get isLoadingLocalCache => _isLoadingLocalCache;
  bool get isLoadingWeather => _isLoadingWeather;
  bool get isLinkingStudent => _isLinkingStudent;
  bool get isRestoringCloudData => _isRestoringCloudData;
  bool get isSigningOut => _isSigningOut;
  bool get showCloudRestoreWarning => _showCloudRestoreWarning;
  bool get showSyncReminder => _showSyncReminder;
  int get currentTab => _currentTab;
  User? get signedInUser => _signedInUser;
  bool get isAuthAvailable => _accountAuthController.isAvailable;
  String? get linkedStudentUsername => _linkedStudentUsername;
  StudentSyncCredentials? get savedSyncCredentials => _savedSyncCredentials;
  bool get hasSavedSyncCredentials => _savedSyncCredentials != null;
  bool get canQuickSyncCurrentStudent {
    final profileUsername = _studentUsernameForPayload(_payload);
    final savedUsername = _savedSyncCredentials?.linkedStudentUsername;
    return _sameStudent(profileUsername, savedUsername);
  }

  List<StudentEvent> get allEvents {
    final merged = <String, StudentEvent>{};
    for (final event in [
      ..._payload.syncedEvents,
      ..._payload.personalEvents,
    ]) {
      merged[event.id] = event;
    }
    for (final entry in _pendingEventSyncs.values) {
      if (!entry.isDeleting) {
        continue;
      }
      merged.putIfAbsent(entry.event.id, () => entry.event);
    }

    final events = merged.values.toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return events;
  }

  bool isEventCloudSyncPending(String eventId) {
    return _pendingEventSyncs.containsKey(eventId);
  }

  bool isEventCloudDeletePending(String eventId) {
    return _pendingEventSyncs[eventId]?.isDeleting ?? false;
  }

  bool isEventCloudSyncDeferred(String eventId) {
    return _pendingEventSyncs[eventId]?.isDeferred ?? false;
  }

  void dismissCloudRestoreWarning() {
    if (!_showCloudRestoreWarning) {
      return;
    }

    _showCloudRestoreWarning = false;
    notifyListeners();
  }

  void initialize() {
    _syncReminderTimer = Timer(const Duration(seconds: 5), () {
      if (_isDisposed) return;
      _showSyncReminder = false;
      notifyListeners();
    });

    unawaited(_loadLocalCache());
    unawaited(_loadSavedSyncCredentials());
    unawaited(reloadWeather());

    if (_accountAuthController.isAvailable) {
      _updateSignedInUser(_accountAuthController.currentUser);
      _authSubscription = _accountAuthController.listenAuthState((user) {
        if (_isDisposed) return;
        _updateSignedInUser(user);
        notifyListeners();
      });

      if (_signedInUser != null) {
        _startInitialCloudRestore();
      }
    }
  }

  void setCurrentTab(int index) {
    _currentTab = index;
    notifyListeners();
  }

  void hideSyncReminder() {
    _showSyncReminder = false;
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = _normalizedDate(date);
    notifyListeners();
  }

  DateTime dateForIndex(int index) {
    return HomeCalendarUtils.dateForIndex(
      today: _today,
      pastDayRange: pastDayRange,
      index: index,
    );
  }

  List<Color> indicatorsForDate(DateTime date) {
    return HomeCalendarUtils.indicatorColors(
      HomeCalendarUtils.eventsForDay(allEvents, date),
    );
  }

  Future<void> reloadWeather() async {
    _isLoadingWeather = true;
    notifyListeners();

    try {
      _weatherForecast = await _weatherService.fetchForecast();
    } on WeatherException {
      _weatherForecast = null;
    } catch (_) {
      _weatherForecast = null;
    }

    if (_isDisposed) return;
    _isLoadingWeather = false;
    notifyListeners();
  }

  Future<AuthFlowResult> emailAuthAndResolve(EmailAuthResult result) async {
    final authResult = await _accountAuthController.submitEmailAuth(result);
    if (!authResult.isSuccess) {
      return AuthFlowResult.failure(authResult.message);
    }

    _updateSignedInUser(_accountAuthController.currentUser);
    if (!_isDisposed) {
      notifyListeners();
    }

    final session = _beginCloudRestoreSession();
    return _resolvePostSignIn(
      authSuccessMessage:
          authResult.message ?? 'Đăng nhập tài khoản thành công.',
      sessionGeneration: session.$1,
      sessionUserId: session.$2,
    );
  }

  Future<AuthFlowResult> googleAuthAndResolve() async {
    final authResult = await _accountAuthController.signInWithGoogle();
    if (!authResult.isSuccess) {
      return AuthFlowResult.failure(authResult.message);
    }

    _updateSignedInUser(_accountAuthController.currentUser);
    if (!_isDisposed) {
      notifyListeners();
    }

    final session = _beginCloudRestoreSession();
    return _resolvePostSignIn(
      authSuccessMessage: authResult.message ?? 'Đã đăng nhập Google.',
      sessionGeneration: session.$1,
      sessionUserId: session.$2,
    );
  }

  Future<HomeActionResult> completeLinkCurrentStudentAfterSignIn({
    required bool clearExistingCloudData,
  }) async {
    final currentStudent = _studentUsernameForPayload(_payload);
    if (_signedInUser == null) {
      return const HomeActionResult.failure(
        'Bạn cần đăng nhập tài khoản trước khi liên kết.',
      );
    }
    if (currentStudent == null) {
      return const HomeActionResult.failure(
        'Chưa có dữ liệu sinh viên trên thiết bị để liên kết.',
      );
    }

    _isLinkingStudent = true;
    if (!_isDisposed) {
      notifyListeners();
    }

    try {
      if (clearExistingCloudData) {
        await _dashboardPersistenceService.clearCloudAccountData();
      }

      await _persistAndApplyPayload(
        previousPayload: _payload,
        nextPayload: _payload,
        linkedStudentUsername: currentStudent,
      );

      return HomeActionResult.success(
        clearExistingCloudData
            ? 'Đã chuyển liên kết sang sinh viên $currentStudent.'
            : 'Đã liên kết tài khoản với sinh viên $currentStudent.',
      );
    } catch (_) {
      return const HomeActionResult.failure(
        'Không thể cập nhật liên kết tài khoản. Vui lòng thử lại.',
      );
    } finally {
      if (!_isDisposed) {
        _isLinkingStudent = false;
        notifyListeners();
      }
    }
  }

  Future<PreparedSyncPlan> prepareSchoolSync(
    CredentialsResult credentials,
  ) async {
    final syncResult = await _schoolSyncCoordinator.sync(
      username: credentials.username,
      password: credentials.password,
      currentPayload: _payload,
    );
    final incomingStudent = _studentUsernameForPayload(syncResult.payload);
    final currentLocalStudent = _studentUsernameForPayload(_payload);
    final requiresLocalReplacementConfirmation =
        currentLocalStudent != null &&
        !_sameStudent(currentLocalStudent, incomingStudent);

    if (_signedInUser == null) {
      return PreparedSyncPlan(
        payload: syncResult.payload,
        selectedDate: syncResult.selectedDate,
        requiresLocalReplacementConfirmation:
            requiresLocalReplacementConfirmation,
        currentLocalStudentUsername: requiresLocalReplacementConfirmation
            ? currentLocalStudent
            : null,
      );
    }

    final remotePayload = await _dashboardPersistenceService
        .fetchRemotePayload();
    final currentLinkedStudent = _studentUsernameForPayload(remotePayload);
    _linkedStudentUsername = currentLinkedStudent;

    var nextPayload = syncResult.payload;

    if (currentLinkedStudent == null) {
      return PreparedSyncPlan(
        payload: nextPayload,
        selectedDate: syncResult.selectedDate,
        decision: AccountLinkDecision(
          action: AccountLinkAction.linkStudent,
          targetStudentUsername: incomingStudent,
        ),
        requiresLocalReplacementConfirmation:
            requiresLocalReplacementConfirmation,
        currentLocalStudentUsername: requiresLocalReplacementConfirmation
            ? currentLocalStudent
            : null,
      );
    }

    if (_sameStudent(currentLinkedStudent, incomingStudent)) {
      nextPayload = _mergeSyncedPayloadWithExistingPersonalData(
        syncedPayload: nextPayload,
        localPayload: _payload,
        remotePayload: remotePayload ?? const LocalCachePayload(),
      );
      return PreparedSyncPlan(
        payload: nextPayload,
        selectedDate: syncResult.selectedDate,
        requiresLocalReplacementConfirmation:
            requiresLocalReplacementConfirmation,
        currentLocalStudentUsername: requiresLocalReplacementConfirmation
            ? currentLocalStudent
            : null,
      );
    }

    return PreparedSyncPlan(
      payload: nextPayload,
      selectedDate: syncResult.selectedDate,
      decision: AccountLinkDecision(
        action: AccountLinkAction.relinkStudent,
        currentLinkedStudentUsername: currentLinkedStudent,
        targetStudentUsername: incomingStudent,
      ),
      requiresLocalReplacementConfirmation:
          requiresLocalReplacementConfirmation,
      currentLocalStudentUsername: requiresLocalReplacementConfirmation
          ? currentLocalStudent
          : null,
    );
  }

  Future<CredentialsResult?> preferredSyncCredentials() async {
    final saved = _savedSyncCredentials;
    final currentStudent = _studentUsernameForPayload(_payload);
    if (saved == null ||
        !_sameStudent(saved.linkedStudentUsername, currentStudent)) {
      return null;
    }

    return CredentialsResult(
      username: saved.username,
      password: saved.password,
    );
  }

  void setSyncInProgress(bool value) {
    if (_isDisposed || _isSyncing == value) {
      return;
    }

    _isSyncing = value;
    notifyListeners();
  }

  Future<HomeActionResult> applyPreparedSync(
    PreparedSyncPlan plan, {
    required bool clearExistingCloudData,
    CredentialsResult? sourceCredentials,
  }) async {
    setSyncInProgress(true);

    try {
      if (_signedInUser != null && clearExistingCloudData) {
        await _dashboardPersistenceService.clearCloudAccountData();
      }

      await _persistAndApplyPayload(
        previousPayload: _payload,
        nextPayload: plan.payload,
        selectedDate: plan.selectedDate,
        linkedStudentUsername: _signedInUser == null
            ? null
            : _studentUsernameForPayload(plan.payload),
      );
      try {
        await _saveLinkedStudentCredentials(
          payload: plan.payload,
          sourceCredentials: sourceCredentials,
        );
      } catch (error, stackTrace) {
        debugPrint(
          'HomeController: failed to cache student sync credentials: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }

      if (_isDisposed) {
        return const HomeActionResult.success();
      }

      _showSyncReminder = false;
      _currentTab = 0;
      notifyListeners();

      return const HomeActionResult.success('Đồng bộ thành công!');
    } catch (error, stackTrace) {
      debugPrint('HomeController: applyPreparedSync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return const HomeActionResult.failure(
        'Đã có lỗi xảy ra khi đồng bộ. Vui lòng thử lại sau.',
      );
    } finally {
      setSyncInProgress(false);
    }
  }

  Future<HomeActionResult> syncSchoolData(CredentialsResult credentials) async {
    try {
      final plan = await prepareSchoolSync(credentials);
      if (plan.decision.requiresConfirmation ||
          plan.requiresLocalReplacementConfirmation) {
        return const HomeActionResult.failure(
          'Cần xác nhận liên kết tài khoản trước khi đồng bộ.',
        );
      }
      return applyPreparedSync(
        plan,
        clearExistingCloudData: false,
        sourceCredentials: credentials,
      );
    } on SchoolApiException catch (error) {
      return HomeActionResult.failure(error.message);
    } catch (_) {
      return const HomeActionResult.failure(
        'Đã có lỗi xảy ra khi đồng bộ. Vui lòng thử lại sau.',
      );
    }
  }

  Future<void> addTask(TaskEditorResult result) async {
    final mutationResult = await _eventMutationService.addTask(
      currentPayload: _payload,
      result: result,
    );
    _payload = mutationResult.payload;
    if (_isDisposed) return;

    _markLocalMutation();
    _selectedDate = _normalizedDate(result.date);
    _isLoadingLocalCache = false;
    _registerPendingEventSync(
      event: mutationResult.affectedEvent,
      action: mutationResult.pendingAction,
      completion: mutationResult.cloudSyncCompletion,
    );
    notifyListeners();
  }

  Future<void> editEvent(StudentEvent event, NoteEditorResult result) async {
    if (result.deleteEvent) {
      await deletePersonalEvent(event);
      return;
    }

    final mutationResult = await _eventMutationService.editEvent(
      currentPayload: _payload,
      event: event,
      result: result,
    );
    _payload = mutationResult.payload;
    if (_isDisposed) return;

    _markLocalMutation();
    _isLoadingLocalCache = false;
    _registerPendingEventSync(
      event: mutationResult.affectedEvent,
      action: mutationResult.pendingAction,
      completion: mutationResult.cloudSyncCompletion,
    );
    notifyListeners();
  }

  Future<void> deletePersonalEvent(StudentEvent event) async {
    final mutationResult = await _eventMutationService.deletePersonalEvent(
      currentPayload: _payload,
      event: event,
    );
    final nextPayload = mutationResult.payload;
    if (identical(nextPayload, _payload)) return;

    _payload = nextPayload;
    if (_isDisposed) return;

    _markLocalMutation();
    _isLoadingLocalCache = false;
    _registerPendingEventSync(
      event: mutationResult.affectedEvent,
      action: mutationResult.pendingAction,
      completion: mutationResult.cloudSyncCompletion,
    );
    notifyListeners();
  }

  Future<void> toggleDone(String id) async {
    final mutationResult = await _eventMutationService.toggleDone(
      currentPayload: _payload,
      id: id,
    );
    _payload = mutationResult.payload;
    if (_isDisposed) return;

    _markLocalMutation();
    _isLoadingLocalCache = false;
    _registerPendingEventSync(
      event: mutationResult.affectedEvent,
      action: mutationResult.pendingAction,
      completion: mutationResult.cloudSyncCompletion,
    );
    notifyListeners();
  }

  Future<AttachmentOpenResult> openAttachment(
    EventAttachment attachment,
  ) async {
    return _eventMutationService.openAttachment(attachment);
  }

  Future<HomeActionResult> emailAuth(EmailAuthResult result) {
    return _accountAuthController.submitEmailAuth(result);
  }

  Future<HomeActionResult> googleAuth() {
    return _accountAuthController.signInWithGoogle();
  }

  Future<HomeActionResult> signOut() async {
    if (_isSigningOut) {
      return const HomeActionResult.failure(
        'Đang đăng xuất. Vui lòng chờ trong giây lát.',
      );
    }

    _isSigningOut = true;
    if (!_isDisposed) {
      notifyListeners();
    }

    try {
      final result = await _accountAuthController.signOut();
      if (!result.isSuccess) {
        return result;
      }

      await _dashboardPersistenceService.clearLocalData();
      await _attachmentStorageService.clearAllAttachments();
      await _studentSyncCredentialsService.clear();

      if (_isDisposed) {
        return const HomeActionResult.success(
          'Đã đăng xuất và dọn sạch dữ liệu trên thiết bị.',
        );
      }

      _payload = const LocalCachePayload();
      _selectedDate = _today;
      _updateSignedInUser(null);
      _isSyncing = false;
      _isLinkingStudent = false;
      _isRestoringCloudData = false;
      _isLoadingLocalCache = false;
      _currentTab = 0;
      _showSyncReminder = true;
      _savedSyncCredentials = null;
      notifyListeners();

      return const HomeActionResult.success(
        'Đã đăng xuất và dọn sạch dữ liệu trên thiết bị.',
      );
    } catch (_) {
      return const HomeActionResult.failure(
        'Không thể đăng xuất lúc này. Vui lòng thử lại.',
      );
    } finally {
      if (!_isDisposed) {
        _isSigningOut = false;
        notifyListeners();
      }
    }
  }

  Future<void> _loadLocalCache() async {
    final cached = await _dashboardPersistenceService.loadLocalCache();
    if (_isDisposed) return;

    if (cached == null) {
      _isLoadingLocalCache = false;
      notifyListeners();
      return;
    }

    _payload = cached;
    _selectedDate = _dashboardPersistenceService.selectedDateForPayload(
      cached,
      _today,
    );
    _isLoadingLocalCache = false;
    notifyListeners();
  }

  Future<void> _loadSavedSyncCredentials() async {
    final saved = await _studentSyncCredentialsService.load();
    if (_isDisposed) {
      return;
    }

    _savedSyncCredentials = saved;
    notifyListeners();
  }

  Future<void> _restoreAndSyncCloudState({
    required int sessionGeneration,
    required String sessionUserId,
  }) async {
    final restoreStartedMutationVersion = _localMutationVersion;
    final remotePayload = await _dashboardPersistenceService
        .fetchRemotePayload();
    if (_isStaleCloudRestore(
      sessionGeneration: sessionGeneration,
      sessionUserId: sessionUserId,
    )) {
      return;
    }

    final remoteStudent = _studentUsernameForPayload(remotePayload);
    _linkedStudentUsername = remoteStudent;

    if (remotePayload == null) {
      notifyListeners();
      return;
    }

    final localStudent = _studentUsernameForPayload(_payload);
    final syncBackEventIds = _collectEventIdsNeedingCloudSyncAfterRestore(
      localPayload: _payload,
      remotePayload: remotePayload,
    );
    final hasLocalMutationsDuringRestore =
        _localMutationVersion != restoreStartedMutationVersion;
    LocalCachePayload nextPayload = _payload;
    DateTime? nextSelectedDate;

    if (remoteStudent != null &&
        (localStudent == null || !_sameStudent(localStudent, remoteStudent))) {
      if (localStudent == null &&
          (_payload.hasData || hasLocalMutationsDuringRestore)) {
        nextPayload = _mergePayloadsForSameStudent(
          local: _payload,
          remote: remotePayload,
        );
        nextSelectedDate = _dashboardPersistenceService.selectedDateForPayload(
          _preferredPayload(_payload, remotePayload),
          _selectedDate,
        );
      } else {
        nextPayload = remotePayload;
        nextSelectedDate = _dashboardPersistenceService.selectedDateForPayload(
          remotePayload,
          _selectedDate,
        );
      }
    } else if (remoteStudent != null &&
        localStudent != null &&
        _sameStudent(localStudent, remoteStudent)) {
      nextPayload = _mergePayloadsForSameStudent(
        local: _payload,
        remote: remotePayload,
      );
      nextSelectedDate = _dashboardPersistenceService.selectedDateForPayload(
        _preferredPayload(_payload, remotePayload),
        _selectedDate,
      );
    } else if (_dashboardPersistenceService.shouldUseRemotePayload(
      _payload,
      remotePayload,
    )) {
      nextPayload = remotePayload;
      nextSelectedDate = _dashboardPersistenceService.selectedDateForPayload(
        remotePayload,
        _selectedDate,
      );
    }

    final persistedPayload = await _persistAndApplyPayload(
      previousPayload: _payload,
      nextPayload: nextPayload,
      selectedDate: nextSelectedDate,
      linkedStudentUsername: remoteStudent,
      syncToCloud: false,
    );

    final syncBackEvents = _eventsByIds(
      payload: persistedPayload,
      ids: syncBackEventIds,
    );
    if (syncBackEvents.isNotEmpty) {
      unawaited(
        _dashboardPersistenceService.queueCloudSyncForPayload(
          persistedPayload,
          changedEvents: syncBackEvents,
        ),
      );
    }
  }

  void _startInitialCloudRestore() {
    final session = _beginCloudRestoreSession();
    final future =
        _restoreAndSyncCloudState(
          sessionGeneration: session.$1,
          sessionUserId: session.$2,
        ).catchError((_) {
          // Keep the app usable if remote restore fails.
        });
    _initialCloudRestoreFuture = future;
    future.whenComplete(() {
      if (identical(_initialCloudRestoreFuture, future)) {
        _initialCloudRestoreFuture = null;
      }
      _endCloudRestoreSession(
        sessionGeneration: session.$1,
        sessionUserId: session.$2,
      );
    });
  }

  void _updateSignedInUser(User? user) {
    final previousUserId = _signedInUser?.uid;
    final nextUserId = user?.uid;
    if (previousUserId != nextUserId) {
      _cloudRestoreGeneration++;
      _pendingEventSyncs.clear();
    }

    _signedInUser = user;
    if (user == null) {
      _linkedStudentUsername = null;
      _initialCloudRestoreFuture = null;
      _isRestoringCloudData = false;
      _showCloudRestoreWarning = false;
      _dashboardPersistenceService.invalidatePendingCloudSyncs();
    }
  }

  (int, String) _beginCloudRestoreSession() {
    final userId = _signedInUser?.uid;
    if (userId == null) {
      return (_cloudRestoreGeneration, '');
    }

    _isRestoringCloudData = true;
    _showCloudRestoreWarning = true;
    if (!_isDisposed) {
      notifyListeners();
    }
    return (_cloudRestoreGeneration, userId);
  }

  void _endCloudRestoreSession({
    required int sessionGeneration,
    required String sessionUserId,
  }) {
    if (_isStaleCloudRestore(
      sessionGeneration: sessionGeneration,
      sessionUserId: sessionUserId,
    )) {
      return;
    }

    _isRestoringCloudData = false;
    _showCloudRestoreWarning = false;
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  bool _isStaleCloudRestore({
    required int sessionGeneration,
    required String sessionUserId,
  }) {
    return _isDisposed ||
        _cloudRestoreGeneration != sessionGeneration ||
        _signedInUser?.uid != sessionUserId;
  }

  Future<AuthFlowResult> _resolvePostSignIn({
    required String authSuccessMessage,
    required int sessionGeneration,
    required String sessionUserId,
  }) async {
    try {
      final remotePayload = await _dashboardPersistenceService
          .fetchRemotePayload();
      if (_isStaleCloudRestore(
        sessionGeneration: sessionGeneration,
        sessionUserId: sessionUserId,
      )) {
        return const AuthFlowResult.success();
      }

      final localStudent = _studentUsernameForPayload(_payload);
      final remoteStudent = _studentUsernameForPayload(remotePayload);
      _linkedStudentUsername = remoteStudent;
      notifyListeners();

      if (localStudent == null) {
        if (remotePayload != null && remoteStudent != null) {
          await _persistAndApplyPayload(
            previousPayload: _payload,
            nextPayload: remotePayload,
            selectedDate: _dashboardPersistenceService.selectedDateForPayload(
              remotePayload,
              _selectedDate,
            ),
            linkedStudentUsername: remoteStudent,
          );
          return AuthFlowResult.success(
            message:
                '$authSuccessMessage Đã khôi phục dữ liệu của sinh viên $remoteStudent.',
          );
        }

        return AuthFlowResult.success(
          message:
              '$authSuccessMessage Hãy đồng bộ tài khoản sinh viên để bắt đầu liên kết dữ liệu.',
        );
      }

      if (remoteStudent == null) {
        return AuthFlowResult.success(
          message: authSuccessMessage,
          decision: AccountLinkDecision(
            action: AccountLinkAction.linkStudent,
            targetStudentUsername: localStudent,
          ),
        );
      }

      if (!_sameStudent(localStudent, remoteStudent)) {
        return AuthFlowResult.success(
          message: authSuccessMessage,
          decision: AccountLinkDecision(
            action: AccountLinkAction.relinkStudent,
            currentLinkedStudentUsername: remoteStudent,
            targetStudentUsername: localStudent,
          ),
        );
      }

      final mergedPayload = _mergePayloadsForSameStudent(
        local: _payload,
        remote: remotePayload ?? const LocalCachePayload(),
      );
      await _persistAndApplyPayload(
        previousPayload: _payload,
        nextPayload: mergedPayload,
        linkedStudentUsername: localStudent,
      );

      return AuthFlowResult.success(
        message:
            '$authSuccessMessage Đã cập nhật dữ liệu đã liên kết của sinh viên $localStudent.',
      );
    } finally {
      _endCloudRestoreSession(
        sessionGeneration: sessionGeneration,
        sessionUserId: sessionUserId,
      );
    }
  }

  Future<LocalCachePayload> _persistAndApplyPayload({
    required LocalCachePayload previousPayload,
    required LocalCachePayload nextPayload,
    DateTime? selectedDate,
    String? linkedStudentUsername,
    bool syncToCloud = true,
  }) async {
    final persistedPayload = syncToCloud
        ? await _dashboardPersistenceService.persistPayload(nextPayload)
        : await _dashboardPersistenceService.persistPayloadLocally(nextPayload);
    try {
      await _attachmentStorageService.deleteUnusedAttachments(
        previousEvents: [
          ...previousPayload.syncedEvents,
          ...previousPayload.personalEvents,
        ],
        nextEvents: [
          ...persistedPayload.syncedEvents,
          ...persistedPayload.personalEvents,
        ],
      );
    } catch (error, stackTrace) {
      debugPrint('HomeController: failed to cleanup old attachments: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    if (_isDisposed) {
      return persistedPayload;
    }

    _payload = persistedPayload;
    if (selectedDate != null) {
      _selectedDate = _normalizedDate(selectedDate);
    }
    _linkedStudentUsername = linkedStudentUsername;
    _isLoadingLocalCache = false;
    notifyListeners();
    return persistedPayload;
  }

  void _markLocalMutation() {
    _localMutationVersion++;
  }

  Set<String> _collectEventIdsNeedingCloudSyncAfterRestore({
    required LocalCachePayload localPayload,
    required LocalCachePayload remotePayload,
  }) {
    final ids = <String>{};

    final remotePersonalById = {
      for (final event in remotePayload.personalEvents) event.id: event,
    };
    for (final localEvent in localPayload.personalEvents) {
      final remoteEvent = remotePersonalById[localEvent.id];
      if (remoteEvent == null ||
          _personalEventNeedsCloudSync(localEvent, remoteEvent)) {
        ids.add(localEvent.id);
      }
    }

    final remoteSyncedBySignature = {
      for (final event in remotePayload.syncedEvents)
        _syncedEventSignature(event): event,
    };
    for (final localEvent in localPayload.syncedEvents) {
      final remoteEvent =
          remoteSyncedBySignature[_syncedEventSignature(localEvent)];
      final localScore = _syncedEventDataScore(localEvent);
      final remoteScore = remoteEvent == null
          ? 0
          : _syncedEventDataScore(remoteEvent);
      if (localScore > 0 && remoteScore < localScore) {
        ids.add(localEvent.id);
      }
    }

    return ids;
  }

  bool _personalEventNeedsCloudSync(StudentEvent local, StudentEvent remote) {
    if (local.title != remote.title ||
        local.start != remote.start ||
        local.end != remote.end ||
        local.note != remote.note ||
        local.isDone != remote.isDone ||
        local.attachments.length != remote.attachments.length) {
      return true;
    }

    for (var index = 0; index < local.attachments.length; index++) {
      final localAttachment = local.attachments[index];
      final remoteAttachment = remote.attachments[index];
      if (localAttachment.id != remoteAttachment.id ||
          localAttachment.name != remoteAttachment.name ||
          localAttachment.remoteKey != remoteAttachment.remoteKey ||
          localAttachment.path != remoteAttachment.path ||
          localAttachment.bytesBase64 != remoteAttachment.bytesBase64) {
        return true;
      }
    }
    return false;
  }

  List<StudentEvent> _eventsByIds({
    required LocalCachePayload payload,
    required Set<String> ids,
  }) {
    if (ids.isEmpty) {
      return const [];
    }

    return [
        ...payload.syncedEvents,
        ...payload.personalEvents,
      ].where((event) => ids.contains(event.id)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  LocalCachePayload _mergePayloadsForSameStudent({
    required LocalCachePayload local,
    required LocalCachePayload remote,
  }) {
    final basePayload = _preferredPayload(local, remote);
    return basePayload.copyWith(
      syncedEvents: _mergeParallelSyncedEvents(
        remote.syncedEvents,
        local.syncedEvents,
      ),
      personalEvents: _mergePersonalEvents(
        remote.personalEvents,
        local.personalEvents,
      ),
    );
  }

  LocalCachePayload _mergeSyncedPayloadWithExistingPersonalData({
    required LocalCachePayload syncedPayload,
    required LocalCachePayload localPayload,
    required LocalCachePayload remotePayload,
  }) {
    final mergedExistingSyncedEvents = _mergeParallelSyncedEvents(
      remotePayload.syncedEvents,
      localPayload.syncedEvents,
    );
    final mergedExistingPersonalEvents = _mergePersonalEvents(
      remotePayload.personalEvents,
      localPayload.personalEvents,
    );

    return _schoolSyncCoordinator.mergeFetchedPayloadWithExistingData(
      fetchedPayload: syncedPayload,
      existingSyncedEvents: mergedExistingSyncedEvents,
      existingPersonalEvents: mergedExistingPersonalEvents,
    );
  }

  LocalCachePayload _preferredPayload(
    LocalCachePayload primary,
    LocalCachePayload secondary,
  ) {
    if (!secondary.hasData) return primary;
    if (!primary.hasData) return secondary;

    final primaryTime = primary.lastSyncedAt;
    final secondaryTime = secondary.lastSyncedAt;
    if (secondaryTime != null &&
        (primaryTime == null || secondaryTime.isAfter(primaryTime))) {
      return secondary;
    }
    return primary;
  }

  List<StudentEvent> _mergePersonalEvents(
    List<StudentEvent> remoteEvents,
    List<StudentEvent> localEvents,
  ) {
    final merged = <String, StudentEvent>{};
    for (final event in remoteEvents) {
      merged[event.id] = event;
    }
    for (final event in localEvents) {
      merged[event.id] = event;
    }

    return merged.values.toList()..sort((a, b) => a.start.compareTo(b.start));
  }

  List<StudentEvent> _mergeParallelSyncedEvents(
    List<StudentEvent> remoteEvents,
    List<StudentEvent> localEvents,
  ) {
    final merged = <String, StudentEvent>{};
    for (final event in remoteEvents) {
      merged[_syncedEventSignature(event)] = event;
    }
    for (final event in localEvents) {
      final key = _syncedEventSignature(event);
      merged[key] = _preferSyncedEventData(event, merged[key]);
    }

    return merged.values.toList()..sort((a, b) => a.start.compareTo(b.start));
  }

  StudentEvent _preferSyncedEventData(
    StudentEvent primary,
    StudentEvent? secondary,
  ) {
    if (secondary == null) {
      return primary;
    }

    final primaryScore = _syncedEventDataScore(primary);
    final secondaryScore = _syncedEventDataScore(secondary);
    if (primaryScore != secondaryScore) {
      return primaryScore >= secondaryScore ? primary : secondary;
    }

    return primary;
  }

  int _syncedEventDataScore(StudentEvent event) {
    var score = 0;
    if ((event.note ?? '').trim().isNotEmpty) {
      score += 4;
    }
    if (event.attachments.isNotEmpty) {
      score += 8;
    }
    if ((event.sourceNote ?? '').trim().isNotEmpty) {
      score += 2;
    }
    return score;
  }

  String _syncedEventSignature(StudentEvent event) {
    return [
      event.type.name,
      event.title.trim(),
      event.start.toIso8601String(),
      event.end.toIso8601String(),
      event.location?.trim() ?? '',
      event.referenceCode?.trim() ?? '',
    ].join('|');
  }

  String? _studentUsernameForPayload(LocalCachePayload? payload) {
    final username = payload?.profile?.username.trim();
    if (username == null || username.isEmpty) {
      return null;
    }
    return username;
  }

  bool _sameStudent(String? left, String? right) {
    return _normalizedStudentKey(left) == _normalizedStudentKey(right);
  }

  String? _normalizedStudentKey(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed.toLowerCase();
  }

  DateTime _normalizedDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  Future<void> _saveLinkedStudentCredentials({
    required LocalCachePayload payload,
    CredentialsResult? sourceCredentials,
  }) async {
    final credentials = sourceCredentials;
    final linkedStudent = _studentUsernameForPayload(payload);
    if (credentials == null || linkedStudent == null) {
      return;
    }

    final saved = StudentSyncCredentials(
      linkedStudentUsername: linkedStudent,
      username: credentials.username,
      password: credentials.password,
      updatedAt: DateTime.now(),
    );
    await _studentSyncCredentialsService.save(saved);

    if (_isDisposed) {
      return;
    }

    _savedSyncCredentials = saved;
    notifyListeners();
  }

  void _registerPendingEventSync({
    required StudentEvent? event,
    required PendingEventSyncAction? action,
    required Future<void> completion,
  }) {
    if (event == null || action == null) {
      return;
    }

    final existing = _pendingEventSyncs[event.id];
    final syncToken = (existing?.syncToken ?? 0) + 1;
    _pendingEventSyncs[event.id] = _PendingEventSyncEntry(
      event: event,
      action: action,
      syncToken: syncToken,
      state: _PendingEventSyncState.syncing,
    );
    if (!_isDisposed) {
      notifyListeners();
    }

    final timeout = _estimatedPendingSyncTimeout(event, action);
    unawaited(
      Future<void>.delayed(timeout).then((_) {
        final current = _pendingEventSyncs[event.id];
        if (current == null ||
            current.syncToken != syncToken ||
            current.isDeferred) {
          return;
        }

        _pendingEventSyncs[event.id] = current.copyWith(
          state: _PendingEventSyncState.deferred,
        );
        if (!_isDisposed) {
          notifyListeners();
        }
      }),
    );

    unawaited(
      completion.whenComplete(() {
        final current = _pendingEventSyncs[event.id];
        if (current == null || current.syncToken != syncToken) {
          return;
        }

        _pendingEventSyncs.remove(event.id);
        if (!_isDisposed) {
          notifyListeners();
        }
      }),
    );
  }

  Duration _estimatedPendingSyncTimeout(
    StudentEvent event,
    PendingEventSyncAction action,
  ) {
    final titleWeight = event.title.trim().length;
    final noteWeight = (event.note ?? '').trim().length;
    final sourceNoteWeight = (event.sourceNote ?? '').trim().length;
    final attachmentWeight = event.attachments.fold<int>(0, (
      total,
      attachment,
    ) {
      final bytesWeight = attachment.bytesBase64?.length ?? 0;
      return total + bytesWeight + attachment.name.length;
    });
    final queueWeight = _pendingEventSyncs.length * 900;
    final baseMs = action == PendingEventSyncAction.deleting ? 5000 : 6500;
    final contentMs =
        ((titleWeight + noteWeight + sourceNoteWeight) * 6) +
        (event.attachments.length * 2500) +
        (attachmentWeight ~/ 180);
    final totalMs = baseMs + contentMs + queueWeight;
    final clampedMs = totalMs.clamp(6000, 45000);
    return Duration(milliseconds: clampedMs);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _syncReminderTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}

class _PendingEventSyncEntry {
  const _PendingEventSyncEntry({
    required this.event,
    required this.action,
    required this.syncToken,
    required this.state,
  });

  final StudentEvent event;
  final PendingEventSyncAction action;
  final int syncToken;
  final _PendingEventSyncState state;

  bool get isDeleting => action == PendingEventSyncAction.deleting;
  bool get isDeferred => state == _PendingEventSyncState.deferred;

  _PendingEventSyncEntry copyWith({
    StudentEvent? event,
    PendingEventSyncAction? action,
    int? syncToken,
    _PendingEventSyncState? state,
  }) {
    return _PendingEventSyncEntry(
      event: event ?? this.event,
      action: action ?? this.action,
      syncToken: syncToken ?? this.syncToken,
      state: state ?? this.state,
    );
  }
}

enum _PendingEventSyncState { syncing, deferred }
