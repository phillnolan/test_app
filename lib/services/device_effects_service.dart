import '../models/local_cache_payload.dart';
import '../models/student_event.dart';
import 'notification_service.dart';
import 'widget_sync_service.dart';

typedef NotificationRescheduler =
    Future<void> Function(List<StudentEvent> events);

class DeviceEffectsService {
  DeviceEffectsService({
    WidgetSyncService? widgetSyncService,
    NotificationRescheduler? rescheduleNotifications,
  }) : _widgetSyncService = widgetSyncService ?? WidgetSyncService(),
       _rescheduleNotifications =
           rescheduleNotifications ??
           NotificationService.instance.rescheduleForEvents;

  final WidgetSyncService _widgetSyncService;
  final NotificationRescheduler _rescheduleNotifications;

  Future<void> refreshDeviceState(LocalCachePayload payload) async {
    final events = [...payload.syncedEvents, ...payload.personalEvents]
      ..sort((a, b) => a.start.compareTo(b.start));

    try {
      await _rescheduleNotifications(events);
    } catch (_) {
      // Notifications are best-effort on unsupported platforms.
    }

    try {
      await _widgetSyncService.updateTodayWidget(
        profile: payload.profile,
        events: events,
      );
    } catch (_) {
      // Widget sync is also best-effort.
    }
  }
}
