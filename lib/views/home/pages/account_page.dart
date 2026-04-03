import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/student_profile.dart';
import '../widgets/home_common_widgets.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({
    super.key,
    required this.isAuthAvailable,
    required this.user,
    required this.profile,
    required this.linkedStudentUsername,
    required this.isSyncing,
    required this.isLinkingStudent,
    required this.isRestoringCloudData,
    required this.isSigningOut,
    required this.showRestoreWarning,
    required this.hasSavedSyncCredentials,
    required this.lastSyncedAt,
    required this.syncedEventCount,
    required this.gradeCount,
    required this.personalEventCount,
    required this.onDismissRestoreWarning,
    required this.onEmailAuth,
    required this.onGoogleAuth,
    required this.onSync,
    required this.onManageSyncCredentials,
    required this.onSignOut,
  });

  final bool isAuthAvailable;
  final User? user;
  final StudentProfile? profile;
  final String? linkedStudentUsername;
  final bool isSyncing;
  final bool isLinkingStudent;
  final bool isRestoringCloudData;
  final bool isSigningOut;
  final bool showRestoreWarning;
  final bool hasSavedSyncCredentials;
  final DateTime? lastSyncedAt;
  final int syncedEventCount;
  final int gradeCount;
  final int personalEventCount;
  final VoidCallback onDismissRestoreWarning;
  final VoidCallback onEmailAuth;
  final VoidCallback onGoogleAuth;
  final VoidCallback onSync;
  final VoidCallback onManageSyncCredentials;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final hasLinkedStudent =
        linkedStudentUsername != null &&
        linkedStudentUsername!.trim().isNotEmpty;
    final hasLocalStudent = profile != null;
    final statusLabel = isSigningOut
        ? 'Đang đăng xuất'
        : isRestoringCloudData
        ? 'Đang tải dữ liệu tài khoản'
        : isLinkingStudent
        ? 'Đang hoàn tất liên kết'
        : switch ((user != null, hasLinkedStudent, hasLocalStudent)) {
            (false, _, true) => 'Đã đồng bộ cục bộ',
            (false, _, false) => 'Chưa đăng nhập',
            (true, true, true) => 'Đã liên kết',
            (true, true, false) => 'Có liên kết cloud',
            (true, false, _) => 'Chờ liên kết sinh viên',
          };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          'Tài khoản & đồng bộ',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Đăng nhập tài khoản ứng dụng, liên kết với tài khoản sinh viên và quản lý toàn bộ dữ liệu học tập, ghi chú, ảnh, tệp ở một nơi.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (showRestoreWarning) ...[
          const SizedBox(height: 14),
          _RestoreWarningBanner(onDismiss: onDismissRestoreWarning),
        ],
        const SizedBox(height: 16),
        _OverviewCard(
          statusLabel: statusLabel,
          isSignedIn: user != null,
          linkedStudentUsername: linkedStudentUsername,
          profile: profile,
          isLinkingStudent: isLinkingStudent,
          isRestoringCloudData: isRestoringCloudData,
        ),
        const SizedBox(height: 16),
        if (!isAuthAvailable)
          const PlaceholderInfoCard(
            icon: Icons.cloud_off_outlined,
            title: 'Firebase chưa sẵn sàng',
            description:
                'App chưa khởi tạo Firebase. Hãy kiểm tra cấu hình nếu muốn đăng nhập và liên kết dữ liệu cloud.',
          )
        else if (user == null)
          _SignedOutCard(
            profile: profile,
            onEmailAuth: onEmailAuth,
            onGoogleAuth: onGoogleAuth,
          )
        else
          _SignedInCard(
            user: user!,
            isSigningOut: isSigningOut,
            onSignOut: onSignOut,
          ),
        const SizedBox(height: 16),
        _StudentLinkCard(
          profile: profile,
          linkedStudentUsername: linkedStudentUsername,
          isSyncing: isSyncing,
          isLinkingStudent: isLinkingStudent,
          isRestoringCloudData: isRestoringCloudData,
          hasSavedSyncCredentials: hasSavedSyncCredentials,
          lastSyncedAt: lastSyncedAt,
          onSync: onSync,
          onManageSyncCredentials: onManageSyncCredentials,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              icon: Icons.event_note_outlined,
              label: 'Sự kiện đồng bộ',
              value: syncedEventCount.toString(),
            ),
            _MetricCard(
              icon: Icons.school_outlined,
              label: 'Môn có điểm',
              value: gradeCount.toString(),
            ),
            _MetricCard(
              icon: Icons.task_alt_outlined,
              label: 'Ghi chú cá nhân',
              value: personalEventCount.toString(),
            ),
          ],
        ),
      ],
    );
  }
}

