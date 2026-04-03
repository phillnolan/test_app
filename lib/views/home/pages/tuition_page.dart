import 'package:flutter/material.dart';

import '../../../models/current_tuition.dart';
import '../../../models/student_profile.dart';
import '../widgets/home_common_widgets.dart';

class TuitionPage extends StatelessWidget {
  const TuitionPage({
    super.key,
    required this.profile,
    required this.currentTuition,
    required this.onOpenAccountTab,
  });

  final StudentProfile? profile;
  final CurrentTuition? currentTuition;
  final VoidCallback onOpenAccountTab;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _TuitionHeroCard(profile: profile, currentTuition: currentTuition),
        const SizedBox(height: 16),
        if (currentTuition == null)
          EmptyStateCard(
            icon: Icons.receipt_long_outlined,
            title: 'Chưa có dữ liệu học phí',
            description:
                'Hãy vào trang Tài khoản để đồng bộ dữ liệu học phí kỳ hiện tại từ cổng trường.',
            actionLabel: 'Mở tài khoản',
            onAction: onOpenAccountTab,
          )
        else ...[
          _TuitionSummaryCard(currentTuition: currentTuition!),
          const SizedBox(height: 16),
          Text(
            'Các môn của kỳ hiện tại',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...currentTuition!.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TuitionSubjectCard(item: item),
            ),
          ),
        ],
      ],
    );
  }
}

class _TuitionHeroCard extends StatelessWidget {
  const _TuitionHeroCard({required this.profile, required this.currentTuition});

  final StudentProfile? profile;
  final CurrentTuition? currentTuition;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.secondaryContainer,
            colorScheme.primaryContainer.withValues(alpha: 0.9),
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
            'Học phí',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currentTuition == null
                ? 'Đồng bộ để xem học phí của kỳ hiện tại.'
                : '${profile?.displayName ?? 'Sinh viên'} • ${currentTuition!.semesterLabel}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSecondaryContainer.withValues(alpha: 0.86),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _TuitionSummaryCard extends StatelessWidget {
  const _TuitionSummaryCard({required this.currentTuition});

  final CurrentTuition currentTuition;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentTuition.registerPeriodLabel,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SummaryChip(
                label: 'Tổng học phí',
                value: _formatCurrency(currentTuition.totalAmount),
              ),
              _SummaryChip(
                label: 'Đã thu',
                value: _formatCurrency(currentTuition.paidAmount),
              ),
              _SummaryChip(
                label: 'Còn lại',
                value: _formatCurrency(currentTuition.outstandingAmount),
                highlight: currentTuition.outstandingAmount > 0,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = highlight
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;
    final foreground = highlight
        ? colorScheme.onErrorContainer
        : colorScheme.onPrimaryContainer;

    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TuitionSubjectCard extends StatelessWidget {
  const _TuitionSubjectCard({required this.item});

  final TuitionSubjectCharge item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.subjectName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                if ((item.subjectCode ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.subjectCode!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatCurrency(item.amount),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCurrency(double value) {
  final rounded = value.round();
  final digits = rounded.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    final reverseIndex = digits.length - index;
    buffer.write(digits[index]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }
  return '${buffer.toString()} đ';
}
