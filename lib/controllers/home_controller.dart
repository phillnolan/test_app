import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/event_attachment.dart';
import '../models/home_action_result.dart';
import '../models/local_cache_payload.dart';
import '../models/student_event.dart';
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
  }) : _accountAuthController =
           accountAuthController ?? AccountAuthController(),
       _weatherService = weatherService ?? WeatherService() {
    final resolvedLocalCacheService = localCacheService ?? LocalCacheService();
    final resolvedCloudSyncService = cloudSyncService ?? CloudSyncService();
    final resolvedWidgetSyncService = widgetSyncService ?? WidgetSyncService();
    final resolvedDeviceEffectsService =
        deviceEffectsService ??
        DeviceEffectsService(widgetSyncService: resolvedWidgetSyncService);
    final resolvedDashboardPersistenceService =
        dashboardPersistenceService ??
        DashboardPersistenceService(
          localCacheService: resolvedLocalCacheService,
          cloudSyncService: resolvedCloudSyncService,
          deviceEffectsService: resolvedDeviceEffectsService,
        );

    _dashboardPersistenceService = resolvedDashboardPersistenceService;
    _schoolSyncCoordinator =
        schoolSyncCoordinator ??
        SchoolSyncCoordinator(
          schoolApiService: schoolApiService ?? SchoolApiService(),
        );
    _eventMutationService =
        eventMutationService ??
        EventMutationService(
          attachmentStorageService:
              attachmentStorageService ?? AttachmentStorageService(),
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
  late final DashboardPersistenceService _dashboardPersistenceService;
  late final SchoolSyncCoordinator _schoolSyncCoordinator;
  late final EventMutationService _eventMutationService;

  late final DateTime _today;
  late DateTime _selectedDate;

  LocalCachePayload _payload = const LocalCachePayload();
  WeatherForecast? _weatherForecast;

  bool _isSyncing = false;
  bool _isLoadingLocalCache = true;
  bool _isLoadingWeather = true;
  bool _showSyncReminder = true;
  int _currentTab = 0;
  User? _signedInUser;

  Timer? _syncReminderTimer;
  StreamSubscription<User?>? _authSubscription;
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
      precipitationLabel: 'Mua ${forecast.precipitationProbabilityMax}%',
      suggestions: _weatherService.suggestionsForDay(forecast).take(2).toList(),
    );
  }

  bool get isSyncing => _isSyncing;
  bool get isLoadingLocalCache => _isLoadingLocalCache;
  bool get isLoadingWeather => _isLoadingWeather;
  bool get showSyncReminder => _showSyncReminder;
  int get currentTab => _currentTab;
  User? get signedInUser => _signedInUser;
  bool get isAuthAvailable => _accountAuthController.isAvailable;

  List<StudentEvent> get allEvents {
    final events = [..._payload.syncedEvents, ..._payload.personalEvents]
      ..sort((a, b) => a.start.compareTo(b.start));
    return events;
  }

  void initialize() {
    _syncReminderTimer = Timer(const Duration(seconds: 5), () {
      if (_isDisposed) return;
      _showSyncReminder = false;
      notifyListeners();
    });

    unawaited(_loadLocalCache());
    unawaited(reloadWeather());

    if (_accountAuthController.isAvailable) {
      _signedInUser = _accountAuthController.currentUser;
      _authSubscription = _accountAuthController.listenAuthState((user) {
        if (_isDisposed) return;
        _signedInUser = user;
        notifyListeners();
        if (user != null) {
          unawaited(_restoreAndSyncCloudState());
        }
      });
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

  Future<HomeActionResult> syncSchoolData(CredentialsResult credentials) async {
    _isSyncing = true;
    notifyListeners();

    try {
      final syncResult = await _schoolSyncCoordinator.sync(
        username: credentials.username,
        password: credentials.password,
        currentPayload: _payload,
      );
      final nextPayload = await _dashboardPersistenceService.persistPayload(
        syncResult.payload,
      );

      if (_isDisposed) {
        return const HomeActionResult.success();
      }

      _payload = nextPayload;
      _selectedDate = syncResult.selectedDate;
      _isLoadingLocalCache = false;
      _showSyncReminder = false;
      _currentTab = 0;
      notifyListeners();

      return const HomeActionResult.success('Đồng bộ thành công!');
    } on SchoolApiException catch (error) {
      return HomeActionResult.failure(error.message);
    } catch (_) {
      return const HomeActionResult.failure(
        'Đã có lỗi xảy ra khi đồng bộ. Vui lòng thử lại sau.',
      );
    } finally {
      if (!_isDisposed) {
        _isSyncing = false;
        notifyListeners();
      }
    }
  }

  Future<void> addTask(TaskEditorResult result) async {
    _payload = await _eventMutationService.addTask(
      currentPayload: _payload,
      result: result,
    );
    if (_isDisposed) return;

    _selectedDate = _normalizedDate(result.date);
    _isLoadingLocalCache = false;
    notifyListeners();
  }

  Future<void> editEvent(StudentEvent event, NoteEditorResult result) async {
    if (result.deleteEvent) {
      await deletePersonalEvent(event);
      return;
    }

    _payload = await _eventMutationService.editEvent(
      currentPayload: _payload,
      event: event,
      result: result,
    );
    if (_isDisposed) return;

    _isLoadingLocalCache = false;
    notifyListeners();
  }

  Future<void> deletePersonalEvent(StudentEvent event) async {
    final nextPayload = await _eventMutationService.deletePersonalEvent(
      currentPayload: _payload,
      event: event,
    );
    if (identical(nextPayload, _payload)) return;

    _payload = nextPayload;
    if (_isDisposed) return;

    _isLoadingLocalCache = false;
    notifyListeners();
  }

  Future<void> toggleDone(String id) async {
    _payload = await _eventMutationService.toggleDone(
      currentPayload: _payload,
      id: id,
    );
    if (_isDisposed) return;

    _isLoadingLocalCache = false;
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

  Future<HomeActionResult> signOut() {
    return _accountAuthController.signOut();
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

  Future<void> _restoreAndSyncCloudState() async {
    final restoreResult = await _dashboardPersistenceService
        .restoreAndSyncCloudState(
          currentPayload: _payload,
          fallbackSelectedDate: _selectedDate,
        );
    if (_isDisposed) return;

    _payload = restoreResult.payload;
    _selectedDate = restoreResult.selectedDate ?? _selectedDate;
    _isLoadingLocalCache = false;
    notifyListeners();
  }

  DateTime _normalizedDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _syncReminderTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
