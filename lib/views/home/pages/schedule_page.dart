import 'package:flutter/material.dart';

import '../../../../models/event_attachment.dart';
import '../../../../models/student_event.dart';
import '../../../../models/student_profile.dart';
import '../../../../controllers/home_flow_models.dart';
import '../widgets/home_common_widgets.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({
    super.key,
    required this.eventsForDay,
    required this.selectedDate,
    required this.profile,
    required this.lastSyncedAt,
    required this.weatherPresentation,
    required this.isLoadingLocalCache,
    required this.isLoadingWeather,
    required this.showSyncReminder,
    required this.dayStripController,
    required this.dayStripItemCount,
    required this.dayTileSpacing,
    required this.dateForIndex,
    required this.indicatorsForDate,
    required this.isSameDate,
    required this.formatFullDate,
    required this.formatTime,
    required this.formatSyncTimestamp,
    required this.onHideSyncReminder,
    required this.onOpenMonthPicker,
    required this.onOpenSyncTab,
    required this.onAddTask,
    required this.onSelectDate,
    required this.onEditEvent,
    required this.onDeleteEvent,
    required this.onOpenAttachment,
    required this.onToggleDone,
    required this.onReloadWeather,
  });

  final List<StudentEvent> eventsForDay;
  final DateTime selectedDate;
  final StudentProfile? profile;
  final DateTime? lastSyncedAt;
  final WeatherPresentation? weatherPresentation;
  final bool isLoadingLocalCache;
  final bool isLoadingWeather;
  final bool showSyncReminder;
  final ScrollController dayStripController;
  final int dayStripItemCount;
  final double dayTileSpacing;
  final DateTime Function(int index) dateForIndex;
  final List<Color> Function(DateTime date) indicatorsForDate;
  final bool Function(DateTime left, DateTime right) isSameDate;
  final String Function(DateTime date) formatFullDate;
  final String Function(DateTime value) formatTime;
  final String Function(DateTime value) formatSyncTimestamp;
  final VoidCallback onHideSyncReminder;
  final VoidCallback onOpenMonthPicker;
  final VoidCallback onOpenSyncTab;
  final VoidCallback onAddTask;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<StudentEvent> onEditEvent;
  final ValueChanged<StudentEvent> onDeleteEvent;
  final ValueChanged<EventAttachment> onOpenAttachment;
  final ValueChanged<String> onToggleDone;
  final VoidCallback onReloadWeather;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showSyncReminder) ...[
                  _SyncReminder(onHide: onHideSyncReminder),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  height: 220,
                  child: ScrollConfiguration(
                    behavior: const DesktopFriendlyScrollBehavior(),
                    child: PageView(
                      padEnds: false,
                      controller: PageController(viewportFraction: 0.94),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _ScheduleHeroCard(
                            eventsForDay: eventsForDay,
                            profile: profile,
                            selectedDate: selectedDate,
                            lastSyncedAt: lastSyncedAt,
                            formatFullDate: formatFullDate,
                            formatTime: formatTime,
                            formatSyncTimestamp: formatSyncTimestamp,
                          ),
                        ),
                        _WeatherCard(
                          weatherPresentation: weatherPresentation,
                          isLoadingWeather: isLoadingWeather,
                          onReloadWeather: onReloadWeather,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ScheduleHeader(
                  selectedDate: selectedDate,
                  formatFullDate: formatFullDate,
                  onOpenMonthPicker: onOpenMonthPicker,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 104,
                  child: ScrollConfiguration(
                    behavior: const DesktopFriendlyScrollBehavior(),
                    child: ListView.builder(
                      controller: dayStripController,
                      scrollDirection: Axis.horizontal,
                      itemCount: dayStripItemCount,
                      itemBuilder: (context, index) {
                        final date = dateForIndex(index);
                        final indicators = indicatorsForDate(date);

                        return Padding(
                          padding: EdgeInsets.only(
                            right: index == dayStripItemCount - 1
                                ? 0
                                : dayTileSpacing,
                          ),
                          child: _DayChip(
                            date: date,
                            isSelected: isSameDate(date, selectedDate),
                            indicators: indicators,
                            onTap: () => onSelectDate(date),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isLoadingLocalCache)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (eventsForDay.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: EmptyStateCard(
                icon: profile == null
                    ? Icons.sync_rounded
                    : Icons.event_available_outlined,
                title: profile == null
                    ? 'Chưa có dữ liệu từ cổng trường'
                    : 'Ngày này chưa có sự kiện',
                description: profile == null
                    ? 'Mở trang Đồng bộ để đăng nhập và tải lịch học, lịch thi, bảng điểm.'
                    : 'Bạn có thể thêm việc cá nhân hoặc chọn ngày khác để xem lịch.',
                actionLabel: profile == null ? 'Mở đồng bộ' : 'Thêm việc',
                onAction: profile == null ? onOpenSyncTab : onAddTask,
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
                    onEditNote: () => onEditEvent(event),
                    onDelete: event.type == StudentEventType.personalTask
                        ? () => onDeleteEvent(event)
                        : null,
                    onOpenAttachment: onOpenAttachment,
                    onToggleDone: event.type == StudentEventType.personalTask
                        ? () => onToggleDone(event.id)
                        : null,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ScheduleHeroCard extends StatelessWidget {
  const _ScheduleHeroCard({
    required this.eventsForDay,
    required this.profile,
    required this.selectedDate,
    required this.lastSyncedAt,
    required this.formatFullDate,
    required this.formatTime,
    required this.formatSyncTimestamp,
  });

  final List<StudentEvent> eventsForDay;
  final StudentProfile? profile;
  final DateTime selectedDate;
  final DateTime? lastSyncedAt;
  final String Function(DateTime date) formatFullDate;
  final String Function(DateTime value) formatTime;
  final String Function(DateTime value) formatSyncTimestamp;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final classCount = eventsForDay
        .where((event) => event.type == StudentEventType.classSchedule)
        .length;
    final examCount = eventsForDay
        .where((event) => event.type == StudentEventType.exam)
        .length;
    final taskCount = eventsForDay
        .where((event) => event.type == StudentEventType.personalTask)
        .length;
    final upcomingEvent = eventsForDay.cast<StudentEvent?>().firstWhere(
      (event) => event!.start.isAfter(DateTime.now()),
      orElse: () => eventsForDay.isEmpty ? null : eventsForDay.first,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile?.displayName ?? 'Lịch học tập',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onPrimaryContainer,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            formatFullDate(selectedDate),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.86),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroCountChip(label: 'Lịch học', count: classCount),
              _HeroCountChip(label: 'Lịch thi', count: examCount),
              _HeroCountChip(label: 'Việc riêng', count: taskCount),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                upcomingEvent == null
                    ? 'Hôm nay chưa có sự kiện nào được lên lịch.'
                    : 'Tiếp theo: ${formatTime(upcomingEvent.start)} • ${upcomingEvent.title}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
          if (lastSyncedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              'Đồng bộ gần nhất: ${formatSyncTimestamp(lastSyncedAt!)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.72),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({
    required this.weatherPresentation,
    required this.isLoadingWeather,
    required this.onReloadWeather,
  });

  final WeatherPresentation? weatherPresentation;
  final bool isLoadingWeather;
  final VoidCallback onReloadWeather;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isLoadingWeather) {
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

    if (weatherPresentation == null) {
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
              onPressed: onReloadWeather,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      );
    }

    final suggestions = weatherPresentation!.suggestions;
    final forecast = _WeatherMetricForecast.fromPresentation(
      weatherPresentation!,
    );
    final dynamic weatherForecast = _WeatherLocationLabel(
      weatherPresentation!.locationLabel,
    );

    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(
                weatherPresentation!.icon,
                size: 26,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thời tiết ${weatherForecast?.locationLabel ?? 'Hà Nội'}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      weatherPresentation!.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Tải lại',
                visualDensity: VisualDensity.compact,
                onPressed: onReloadWeather,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
            ],
          ),
          if (suggestions.isNotEmpty) ...[const SizedBox(height: 10)],
          ...suggestions.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncReminder extends StatelessWidget {
  const _SyncReminder({required this.onHide});

  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: const ValueKey('sync-reminder'),
      direction: DismissDirection.up,
      onDismissed: (_) => onHide(),
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
              onPressed: onHide,
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
}

class _ScheduleHeader extends StatelessWidget {
  const _ScheduleHeader({
    required this.selectedDate,
    required this.formatFullDate,
    required this.onOpenMonthPicker,
  });

  final DateTime selectedDate;
  final String Function(DateTime date) formatFullDate;
  final VoidCallback onOpenMonthPicker;

  @override
  Widget build(BuildContext context) {
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
                formatFullDate(selectedDate),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Chọn ngày',
          onPressed: onOpenMonthPicker,
          icon: const Icon(Icons.calendar_month_outlined),
        ),
      ],
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
    if (type != StudentEventType.classSchedule) {
      return false;
    }
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
    if (attachment.isPdf) {
      return Icons.picture_as_pdf_outlined;
    }
    if (attachment.isImage) {
      return Icons.image_outlined;
    }
    return Icons.attach_file_outlined;
  }
}

class _HeroCountChip extends StatelessWidget {
  const _HeroCountChip({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $count',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
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
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
      ),
    );
  }
}

class _WeatherLocationLabel {
  const _WeatherLocationLabel(this.locationLabel);

  final String locationLabel;
}

class _WeatherMetricForecast {
  const _WeatherMetricForecast({
    required this.temperatureMin,
    required this.temperatureMax,
    required this.precipitationProbabilityMax,
  });

  factory _WeatherMetricForecast.fromPresentation(
    WeatherPresentation presentation,
  ) {
    return _WeatherMetricForecast(
      temperatureMin: presentation.temperatureMin,
      temperatureMax: presentation.temperatureMax,
      precipitationProbabilityMax: presentation.precipitationProbabilityMax,
    );
  }

  final int temperatureMin;
  final int temperatureMax;
  final int precipitationProbabilityMax;
}
