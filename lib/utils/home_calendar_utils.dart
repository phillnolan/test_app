import 'package:flutter/material.dart';

import '../models/student_event.dart';
import '../widgets/home/home_dialogs.dart';

class HomeCalendarUtils {
  const HomeCalendarUtils._();

  static List<StudentEvent> eventsForDay(
    List<StudentEvent> events,
    DateTime date,
  ) {
    return events.where((event) => isSameDate(event.start, date)).toList();
  }

  static List<Color> indicatorColors(List<StudentEvent> events) {
    if (events.isEmpty) {
      return const [];
    }

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

  static CalendarEventLevel eventLevelForEvents(List<StudentEvent> events) {
    if (events.any((event) => event.type == StudentEventType.exam)) {
      return CalendarEventLevel.important;
    }
    if (events.isNotEmpty) {
      return CalendarEventLevel.normal;
    }
    return CalendarEventLevel.none;
  }

  static DateTime dateForIndex({
    required DateTime today,
    required int pastDayRange,
    required int index,
  }) {
    final offset = index - pastDayRange;
    return today.add(Duration(days: offset));
  }

  static int indexForDate({
    required DateTime today,
    required int pastDayRange,
    required DateTime date,
  }) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.difference(today).inDays + pastDayRange;
  }

  static double stripOffsetForDate({
    required DateTime today,
    required int pastDayRange,
    required DateTime date,
    required double itemExtent,
  }) {
    return indexForDate(today: today, pastDayRange: pastDayRange, date: date) *
        itemExtent;
  }

  static String formatFullDate(DateTime date) {
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

  static String formatTime(DateTime value) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(value.hour)}:${twoDigits(value.minute)}';
  }

  static String formatSyncTimestamp(DateTime value) {
    return '${formatTime(value)} ${value.day}/${value.month}/${value.year}';
  }

  static bool isSameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
