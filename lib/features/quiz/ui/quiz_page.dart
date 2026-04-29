import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quiz_models.dart';
import 'quiz_controller.dart';

/// Quiz feature landing page.
class QuizPage extends ConsumerStatefulWidget {
  const QuizPage({super.key});

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

final class _QuizPageState extends ConsumerState<QuizPage> {
  String? _selectedBankId;

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(quizCatalogProvider);
    final quizState = ref.watch(quizControllerProvider);
    final banks = catalogAsync.asData?.value ?? const <QuizBankMetadata>[];
    final activeSession = quizState.session;
    final totals = _QuizCatalogTotals.fromBanks(banks);
    final selectedBank = banks.isEmpty ? null : _resolveSelectedBank(banks);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _QuizHeroCard(
          bankCount: totals.bankCount,
          questionCount: totals.questionCount,
          practiceSetCount: totals.practiceSetCount,
          skippedQuestionCount: totals.skippedQuestionCount,
          isLoading: catalogAsync.isLoading,
          hasActiveSession: activeSession != null,
          isStarting: quizState.isStarting,
        ),
        const SizedBox(height: 16),
        if (quizState.errorMessage != null) ...[
          _InlineMessageCard(
            icon: Icons.error_outline,
            title: 'Không tải được bộ đề',
            description: quizState.errorMessage!,
            tintColor: Theme.of(context).colorScheme.errorContainer,
          ),
          const SizedBox(height: 16),
        ],
        if (catalogAsync.hasError) ...[
          _InlineMessageCard(
            icon: Icons.cloud_off_outlined,
            title: 'Không đọc được dữ liệu quiz',
            description:
                'App không thể tải manifest của `data-quiz`. Hãy kiểm tra lại asset đã được đóng gói.',
            tintColor: Theme.of(context).colorScheme.errorContainer,
          ),
          const SizedBox(height: 16),
        ],
        if (quizState.isStarting) ...[
          const _LoadingQuizCard(),
          const SizedBox(height: 16),
        ],
        if (activeSession != null) ...[
          _QuizSessionSection(
            session: activeSession,
            onRestartSession: () =>
                ref.read(quizControllerProvider.notifier).restartSession(),
            onClearSession: ref
                .read(quizControllerProvider.notifier)
                .clearSession,
            onOptionSelected: ref
                .read(quizControllerProvider.notifier)
                .selectOption,
            onSubmitAnswer: ref
                .read(quizControllerProvider.notifier)
                .submitCurrentAnswer,
            onGoToNextQuestion: ref
                .read(quizControllerProvider.notifier)
                .goToNextQuestion,
            onGoToPreviousQuestion: ref
                .read(quizControllerProvider.notifier)
                .goToPreviousQuestion,
            onJumpToQuestion: ref
                .read(quizControllerProvider.notifier)
                .jumpToQuestion,
          ),
          const SizedBox(height: 16),
        ],
        if (banks.isEmpty)
          const _InlineMessageCard(
            icon: Icons.quiz_outlined,
            title: 'Chưa có môn nào',
            description: 'Không tìm thấy bộ quiz nào trong manifest hiện tại.',
            tintColor: null,
          )
        else ...[
          _QuizSubjectSection(
            banks: banks,
            selectedBankId: selectedBank!.id,
            isBusy: quizState.isStarting,
            onSubjectTap: (bank) {
              setState(() {
                _selectedBankId = bank.id;
              });
            },
          ),
          const SizedBox(height: 16),
          _QuizPracticeSetSection(
            bank: selectedBank,
            isBusy: quizState.isStarting,
            hasActiveSession: activeSession != null,
            onPracticeSetTap: (setNumber) {
              unawaited(
                _handlePracticeSetTap(
                  context: context,
                  bank: selectedBank,
                  setNumber: setNumber,
                  activeSession: activeSession,
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  QuizBankMetadata _resolveSelectedBank(List<QuizBankMetadata> banks) {
    final selectedBankId = _selectedBankId;
    if (selectedBankId != null) {
      for (final bank in banks) {
        if (bank.id == selectedBankId) {
          return bank;
        }
      }
    }

    return banks.first;
  }

  Future<void> _handlePracticeSetTap({
    required BuildContext context,
    required QuizBankMetadata bank,
    required int setNumber,
    required QuizSession? activeSession,
  }) async {
    if (activeSession != null && !activeSession.isCompleted) {
      final shouldReplace = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Đổi bộ đề?'),
          content: const Text(
            'Bạn đang làm dở một bộ đề khác. Nếu tiếp tục, tiến độ hiện tại sẽ bị thay thế.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Giữ bộ hiện tại'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Đổi bộ đề'),
            ),
          ],
        ),
      );
      if (shouldReplace != true || !context.mounted) {
        return;
      }
    }

    await ref
        .read(quizControllerProvider.notifier)
        .startQuiz(
          bank,
          questionCount: quizPracticeDeckSize,
          setNumber: setNumber,
        );
  }
}

class _QuizHeroCard extends StatelessWidget {
  const _QuizHeroCard({
    required this.bankCount,
    required this.questionCount,
    required this.practiceSetCount,
    required this.skippedQuestionCount,
    required this.isLoading,
    required this.hasActiveSession,
    required this.isStarting,
  });

  final int bankCount;
  final int questionCount;
  final int practiceSetCount;
  final int skippedQuestionCount;
  final bool isLoading;
  final bool hasActiveSession;
  final bool isStarting;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tintColor = hasActiveSession
        ? colorScheme.primaryContainer
        : colorScheme.tertiaryContainer;
    final foregroundColor = hasActiveSession
        ? colorScheme.onPrimaryContainer
        : colorScheme.onTertiaryContainer;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tintColor.withValues(alpha: 0.92),
            colorScheme.secondaryContainer.withValues(alpha: 0.94),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quiz theo môn',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: foregroundColor,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chọn môn, mở từng đề 50 câu và ôn đi ôn lại nhiều lần để nhớ sâu hơn.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.35,
                        color: foregroundColor.withValues(alpha: 0.86),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.quiz_outlined, size: 40, color: foregroundColor),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroMetric(
                label: 'Môn học',
                value: isLoading ? '...' : _formatCount(bankCount),
                icon: Icons.view_list_outlined,
              ),
              _HeroMetric(
                label: 'Câu khả dụng',
                value: isLoading ? '...' : _formatCount(questionCount),
                icon: Icons.help_outline,
              ),
              _HeroMetric(
                label: 'Đề 50 câu',
                value: isLoading ? '...' : _formatCount(practiceSetCount),
                icon: Icons.grid_view_rounded,
              ),
              if (skippedQuestionCount > 0)
                _HeroMetric(
                  label: 'Câu trống đáp án',
                  value: _formatCount(skippedQuestionCount),
                  icon: Icons.report_outlined,
                ),
            ],
          ),
          if (isStarting) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              minHeight: 4,
              borderRadius: BorderRadius.circular(999),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurface),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingQuizCard extends StatelessWidget {
  const _LoadingQuizCard();

  @override
  Widget build(BuildContext context) {
    return const _InlineMessageCard(
      icon: Icons.hourglass_top_outlined,
      title: 'Đang chuẩn bị quiz',
      description:
          'App đang nạp bộ đề và xáo trộn câu hỏi cho phiên làm bài mới.',
      tintColor: null,
      showProgress: true,
    );
  }
}

