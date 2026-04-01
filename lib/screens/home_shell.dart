import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/event_attachment.dart';
import '../models/grade_item.dart';
import '../models/school_sync_snapshot.dart';
import '../models/student_event.dart';
import '../models/student_profile.dart';
import '../models/weather_forecast.dart';
import 'image_attachment_editor.dart';
import '../services/attachment_opener.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/local_cache_service.dart';
import '../services/school_api_service.dart';
import '../services/weather_service.dart';

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
  final AuthService _authService = AuthService();
  final CloudSyncService _cloudSyncService = CloudSyncService();
  final WeatherService _weatherService = WeatherService();
  final ScrollController _dayStripController = ScrollController();

  late final DateTime _today;
  late DateTime _selectedDate;

  List<StudentEvent> _syncedEvents = const [];
  List<StudentEvent> _personalEvents = const [];
  List<GradeItem> _grades = const [];
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
      _buildSchedulePage(context),
      _buildGradesPage(context),
      _buildSyncPage(context),
      _buildAccountPage(context),
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

  Widget _buildSchedulePage(BuildContext context) {
    final eventsForDay = _eventsForDay(_selectedDate);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profile == null
                      ? 'Lịch học tập'
                      : 'Xin chào, ${_profile!.displayName}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Theo dõi lịch học, lịch thi và việc cá nhân trong một dòng thời gian gọn gàng.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                if (_showSyncReminder) ...[
                  _buildSyncReminder(context),
                  const SizedBox(height: 16),
                ],
                _buildWeatherCard(context),
                const SizedBox(height: 16),
                _buildScheduleHeader(context),
                const SizedBox(height: 16),
                _buildDayStrip(context),
                const SizedBox(height: 20),
                _buildSelectedDateSummary(context, eventsForDay),
              ],
            ),
          ),
        ),
        if (_isLoadingLocalCache)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (eventsForDay.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: _EmptyState(
                icon: _profile == null
                    ? Icons.sync_rounded
                    : Icons.event_available_outlined,
                title: _profile == null
                    ? 'Chưa có dữ liệu từ cổng trường'
                    : 'Ngày này chưa có sự kiện',
                description: _profile == null
                    ? 'Mở trang Đồng bộ để đăng nhập và tải lịch học, lịch thi, bảng điểm.'
                    : 'Bạn có thể thêm việc cá nhân hoặc chọn ngày khác để xem lịch.',
                actionLabel: _profile == null ? 'Mở đồng bộ' : 'Thêm việc',
                onAction: _profile == null
                    ? () => setState(() => _currentTab = 2)
                    : _showAddTaskSheet,
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.builder(
              itemCount: eventsForDay.length,
              itemBuilder: (context, index) {
                final event = eventsForDay[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _EventCard(
                    event: event,
                    onEditNote: () => _showEditNoteSheet(event),
                    onDelete: event.type == StudentEventType.personalTask
                        ? () => _confirmDeletePersonalEvent(event)
                        : null,
                    onOpenAttachment: _openAttachment,
                    onToggleDone: event.type == StudentEventType.personalTask
                        ? () => _toggleDone(event.id)
                        : null,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildGradesPage(BuildContext context) {
    final totalCredits = _grades.fold<int>(
      0,
      (sum, item) => sum + item.credits,
    );
    final gpa = totalCredits == 0
        ? 0.0
        : _grades.fold<double>(
                0,
                (sum, item) => sum + (item.mark4 * item.credits),
              ) /
              totalCredits;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text('Bảng điểm', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Dữ liệu được lấy từ cổng trường sau mỗi lần đồng bộ.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (_grades.isEmpty)
          _EmptyState(
            icon: Icons.school_outlined,
            title: 'Chưa có bảng điểm',
            description:
                'Hãy chuyển sang trang Đồng bộ để đăng nhập và tải dữ liệu mới nhất.',
            actionLabel: 'Mở đồng bộ',
            onAction: () => setState(() => _currentTab = 2),
          )
        else ...[
          _GradesHeroCard(
            gpa: gpa,
            totalCredits: totalCredits,
            gradeCount: _grades.length,
          ),
          const SizedBox(height: 16),
          ..._grades.map(
            (grade) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _GradeCard(grade: grade),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWeatherCard(BuildContext context) {
    final forecast = _weatherForecast?.dayForDate(_selectedDate);
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoadingWeather) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(child: Text('Đang tải dự báo thời tiết...')),
          ],
        ),
      );
    }

    if (forecast == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_outlined),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Chưa tải được dự báo thời tiết cho ngày này.'),
            ),
            IconButton(
              tooltip: 'Tải lại',
              onPressed: _loadWeatherForecast,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      );
    }

    final suggestions = _weatherService.suggestionsForDay(forecast);
    final weatherDescription =
        _weatherService.descriptionForCode(forecast.weatherCode);
    final weatherIcon = _weatherService.iconForCode(forecast.weatherCode);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(weatherIcon, size: 28, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thời tiết ${_weatherForecast?.locationLabel ?? 'Hà Nội'}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      weatherDescription,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Tải lại',
                onPressed: _loadWeatherForecast,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _WeatherMetricChip(
                icon: Icons.thermostat_outlined,
                label:
                    '${forecast.temperatureMin.round()}° - ${forecast.temperatureMax.round()}°',
              ),
              _WeatherMetricChip(
                icon: Icons.umbrella_outlined,
                label: 'Mưa ${forecast.precipitationProbabilityMax}%',
              ),
              _WeatherMetricChip(
                icon: Icons.air,
                label: 'Gió ${forecast.windSpeedMax.round()} km/h',
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...suggestions.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncPage(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          'Đồng bộ dữ liệu',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Đồng bộ chỉ dùng để lấy dữ liệu thật từ cổng trường. Không cần đăng nhập tài khoản ứng dụng để đồng bộ.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        _SyncActionCard(
          isSyncing: _isSyncing,
          onSync: _openSyncDialog,
          lastSyncedAt: _lastSyncedAt,
        ),
        const SizedBox(height: 16),
        if (_profile != null)
          _ProfileCard(profile: _profile!)
        else
          const _PlaceholderInfoCard(
            icon: Icons.account_circle_outlined,
            title: 'Chưa đăng nhập',
            description:
                'Sau khi đồng bộ lần đầu, thông tin sinh viên từ cổng trường sẽ hiển thị tại đây.',
          ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              icon: Icons.event_note_outlined,
              label: 'Sự kiện',
              value: _syncedEvents.length.toString(),
            ),
            _MetricCard(
              icon: Icons.school_outlined,
              label: 'Môn có điểm',
              value: _grades.length.toString(),
            ),
            _MetricCard(
              icon: Icons.task_alt_outlined,
              label: 'Việc cá nhân',
              value: _personalEvents.length.toString(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountPage(BuildContext context) {
    final user = _signedInUser;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text('Tài khoản', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Đăng nhập là tùy chọn. Tài khoản chỉ dùng để đồng bộ ghi chú, tệp đính kèm và dữ liệu đã lưu lên cloud.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (!_authService.isAvailable)
          const _PlaceholderInfoCard(
            icon: Icons.cloud_off_outlined,
            title: 'Firebase chưa sẵn sàng',
            description:
                'App chưa khởi tạo Firebase. Hãy kiểm tra cấu hình Firebase nếu muốn đăng nhập.',
          )
        else if (user == null)
          _AuthEntryCard(
            onEmailAuth: _openEmailAuthSheet,
            onGoogleAuth: _signInWithGoogle,
          )
        else
          _SignedInCard(user: user, onSignOut: _signOut),
        const SizedBox(height: 16),
        const _PlaceholderInfoCard(
          icon: Icons.offline_bolt_outlined,
          title: 'Chế độ offline',
          description:
              'Dữ liệu đồng bộ, ghi chú và việc cá nhân hiện đã được lưu lại trên điện thoại để bạn mở app lần sau vẫn xem được.',
        ),
      ],
    );
  }

  Widget _buildSyncReminder(BuildContext context) {
    return Dismissible(
      key: const ValueKey('sync-reminder'),
      direction: DismissDirection.up,
      onDismissed: (_) {
        if (!mounted) return;
        setState(() => _showSyncReminder = false);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Hãy thường xuyên đồng bộ để đảm bảo dữ liệu luôn mới nhất.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _showSyncReminder = false),
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.close,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ngày đã chọn',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatFullDate(_selectedDate),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Chọn ngày',
          onPressed: _openMonthPicker,
          icon: const Icon(Icons.calendar_month_outlined),
        ),
      ],
    );
  }

  Widget _buildDayStrip(BuildContext context) {
    final itemCount = _pastDayRange + _futureDayRange + 1;

    return SizedBox(
      height: 104,
      child: ListView.builder(
        controller: _dayStripController,
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          final date = _dateForIndex(index);
          final indicators = _indicatorColors(_eventsForDay(date));

          return Padding(
            padding: EdgeInsets.only(
              right: index == itemCount - 1 ? 0 : _dayTileSpacing,
            ),
            child: _DayChip(
              date: date,
              isSelected: _isSameDate(date, _selectedDate),
              indicators: indicators,
              onTap: () {
                setState(() => _selectedDate = date);
                _scrollDayStripToDate(date);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedDateSummary(
    BuildContext context,
    List<StudentEvent> eventsForDay,
  ) {
    final classCount = eventsForDay
        .where((event) => event.type == StudentEventType.classSchedule)
        .length;
    final examCount = eventsForDay
        .where((event) => event.type == StudentEventType.exam)
        .length;
    final taskCount = eventsForDay
        .where((event) => event.type == StudentEventType.personalTask)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CountPill(label: 'Lịch học', count: classCount),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _CountPill(
              label: 'Lịch thi',
              count: examCount,
              accent: const Color(0xFFC62828),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _CountPill(label: 'Việc riêng', count: taskCount),
          ),
        ],
      ),
    );
  }

  Future<void> _openMonthPicker() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => _MonthPickerDialog(
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
    final credentials = await showDialog<_CredentialsResult>(
      context: context,
      builder: (context) => const _SyncCredentialsDialog(),
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
        const SnackBar(content: Text('Đồng bộ dữ liệu thành công.')),
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
          content: Text('Có lỗi xảy ra khi đồng bộ dữ liệu. Vui lòng thử lại.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  void _applySnapshot(SchoolSyncSnapshot snapshot) {
    setState(() {
      _profile = snapshot.profile;
      _grades = snapshot.grades;
      _syncedEvents = snapshot.events;
      _lastSyncedAt = snapshot.syncedAt;
      _selectedDate = DateTime(
        snapshot.syncedAt.year,
        snapshot.syncedAt.month,
        snapshot.syncedAt.day,
      );
      _showSyncReminder = false;
      _currentTab = 0;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollDayStripToDate(_selectedDate);
    });
  }

  Future<void> _showAddTaskSheet() async {
    final result = await showModalBottomSheet<_TaskEditorResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          _EnhancedTaskEditorSheet(initialDate: _selectedDate),
    );

    if (result == null || !mounted) return;

    final start = DateTime(
      result.date.year,
      result.date.month,
      result.date.day,
      result.hour.hour,
      result.hour.minute,
    );

    setState(() {
      _personalEvents = [
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
      ]..sort((a, b) => a.start.compareTo(b.start));

      _selectedDate = DateTime(
        result.date.year,
        result.date.month,
        result.date.day,
      );
    });

    _scrollDayStripToDate(_selectedDate);
    await _persistLocalCache();
    unawaited(_syncCurrentStateToCloud());
  }

  Future<void> _showEditNoteSheet(StudentEvent event) async {
    final result = await showModalBottomSheet<_NoteEditorResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _EnhancedNoteEditorSheet(event: event),
    );

    if (result == null || !mounted) return;

    if (result.deleteEvent && event.type == StudentEventType.personalTask) {
      setState(() {
        _personalEvents = _personalEvents
            .where((item) => item.id != event.id)
            .toList();
      });
      await _persistLocalCache();
      unawaited(_syncCurrentStateToCloud());
      return;
    }

    final trimmed = result.note.trim();
    setState(() {
      _personalEvents = _personalEvents.map((item) {
        if (item.id != event.id) return item;
        return item.copyWith(
          title: item.type == StudentEventType.personalTask
              ? result.title?.trim()
              : item.title,
          note: trimmed.isEmpty ? null : trimmed,
          attachments: result.attachments,
        );
      }).toList();

      _syncedEvents = _syncedEvents.map((item) {
        if (item.id != event.id) return item;
        return item.copyWith(
          note: trimmed.isEmpty ? null : trimmed,
          attachments: result.attachments,
        );
      }).toList();
    });
    await _persistLocalCache();
    unawaited(_syncCurrentStateToCloud());
  }

  Future<void> _confirmDeletePersonalEvent(StudentEvent event) async {
    if (event.type != StudentEventType.personalTask) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ghi chú cá nhân?'),
        content: Text('Ghi chú "${event.title}" sẽ bị xóa khỏi thiết bị và cloud.'),
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
    unawaited(_syncCurrentStateToCloud());
  }

  Future<void> _openAttachment(EventAttachment attachment) async {
    final bytes = attachment.bytesBase64 == null
        ? await _cloudSyncService.downloadAttachmentBytes(attachment)
        : base64Decode(attachment.bytesBase64!);
    final opened = await openAttachmentFile(
      fileName: attachment.name,
      localPath: kIsWeb ? null : attachment.path,
      bytes: bytes,
    );

    if (opened) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Không tìm thấy tệp đính kèm để mở.')),
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
    final updatedPersonalEvents = await _uploadMissingAttachments(_personalEvents);

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
    final result = await showModalBottomSheet<_EmailAuthResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _EmailAuthSheet(),
    );
    if (result == null) return;

    try {
      if (result.mode == _EmailAuthMode.signIn) {
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
        const SnackBar(content: Text('Đăng nhập tài khoản thành công.')),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã đăng nhập Google.')));
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Không thể đăng nhập Google.')),
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
      const SnackBar(content: Text('Đã đăng xuất tài khoản ứng dụng.')),
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

  _CalendarEventLevel _eventLevelForDate(DateTime date) {
    final events = _eventsForDay(date);
    if (events.any((event) => event.type == StudentEventType.exam)) {
      return _CalendarEventLevel.important;
    }
    if (events.isNotEmpty) {
      return _CalendarEventLevel.normal;
    }
    return _CalendarEventLevel.none;
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
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ nhật',
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

  bool _isSameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}

enum _CalendarEventLevel { none, normal, important }

class _MonthPickerDialog extends StatefulWidget {
  const _MonthPickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.eventLevelForDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final _CalendarEventLevel Function(DateTime date) eventLevelForDate;

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      1,
    );
    final firstAllowedMonth = DateTime(
      widget.firstDate.year,
      widget.firstDate.month,
    );
    final lastAllowedMonth = DateTime(
      widget.lastDate.year,
      widget.lastDate.month,
    );
    final daysInMonth = DateUtils.getDaysInMonth(
      _displayedMonth.year,
      _displayedMonth.month,
    );
    final leadingEmptyCount = firstOfMonth.weekday - 1;
    final totalCells = leadingEmptyCount + daysInMonth;
    final canGoPrevious = _displayedMonth.isAfter(firstAllowedMonth);
    final canGoNext = _displayedMonth.isBefore(lastAllowedMonth);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  _monthLabel(_displayedMonth),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  onPressed: canGoPrevious ? _goToPreviousMonth : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  onPressed: canGoNext ? _goToNextMonth : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                _WeekdayCell(label: 'T2'),
                _WeekdayCell(label: 'T3'),
                _WeekdayCell(label: 'T4'),
                _WeekdayCell(label: 'T5'),
                _WeekdayCell(label: 'T6'),
                _WeekdayCell(label: 'T7'),
                _WeekdayCell(label: 'CN'),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalCells,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.88,
              ),
              itemBuilder: (context, index) {
                if (index < leadingEmptyCount) {
                  return const SizedBox.shrink();
                }

                final day = index - leadingEmptyCount + 1;
                final date = DateTime(
                  _displayedMonth.year,
                  _displayedMonth.month,
                  day,
                );
                final isSelected = DateUtils.isSameDay(
                  date,
                  widget.initialDate,
                );
                final isOutOfRange =
                    date.isBefore(
                      DateTime(
                        widget.firstDate.year,
                        widget.firstDate.month,
                        widget.firstDate.day,
                      ),
                    ) ||
                    date.isAfter(
                      DateTime(
                        widget.lastDate.year,
                        widget.lastDate.month,
                        widget.lastDate.day,
                      ),
                    );

                return _MonthDayCell(
                  date: date,
                  isSelected: isSelected,
                  isDisabled: isOutOfRange,
                  eventLevel: widget.eventLevelForDate(date),
                  onTap: isOutOfRange
                      ? null
                      : () => Navigator.of(context).pop(date),
                );
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToPreviousMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
      );
    });
  }

  void _goToNextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
      );
    });
  }

  String _monthLabel(DateTime date) {
    return 'Tháng ${date.month}/${date.year}';
  }
}

class _WeekdayCell extends StatelessWidget {
  const _WeekdayCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.date,
    required this.isSelected,
    required this.isDisabled,
    required this.eventLevel,
    this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool isDisabled;
  final _CalendarEventLevel eventLevel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = isDisabled
        ? colorScheme.onSurface.withValues(alpha: 0.28)
        : isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;
    final background = isSelected ? colorScheme.primaryContainer : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: foreground,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            _MonthEventDot(level: eventLevel),
          ],
        ),
      ),
    );
  }
}

