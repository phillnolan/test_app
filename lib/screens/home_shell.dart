import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/home_shell_view_model.dart';
import '../utils/home_calendar_utils.dart';
import '../widgets/home/home_common_widgets.dart';
import 'account_page.dart';
import 'grades_page.dart';
import 'schedule_page.dart';
import 'sync_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final HomeShellViewModel _viewModel = HomeShellViewModel()..initialize();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final pages = <Widget>[
          _buildSchedulePage(context),
          _buildGradesPage(),
          _buildSyncPage(context),
          _buildAccountPage(context),
        ];

        return Scaffold(
          body: SafeArea(
            child: IndexedStack(index: _viewModel.currentTab, children: pages),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _viewModel.currentTab,
            onDestinationSelected: _viewModel.setCurrentTab,
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
          floatingActionButton: _viewModel.currentTab == 0
              ? FloatingActionButton(
                  onPressed: () {
                    unawaited(_viewModel.addTask(context));
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
      _viewModel.allEvents,
      _viewModel.selectedDate,
    );

    return SchedulePage(
      eventsForDay: eventsForDay,
      selectedDate: _viewModel.selectedDate,
      profile: _viewModel.payload.profile,
      lastSyncedAt: _viewModel.payload.lastSyncedAt,
      weatherForecast: _viewModel.weatherForecast,
      weatherService: _viewModel.weatherService,
      isLoadingLocalCache: _viewModel.isLoadingLocalCache,
      isLoadingWeather: _viewModel.isLoadingWeather,
      showSyncReminder: _viewModel.showSyncReminder,
      dayStripController: _viewModel.dayStripController,
      dayStripItemCount:
          HomeShellViewModel.pastDayRange +
          HomeShellViewModel.futureDayRange +
          1,
      dayTileSpacing: HomeShellViewModel.dayTileSpacing,
      dateForIndex: _viewModel.dateForIndex,
      indicatorsForDate: _viewModel.indicatorsForDate,
      isSameDate: HomeCalendarUtils.isSameDate,
      formatFullDate: HomeCalendarUtils.formatFullDate,
      formatTime: HomeCalendarUtils.formatTime,
      formatSyncTimestamp: HomeCalendarUtils.formatSyncTimestamp,
      onHideSyncReminder: _viewModel.hideSyncReminder,
      onOpenMonthPicker: () {
        unawaited(_viewModel.openMonthPicker(context));
      },
      onOpenSyncTab: () => _viewModel.setCurrentTab(2),
      onAddTask: () {
        unawaited(_viewModel.addTask(context));
      },
      onSelectDate: _viewModel.selectDate,
      onEditEvent: (event) {
        unawaited(_viewModel.editEvent(context, event));
      },
      onDeleteEvent: (event) {
        unawaited(_viewModel.deletePersonalEvent(context, event));
      },
      onOpenAttachment: (attachment) {
        unawaited(_viewModel.openAttachment(context, attachment));
      },
      onToggleDone: (id) {
        unawaited(_viewModel.toggleDone(id));
      },
      onReloadWeather: () {
        unawaited(_viewModel.reloadWeather());
      },
    );
  }

  Widget _buildGradesPage() {
    return GradesPage(
      grades: _viewModel.payload.grades,
      curriculumSubjects: _viewModel.payload.curriculumSubjects,
      curriculumRawItems: _viewModel.payload.curriculumRawItems,
      emptyState: EmptyStateCard(
        icon: Icons.school_outlined,
        title: 'Chưa có bảng điểm',
        description:
            'Hãy chuyển sang trang Đồng bộ để đăng nhập và tải dữ liệu mới nhất.',
        actionLabel: 'Mở đồng bộ',
        onAction: () => _viewModel.setCurrentTab(2),
      ),
    );
  }

  Widget _buildSyncPage(BuildContext context) {
    return SyncPage(
      isSyncing: _viewModel.isSyncing,
      onSync: () {
        unawaited(_viewModel.openSyncDialog(context));
      },
      lastSyncedAt: _viewModel.payload.lastSyncedAt,
      profile: _viewModel.payload.profile,
      syncedEventCount: _viewModel.payload.syncedEvents.length,
      gradeCount: _viewModel.payload.grades.length,
      personalEventCount: _viewModel.payload.personalEvents.length,
    );
  }

  Widget _buildAccountPage(BuildContext context) {
    return AccountPage(
      isAuthAvailable: _viewModel.isAuthAvailable,
      user: _viewModel.signedInUser,
      onEmailAuth: () {
        unawaited(_viewModel.emailAuth(context));
      },
      onGoogleAuth: () {
        unawaited(_viewModel.googleAuth(context));
      },
      onSignOut: () {
        unawaited(_viewModel.signOut(context));
      },
    );
  }
}
