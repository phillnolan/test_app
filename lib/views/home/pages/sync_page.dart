import 'package:flutter/material.dart';

import '../../../models/student_profile.dart';
import '../widgets/home_common_widgets.dart';

class SyncPage extends StatelessWidget {
  const SyncPage({
    super.key,
    required this.isSyncing,
    required this.onSync,
    required this.lastSyncedAt,
    required this.profile,
    required this.syncedEventCount,
    required this.gradeCount,
    required this.personalEventCount,
  });

  final bool isSyncing;
  final VoidCallback onSync;
  final DateTime? lastSyncedAt;
  final StudentProfile? profile;
  final int syncedEventCount;
  final int gradeCount;
  final int personalEventCount;

  @override
  Widget build(BuildContext context) {
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
          isSyncing: isSyncing,
          onSync: onSync,
          lastSyncedAt: lastSyncedAt,
        ),
        const SizedBox(height: 16),
        if (profile != null)
          _ProfileCard(profile: profile!)
        else
          const PlaceholderInfoCard(
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
              value: syncedEventCount.toString(),
            ),
            _MetricCard(
              icon: Icons.school_outlined,
              label: 'Môn có điểm',
              value: gradeCount.toString(),
            ),
            _MetricCard(
              icon: Icons.task_alt_outlined,
              label: 'Việc cá nhân',
              value: personalEventCount.toString(),
            ),
          ],
        ),
      ],
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