class _MonthEventDot extends StatelessWidget {
  const _MonthEventDot({required this.level});

  final _CalendarEventLevel level;

  @override
  Widget build(BuildContext context) {
    if (level == _CalendarEventLevel.none) {
      return const SizedBox(height: 6);
    }

    final color = switch (level) {
      _CalendarEventLevel.important => const Color(0xFFC62828),
      _CalendarEventLevel.normal => const Color(0xFF9AA0A6),
      _CalendarEventLevel.none => Colors.transparent,
    };

    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.date,
    required this.isSelected,
    required this.indicators,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final List<Color> indicators;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final colorScheme = Theme.of(context).colorScheme;
    final background = isSelected
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerLow;
    final foreground = isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 72,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.18)
                : colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              labels[date.weekday - 1],
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: foreground.withValues(alpha: 0.8),
              ),
            ),
            Text(
              '${date.day}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: indicators.isEmpty
                  ? const [SizedBox(height: 8, width: 8)]
                  : indicators
                        .map(
                          (color) => Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                        .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.onEditNote,
    this.onDelete,
    required this.onOpenAttachment,
    this.onToggleDone,
  });

  final StudentEvent event;
  final VoidCallback onEditNote;
  final VoidCallback? onDelete;
  final ValueChanged<EventAttachment> onOpenAttachment;
  final VoidCallback? onToggleDone;

  @override
  Widget build(BuildContext context) {
    final isTask = event.type == StudentEventType.personalTask;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EventTypeBadge(event: event),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    decoration: event.isDone
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              if (isTask)
                Checkbox(
                  value: event.isDone,
                  onChanged: (_) => onToggleDone?.call(),
                ),
              if (isTask)
                IconButton(
                  tooltip: 'Xóa ghi chú cá nhân',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _LabeledValueRow(label: 'Thời gian', value: _eventTimeRange(event)),
          if ((event.subtitle ?? '').isNotEmpty &&
              !_isRedundantSubtitle(event.subtitle!, event.type)) ...[
            const SizedBox(height: 8),
            _LabeledValueRow(
              label: event.type == StudentEventType.exam
                  ? 'Ca thi'
                  : 'Giảng viên',
              value: event.subtitle!,
            ),
          ],
          if ((event.location ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            _LabeledValueRow(
              label: event.type == StudentEventType.exam
                  ? 'Phòng thi'
                  : 'Phòng học',
              value: event.location!,
            ),
          ],
          if ((event.referenceCode ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            _LabeledValueRow(label: 'Số báo danh', value: event.referenceCode!),
          ],
          if ((event.note ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            _LabeledValueRow(
              label: event.type == StudentEventType.exam
                  ? 'Đợt thi'
                  : 'Ghi chú',
              value: event.note!,
              maxLines: 2,
            ),
          ],
          if (event.attachments.isNotEmpty) ...[
            const SizedBox(height: 8),
            _AttachmentSection(
              attachments: event.attachments,
              onOpenAttachment: onOpenAttachment,
            ),
          ],
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onEditNote,
              icon: const Icon(Icons.edit_note),
              label: Text(isTask ? 'Sửa ghi chú' : 'Ghi chú'),
            ),
          ),
        ],
      ),
    );
  }

  bool _isRedundantSubtitle(String subtitle, StudentEventType type) {
    if (type != StudentEventType.classSchedule) return false;
    return subtitle.trim().toLowerCase() == 'lịch học';
  }

  String _eventTimeRange(StudentEvent event) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(event.start.hour)}:${twoDigits(event.start.minute)} - '
        '${twoDigits(event.end.hour)}:${twoDigits(event.end.minute)}';
  }
}

