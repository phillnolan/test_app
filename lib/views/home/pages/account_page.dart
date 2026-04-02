import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/home_common_widgets.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({
    super.key,
    required this.isAuthAvailable,
    required this.user,
    required this.onEmailAuth,
    required this.onGoogleAuth,
    required this.onSignOut,
  });

  final bool isAuthAvailable;
  final User? user;
  final VoidCallback onEmailAuth;
  final VoidCallback onGoogleAuth;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text('Tài khoản', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Đăng nhập là tùy chọn. Tài khoản chỉ dùng để đồng bộ ghi chú, tệp đính kèm và dữ liệu đã lưu lên cloud.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (!isAuthAvailable)
          const PlaceholderInfoCard(
            icon: Icons.cloud_off_outlined,
            title: 'Firebase chưa sẵn sàng',
            description:
                'App chưa khởi tạo Firebase. Hãy kiểm tra cấu hình Firebase nếu muốn đăng nhập.',
          )
        else if (user == null)
          _AuthEntryCard(onEmailAuth: onEmailAuth, onGoogleAuth: onGoogleAuth)
        else
          _SignedInCard(user: user!, onSignOut: onSignOut),
        const SizedBox(height: 16),
        const PlaceholderInfoCard(
          icon: Icons.offline_bolt_outlined,
          title: 'Chế độ offline',
          description:
              'Dữ liệu đồng bộ, ghi chú và việc cá nhân hiện đã được lưu lại trên điện thoại để bạn mở app lần sau vẫn xem được.',
        ),
      ],
    );
  }
}

class _AuthEntryCard extends StatelessWidget {
  const _AuthEntryCard({required this.onEmailAuth, required this.onGoogleAuth});

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
            'Đăng nhập để lưu cloud',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Tài khoản ứng dụng được dùng để lưu ghi chú, tệp đính kèm và dữ liệu đồng bộ lên Firebase/Cloudflare.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onGoogleAuth,
            icon: const Icon(Icons.account_circle_outlined),
            label: const Text('Đăng nhập Google'),
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
  const _SignedInCard({required this.user, required this.onSignOut});

  final User user;
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
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
            label: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