class _RestoreWarningBanner extends StatelessWidget {
  const _RestoreWarningBanner({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFFFE7B8);
    const borderColor = Color(0xFFF2B84B);
    const foregroundColor = Color(0xFF7A4B00);

    return Dismissible(
      key: const ValueKey('cloud-restore-warning'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) => onDismiss(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A7A4B00),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0x33FFFFFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: foregroundColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Đang tải dữ liệu, vui chờ đến lúc hoàn tất để tránh xảy ra lỗi.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, color: foregroundColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.statusLabel,
    required this.isSignedIn,
    required this.linkedStudentUsername,
    required this.profile,
    required this.isLinkingStudent,
    required this.isRestoringCloudData,
  });

  final String statusLabel;
  final bool isSignedIn;
  final String? linkedStudentUsername;
  final StudentProfile? profile;
  final bool isLinkingStudent;
  final bool isRestoringCloudData;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final subtitle = isRestoringCloudData
        ? 'Đang tải dữ liệu từ tài khoản đã liên kết. Vui lòng chờ hoàn tất trước khi tiếp tục đồng bộ.'
        : isLinkingStudent
        ? 'Đang lưu liên kết với ${profile?.displayName ?? linkedStudentUsername ?? 'sinh viên hiện tại'}. Vui lòng chờ trong giây lát.'
        : linkedStudentUsername ??
              profile?.displayName ??
              'Đăng nhập để bắt đầu liên kết dữ liệu.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.surfaceContainerLow,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  isSignedIn
                      ? Icons.verified_user_outlined
                      : Icons.person_outline,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusLabel,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(
                icon: isSignedIn
                    ? Icons.lock_open_outlined
                    : Icons.lock_outline,
                label: isSignedIn ? 'Đã đăng nhập' : 'Khách',
              ),
              _StatusChip(
                icon: linkedStudentUsername == null
                    ? Icons.link_off_outlined
                    : Icons.link_outlined,
                label: linkedStudentUsername == null
                    ? 'Chưa liên kết sinh viên'
                    : 'Liên kết: $linkedStudentUsername',
                isLoading: isLinkingStudent || isRestoringCloudData,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignedOutCard extends StatelessWidget {
  const _SignedOutCard({
    required this.profile,
    required this.onEmailAuth,
    required this.onGoogleAuth,
  });

  final StudentProfile? profile;
  final VoidCallback onEmailAuth;
  final VoidCallback onGoogleAuth;

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
            'Đăng nhập tài khoản ứng dụng',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            profile == null
                ? 'Đăng nhập để liên kết dữ liệu khi bạn đồng bộ tài khoản sinh viên.'
                : 'Bạn đang có dữ liệu của ${profile!.displayName}. Đăng nhập để liên kết và sao lưu toàn bộ dữ liệu này lên cloud.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onGoogleAuth,
            icon: const Icon(Icons.account_circle_outlined),
            label: const Text('Tiếp tục với Google'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onEmailAuth,
            icon: const Icon(Icons.mail_outline),
            label: const Text('Email và mật khẩu'),
          ),
        ],
      ),
    );
  }
}

class _SignedInCard extends StatelessWidget {
  const _SignedInCard({
    required this.user,
    required this.isSigningOut,
    required this.onSignOut,
  });

  final User user;
  final bool isSigningOut;
  final VoidCallback onSignOut;

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
            user.displayName?.trim().isNotEmpty == true
                ? user.displayName!
                : (user.email ?? 'Tài khoản ứng dụng'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            user.email ?? 'Đã đăng nhập',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.tonalIcon(
            onPressed: isSigningOut ? null : onSignOut,
            icon: isSigningOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            label: Text(isSigningOut ? 'Đang đăng xuất...' : 'Đăng xuất'),
          ),
        ],
      ),
    );
  }
}

