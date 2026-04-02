import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/event_attachment.dart';
import '../models/grade_item.dart';
import '../models/program_subject.dart';
import '../models/school_sync_snapshot.dart';
import '../models/student_event.dart';
import '../models/student_profile.dart';
import '../models/weather_forecast.dart';
import 'account_page.dart';
import 'grades_page.dart';
import 'schedule_page.dart';
import 'sync_page.dart';
import '../services/attachment_opener.dart';
import '../services/attachment_storage_service.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/local_cache_service.dart';
import '../services/notification_service.dart';
import '../services/school_api_service.dart';
import '../services/weather_service.dart';
import '../services/widget_sync_service.dart';
import '../widgets/home/home_common_widgets.dart';
import '../widgets/home/home_dialogs.dart';
import '../widgets/home/home_editors.dart';
import '../widgets/home/home_sheet_models.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const int _pastDayRange = 365;
  static const int _futureDayRange = 365;
  static const double _dayTileWidth = 72;
  static const double _dayTileSpacing = 10;

  final SchoolApiService _schoolApiService = SchoolApiService();
  final LocalCacheService _localCacheService = LocalCacheService();
  final AttachmentStorageService _attachmentStorageService =
      AttachmentStorageService();
  final AuthService _authService = AuthService();
  final CloudSyncService _cloudSyncService = CloudSyncService();
  final WeatherService _weatherService = WeatherService();
  final WidgetSyncService _widgetSyncService = WidgetSyncService();
  final ScrollController _dayStripController = ScrollController();

  late final DateTime _today;
  late DateTime _selectedDate;

  List<StudentEvent> _syncedEvents = const [];
  List<StudentEvent> _personalEvents = const [];
  List<GradeItem> _grades = const [];
  List<ProgramSubject> _curriculumSubjects = const [];
  List<Map<String, dynamic>> _curriculumRawItems = const [];
  StudentProfile? _profile;
  DateTime? _lastSyncedAt;
  WeatherForecast? _weatherForecast;

  bool _isSyncing = false;
  bool _isLoadingLocalCache = true;
  bool _isLoadingWeather = true;
  bool _showSyncReminder = true;
  int _currentTab = 0;
  User? _signedInUser;

  Timer? _syncReminderTimer;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _selectedDate = _today;

    _syncReminderTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() => _showSyncReminder = false);
    });

    _loadLocalCache();
    _loadWeatherForecast();
    if (_authService.isAvailable) {
      _signedInUser = _authService.currentUser;
      _authSubscription = _authService.authStateChanges().listen((user) {
        if (!mounted) return;
        setState(() => _signedInUser = user);
        if (user != null) {
          unawaited(_restoreAndSyncCloudState());
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpDayStripToDate(_selectedDate);
    });
  }

  Future<void> _loadWeatherForecast() async {
    setState(() => _isLoadingWeather = true);
    try {
      final forecast = await _weatherService.fetchForecast();
      if (!mounted) return;
      setState(() {
        _weatherForecast = forecast;
        _isLoadingWeather = false;
      });
    } on WeatherException {
      if (!mounted) return;
      setState(() => _isLoadingWeather = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingWeather = false);
    }
  }

  @override
  void dispose() {
    _syncReminderTimer?.cancel();
    _authSubscription?.cancel();
    _dayStripController.dispose();
    super.dispose();
  }

  List<StudentEvent> get _allEvents {
    final events = [..._syncedEvents, ..._personalEvents]
      ..sort((a, b) => a.start.compareTo(b.start));
    return events;
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _buildSchedulePage(),
      _buildGradesPage(context),
      _buildSyncPage(),
      _buildAccountPage(),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _currentTab, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (index) {
          setState(() => _currentTab = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Lịch',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Điểm',
          ),
          NavigationDestination(
            icon: Icon(Icons.sync_outlined),
            selectedIcon: Icon(Icons.sync),
            label: 'Đồng bộ',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
      floatingActionButton: _currentTab == 0
          ? FloatingActionButton(
              onPressed: _showAddTaskSheet,
              tooltip: 'Thêm việc',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildSchedulePage() {
    final eventsForDay = _eventsForDay(_selectedDate);

    return SchedulePage(
      eventsForDay: eventsForDay,
      selectedDate: _selectedDate,
      profile: _profile,
      lastSyncedAt: _lastSyncedAt,
      weatherForecast: _weatherForecast,
      weatherService: _weatherService,
      isLoadingLocalCache: _isLoadingLocalCache,
      isLoadingWeather: _isLoadingWeather,
      showSyncReminder: _showSyncReminder,
      dayStripController: _dayStripController,
      dayStripItemCount: _pastDayRange + _futureDayRange + 1,
      dayTileSpacing: _dayTileSpacing,
      dateForIndex: _dateForIndex,
      indicatorsForDate: (date) => _indicatorColors(_eventsForDay(date)),
      isSameDate: _isSameDate,
      formatFullDate: _formatFullDate,
      formatTime: _formatTime,
      formatSyncTimestamp: _formatSyncTimestamp,
      onHideSyncReminder: () {
        if (!mounted) return;
        setState(() => _showSyncReminder = false);
      },
      onOpenMonthPicker: _openMonthPicker,
      onOpenSyncTab: () => setState(() => _currentTab = 2),
      onAddTask: _showAddTaskSheet,
      onSelectDate: (date) {
        setState(() => _selectedDate = date);
        _scrollDayStripToDate(date);
      },
      onEditEvent: _showEditNoteSheet,
      onDeleteEvent: _confirmDeletePersonalEvent,
      onOpenAttachment: _openAttachment,
      onToggleDone: _toggleDone,
      onReloadWeather: _loadWeatherForecast,
    );
  }

  Widget _buildGradesPage(BuildContext context) {
    return GradesPage(
      grades: _grades,
      curriculumSubjects: _curriculumSubjects,
      curriculumRawItems: _curriculumRawItems,
      emptyState: EmptyStateCard(
        icon: Icons.school_outlined,
        title: 'Chưa có bảng điểm',
        description:
            'Hãy chuyển sang trang Đồng bộ để đăng nhập và tải dữ liệu mới nhất.',
        actionLabel: 'Mở đồng bộ',
        onAction: () => setState(() => _currentTab = 2),
      ),
    );
  }

  Widget _buildSyncPage() {
    return SyncPage(
      isSyncing: _isSyncing,
      onSync: _openSyncDialog,
      lastSyncedAt: _lastSyncedAt,
      profile: _profile,
      syncedEventCount: _syncedEvents.length,
      gradeCount: _grades.length,
      personalEventCount: _personalEvents.length,
    );
  }

  Widget _buildAccountPage() {
    return AccountPage(
      isAuthAvailable: _authService.isAvailable,
      user: _signedInUser,
      onEmailAuth: _openEmailAuthSheet,
      onGoogleAuth: _signInWithGoogle,
      onSignOut: _signOut,
    );
  }

  Future<void> _openMonthPicker() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => MonthPickerDialog(
        initialDate: _selectedDate,
        firstDate: _today.subtract(const Duration(days: _pastDayRange)),
        lastDate: _today.add(const Duration(days: _futureDayRange)),
        eventLevelForDate: _eventLevelForDate,
      ),
    );

    if (picked == null || !mounted) return;

    final normalized = DateTime(picked.year, picked.month, picked.day);
    setState(() => _selectedDate = normalized);
    _scrollDayStripToDate(normalized);
  }

  Future<void> _openSyncDialog() async {
    final credentials = await showDialog<CredentialsResult>(
      context: context,
      builder: (context) => const SyncCredentialsDialog(),
    );

    if (credentials == null || !mounted) return;

    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    await _syncData(credentials.username, credentials.password);
  }

  Future<void> _syncData(String username, String password) async {
    setState(() => _isSyncing = true);

    try {
      final snapshot = await _schoolApiService.sync(
        username: username,
        password: password,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đồng bộ thành công.')),
      );
      _applySnapshot(snapshot);
      await _persistLocalCache();
      unawaited(_syncCurrentStateToCloud());
    } on SchoolApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã có lỗi xảy ra khi đồng bộ. Vui lòng thử lại sau.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  void _applySnapshot(SchoolSyncSnapshot snapshot) {
    final isDifferentStudent =
        _profile?.username.trim().isNotEmpty == true &&
        _profile!.username.trim() != snapshot.profile.username.trim();

    setState(() {
      _profile = snapshot.profile;
      _grades = snapshot.grades;
      _curriculumSubjects = snapshot.curriculumSubjects;
      _curriculumRawItems = snapshot.curriculumRawItems;
      _syncedEvents = snapshot.events;
      if (isDifferentStudent) {
        _personalEvents = const [];
      }
      _lastSyncedAt = snapshot.syncedAt;
      _selectedDate = DateTime(
        snapshot.syncedAt.year,
        snapshot.syncedAt.month,
        snapshot.syncedAt.day,
      );
      _showSyncReminder = false;
      _currentTab = 0;
    });

    unawaited(_refreshDeviceState());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollDayStripToDate(_selectedDate);
    });
  }

  Future<void> _showAddTaskSheet() async {
    final result = await showModalBottomSheet<TaskEditorResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => EnhancedTaskEditorSheet(initialDate: _selectedDate),
    );

    if (result == null || !mounted) return;

    final start = DateTime(
      result.date.year,
      result.date.month,
      result.date.day,
      result.hour.hour,
      result.hour.minute,
    );

    final updatedPersonalEvents = await _attachmentStorageService
        .persistEvents([
          ..._personalEvents,
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

    setState(() {
      _personalEvents = updatedPersonalEvents
        ..sort((a, b) => a.start.compareTo(b.start));
      _selectedDate = DateTime(
        result.date.year,
        result.date.month,
        result.date.day,
      );
    });

    _scrollDayStripToDate(_selectedDate);
    await _persistLocalCache();
    await _refreshDeviceState();
    unawaited(_syncCurrentStateToCloud());
  }

  Future<void> _showEditNoteSheet(StudentEvent event) async {
    final result = await showModalBottomSheet<NoteEditorResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => EnhancedNoteEditorSheet(event: event),
    );

    if (result == null || !mounted) return;

    if (result.deleteEvent && event.type == StudentEventType.personalTask) {
      setState(() {
        _personalEvents = _personalEvents
            .where((item) => item.id != event.id)
            .toList();
      });
      await _persistLocalCache();
      await _refreshDeviceState();
      unawaited(_syncCurrentStateToCloud());
      return;
    }

    final trimmed = result.note.trim();
    final updatedPersonalEvents = await _attachmentStorageService.persistEvents(
      _personalEvents.map((item) {
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
      _syncedEvents.map((item) {
        if (item.id != event.id) return item;
        return item.copyWith(
          note: trimmed.isEmpty ? null : trimmed,
          attachments: result.attachments,
        );
      }).toList(),
    );
    setState(() {
      _personalEvents = updatedPersonalEvents;
      _syncedEvents = updatedSyncedEvents;
    });
    await _persistLocalCache();
    await _refreshDeviceState();
    unawaited(_syncCurrentStateToCloud());
  }

  Future<void> _confirmDeletePersonalEvent(StudentEvent event) async {
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

    if (confirmed != true || !mounted) return;
    setState(() {
      _personalEvents = _personalEvents
          .where((item) => item.id != event.id)
          .toList();
    });
    await _persistLocalCache();
    await _refreshDeviceState();
    unawaited(_syncCurrentStateToCloud());
  }

  void _toggleDone(String id) {
    setState(() {
      _personalEvents = _personalEvents.map((event) {
        if (event.id != id) return event;
        return event.copyWith(isDone: !event.isDone);
      }).toList();
    });
    unawaited(_persistLocalCache());
    unawaited(_refreshDeviceState());
    unawaited(_syncCurrentStateToCloud());
  }

  Future<void> _openAttachment(EventAttachment attachment) async {
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

    if (opened) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Không thể mở tệp đính kèm. Vui lòng thử lại.'),
      ),
    );
  }

  Future<void> _loadLocalCache() async {
    final cached = await _localCacheService.load();
    if (!mounted) return;

    if (cached != null) {
      _applyLocalCachePayload(cached, switchToScheduleTab: false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _jumpDayStripToDate(_selectedDate);
      });
    } else {
      setState(() => _isLoadingLocalCache = false);
    }
  }

  Future<void> _persistLocalCache() {
    return _localCacheService.save(_buildCurrentPayload());
  }

  Future<void> _refreshDeviceState() async {
    await NotificationService.instance.rescheduleForEvents(_allEvents);
    await _widgetSyncService.updateTodayWidget(
      profile: _profile,
      events: _allEvents,
    );
  }

  Future<void> _restoreAndSyncCloudState() async {
    if (_signedInUser == null || !_cloudSyncService.isConfigured) return;

    try {
      final remotePayload = await _cloudSyncService.fetchSyncCache();
      if (!mounted) return;

      final localPayload = _buildCurrentPayload();
      if (_shouldUseRemotePayload(localPayload, remotePayload)) {
        _applyLocalCachePayload(remotePayload!, switchToScheduleTab: false);
        await _persistLocalCache();
      }
    } catch (_) {
      // Keep local-first experience if cloud read fails.
    }

    await _syncCurrentStateToCloud();
  }

  Future<void> _syncCurrentStateToCloud() async {
    if (_signedInUser == null || !_cloudSyncService.isConfigured) return;

    final updatedSyncedEvents = await _uploadMissingAttachments(_syncedEvents);
    final updatedPersonalEvents = await _uploadMissingAttachments(
      _personalEvents,
    );

    if (!mounted) return;
    setState(() {
      _syncedEvents = updatedSyncedEvents;
      _personalEvents = updatedPersonalEvents;
    });

    final payload = _buildCurrentPayload(
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

    await _cloudSyncService.saveSyncCache(payload);
    await _persistLocalCache();
  }

  LocalCachePayload _buildCurrentPayload({
    List<StudentEvent>? syncedEvents,
    List<StudentEvent>? personalEvents,
  }) {
    return LocalCachePayload(
      profile: _profile,
      grades: _grades,
      curriculumSubjects: _curriculumSubjects,
      curriculumRawItems: _curriculumRawItems,
      syncedEvents: syncedEvents ?? _syncedEvents,
      personalEvents: personalEvents ?? _personalEvents,
      lastSyncedAt: _lastSyncedAt,
    );
  }

  void _applyLocalCachePayload(
    LocalCachePayload payload, {
    required bool switchToScheduleTab,
  }) {
    setState(() {
      _profile = payload.profile;
      _grades = payload.grades;
      _curriculumSubjects = payload.curriculumSubjects;
      _curriculumRawItems = payload.curriculumRawItems;
      _syncedEvents = payload.syncedEvents;
      _personalEvents = payload.personalEvents;
      _lastSyncedAt = payload.lastSyncedAt;
      _selectedDate = payload.lastSyncedAt == null
          ? _today
          : DateTime(
              payload.lastSyncedAt!.year,
              payload.lastSyncedAt!.month,
              payload.lastSyncedAt!.day,
            );
      _isLoadingLocalCache = false;
      if (switchToScheduleTab) {
        _currentTab = 0;
      }
    });
    unawaited(_refreshDeviceState());
  }

  bool _shouldUseRemotePayload(
    LocalCachePayload localPayload,
    LocalCachePayload? remotePayload,
  ) {
    if (remotePayload == null) return false;
    final hasLocalData =
        localPayload.profile != null ||
        localPayload.grades.isNotEmpty ||
        localPayload.syncedEvents.isNotEmpty ||
        localPayload.personalEvents.isNotEmpty;
    if (!hasLocalData) return true;

    final remoteTime = remotePayload.lastSyncedAt;
    final localTime = localPayload.lastSyncedAt;
    if (remoteTime == null) return false;
    if (localTime == null) return true;
    return remoteTime.isAfter(localTime);
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

  Future<void> _openEmailAuthSheet() async {
    final result = await showModalBottomSheet<EmailAuthResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const EmailAuthSheet(),
    );
    if (result == null) return;

    try {
      if (result.mode == EmailAuthMode.signIn) {
        await _authService.signInWithEmail(
          email: result.email,
          password: result.password,
        );
      } else {
        await _authService.registerWithEmail(
          email: result.email,
          password: result.password,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng nhập thành công.'),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Không thể đăng nhập.')),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      await _authService.signInWithGoogle();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đăng nhập Google.')),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Không thể đăng nhập Google.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể đăng nhập Google.')),
      );
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã đăng xuất tài khoản ứng dụng.'),
      ),
    );
  }

  List<StudentEvent> _eventsForDay(DateTime date) {
    return _allEvents.where((event) => _isSameDate(event.start, date)).toList();
  }

  List<Color> _indicatorColors(List<StudentEvent> events) {
    if (events.isEmpty) return const [];

    final colors = <Color>{};
    for (final event in events) {
      if (event.type == StudentEventType.exam) {
        colors.add(const Color(0xFFC62828));
      } else {
        colors.add(const Color(0xFF9AA0A6));
      }
    }
    return colors.take(2).toList();
  }

  CalendarEventLevel _eventLevelForDate(DateTime date) {
    final events = _eventsForDay(date);
    if (events.any((event) => event.type == StudentEventType.exam)) {
      return CalendarEventLevel.important;
    }
    if (events.isNotEmpty) {
      return CalendarEventLevel.normal;
    }
    return CalendarEventLevel.none;
  }

  DateTime _dateForIndex(int index) {
    final offset = index - _pastDayRange;
    return _today.add(Duration(days: offset));
  }

  int _indexForDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.difference(_today).inDays + _pastDayRange;
  }

  void _jumpDayStripToDate(DateTime date) {
    if (!_dayStripController.hasClients) return;
    final offset = _indexForDate(date) * (_dayTileWidth + _dayTileSpacing);
    _dayStripController.jumpTo(
      offset.clamp(0.0, _dayStripController.position.maxScrollExtent),
    );
  }

  void _scrollDayStripToDate(DateTime date) {
    if (!_dayStripController.hasClients) return;
    final offset = _indexForDate(date) * (_dayTileWidth + _dayTileSpacing);
    _dayStripController.animateTo(
      offset.clamp(0.0, _dayStripController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  String _formatFullDate(DateTime date) {
    const weekdays = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tứ',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    const months = [
      'tháng 1',
      'tháng 2',
      'tháng 3',
      'tháng 4',
      'tháng 5',
      'tháng 6',
      'tháng 7',
      'tháng 8',
      'tháng 9',
      'tháng 10',
      'tháng 11',
      'tháng 12',
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  String _formatTime(DateTime value) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(value.hour)}:${twoDigits(value.minute)}';
  }

  String _formatSyncTimestamp(DateTime value) {
    return '${_formatTime(value)} ${value.day}/${value.month}/${value.year}';
  }

  bool _isSameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