class _EventTypeBadge extends StatelessWidget {
  const _EventTypeBadge({required this.event});

  final StudentEvent event;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (event.type) {
      StudentEventType.exam => ('Lịch thi', const Color(0xFFC62828)),
      StudentEventType.classSchedule => ('Lịch học', const Color(0xFF3559A8)),
      StudentEventType.personalTask => (
        'Việc cá nhân',
        const Color(0xFF2E7D32),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledValueRow extends StatelessWidget {
  const _LabeledValueRow({
    required this.label,
    required this.value,
    this.maxLines,
  });

  final String label;
  final String value;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: maxLines,
            overflow: maxLines == null ? null : TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _AttachmentSection extends StatelessWidget {
  const _AttachmentSection({
    required this.attachments,
    required this.onOpenAttachment,
  });

  final List<EventAttachment> attachments;
  final ValueChanged<EventAttachment> onOpenAttachment;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 84,
          child: Text(
            'Tệp đính kèm',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: attachments
                .map(
                  (attachment) => ActionChip(
                    avatar: Icon(_attachmentIcon(attachment), size: 18),
                    label: Text(attachment.name),
                    onPressed: () => onOpenAttachment(attachment),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  IconData _attachmentIcon(EventAttachment attachment) {
    if (attachment.isPdf) return Icons.picture_as_pdf_outlined;
    if (attachment.isImage) return Icons.image_outlined;
    return Icons.attach_file_outlined;
  }
}

class _GradesHeroCard extends StatelessWidget {
  const _GradesHeroCard({
    required this.gpa,
    required this.totalCredits,
    required this.gradeCount,
  });

  final double gpa;
  final int totalCredits;
  final int gradeCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng quan kết quả',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            gpa.toStringAsFixed(2),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$gradeCount môn đã có điểm • $totalCredits tín chỉ',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({required this.grade});

  final GradeItem grade;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grade.subjectName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${grade.subjectCode} • ${grade.credits} tín chỉ',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                grade.mark10.toStringAsFixed(1),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                'Hệ 4: ${grade.mark4.toStringAsFixed(1)} • ${grade.letter}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SyncActionCard extends StatelessWidget {
  const _SyncActionCard({
    required this.isSyncing,
    required this.onSync,
    required this.lastSyncedAt,
  });

  final bool isSyncing;
  final VoidCallback onSync;
  final DateTime? lastSyncedAt;

  @override
  Widget build(BuildContext context) {
    final label = isSyncing ? 'Đang đồng bộ...' : 'Đồng bộ ngay';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cập nhật dữ liệu',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            lastSyncedAt == null
                ? 'Bạn chưa đồng bộ lần nào.'
                : 'Lần gần nhất: ${_formatTimestamp(lastSyncedAt!)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: isSyncing ? null : onSync,
            icon: isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: Text(label),
          ),
        ],
      ),
    );
  }

  static String _formatTimestamp(DateTime value) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(value.hour)}:${twoDigits(value.minute)} '
        '${value.day}/${value.month}/${value.year}';
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});

  final StudentProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile.displayName,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _ProfileLine(label: 'Tài khoản', value: profile.username),
          if ((profile.studentCode ?? '').isNotEmpty)
            _ProfileLine(label: 'Mã sinh viên', value: profile.studentCode!),
          if ((profile.className ?? '').isNotEmpty)
            _ProfileLine(label: 'Lớp', value: profile.className!),
        ],
      ),
    );
  }
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label, required this.count, this.accent});

  final String label;
  final int count;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(label),
        ],
      ),
    );
  }
}

