import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/event_attachment.dart';
import '../models/student_event.dart';
import '../models/weather_forecast.dart';
import '../services/local_cache_service.dart';
import '../services/weather_service.dart';
import '../utils/home_calendar_utils.dart';
import '../widgets/home/home_dialogs.dart';
import '../widgets/home/home_sheet_models.dart';
import 'account_auth_controller.dart';
import 'home_shell_controller.dart';

class HomeShellViewModel extends ChangeNotifier {
  HomeShellViewModel({
    AccountAuthController? accountAuthController,
    WeatherService? weatherService,
    HomeShellController? homeShellController,
  }) : _accountAuthController =
           accountAuthController ?? AccountAuthController(),
       weatherService = weatherService ?? WeatherService(),
       _homeShellController =
           homeShellController ??
           HomeShellController(weatherService: weatherService) {
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _selectedDate = _today;
  }

  static const int pastDayRange = 365;
  static const int futureDayRange = 365;
  static const double dayTileWidth = 72;
  static const double dayTileSpacing = 10;

  final AccountAuthController _accountAuthController;
  final HomeShellController _homeShellController;

  final WeatherService weatherService;
  final ScrollController dayStripController = ScrollController();

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed) return;
      _jumpDayStripToDate(_selectedDate);
    });
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
    _selectedDate = date;
    notifyListeners();
    _scrollDayStripToDate(date);
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

    final forecast = await _homeShellController.loadWeatherForecast();
    if (_isDisposed) return;

    _weatherForecast = forecast;
    _isLoadingWeather = false;
    notifyListeners();
  }

  Future<void> openMonthPicker(BuildContext context) async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => MonthPickerDialog(
        initialDate: _selectedDate,
        firstDate: _today.subtract(const Duration(days: pastDayRange)),
        lastDate: _today.add(const Duration(days: futureDayRange)),
        eventLevelForDate: (date) => HomeCalendarUtils.eventLevelForEvents(
          HomeCalendarUtils.eventsForDay(allEvents, date),
        ),
      ),
    );

    if (picked == null || !context.mounted || _isDisposed) return;

    final normalized = DateTime(picked.year, picked.month, picked.day);
    _selectedDate = normalized;
    notifyListeners();
    _scrollDayStripToDate(normalized);
  }

  Future<void> openSyncDialog(BuildContext context) async {
    final credentials = await showDialog<CredentialsResult>(
      context: context,
      builder: (context) => const SyncCredentialsDialog(),
    );

    if (credentials == null || !context.mounted || _isDisposed) return;

    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!context.mounted || _isDisposed) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final mutation = await _homeShellController.syncSchool(
        username: credentials.username,
        password: credentials.password,
        currentPayload: _payload,
      );
      if (!context.mounted || _isDisposed) return;

      _applyMutation(
        mutation,
        isLoadingLocalCache: false,
        switchToScheduleTab: true,
      );
      _showSyncReminder = false;
      notifyListeners();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isDisposed) return;
        _scrollDayStripToDate(_selectedDate);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đồng bộ thành công.')));
    } catch (error) {
      if (!context.mounted || _isDisposed) return;
      final message = error is Exception && error is! Error
          ? error.toString().replaceFirst('Exception: ', '')
          : 'Đã có lỗi xảy ra khi đồng bộ. Vui lòng thử lại sau.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (!_isDisposed) {
        _isSyncing = false;
        notifyListeners();
      }
    }
  }

  Future<void> addTask(BuildContext context) async {
    final mutation = await _homeShellController.addTask(
      context: context,
      selectedDate: _selectedDate,
      currentPayload: _payload,
    );
    if (mutation == null || !context.mounted || _isDisposed) return;

    _applyMutation(mutation, isLoadingLocalCache: false);
    _scrollDayStripToDate(_selectedDate);
  }

  Future<void> editEvent(BuildContext context, StudentEvent event) async {
    final mutation = await _homeShellController.editEvent(
      context: context,
      event: event,
      currentPayload: _payload,
    );
    if (mutation == null || !context.mounted || _isDisposed) return;

    _applyMutation(mutation, isLoadingLocalCache: false);
  }

  Future<void> deletePersonalEvent(
    BuildContext context,
    StudentEvent event,
  ) async {
    final payload = await _homeShellController.deletePersonalEvent(
      context: context,
      event: event,
      currentPayload: _payload,
    );
    if (payload == null || !context.mounted || _isDisposed) return;

    _payload = payload;
    _isLoadingLocalCache = false;
    notifyListeners();
  }

  Future<void> toggleDone(String id) async {
    final mutation = await _homeShellController.toggleDone(
      id: id,
      currentPayload: _payload,
    );
    if (_isDisposed) return;

    _applyMutation(mutation, isLoadingLocalCache: false);
  }

  Future<void> openAttachment(
    BuildContext context,
    EventAttachment attachment,
  ) async {
    final opened = await _homeShellController.openAttachment(attachment);
    if (opened || !context.mounted || _isDisposed) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Không thể mở tệp đính kèm. Vui lòng thử lại.'),
      ),
    );
  }

  Future<void> emailAuth(BuildContext context) {
    return _accountAuthController.openEmailAuthSheet(context);
  }

  Future<void> googleAuth(BuildContext context) {
    return _accountAuthController.signInWithGoogle(context);
  }

  Future<void> signOut(BuildContext context) {
    return _accountAuthController.signOut(context);
  }

  Future<void> _loadLocalCache() async {
    final cached = await _homeShellController.loadLocalCache();
    if (_isDisposed) return;

    if (cached == null) {
      _isLoadingLocalCache = false;
      notifyListeners();
      return;
    }

    _payload = cached;
    _selectedDate = HomeShellController.selectedDateForPayload(cached, _today);
    _isLoadingLocalCache = false;
    notifyListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed) return;
      _jumpDayStripToDate(_selectedDate);
    });
  }

  Future<void> _restoreAndSyncCloudState() async {
    final mutation = await _homeShellController.restoreAndSyncCloudState(
      currentPayload: _payload,
      fallbackSelectedDate: _selectedDate,
    );
    if (_isDisposed) return;

    _applyMutation(mutation, isLoadingLocalCache: false);
  }

  void _applyMutation(
    HomeShellMutation mutation, {
    required bool isLoadingLocalCache,
    bool switchToScheduleTab = false,
  }) {
    _payload = mutation.payload;
    _selectedDate = mutation.selectedDate ?? _selectedDate;
    _isLoadingLocalCache = isLoadingLocalCache;
    if (switchToScheduleTab) {
      _currentTab = 0;
    }
    notifyListeners();
  }

  void _jumpDayStripToDate(DateTime date) {
    if (!dayStripController.hasClients) return;
    final offset = HomeCalendarUtils.stripOffsetForDate(
      today: _today,
      pastDayRange: pastDayRange,
      date: date,
      itemExtent: dayTileWidth + dayTileSpacing,
    );
    dayStripController.jumpTo(
      offset.clamp(0.0, dayStripController.position.maxScrollExtent),
    );
  }

  void _scrollDayStripToDate(DateTime date) {
    if (!dayStripController.hasClients) return;
    final offset = HomeCalendarUtils.stripOffsetForDate(
      today: _today,
      pastDayRange: pastDayRange,
      date: date,
      itemExtent: dayTileWidth + dayTileSpacing,
    );
    dayStripController.animateTo(
      offset.clamp(0.0, dayStripController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _syncReminderTimer?.cancel();
    _authSubscription?.cancel();
    dayStripController.dispose();
    super.dispose();
  }
}