class _InlineMessageCard extends StatelessWidget {
  const _InlineMessageCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.tintColor,
    this.showProgress = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color? tintColor;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = tintColor ?? colorScheme.surfaceContainerLow;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showProgress) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(minHeight: 4),
          ],
        ],
      ),
    );
  }
}

class _QuizSubjectSection extends StatelessWidget {
  const _QuizSubjectSection({
    required this.banks,
    required this.selectedBankId,
    required this.isBusy,
    required this.onSubjectTap,
  });

  final List<QuizBankMetadata> banks;
  final String selectedBankId;
  final bool isBusy;
  final ValueChanged<QuizBankMetadata> onSubjectTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Môn học',
          subtitle:
              'Mỗi môn được hiển thị dưới dạng card. Chọn một môn để mở các đề 50 câu tương ứng.',
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = _gridCardWidth(constraints.maxWidth);
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final bank in banks)
                  SizedBox(
                    width: cardWidth,
                    child: _QuizSubjectCard(
                      bank: bank,
                      isBusy: isBusy,
                      isSelected: bank.id == selectedBankId,
                      onTap: () => onSubjectTap(bank),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuizSubjectCard extends StatelessWidget {
  const _QuizSubjectCard({
    required this.bank,
    required this.isBusy,
    required this.isSelected,
    required this.onTap,
  });

  final QuizBankMetadata bank;
  final bool isBusy;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = Color(bank.accentColor);
    final visual = _bankVisual(bank);
    final backgroundColor = isSelected
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerLow;
    final borderColor = isSelected
        ? colorScheme.primary
        : colorScheme.outlineVariant;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: isBusy ? null : onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.6 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(visual.icon, color: accent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                bank.title,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _MiniBadge(
                          icon: Icons.code,
                          label: bank.code,
                          tintColor: colorScheme.surface.withValues(
                            alpha: 0.72,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                bank.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.35,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniBadge(
                    icon: Icons.library_books_outlined,
                    label: '${_formatCount(quizPracticeDeckSize)} câu/đề',
                    tintColor: accent.withValues(alpha: 0.12),
                  ),
                  _MiniBadge(
                    icon: Icons.collections_bookmark_outlined,
                    label: '${_formatCount(_practiceSetCountFor(bank))} đề',
                    tintColor: colorScheme.surface.withValues(alpha: 0.72),
                  ),
                  _MiniBadge(
                    icon: Icons.quiz_outlined,
                    label: '${_formatCount(bank.questionCount)} câu',
                    tintColor: colorScheme.surface.withValues(alpha: 0.72),
                  ),
                ],
              ),
              if (bank.hasSkippedQuestions) ...[
                const SizedBox(height: 10),
                Text(
                  'Bộ gốc có ${_formatCount(bank.sourceQuestionCount)} câu, '
                  'app đã lọc ${_formatCount(bank.skippedQuestionCount)} câu chưa có đáp án.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.35,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizPracticeSetSection extends StatelessWidget {
  const _QuizPracticeSetSection({
    required this.bank,
    required this.isBusy,
    required this.hasActiveSession,
    required this.onPracticeSetTap,
  });

  final QuizBankMetadata bank;
  final bool isBusy;
  final bool hasActiveSession;
  final ValueChanged<int> onPracticeSetTap;

  @override
  Widget build(BuildContext context) {
    final practiceSetCount = _practiceSetCountFor(bank);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Các đề của ${bank.title}',
          subtitle: hasActiveSession
              ? 'Đang có một phiên làm bài mở. Chọn đề mới sẽ thay thế tiến độ hiện tại.'
              : 'Mỗi đề có đúng ${_formatCount(quizPracticeDeckSize)} câu và được xáo trộn riêng để bạn ôn đi ôn lại nhiều lần.',
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = _gridCardWidth(constraints.maxWidth);
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final setNumber in _practiceSetNumbers(practiceSetCount))
                  SizedBox(
                    width: cardWidth,
                    child: _QuizPracticeSetCard(
                      bank: bank,
                      setNumber: setNumber,
                      isBusy: isBusy,
                      onTap: () => onPracticeSetTap(setNumber),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuizPracticeSetCard extends StatelessWidget {
  const _QuizPracticeSetCard({
    required this.bank,
    required this.setNumber,
    required this.isBusy,
    required this.onTap,
  });

  final QuizBankMetadata bank;
  final int setNumber;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = Color(bank.accentColor);

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: isBusy ? null : onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _formatCount(setNumber),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đề $setNumber',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bank.title,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Ôn lại bằng ${_formatCount(quizPracticeDeckSize)} câu cố định. '
                'Làm xong có thể vào lại để làm cùng đề hoặc chọn đề khác.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.35,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniBadge(
                    icon: Icons.replay_outlined,
                    label: 'Ôn lặp lại',
                    tintColor: colorScheme.surface.withValues(alpha: 0.72),
                  ),
                  _MiniBadge(
                    icon: Icons.grid_view_rounded,
                    label: '${_formatCount(quizPracticeDeckSize)} câu',
                    tintColor: accent.withValues(alpha: 0.12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizSessionSection extends StatelessWidget {
  const _QuizSessionSection({
    required this.session,
    required this.onRestartSession,
    required this.onClearSession,
    required this.onOptionSelected,
    required this.onSubmitAnswer,
    required this.onGoToNextQuestion,
    required this.onGoToPreviousQuestion,
    required this.onJumpToQuestion,
  });

  final QuizSession session;
  final Future<void> Function() onRestartSession;
  final VoidCallback onClearSession;
  final ValueChanged<int> onOptionSelected;
  final VoidCallback onSubmitAnswer;
  final VoidCallback onGoToNextQuestion;
  final VoidCallback onGoToPreviousQuestion;
  final ValueChanged<int> onJumpToQuestion;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: session.isCompleted ? 'Kết quả bài làm' : 'Bài đang làm',
          subtitle: session.isCompleted
              ? 'Bạn có thể xem lại từng câu, làm lại đề này hoặc đổi sang đề khác.'
              : 'Hoàn thành từng câu, sau đó lướt lại để ôn những câu đã làm.',
        ),
        const SizedBox(height: 12),
        _QuizSummaryCard(
          session: session,
          onRestartSession: onRestartSession,
          onClearSession: onClearSession,
        ),
        const SizedBox(height: 12),
        _QuizQuestionCard(
          session: session,
          onOptionSelected: onOptionSelected,
          onSubmitAnswer: onSubmitAnswer,
          onGoToNextQuestion: onGoToNextQuestion,
          onGoToPreviousQuestion: onGoToPreviousQuestion,
          onRestartSession: onRestartSession,
        ),
        const SizedBox(height: 12),
        _QuizReviewStrip(session: session, onJumpToQuestion: onJumpToQuestion),
      ],
    );
  }
}

class _QuizSummaryCard extends StatelessWidget {
  const _QuizSummaryCard({
    required this.session,
    required this.onRestartSession,
    required this.onClearSession,
  });

  final QuizSession session;
  final Future<void> Function() onRestartSession;
  final VoidCallback onClearSession;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scorePercent = (session.scorePercent * 100).round();
    final elapsed = switch (session.completedAt) {
      null => null,
      final completedAt => completedAt.difference(session.startedAt),
    };
    final elapsedLabel = switch (elapsed) {
      null => 'Đang làm bài',
      final value => 'Thời gian: ${_formatDuration(value)}',
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.bank.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MiniBadge(
                          icon: Icons.view_list_outlined,
                          label: 'Đề ${session.practiceSetNumber}',
                          tintColor: colorScheme.surface.withValues(
                            alpha: 0.44,
                          ),
                        ),
                        _MiniBadge(
                          icon: Icons.grid_view_rounded,
                          label: '${_formatCount(session.questionCount)} câu',
                          tintColor: colorScheme.surface.withValues(
                            alpha: 0.44,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$scorePercent%',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniBadge(
                icon: Icons.fact_check_outlined,
                label: '${_formatCount(session.answeredCount)} câu đã nộp',
                tintColor: colorScheme.surface.withValues(alpha: 0.44),
              ),
              _MiniBadge(
                icon: Icons.timelapse_outlined,
                label: elapsedLabel,
                tintColor: colorScheme.surface.withValues(alpha: 0.44),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  unawaited(onRestartSession());
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Làm lại'),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: onClearSession,
                icon: const Icon(Icons.view_list_outlined),
                label: const Text('Đổi bộ đề'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuizQuestionCard extends StatelessWidget {
  const _QuizQuestionCard({
    required this.session,
    required this.onOptionSelected,
    required this.onSubmitAnswer,
    required this.onGoToNextQuestion,
    required this.onGoToPreviousQuestion,
    required this.onRestartSession,
  });

  final QuizSession session;
  final ValueChanged<int> onOptionSelected;
  final VoidCallback onSubmitAnswer;
  final VoidCallback onGoToNextQuestion;
  final VoidCallback onGoToPreviousQuestion;
  final Future<void> Function() onRestartSession;

  @override
  Widget build(BuildContext context) {
    final question = session.currentQuestion;
    final attempt = session.currentAttempt;
    final colorScheme = Theme.of(context).colorScheme;
    final isLastQuestion = session.currentIndex == session.questions.length - 1;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MiniBadge(
                icon: Icons.confirmation_number_outlined,
                label:
                    'Câu ${_formatCount(session.currentIndex + 1)}/${_formatCount(session.questionCount)}',
                tintColor: colorScheme.surface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 10),
              if (question.hasMultipleCorrectAnswers)
                _MiniBadge(
                  icon: Icons.checklist_rtl,
                  label: 'Chọn nhiều đáp án',
                  tintColor: colorScheme.tertiaryContainer,
                )
              else
                _MiniBadge(
                  icon: Icons.radio_button_checked_outlined,
                  label: 'Chọn một đáp án',
                  tintColor: colorScheme.tertiaryContainer,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            question.question,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          ...question.options.asMap().entries.map((entry) {
            final optionIndex = entry.key;
            final optionText = entry.value;
            final isSelected = attempt.selectedOptionIndices.contains(
              optionIndex,
            );
            final isCorrect = question.correctOptionIndices.contains(
              optionIndex,
            );
            final optionState = _quizOptionState(
              isSubmitted: attempt.isSubmitted,
              isSelected: isSelected,
              isCorrect: isCorrect,
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _QuizOptionTile(
                label: _optionLabel(optionIndex),
                text: optionText,
                state: optionState,
                onTap: attempt.isSubmitted
                    ? null
                    : () => onOptionSelected(optionIndex),
              ),
            );
          }),
          if (attempt.isSubmitted) ...[
            const SizedBox(height: 10),
            _AnswerExplanationBox(question: question, attempt: attempt),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: session.currentIndex == 0
                    ? null
                    : onGoToPreviousQuestion,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Câu trước'),
              ),
              const Spacer(),
              if (!attempt.isSubmitted)
                FilledButton.icon(
                  onPressed: attempt.hasSelection ? onSubmitAnswer : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Nộp đáp án'),
                )
              else
                FilledButton.icon(
                  onPressed: isLastQuestion
                      ? () => unawaited(onRestartSession())
                      : onGoToNextQuestion,
                  icon: Icon(
                    isLastQuestion ? Icons.refresh : Icons.arrow_forward,
                  ),
                  label: Text(isLastQuestion ? 'Làm lại' : 'Câu tiếp'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnswerExplanationBox extends StatelessWidget {
  const _AnswerExplanationBox({required this.question, required this.attempt});

  final QuizQuestion question;
  final QuizQuestionAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCorrect = attempt.isCorrect;
    final background = isCorrect
        ? colorScheme.primaryContainer
        : colorScheme.errorContainer;
    final onBackground = isCorrect
        ? colorScheme.onPrimaryContainer
        : colorScheme.onErrorContainer;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCorrect ? 'Chính xác' : 'Chưa đúng',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đáp án đúng: ${_answerLetters(question.correctOptionIndices)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: onBackground,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question.explanationText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: onBackground.withValues(alpha: 0.92),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizReviewStrip extends StatelessWidget {
  const _QuizReviewStrip({
    required this.session,
    required this.onJumpToQuestion,
  });

  final QuizSession session;
  final ValueChanged<int> onJumpToQuestion;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Đi tới câu',
          subtitle: 'Dùng dải số để quay lại câu bất kỳ trong phiên làm bài.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var index = 0; index < session.questions.length; index++)
              _ReviewChip(
                label: _formatCount(index + 1),
                state: _questionProgressState(session: session, index: index),
                isSelected: index == session.currentIndex,
                onTap: () => onJumpToQuestion(index),
              ),
          ],
        ),
      ],
    );
  }
}

class _ReviewChip extends StatelessWidget {
  const _ReviewChip({
    required this.label,
    required this.state,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final _QuestionProgressState state;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = switch (state) {
      _QuestionProgressState.correct => colorScheme.primaryContainer,
      _QuestionProgressState.wrong => colorScheme.errorContainer,
      _QuestionProgressState.unanswered => colorScheme.surfaceContainerLow,
    };
    final borderColor = isSelected
        ? colorScheme.primary
        : colorScheme.outlineVariant;
    final textColor = switch (state) {
      _QuestionProgressState.correct => colorScheme.onPrimaryContainer,
      _QuestionProgressState.wrong => colorScheme.onErrorContainer,
      _QuestionProgressState.unanswered => colorScheme.onSurfaceVariant,
    };

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                switch (state) {
                  _QuestionProgressState.correct => Icons.check_circle_outline,
                  _QuestionProgressState.wrong => Icons.cancel_outlined,
                  _QuestionProgressState.unanswered => Icons.circle_outlined,
                },
                size: 16,
                color: textColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizOptionTile extends StatelessWidget {
  const _QuizOptionTile({
    required this.label,
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String label;
  final String text;
  final _QuizOptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = switch (state) {
      _QuizOptionState.neutral => colorScheme.surface,
      _QuizOptionState.selected => colorScheme.primaryContainer,
      _QuizOptionState.correctSelected => colorScheme.primaryContainer,
      _QuizOptionState.incorrectSelected => colorScheme.errorContainer,
      _QuizOptionState.correctUnselected => colorScheme.tertiaryContainer,
    };
    final borderColor = switch (state) {
      _QuizOptionState.neutral => colorScheme.outlineVariant,
      _QuizOptionState.selected => colorScheme.primary,
      _QuizOptionState.correctSelected => colorScheme.primary,
      _QuizOptionState.incorrectSelected => colorScheme.error,
      _QuizOptionState.correctUnselected => colorScheme.tertiary,
    };
    final textColor = switch (state) {
      _QuizOptionState.neutral => colorScheme.onSurface,
      _QuizOptionState.selected => colorScheme.onPrimaryContainer,
      _QuizOptionState.correctSelected => colorScheme.onPrimaryContainer,
      _QuizOptionState.incorrectSelected => colorScheme.onErrorContainer,
      _QuizOptionState.correctUnselected => colorScheme.onTertiaryContainer,
    };
    final leadingColor = switch (state) {
      _QuizOptionState.neutral => colorScheme.surfaceContainerHighest,
      _QuizOptionState.selected => colorScheme.primary,
      _QuizOptionState.correctSelected => colorScheme.primary,
      _QuizOptionState.incorrectSelected => colorScheme.error,
      _QuizOptionState.correctUnselected => colorScheme.tertiary,
    };
    final trailingIcon = switch (state) {
      _QuizOptionState.neutral => null,
      _QuizOptionState.selected => Icons.radio_button_checked_outlined,
      _QuizOptionState.correctSelected => Icons.check_circle_outline,
      _QuizOptionState.incorrectSelected => Icons.cancel_outlined,
      _QuizOptionState.correctUnselected => Icons.check_circle_outline,
    };

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: leadingColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.35,
                    color: textColor,
                  ),
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                Icon(trailingIcon, color: textColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.icon,
    required this.label,
    required this.tintColor,
  });

  final IconData icon;
  final String label;
  final Color tintColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tintColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.35,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

enum _QuizOptionState {
  neutral,
  selected,
  correctSelected,
  incorrectSelected,
  correctUnselected,
}

enum _QuestionProgressState { unanswered, correct, wrong }

_QuizOptionState _quizOptionState({
  required bool isSubmitted,
  required bool isSelected,
  required bool isCorrect,
}) {
  return switch ((isSubmitted, isSelected, isCorrect)) {
    (false, true, _) => _QuizOptionState.selected,
    (false, false, _) => _QuizOptionState.neutral,
    (true, true, true) => _QuizOptionState.correctSelected,
    (true, true, false) => _QuizOptionState.incorrectSelected,
    (true, false, true) => _QuizOptionState.correctUnselected,
    (true, false, false) => _QuizOptionState.neutral,
  };
}

_QuestionProgressState _questionProgressState({
  required QuizSession session,
  required int index,
}) {
  final attempt = session.attempts[index];
  if (!attempt.isSubmitted) {
    return _QuestionProgressState.unanswered;
  }

  return attempt.isCorrect
      ? _QuestionProgressState.correct
      : _QuestionProgressState.wrong;
}

_QuizBankVisual _bankVisual(QuizBankMetadata bank) {
  return switch (bank.code) {
    'CNPM' => const _QuizBankVisual(icon: Icons.build_circle_outlined),
    'LSD' => const _QuizBankVisual(icon: Icons.history_edu_outlined),
    'MMT' => const _QuizBankVisual(icon: Icons.router_outlined),
    'TTHCM' => const _QuizBankVisual(icon: Icons.school_outlined),
    'TTNT' => const _QuizBankVisual(icon: Icons.psychology_outlined),
    _ => const _QuizBankVisual(icon: Icons.quiz_outlined),
  };
}

String _optionLabel(int index) {
  return String.fromCharCode('A'.codeUnitAt(0) + index);
}

String _answerLetters(Set<int> indices) {
  final labels = indices.toList()..sort();
  return labels.map(_optionLabel).join(', ');
}

int _practiceSetCountFor(QuizBankMetadata bank) {
  final derived = (bank.questionCount / quizPracticeDeckSize).ceil();
  return derived.clamp(3, 12);
}

List<int> _practiceSetNumbers(int count) {
  return List<int>.generate(count, (index) => index + 1, growable: false);
}

double _gridCardWidth(double maxWidth) {
  if (maxWidth >= 1120) {
    return (maxWidth - 24) / 3;
  }
  if (maxWidth >= 720) {
    return (maxWidth - 12) / 2;
  }
  return maxWidth;
}

String _formatCount(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    final remaining = digits.length - index;
    if (index > 0 && remaining % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[index]);
  }
  final formatted = buffer.toString();
  return value < 0 ? '-$formatted' : formatted;
}

String _formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  if (hours > 0) {
    return '$hours giờ $minutes phút $seconds giây';
  }
  if (minutes > 0) {
    return '$minutes phút $seconds giây';
  }
  return '$seconds giây';
}

final class _QuizBankVisual {
  const _QuizBankVisual({required this.icon});

  final IconData icon;
}

final class _QuizCatalogTotals {
  const _QuizCatalogTotals({
    required this.bankCount,
    required this.questionCount,
    required this.practiceSetCount,
    required this.skippedQuestionCount,
  });

  factory _QuizCatalogTotals.fromBanks(List<QuizBankMetadata> banks) {
    return _QuizCatalogTotals(
      bankCount: banks.length,
      questionCount: banks.fold<int>(
        0,
        (sum, bank) => sum + bank.questionCount,
      ),
      practiceSetCount: banks.fold<int>(
        0,
        (sum, bank) => sum + _practiceSetCountFor(bank),
      ),
      skippedQuestionCount: banks.fold<int>(
        0,
        (sum, bank) => sum + bank.skippedQuestionCount,
      ),
    );
  }

  final int bankCount;
  final int questionCount;
  final int practiceSetCount;
  final int skippedQuestionCount;
}