class _PlaceholderInfoCard extends StatelessWidget {
  const _PlaceholderInfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthEntryCard extends StatelessWidget {
  const _AuthEntryCard({required this.onEmailAuth, required this.onGoogleAuth});

  final Future<void> Function() onEmailAuth;
  final Future<void> Function() onGoogleAuth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Đăng nhập để lưu cloud',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Tài khoản ứng dụng được dùng để lưu ghi chú, tệp đính kèm và dữ liệu đồng bộ lên Firebase/Cloudflare.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onGoogleAuth,
            icon: const Icon(Icons.account_circle_outlined),
            label: const Text('Đăng nhập Google'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onEmailAuth,
            icon: const Icon(Icons.mail_outline),
            label: const Text('Email và mật khẩu'),
          ),
        ],
      ),
    );
  }
}

class _SignedInCard extends StatelessWidget {
  const _SignedInCard({required this.user, required this.onSignOut});

  final User user;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.displayName?.trim().isNotEmpty == true
                ? user.displayName!
                : (user.email ?? 'Tài khoản ứng dụng'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            user.email ?? 'Đã đăng nhập',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
            label: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _WeatherMetricChip extends StatelessWidget {
  const _WeatherMetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _SyncCredentialsDialog extends StatefulWidget {
  const _SyncCredentialsDialog();

  @override
  State<_SyncCredentialsDialog> createState() => _SyncCredentialsDialogState();
}

class _SyncCredentialsDialogState extends State<_SyncCredentialsDialog> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đăng nhập để đồng bộ'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Tên đăng nhập',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            final username = _usernameController.text.trim();
            final password = _passwordController.text;
            if (username.isEmpty || password.isEmpty) return;
            Navigator.of(
              context,
            ).pop(_CredentialsResult(username: username, password: password));
          },
          child: const Text('Đồng bộ'),
        ),
      ],
    );
  }
}

