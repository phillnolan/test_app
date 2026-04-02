import 'dart:async';

import 'package:flutter/material.dart';

import '../../controllers/home_controller.dart';
import '../../controllers/home_flow_models.dart';
import '../../models/event_attachment.dart';
import '../../models/student_event.dart';
import '../../utils/home_calendar_utils.dart';
import '../grades/grades_page.dart';
import 'pages/account_page.dart';
import 'pages/schedule_page.dart';
import 'pages/sync_page.dart';
import 'widgets/home_common_widgets.dart';
import 'widgets/home_dialogs.dart';
import 'widgets/home_editors.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.controller});

  final HomeController? controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final HomeController _controller = widget.controller ?? HomeController();
  late final bool _ownsController = widget.controller == null;

  @override
  void initState() {
    super.initState();
    _controller.initialize();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final pages = <Widget>[
          _buildSchedulePage(context),
          _buildGradesPage(),
          _buildSyncPage(),
          _buildAccountPage(),
        ];

        return Scaffold(
          body: SafeArea(
            child: IndexedStack(index: _controller.currentTab, children: pages),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _controller.currentTab,
            onDestinationSelected: _controller.setCurrentTab,
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
          floatingActionButton: _controller.currentTab == 0
              ? FloatingActionButton(
                  onPressed: () {
                    unawaited(_openTaskEditor());
                  },
                  tooltip: 'Thêm việc',
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }

  Widget _buildSchedulePage(BuildContext context) {
    final eventsForDay = HomeCalendarUtils.eventsForDay(
      _controller.allEvents,
      _controller.selectedDate,
    );

    return SchedulePage(
      eventsForDay: eventsForDay,
      selectedDate: _controller.selectedDate,
      profile: _controller.payload.profile,
      lastSyncedAt: _controller.payload.lastSyncedAt,
      weatherPresentation: _controller.selectedDayWeather,
      isLoadingLocalCache: _controller.isLoadingLocalCache,
      isLoadingWeather: _controller.isLoadingWeather,
      showSyncReminder: _controller.showSyncReminder,
      dayStripController: _controller.dayStripController,
      dayStripItemCount:
          HomeController.pastDayRange + HomeController.futureDayRange + 1,
      dayTileSpacing: HomeController.dayTileSpacing,
      dateForIndex: _controller.dateForIndex,
      indicatorsForDate: _controller.indicatorsForDate,
      isSameDate: HomeCalendarUtils.isSameDate,
      formatFullDate: HomeCalendarUtils.formatFullDate,
      formatTime: HomeCalendarUtils.formatTime,
      formatSyncTimestamp: HomeCalendarUtils.formatSyncTimestamp,
      onHideSyncReminder: _controller.hideSyncReminder,
      onOpenMonthPicker: () {
        unawaited(_openMonthPicker(context));
      },
      onOpenSyncTab: () => _controller.setCurrentTab(2),
      onAddTask: () {
        unawaited(_openTaskEditor());
      },
      onSelectDate: _controller.selectDate,
      onEditEvent: (event) {
        unawaited(_openNoteEditor(event));
      },
      onDeleteEvent: (event) {
        unawaited(_confirmDeleteEvent(context, event));
      },
      onOpenAttachment: (attachment) {
        unawaited(_openAttachment(attachment));
      },
      onToggleDone: (id) {
        unawaited(_controller.toggleDone(id));
      },
      onReloadWeather: () {
        unawaited(_controller.reloadWeather());
      },
    );
  }

  Widget _buildGradesPage() {
    return GradesPage(
      grades: _controller.payload.grades,
      curriculumSubjects: _controller.payload.curriculumSubjects,
      curriculumRawItems: _controller.payload.curriculumRawItems,
      emptyState: EmptyStateCard(
        icon: Icons.school_outlined,
        title: 'Chưa có bảng điểm',
        description:
            'Hãy chuyển sang trang Đồng bộ để đăng nhập và tải dữ liệu mới nhất.',
        actionLabel: 'Mở đồng bộ',
        onAction: () => _controller.setCurrentTab(2),
      ),
    );
  }

  Widget _buildSyncPage() {
    return SyncPage(
      isSyncing: _controller.isSyncing,
      onSync: () {
        unawaited(_openSyncDialog(context));
      },
      lastSyncedAt: _controller.payload.lastSyncedAt,
      profile: _controller.payload.profile,
      syncedEventCount: _controller.payload.syncedEvents.length,
      gradeCount: _controller.payload.grades.length,
      personalEventCount: _controller.payload.personalEvents.length,
    );
  }

  Widget _buildAccountPage() {
    return AccountPage(
      isAuthAvailable: _controller.isAuthAvailable,
      user: _controller.signedInUser,
      onEmailAuth: () {
        unawaited(_openEmailAuthSheet(context));
      },
      onGoogleAuth: () {
        unawaited(_runAndShowMessage(_controller.googleAuth()));
      },
      onSignOut: () {
        unawaited(_runAndShowMessage(_controller.signOut()));
      },
    );
  }

  Future<void> _openMonthPicker(BuildContext context) async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => MonthPickerDialog(
        initialDate: _controller.selectedDate,
        firstDate: _controller.today.subtract(
          const Duration(days: HomeController.pastDayRange),
        ),
        lastDate: _controller.today.add(
          const Duration(days: HomeController.futureDayRange),
        ),
        eventLevelForDate: (date) => HomeCalendarUtils.eventLevelForEvents(
          HomeCalendarUtils.eventsForDay(_controller.allEvents, date),
        ),
      ),
    );

    if (picked == null || !mounted) return;
    _controller.selectDate(picked);
  }

  Future<void> _openSyncDialog(BuildContext context) async {
    final credentials = await showDialog<CredentialsResult>(
      context: context,
      builder: (context) => const SyncCredentialsDialog(),
    );
    if (credentials == null || !mounted) return;

    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    final result = await _controller.syncSchoolData(credentials);
    if (!mounted || result.message == null) return;

    _showSnackBar(result.message!);
  }

  Future<void> _openTaskEditor() async {
    final result = await showModalBottomSheet<TaskEditorResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          EnhancedTaskEditorSheet(initialDate: _controller.selectedDate),
    );
    if (result == null || !mounted) return;

    await _controller.addTask(result);
  }

  Future<void> _openNoteEditor(StudentEvent event) async {
    final result = await showModalBottomSheet<NoteEditorResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => EnhancedNoteEditorSheet(event: event),
    );
    if (result == null || !mounted) return;

    await _controller.editEvent(event, result);
  }

  Future<void> _confirmDeleteEvent(
    BuildContext context,
    StudentEvent event,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoa ghi chu ca nhan?'),
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

    await _controller.deletePersonalEvent(event);
  }

  Future<void> _openAttachment(EventAttachment attachment) async {
    final result = await _controller.openAttachment(attachment);
    if (!mounted || result.didOpen || result.message == null) return;

    _showSnackBar(result.message!);
  }

  Future<void> _openEmailAuthSheet(BuildContext context) async {
    final result = await showModalBottomSheet<EmailAuthResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const EmailAuthSheet(),
    );
    if (result == null || !mounted) return;

    await _runAndShowMessage(_controller.emailAuth(result));
  }

  Future<void> _runAndShowMessage(Future<HomeActionResult> futureResult) async {
    final result = await futureResult;
    if (!mounted || result.message == null) return;

    _showSnackBar(result.message!);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