class _StudentLinkCard extends StatelessWidget {
  const _StudentLinkCard({
    required this.profile,
    required this.linkedStudentUsername,
    required this.isSyncing,
    required this.isLinkingStudent,
    required this.isRestoringCloudData,
    required this.hasSavedSyncCredentials,
    required this.lastSyncedAt,
    required this.onSync,
    required this.onManageSyncCredentials,
  });

  final StudentProfile? profile;
  final String? linkedStudentUsername;
  final bool isSyncing;
  final bool isLinkingStudent;
  final bool isRestoringCloudData;
  final bool hasSavedSyncCredentials;
  final DateTime? lastSyncedAt;
  final VoidCallback onSync;
  final VoidCallback onManageSyncCredentials;

  @override
  Widget build(BuildContext context) {
    final isBusy = isSyncing || isLinkingStudent || isRestoringCloudData;
    final syncLabel = isSyncing
        ? 'Đang đồng bộ...'
        : isRestoringCloudData
        ? 'Đang tải dữ liệu...'
        : isLinkingStudent
        ? 'Đang lưu liên kết...'
        : hasSavedSyncCredentials
        ? 'Đồng bộ ngay'
        : 'Đồng bộ tài khoản sinh viên';
    final isLinked =
        linkedStudentUsername != null &&
        linkedStudentUsername!.trim().isNotEmpty &&
        profile != null &&
        linkedStudentUsername!.trim().toLowerCase() ==
            profile!.username.trim().toLowerCase();
    final description = isRestoringCloudData
        ? 'Đang tải dữ liệu từ cloud của tài khoản đã liên kết. Tạm thời khóa đồng bộ để tránh chồng lấn dữ liệu.'
        : isLinkingStudent
        ? 'Đang lưu liên kết giữa tài khoản ứng dụng và ${profile?.displayName ?? linkedStudentUsername ?? 'sinh viên hiện tại'}. Vui lòng chờ hoàn tất.'
        : profile == null
        ? 'Chưa có tài khoản sinh viên nào được đồng bộ trên thiết bị này.'
        : linkedStudentUsername == null
        ? 'Sinh viên ${profile!.displayName} đang ở trên thiết bị nhưng chưa liên kết với tài khoản ứng dụng.'
        : isLinked
        ? 'Tài khoản ứng dụng hiện đang liên kết với ${profile!.displayName}.'
        : 'Tài khoản ứng dụng đang liên kết với $linkedStudentUsername, còn dữ liệu hiện tại trên máy là ${profile!.displayName}.';

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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Liên kết sinh viên',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (isLinkingStudent)
                const _StatusChip(
                  icon: Icons.sync,
                  label: 'Đang lưu liên kết',
                  isLoading: true,
                )
              else if (isLinked)
                const _StatusChip(
                  icon: Icons.check_circle_outline,
                  label: 'Đã liên kết',
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (isBusy) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 14),
          if (profile != null) ...[
            _ProfileLine(label: 'Tên hiển thị', value: profile!.displayName),
            _ProfileLine(label: 'Tài khoản', value: profile!.username),
            if ((profile!.studentCode ?? '').isNotEmpty)
              _ProfileLine(label: 'Mã sinh viên', value: profile!.studentCode!),
            if ((profile!.className ?? '').isNotEmpty)
              _ProfileLine(label: 'Lớp', value: profile!.className!),
            const SizedBox(height: 10),
          ],
          Text(
            lastSyncedAt == null
                ? 'Bạn chưa đồng bộ lần nào.'
                : 'Lần gần nhất: ${_formatTimestamp(lastSyncedAt!)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isBusy ? null : onSync,
                  icon: isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync),
                  label: Text(syncLabel),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                tooltip: hasSavedSyncCredentials
                    ? 'Đổi tài khoản hoặc mật khẩu sinh viên'
                    : 'Nhập tài khoản sinh viên',
                onPressed: isBusy ? null : onManageSyncCredentials,
                icon: const Icon(Icons.autorenew_rounded),
              ),
            ],
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
            width: 104,
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}