class _NoteEditorSheet extends StatefulWidget {
  const _NoteEditorSheet({required this.event});

  final StudentEvent event;

  @override
  State<_NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<_NoteEditorSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.event.note ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ghi chú', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Nhập ghi chú cho sự kiện này',
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(_controller.text),
              child: const Text('Lưu'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskEditorSheet extends StatefulWidget {
  const _TaskEditorSheet({required this.initialDate});

  final DateTime initialDate;

  @override
  State<_TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<_TaskEditorSheet> {
  late DateTime _date;
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thêm việc cá nhân',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Tiêu đề',
              hintText: 'Ví dụ: Ôn thi giữa kỳ',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      locale: const Locale('vi', 'VN'),
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked == null) return;
                    setState(() {
                      _date = DateTime(picked.year, picked.month, picked.day);
                    });
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('${_date.day}/${_date.month}/${_date.year}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _time,
                    );
                    if (picked == null) return;
                    setState(() => _time = picked);
                  },
                  icon: const Icon(Icons.access_time),
                  label: Text(
                    '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Ghi chú',
              hintText: 'Những điều quan trọng cần nhớ',
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () {
                final title = _titleController.text.trim();
                if (title.isEmpty) return;
                Navigator.of(context).pop(
                  _TaskEditorResult(
                    title: title,
                    note: _noteController.text.trim(),
                    date: _date,
                    hour: _time,
                  ),
                );
              },
              child: const Text('Tạo việc'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnhancedNoteEditorSheet extends StatefulWidget {
  const _EnhancedNoteEditorSheet({required this.event});

  final StudentEvent event;

  @override
  State<_EnhancedNoteEditorSheet> createState() =>
      _EnhancedNoteEditorSheetState();
}

class _EnhancedNoteEditorSheetState extends State<_EnhancedNoteEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _controller;
  late List<EventAttachment> _attachments;
  String? _titleErrorText;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _controller = TextEditingController(text: widget.event.note ?? '');
    _attachments = List<EventAttachment>.from(widget.event.attachments);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ghi chú', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          if (widget.event.type == StudentEventType.personalTask) ...[
            TextField(
              controller: _titleController,
              onChanged: (_) {
                if (_titleErrorText != null &&
                    _titleController.text.trim().isNotEmpty) {
                  setState(() => _titleErrorText = null);
                }
              },
              decoration: InputDecoration(
                labelText: 'Tiêu đề',
                hintText: 'Nhập tiêu đề ghi chú',
                errorText: _titleErrorText,
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Nhập ghi chú cho sự kiện này',
            ),
          ),
          const SizedBox(height: 12),
          _AttachmentEditorSection(
            attachments: _attachments,
            onAddFiles: _pickAttachments,
            onEdit: _editAttachment,
            onRemove: _removeAttachment,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (widget.event.type == StudentEventType.personalTask)
                TextButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Xóa ghi chú cá nhân?'),
                        content: const Text(
                          'Ghi chú này sẽ bị xóa khỏi thiết bị và cloud.',
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
                    if (confirmed != true || !context.mounted) return;
                    Navigator.of(
                      context,
                    ).pop(const _NoteEditorResult(deleteEvent: true));
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Xóa ghi chú cá nhân'),
                ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  final title = _titleController.text.trim();
                  if (widget.event.type == StudentEventType.personalTask &&
                      title.isEmpty) {
                    setState(() {
                      _titleErrorText = 'Không được để trống tiêu đề';
                    });
                    return;
                  }
                  Navigator.of(context).pop(
                    _NoteEditorResult(
                      title: widget.event.type == StudentEventType.personalTask
                          ? title
                          : null,
                      note: _controller.text,
                      attachments: _attachments,
                    ),
                  );
                },
                child: const Text('Lưu'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickAttachments() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: kIsWeb,
      );
      if (result == null) return;

      final additions = result.files
          .map(
            (file) => EventAttachment(
              id: 'attachment-${DateTime.now().microsecondsSinceEpoch}-${file.name}',
              name: file.name,
              path: file.path ?? '',
              bytesBase64: file.bytes == null ? null : base64Encode(file.bytes!),
            ),
          )
          .where((attachment) =>
              attachment.path.isNotEmpty || attachment.bytesBase64 != null)
          .toList();

      if (additions.isEmpty) return;

      setState(() {
        _attachments = [..._attachments, ...additions];
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở bộ chọn tệp.')),
      );
    }
  }

  void _removeAttachment(String attachmentId) {
    setState(() {
      _attachments = _attachments
          .where((attachment) => attachment.id != attachmentId)
          .toList();
    });
  }

  Future<void> _editAttachment(EventAttachment attachment) async {
    if (!attachment.isImage) return;
    final edited = await Navigator.of(context).push<EventAttachment>(
      MaterialPageRoute(
        builder: (context) => ImageAttachmentEditor(attachment: attachment),
      ),
    );
    if (edited == null || !mounted) return;
    setState(() {
      _attachments = _attachments
          .map((item) => item.id == attachment.id ? edited : item)
          .toList();
    });
  }
}

class _EnhancedTaskEditorSheet extends StatefulWidget {
  const _EnhancedTaskEditorSheet({required this.initialDate});

  final DateTime initialDate;

  @override
  State<_EnhancedTaskEditorSheet> createState() =>
      _EnhancedTaskEditorSheetState();
}

class _EnhancedTaskEditorSheetState extends State<_EnhancedTaskEditorSheet> {
  late DateTime _date;
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  List<EventAttachment> _attachments = const [];
  String? _titleErrorText;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thêm việc cá nhân',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            onChanged: (_) {
              if (_titleErrorText != null &&
                  _titleController.text.trim().isNotEmpty) {
                setState(() => _titleErrorText = null);
              }
            },
            decoration: InputDecoration(
              labelText: 'Tiêu đề',
              hintText: 'Ví dụ: Ôn thi giữa kỳ',
              errorText: _titleErrorText,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      locale: const Locale('vi', 'VN'),
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked == null) return;
                    setState(() {
                      _date = DateTime(picked.year, picked.month, picked.day);
                    });
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('${_date.day}/${_date.month}/${_date.year}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _time,
                    );
                    if (picked == null) return;
                    setState(() => _time = picked);
                  },
                  icon: const Icon(Icons.access_time),
                  label: Text(
                    '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Ghi chú',
              hintText: 'Những điều quan trọng cần nhớ',
            ),
          ),
          const SizedBox(height: 12),
          _AttachmentEditorSection(
            attachments: _attachments,
            onAddFiles: _pickAttachments,
            onEdit: _editAttachment,
            onRemove: _removeAttachment,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () {
                final title = _titleController.text.trim();
                if (title.isEmpty) {
                  setState(() {
                    _titleErrorText = 'Không được để trống tiêu đề';
                  });
                  return;
                }
                Navigator.of(context).pop(
                  _TaskEditorResult(
                    title: title,
                    note: _noteController.text.trim(),
                    date: _date,
                    hour: _time,
                    attachments: _attachments,
                  ),
                );
              },
              child: const Text('Tạo việc'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAttachments() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: kIsWeb,
      );
      if (result == null) return;

      final additions = result.files
          .map(
            (file) => EventAttachment(
              id: 'attachment-${DateTime.now().microsecondsSinceEpoch}-${file.name}',
              name: file.name,
              path: file.path ?? '',
              bytesBase64: file.bytes == null ? null : base64Encode(file.bytes!),
            ),
          )
          .where((attachment) =>
              attachment.path.isNotEmpty || attachment.bytesBase64 != null)
          .toList();

      if (additions.isEmpty) return;

      setState(() {
        _attachments = [..._attachments, ...additions];
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở bộ chọn tệp.')),
      );
    }
  }

