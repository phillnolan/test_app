import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/student_event.dart';
import '../models/student_profile.dart';

class WidgetSyncService {
  static const MethodChannel _channel = MethodChannel(
    'sinhvien_app/home_widget',
  );

  Future<void> updateTodayWidget({
    required StudentProfile? profile,
    required List<StudentEvent> events,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayEvents = events
        .where((event) => _isSameDate(event.start, today))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    final title = profile == null
        ? 'Lịch hôm nay'
        : 'Lịch hôm nay của ${profile.displayName}';
    final subtitle = todayEvents.isEmpty
        ? 'Không có sự kiện nào trong hôm nay'
        : '${todayEvents.length} sự kiện trong hôm nay';

    final line1 = todayEvents.isNotEmpty ? _formatEventLine(todayEvents[0]) : '';
    final line2 = todayEvents.length > 1 ? _formatEventLine(todayEvents[1]) : '';
    final line3 = todayEvents.length > 2
        ? '+${todayEvents.length - 2} sự kiện khác'
        : '';

    await prefs.setString('widget_title', title);
    await prefs.setString('widget_subtitle', subtitle);
    await prefs.setString('widget_line_1', line1);
    await prefs.setString('widget_line_2', line2);
    await prefs.setString('widget_line_3', line3);

    try {
      await _channel.invokeMethod<void>('updateWidget');
    } catch (_) {
      // Widget update is best-effort on unsupported platforms.
    }
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatEventLine(StudentEvent event) {
    final time =
        '${event.start.hour.toString().padLeft(2, '0')}:${event.start.minute.toString().padLeft(2, '0')}';
    final prefix = switch (event.type) {
      StudentEventType.exam => 'Thi',
      StudentEventType.classSchedule => 'Học',
      StudentEventType.personalTask => 'Việc',
    };
    return '$time • $prefix • ${event.title}';
  }
}
