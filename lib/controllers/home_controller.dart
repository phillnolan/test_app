import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/event_attachment.dart';
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
import '../utils/home_calendar_utils.dart';
import '../views/home/widgets/home_dialogs.dart';
import '../views/home/widgets/home_editors.dart';
import '../views/home/widgets/home_sheet_models.dart';
import 'account_auth_controller.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    AccountAuthController? accountAuthController,
    SchoolApiService? schoolApiService,
    LocalCacheService? localCacheService,
    AttachmentStorageService? attachmentStorageService,
    CloudSyncService? cloudSyncService,
    WeatherService? weatherService,
    WidgetSyncService? widgetSyncService,
  }) : _accountAuthController =
           accountAuthController ?? AccountAuthController(),
       _schoolApiService = schoolApiService ?? SchoolApiService(),
       _localCacheService = localCacheService ?? LocalCacheService(),
       _attachmentStorageService =
           attachmentStorageService ?? AttachmentStorageService(),
       _cloudSyncService = cloudSyncService ?? CloudSyncService(),
       weatherService = weatherService ?? WeatherService(),
       _widgetSyncService = widgetSyncService ?? WidgetSyncService() {
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _selectedDate = _today;
  }

  static const int pastDayRange = 365;
  static const int futureDayRange = 365;
  static const double dayTileWidth = 72;
  static const double dayTileSpacing = 10;

  final AccountAuthController _accountAuthController;
  final SchoolApiService _schoolApiService;
  final LocalCacheService _localCacheService;
  final AttachmentStorageService _attachmentStorageService;
  final CloudSyncService _cloudSyncService;
  final WidgetSyncService _widgetSyncService;

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

    try {
      _weatherForecast = await weatherService.fetchForecast();
    } on WeatherException {
      _weatherForecast = null;
    } catch (_) {
      _weatherForecast = null;
    }

    if (_isDisposed) return;
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

    _selectedDate = DateTime(picked.year, picked.month, picked.day);
    notifyListeners();
    _scrollDayStripToDate(_selectedDate);
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
      final snapshot = await _schoolApiService.sync(
        username: credentials.username,
        password: credentials.password,
      );
      final nextPayload = await _persistPayload(
        _payloadFromSnapshot(snapshot, _payload),
      );
      if (!context.mounted || _isDisposed) return;

      _payload = nextPayload;
      _selectedDate = _normalizedDate(snapshot.syncedAt);
      _isLoadingLocalCache = false;
      _showSyncReminder = false;
      _currentTab = 0;
      notifyListeners();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isDisposed) return;
        _scrollDayStripToDate(_selectedDate);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đồng bộ thành công.')));
    } on SchoolApiException catch (error) {
      if (!context.mounted || _isDisposed) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!context.mounted || _isDisposed) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã có lỗi xảy ra khi đồng bộ. Vui lòng thử lại sau.'),
        ),
      );
    } finally {
      if (!_isDisposed) {
        _isSyncing = false;
        notifyListeners();
      }
    }
  }

  Future<void> addTask(BuildContext context) async {
    final result = await showModalBottomSheet<TaskEditorResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => EnhancedTaskEditorSheet(initialDate: _selectedDate),
    );

    if (result == null || !context.mounted || _isDisposed) return;

    final start = DateTime(
      result.date.year,
      result.date.month,
      result.date.day,
      result.hour.hour,
      result.hour.minute,
    );
    final updatedPersonalEvents = await _attachmentStorageService
        .persistEvents([
          ..._payload.personalEvents,
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

    _payload = await _persistPayload(
      _payload.copyWith(personalEvents: updatedPersonalEvents),
    );
    if (!context.mounted || _isDisposed) return;

    _selectedDate = _normalizedDate(result.date);
    _isLoadingLocalCache = false;
    notifyListeners();
    _scrollDayStripToDate(_selectedDate);
  }

  Future<void> editEvent(BuildContext context, StudentEvent event) async {
    final result = await showModalBottomSheet<NoteEditorResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => EnhancedNoteEditorSheet(event: event),
    );

    if (result == null || !context.mounted || _isDisposed) return;

    if (result.deleteEvent && event.type == StudentEventType.personalTask) {
      _payload = await _persistPayload(
        _payload.copyWith(
          personalEvents: _payload.personalEvents
              .where((item) => item.id != event.id)
              .toList(),
        ),
      );
      if (_isDisposed) return;
      _isLoadingLocalCache = false;
      notifyListeners();
      return;
    }

    final trimmed = result.note.trim();
    final updatedPersonalEvents = await _attachmentStorageService.persistEvents(
      _payload.personalEvents.map((item) {
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
      _payload.syncedEvents.map((item) {
        if (item.id != event.id) return item;
        return item.copyWith(
          note: trimmed.isEmpty ? null : trimmed,
          attachments: result.attachments,
        );
      }).toList(),
    );

    _payload = await _persistPayload(
      _payload.copyWith(
        personalEvents: updatedPersonalEvents,
        syncedEvents: updatedSyncedEvents,
      ),
    );
    if (_isDisposed) return;
    _isLoadingLocalCache = false;
    notifyListeners();
  }

  Future<void> deletePersonalEvent(
    BuildContext context,
    StudentEvent event,
  ) async {
    if (event.type != StudentEventType.personalTask) return;

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

    if (confirmed != true || !context.mounted || _isDisposed) return;

    _payload = await _persistPayload(
      _payload.copyWith(
        personalEvents: _payload.personalEvents
            .where((item) => item.id != event.id)
            .toList(),
      ),
    );
    if (_isDisposed) return;
    _isLoadingLocalCache = false;
    notifyListeners();
  }

  Future<void> toggleDone(String id) async {
    _payload = await _persistPayload(
      _payload.copyWith(
        personalEvents: _payload.personalEvents.map((event) {
          if (event.id != id) return event;
          return event.copyWith(isDone: !event.isDone);
        }).toList(),
      ),
    );
    if (_isDisposed) return;
    _isLoadingLocalCache = false;
    notifyListeners();
  }

  Future<void> openAttachment(
    BuildContext context,
    EventAttachment attachment,
  ) async {
    final localBytes = await _attachmentStorageService.readAttachmentBytes(
      attachment,
    );
    final bytes =
        localBytes ??
        (attachment.bytesBase64 == null
            ? await _cloudSyncService.downloadAttachmentBytes(attachment)
            : base64Decode(attachment.bytesBase64!));
    final opened = await openAttachmentFile(
      fileName: attachment.name,
      localPath: kIsWeb ? null : attachment.path,
      bytes: bytes,
    );

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
    final cached = await _localCacheService.load();
    if (_isDisposed) return;

    if (cached == null) {
      _isLoadingLocalCache = false;
      notifyListeners();
      return;
    }

    _payload = cached;
    _selectedDate = _selectedDateForPayload(cached, _today);
    _isLoadingLocalCache = false;
    notifyListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed) return;
      _jumpDayStripToDate(_selectedDate);
    });
  }

  Future<void> _restoreAndSyncCloudState() async {
    var nextPayload = _payload;
    DateTime? nextSelectedDate;

    try {
      final remotePayload = await _cloudSyncService.fetchSyncCache();
      if (_shouldUseRemotePayload(_payload, remotePayload)) {
        nextPayload = remotePayload!;
        nextSelectedDate = _selectedDateForPayload(nextPayload, _selectedDate);
      }
    } catch (_) {
      // Keep local-first experience if cloud read fails.
    }

    _payload = await _persistPayload(nextPayload);
    if (_isDisposed) return;

    _selectedDate = nextSelectedDate ?? _selectedDate;
    _isLoadingLocalCache = false;
    notifyListeners();
  }

  Future<LocalCachePayload> _persistPayload(LocalCachePayload payload) async {
    await _localCacheService.save(payload);
    await _refreshDeviceState(payload);

    final syncedPayload = await _syncPayloadToCloud(payload);
    await _localCacheService.save(syncedPayload);
    return syncedPayload;
  }

  Future<void> _refreshDeviceState(LocalCachePayload payload) async {
    final events = [...payload.syncedEvents, ...payload.personalEvents]
      ..sort((a, b) => a.start.compareTo(b.start));
    await NotificationService.instance.rescheduleForEvents(events);
    await _widgetSyncService.updateTodayWidget(
      profile: payload.profile,
      events: events,
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
    dynamic snapshot,
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

  DateTime _selectedDateForPayload(
    LocalCachePayload payload,
    DateTime fallback,
  ) {
    final lastSyncedAt = payload.lastSyncedAt;
    if (lastSyncedAt == null) {
      return _normalizedDate(fallback);
    }
    return _normalizedDate(lastSyncedAt);
  }

  DateTime _normalizedDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
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