  void _removeAttachment(String attachmentId) {
    setState(() {
      _attachments = _attachments
          .where((attachment) => attachment.id != attachmentId)
          .toList();
    });
  }

  Future<void> _editAttachment(EventAttachment attachment) async {
    if (!attachment.isImage) return;
    final edited = await Navigator.of(context).push<EventAttachment>(
      MaterialPageRoute(
        builder: (context) => ImageAttachmentEditor(attachment: attachment),
      ),
    );
    if (edited == null || !mounted) return;
    setState(() {
      _attachments = _attachments
          .map((item) => item.id == attachment.id ? edited : item)
          .toList();
    });
  }
}

class _AttachmentEditorSection extends StatelessWidget {
  const _AttachmentEditorSection({
    required this.attachments,
    required this.onAddFiles,
    required this.onEdit,
    required this.onRemove,
  });

  final List<EventAttachment> attachments;
  final Future<void> Function() onAddFiles;
  final Future<void> Function(EventAttachment attachment) onEdit;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: onAddFiles,
          icon: const Icon(Icons.attach_file),
          label: const Text('Đính kèm tệp'),
        ),
        if (attachments.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: attachments
                .map(
                  (attachment) => InputChip(
                    avatar: Icon(
                      attachment.isPdf
                          ? Icons.picture_as_pdf_outlined
                          : attachment.isImage
                          ? Icons.image_outlined
                          : Icons.description_outlined,
                      size: 18,
                    ),
                    label: Text(attachment.name),
                    onPressed: attachment.isImage
                        ? () => onEdit(attachment)
                        : null,
                    tooltip: attachment.isImage
                        ? 'Chỉnh sửa ảnh'
                        : attachment.name,
                    onDeleted: () => onRemove(attachment.id),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

enum _EmailAuthMode { signIn, register }

class _EmailAuthSheet extends StatefulWidget {
  const _EmailAuthSheet();

  @override
  State<_EmailAuthSheet> createState() => _EmailAuthSheetState();
}

class _EmailAuthSheetState extends State<_EmailAuthSheet> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  _EmailAuthMode _mode = _EmailAuthMode.signIn;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _mode == _EmailAuthMode.signIn
                ? 'Đăng nhập email'
                : 'Tạo tài khoản',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          SegmentedButton<_EmailAuthMode>(
            segments: const [
              ButtonSegment(
                value: _EmailAuthMode.signIn,
                label: Text('Đăng nhập'),
              ),
              ButtonSegment(
                value: _EmailAuthMode.register,
                label: Text('Đăng ký'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (selection) {
              setState(() => _mode = selection.first);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () {
                final email = _emailController.text.trim();
                final password = _passwordController.text;
                if (email.isEmpty || password.isEmpty) return;
                Navigator.of(context).pop(
                  _EmailAuthResult(
                    mode: _mode,
                    email: email,
                    password: password,
                  ),
                );
              },
              child: Text(
                _mode == _EmailAuthMode.signIn ? 'Đăng nhập' : 'Tạo tài khoản',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CredentialsResult {
  const _CredentialsResult({required this.username, required this.password});

  final String username;
  final String password;
}

class _TaskEditorResult {
  const _TaskEditorResult({
    required this.title,
    required this.note,
    required this.date,
    required this.hour,
    this.attachments = const [],
  });

  final String title;
  final String note;
  final DateTime date;
  final TimeOfDay hour;
  final List<EventAttachment> attachments;
}

class _NoteEditorResult {
  const _NoteEditorResult({
    this.title,
    this.note = '',
    this.attachments = const [],
    this.deleteEvent = false,
  });

  final String? title;
  final String note;
  final List<EventAttachment> attachments;
  final bool deleteEvent;
}

class _EmailAuthResult {
  const _EmailAuthResult({
    required this.mode,
    required this.email,
    required this.password,
  });

  final _EmailAuthMode mode;
  final String email;
  final String password;
}
