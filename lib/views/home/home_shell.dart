import 'dart:async';

import 'package:flutter/material.dart';

import '../../controllers/home_controller.dart';
import '../../utils/home_calendar_utils.dart';
import '../grades/grades_page.dart';
import 'pages/account_page.dart';
import 'pages/schedule_page.dart';
import 'pages/sync_page.dart';
import 'widgets/home_common_widgets.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final HomeController _controller = HomeController()..initialize();

  @override
  void dispose() {
    _controller.dispose();
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
          _buildSyncPage(context),
          _buildAccountPage(context),
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
                    unawaited(_controller.addTask(context));
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
      weatherForecast: _controller.weatherForecast,
      weatherService: _controller.weatherService,
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
        unawaited(_controller.openMonthPicker(context));
      },
      onOpenSyncTab: () => _controller.setCurrentTab(2),
      onAddTask: () {
        unawaited(_controller.addTask(context));
      },
      onSelectDate: _controller.selectDate,
      onEditEvent: (event) {
        unawaited(_controller.editEvent(context, event));
      },
      onDeleteEvent: (event) {
        unawaited(_controller.deletePersonalEvent(context, event));
      },
      onOpenAttachment: (attachment) {
        unawaited(_controller.openAttachment(context, attachment));
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

  Widget _buildSyncPage(BuildContext context) {
    return SyncPage(
      isSyncing: _controller.isSyncing,
      onSync: () {
        unawaited(_controller.openSyncDialog(context));
      },
      lastSyncedAt: _controller.payload.lastSyncedAt,
      profile: _controller.payload.profile,
      syncedEventCount: _controller.payload.syncedEvents.length,
      gradeCount: _controller.payload.grades.length,
      personalEventCount: _controller.payload.personalEvents.length,
    );
  }

  Widget _buildAccountPage(BuildContext context) {
    return AccountPage(
      isAuthAvailable: _controller.isAuthAvailable,
      user: _controller.signedInUser,
      onEmailAuth: () {
        unawaited(_controller.emailAuth(context));
      },
      onGoogleAuth: () {
        unawaited(_controller.googleAuth(context));
      },
      onSignOut: () {
        unawaited(_controller.signOut(context));
      },
    );
  }
}
