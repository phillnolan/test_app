import 'dart:async';

import 'package:flutter/material.dart';

import '../../controllers/home_controller.dart';
import '../../controllers/home_flow_models.dart';
import '../../models/event_attachment.dart';
import '../../models/home_action_result.dart';
import '../../models/student_event.dart';
import '../../services/school_api_service.dart';
import '../../utils/home_calendar_utils.dart';
import '../grades/grades_page.dart';
import 'pages/account_page.dart';
import 'pages/quiz_page.dart';
import 'pages/schedule_page.dart';
import 'pages/tuition_page.dart';
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
  static const double _dayTileWidth = 72;
  static const double _dayTileSpacing = 10;

  late final HomeController _controller = widget.controller ?? HomeController();
  late final bool _ownsController = widget.controller == null;
  late final ScrollController _dayStripController = ScrollController();
  late DateTime _lastSelectedDate;
  late bool _wasLoadingLocalCache;

  @override
  void initState() {
    super.initState();
    _lastSelectedDate = _normalizedDate(_controller.selectedDate);
    _wasLoadingLocalCache = _controller.isLoadingLocalCache;
    _controller.addListener(_handleControllerChanged);
    _controller.initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _jumpDayStripToDate(_controller.selectedDate);
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _dayStripController.dispose();
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
          _buildGradesPage(),
          _buildQuizPage(),
          _buildSchedulePage(context),
          _buildTuitionPage(),
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
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school),
                label: 'Điểm',
              ),
              NavigationDestination(
                icon: Icon(Icons.quiz_outlined),
                selectedIcon: Icon(Icons.quiz),
                label: 'Quiz',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today),
                label: 'Lịch',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Học phí',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Tài khoản',
              ),
            ],
          ),
          floatingActionButton: _controller.currentTab == 2
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
      dayStripController: _dayStripController,
      dayStripItemCount:
          HomeController.pastDayRange + HomeController.futureDayRange + 1,
      dayTileSpacing: _dayTileSpacing,
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
      onOpenSyncTab: () => _controller.setCurrentTab(4),
      onAddTask: () {
        unawaited(_openTaskEditor());
      },
      onSelectDate: _handleSelectDate,
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
      showCloudSyncStatus: _controller.signedInUser != null,
      isEventCloudSyncPending: _controller.isEventCloudSyncPending,
      isEventCloudDeletePending: _controller.isEventCloudDeletePending,
      isEventCloudSyncDeferred: _controller.isEventCloudSyncDeferred,
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
        title: 'Chưa đông bộ dữ liệu',
        description:
            'Hãy chuyển sang trang Tài khoản để đăng nhập và đồng bộ dữ liệu mới nhất.',
        actionLabel: 'Mở tài khoản',
        onAction: () => _controller.setCurrentTab(4),
      ),
    );
  }

  Widget _buildQuizPage() {
    return const QuizPage();
  }

  Widget _buildTuitionPage() {
    return TuitionPage(
      profile: _controller.payload.profile,
      currentTuition: _controller.payload.currentTuition,
      onOpenAccountTab: () => _controller.setCurrentTab(4),
    );
  }

  Widget _buildAccountPage() {
    return AccountPage(
      isAuthAvailable: _controller.isAuthAvailable,
      user: _controller.signedInUser,
      profile: _controller.payload.profile,
      linkedStudentUsername: _controller.linkedStudentUsername,
      isSyncing: _controller.isSyncing,
      isLinkingStudent: _controller.isLinkingStudent,
      isRestoringCloudData: _controller.isRestoringCloudData,
      isSigningOut: _controller.isSigningOut,
      showRestoreWarning: _controller.showCloudRestoreWarning,
      hasSavedSyncCredentials: _controller.canQuickSyncCurrentStudent,
      lastSyncedAt: _controller.payload.lastSyncedAt,
      syncedEventCount: _controller.payload.syncedEvents.length,
      gradeCount: _controller.payload.grades.length,
      personalEventCount: _controller.payload.personalEvents.length,
      onDismissRestoreWarning: _controller.dismissCloudRestoreWarning,
      onEmailAuth: () {
        unawaited(_openEmailAuthSheet(context));
      },
      onGoogleAuth: () {
        unawaited(_handleGoogleAuth());
      },
      onSync: () {
        unawaited(_handleSyncAction(context));
      },
      onManageSyncCredentials: () {
        unawaited(_openSyncDialog(context, forceCredentialForm: true));
      },
      onSignOut: () {
        unawaited(_handleSignOut());
      },
    );
  }

  Future<void> _handleSyncAction(BuildContext context) async {
    final savedCredentials = await _controller.preferredSyncCredentials();
    if (!context.mounted) return;

    if (savedCredentials != null) {
      await _runSyncFlow(savedCredentials);
      return;
    }

    await _openSyncDialog(context, forceCredentialForm: true);
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
    _handleSelectDate(picked);
  }

  Future<void> _openSyncDialog(
    BuildContext context, {
    bool forceCredentialForm = false,
  }) async {
    if (_controller.isSyncing ||
        _controller.isLinkingStudent ||
        _controller.isRestoringCloudData) {
      return;
    }

    final savedCredentials = await _controller.preferredSyncCredentials();
    if (!context.mounted) return;

    if (!forceCredentialForm && savedCredentials != null) {
      await _runSyncFlow(savedCredentials);
      return;
    }

    final credentials = await showModalBottomSheet<CredentialsResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SyncCredentialsDialog(
        initialUsername: forceCredentialForm
            ? null
            : savedCredentials?.username,
        initialPassword: forceCredentialForm
            ? null
            : savedCredentials?.password,
      ),
    );
    if (credentials == null || !mounted) return;

    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    await _runSyncFlow(credentials);
  }

  Future<void> _runSyncFlow(CredentialsResult credentials) async {
    _controller.setSyncInProgress(true);
    try {
      final plan = await _controller.prepareSchoolSync(credentials);
      debugPrint(
        'HomeShell: prepared sync localReplace='
        '${plan.requiresLocalReplacementConfirmation} '
        'decision=${plan.decision.action} '
        'currentLocal=${plan.currentLocalStudentUsername} '
        'target=${plan.decision.targetStudentUsername}',
      );
      if (!mounted) return;

      if (plan.requiresLocalReplacementConfirmation) {
        final confirmed = await _confirmReplaceCurrentStudentData(plan);
        if (confirmed != true || !mounted) {
          return;
        }
      }

      if (plan.decision.requiresConfirmation) {
        final confirmed = await _confirmAccountLinkDecision(
          plan.decision,
          isSyncFlow: true,
        );
        if (confirmed != true || !mounted) {
          return;
        }
      }

      final result = await _controller.applyPreparedSync(
        plan,
        clearExistingCloudData:
            plan.decision.action == AccountLinkAction.relinkStudent,
        sourceCredentials: credentials,
      );
      debugPrint(
        'HomeShell: applyPreparedSync result isSuccess=${result.isSuccess} '
        'message=${result.message}',
      );
      if (!mounted) return;

      if (result.isSuccess) {
        _controller.setCurrentTab(2);
        _animateDayStripToDate(_controller.selectedDate);
      }
      if (result.message != null) {
        _showSnackBar(result.message!);
      }
    } on SchoolApiException catch (error) {
      debugPrint('HomeShell: school sync failed: ${error.message}');
      if (!mounted) return;
      _showSnackBar(error.message);
    } catch (error, stackTrace) {
      debugPrint('HomeShell: sync flow failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      _showSnackBar(
        'Đã có lỗi xảy ra trong quá trình đồng bộ. Vui lòng thử lại sau.',
      );
    } finally {
      _controller.setSyncInProgress(false);
    }
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
    if (!mounted) return;
    _animateDayStripToDate(_controller.selectedDate);
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

    final resolution = await _controller.emailAuthAndResolve(result);
    if (!mounted) return;
    await _handleAuthFlowResult(resolution);
  }

  Future<void> _handleGoogleAuth() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng nhập Google?'),
        content: const Text(
          'Bạn sắp đăng nhập bằng Google để mở dữ liệu cloud và kiểm tra liên kết với tài khoản sinh viên hiện tại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    final resolution = await _controller.googleAuthAndResolve();
    if (!mounted) return;
    await _handleAuthFlowResult(resolution);
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất?'),
        content: const Text(
          'Bạn sẽ đăng xuất khỏi tài khoản ứng dụng và toàn bộ dữ liệu đang lưu trên thiết bị này sẽ được dọn dẹp.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    await _runAndShowMessage(_controller.signOut());
  }

  Future<void> _handleAuthFlowResult(AuthFlowResult result) async {
    if (result.message != null) {
      _showSnackBar(result.message!);
    }
    if (!result.isSuccess || !mounted) {
      return;
    }

    if (result.decision.requiresConfirmation) {
      final confirmed = await _confirmAccountLinkDecision(
        result.decision,
        isSyncFlow: false,
      );
      if (confirmed != true || !mounted) {
        return;
      }

      final finalizeResult = await _controller
          .completeLinkCurrentStudentAfterSignIn(
            clearExistingCloudData:
                result.decision.action == AccountLinkAction.relinkStudent,
          );
      if (!mounted) return;
      if (finalizeResult.message != null) {
        _showSnackBar(finalizeResult.message!);
      }
      if (finalizeResult.isSuccess && _controller.payload.profile != null) {
        _animateDayStripToDate(_controller.selectedDate);
      }
      return;
    }

    if (_controller.payload.profile != null) {
      _animateDayStripToDate(_controller.selectedDate);
    }
  }

  Future<bool?> _confirmAccountLinkDecision(
    AccountLinkDecision decision, {
    required bool isSyncFlow,
  }) {
    final target = decision.targetStudentUsername ?? 'sinh viên mới';

    if (decision.action == AccountLinkAction.linkStudent) {
      final content = isSyncFlow
          ? 'Tài khoản ứng dụng này chưa liên kết với sinh viên nào. Bạn có muốn liên kết với "$target" ngay sau lần đồng bộ này không?'
          : 'Tài khoản ứng dụng này chưa liên kết với sinh viên nào. Bạn có muốn liên kết với dữ liệu sinh viên "$target" đang có trên thiết bị không?';
      return showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Liên kết với sinh viên này?'),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Liên kết'),
            ),
          ],
        ),
      );
    }

    final current = decision.currentLinkedStudentUsername ?? 'sinh viên khác';
    final content = isSyncFlow
        ? 'Tài khoản ứng dụng hiện đang liên kết với "$current". Nếu tiếp tục, toàn bộ ghi chú, ảnh và tập của sinh viên cũ trên cloud sẽ bị xóa, sau đó tài khoản sẽ được liên kết với "$target".'
        : 'Tài khoản ứng dụng hiện đang liên kết với "$current". Nếu xác nhận, toàn bộ ghi chú, ảnh và tập của sinh viên cũ trên cloud sẽ bị xóa để chuyển sang liên kết với "$target".';

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chuyển liên kết sinh viên?'),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Giữ liên kết cũ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Chuyển liên kết'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmReplaceCurrentStudentData(PreparedSyncPlan plan) {
    final currentStudent =
        plan.currentLocalStudentUsername ?? 'sinh viên hiện tại';
    final nextStudent =
        plan.decision.targetStudentUsername ??
        _controller.payload.profile?.studentCode ??
        'sinh viên mới';

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi sinh viên đồng bộ?'),
        content: Text(
          'Thiết bị đang có dữ liệu của "$currentStudent". '
          'Nếu đồng bộ với "$nextStudent", dữ liệu hiện tại sẽ bị mất '
          '(bạn nên đổi sang một tài khoản khác để đồng bộ).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Giữ dữ liệu cũ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa và đồng bộ'),
          ),
        ],
      ),
    );
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

  void _handleControllerChanged() {
    final selectedDate = _normalizedDate(_controller.selectedDate);
    final localCacheJustLoaded =
        _wasLoadingLocalCache && !_controller.isLoadingLocalCache;
    _wasLoadingLocalCache = _controller.isLoadingLocalCache;

    if (localCacheJustLoaded &&
        !HomeCalendarUtils.isSameDate(_lastSelectedDate, selectedDate)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _jumpDayStripToDate(selectedDate);
      });
    }

    _lastSelectedDate = selectedDate;
  }

  void _handleSelectDate(DateTime date) {
    _controller.selectDate(date);
    _animateDayStripToDate(_controller.selectedDate);
  }

  DateTime _normalizedDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  void _jumpDayStripToDate(DateTime date) {
    if (!_dayStripController.hasClients) return;
    final offset = HomeCalendarUtils.stripOffsetForDate(
      today: _controller.today,
      pastDayRange: HomeController.pastDayRange,
      date: date,
      itemExtent: _dayTileWidth + _dayTileSpacing,
    );
    _dayStripController.jumpTo(
      offset.clamp(0.0, _dayStripController.position.maxScrollExtent),
    );
  }

  void _animateDayStripToDate(DateTime date) {
    if (!_dayStripController.hasClients) return;
    final offset = HomeCalendarUtils.stripOffsetForDate(
      today: _controller.today,
      pastDayRange: HomeController.pastDayRange,
      date: date,
      itemExtent: _dayTileWidth + _dayTileSpacing,
    );
    _dayStripController.animateTo(
      offset.clamp(0.0, _dayStripController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }
}
