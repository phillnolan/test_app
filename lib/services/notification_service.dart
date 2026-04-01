import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/student_event.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized || kIsWeb) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();

    _isInitialized = true;
  }

  Future<void> rescheduleForEvents(List<StudentEvent> events) async {
    if (!_isSupportedPlatform) return;
    await initialize();
    await _plugin.cancelAll();

    final now = DateTime.now();
    final futureEvents = events
        .where((event) => event.start.isAfter(now))
        .where((event) => event.start.isBefore(now.add(const Duration(days: 14))))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    for (final event in futureEvents) {
      final scheduledTime = _scheduledReminderTime(event);
      if (!scheduledTime.isAfter(now)) continue;

      final id = _notificationIdForEvent(event);
      await _plugin.zonedSchedule(
        id,
        _titleForEvent(event),
        _bodyForEvent(event),
        tz.TZDateTime.from(scheduledTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'student_schedule_reminders',
            'Nhắc lịch học',
            channelDescription: 'Nhắc trước giờ học, thi và việc cá nhân',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  bool get _isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  DateTime _scheduledReminderTime(StudentEvent event) {
    final leadTime = switch (event.type) {
      StudentEventType.exam => const Duration(hours: 2),
      StudentEventType.classSchedule => const Duration(minutes: 30),
      StudentEventType.personalTask => const Duration(minutes: 30),
    };
    return event.start.subtract(leadTime);
  }

  int _notificationIdForEvent(StudentEvent event) {
    return event.id.hashCode & 0x7fffffff;
  }

  String _titleForEvent(StudentEvent event) {
    return switch (event.type) {
      StudentEventType.exam => 'Sắp đến giờ thi',
      StudentEventType.classSchedule => 'Sắp đến giờ học',
      StudentEventType.personalTask => 'Sắp tới việc cá nhân',
    };
  }

  String _bodyForEvent(StudentEvent event) {
    final timeLabel =
        '${event.start.hour.toString().padLeft(2, '0')}:${event.start.minute.toString().padLeft(2, '0')}';
    final location = (event.location ?? '').trim();
    final locationText = location.isEmpty ? '' : ' • $location';
    return '$timeLabel • ${event.title}$locationText';
  }
}
