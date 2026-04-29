import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/program_subject.dart';
import '../../home/ui/home_controller.dart';
import '../data/quiz_models.dart';
import 'quiz_controller.dart';

/// Entry point for the quiz flow.
class QuizPage extends ConsumerWidget {
  const QuizPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeControllerProvider);

    if (homeState.isLoadingLocalCache ||
        homeState.isRestoringCloudData ||
        homeState.isLinkingStudent) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    final curriculumSubjects = homeState.payload.curriculumSubjects;
    final hasSyncedCurriculum =
        homeState.payload.profile != null && curriculumSubjects.isNotEmpty;

    if (!hasSyncedCurriculum) {
      return const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: _QuizInlineNotice(
              icon: Icons.sync_problem_outlined,
              title: 'Cần đồng bộ dữ liệu',
              message: 'Hãy đồng bộ dữ liệu sinh viên để xem các môn quiz.',
            ),
          ),
        ),
      );
    }

    final catalogAsync = ref.watch(quizCatalogProvider);

    return SafeArea(
      child: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: _QuizInlineNotice(
              icon: Icons.cloud_off_outlined,
              title: 'Không tải được quiz',
              message: 'Vui lòng thử lại sau.',
            ),
          ),
        ),
        data: (banks) {
          final subjects = _buildQuizSubjects(banks, curriculumSubjects);
          if (subjects.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: _QuizInlineNotice(
                  icon: Icons.school_outlined,
                  title: 'Chưa có môn quiz phù hợp',
                  message:
                      'Dữ liệu đã đồng bộ nhưng hiện chưa có môn quiz nào khớp với chương trình đào tạo.',
                ),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _quizGridColumns(constraints.maxWidth),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  final subject = subjects[index];
                  return _QuizSubjectCard(
                    subject: subject,
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              _QuizSetSelectionPage(subject: subject),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// Page for picking a deck within one subject.
final class _QuizSetSelectionPage extends ConsumerWidget {
  const _QuizSetSelectionPage({required this.subject});

  final _QuizSubjectGroup subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizState = ref.watch(quizControllerProvider);
    final decks = _buildQuizDecks(subject);

    return Scaffold(
      appBar: AppBar(title: Text(subject.title)),
      body: SafeArea(
        child: Column(
          children: [
            if (quizState.isStarting) ...[
              const LinearProgressIndicator(minHeight: 3),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: decks.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: _QuizInlineNotice(
                          icon: Icons.quiz_outlined,
                          title: 'Chưa có đề nào',
                          message:
                              'Môn này chưa có bộ đề để ôn tập trong manifest.',
                        ),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: _quizGridColumns(
                                  constraints.maxWidth,
                                ),
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1,
                              ),
                          itemCount: decks.length,
                          itemBuilder: (context, index) {
                            final deck = decks[index];
                            return _QuizDeckCard(
                              label: deck.label,
                              accentColor: Color(deck.bank.accentColor),
                              isEnabled: !quizState.isStarting,
                              onTap: () {
                                unawaited(
                                  _startAndOpenQuiz(
                                    context: context,
                                    ref: ref,
                                    deck: deck,
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startAndOpenQuiz({
    required BuildContext context,
    required WidgetRef ref,
    required _QuizDeck deck,
  }) async {
    final controller = ref.read(quizControllerProvider.notifier);
    await controller.startQuiz(
      deck.bank,
      questionCount: quizPracticeDeckSize,
      setNumber: deck.setNumber,
    );

    if (!context.mounted) {
      return;
    }

    final session = ref.read(quizControllerProvider).session;
    if (session == null) {
      return;
    }

    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(builder: (_) => QuizPlayPage(deckLabel: deck.label)),
    );
  }
}

/// Full-screen page for taking one quiz deck.
final class QuizPlayPage extends ConsumerWidget {
  const QuizPlayPage({super.key, required this.deckLabel});

  final String deckLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizState = ref.watch(quizControllerProvider);
    final session = quizState.session;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          ref.read(quizControllerProvider.notifier).clearSession();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(deckLabel),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              tooltip: 'Làm lại',
              onPressed: () {
                unawaited(
                  ref.read(quizControllerProvider.notifier).restartSession(),
                );
              },
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'Đóng',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        body: session == null
            ? const Center(child: Text('Không có phiên quiz nào đang mở.'))
            : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _QuizProgressStrip(session: session),
                    const SizedBox(height: 16),
                    _QuizQuestionCard(
                      session: session,
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
                      onRestartSession: () {
                        unawaited(
                          ref
                              .read(quizControllerProvider.notifier)
                              .restartSession(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _QuizReviewStrip(
                      session: session,
                      onJumpToQuestion: ref
                          .read(quizControllerProvider.notifier)
                          .jumpToQuestion,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

final class _QuizSubjectGroup {
  const _QuizSubjectGroup({
    required this.key,
    required this.title,
    required this.banks,
  });

  final String key;
  final String title;
  final List<QuizBankMetadata> banks;

  QuizBankMetadata get primaryBank {
    return banks.firstWhere(
      (bank) => bank.id == key,
      orElse: () => banks.first,
    );
  }
}

final class _QuizDeck {
  const _QuizDeck({
    required this.label,
    required this.bank,
    required this.setNumber,
  });

  final String label;
  final QuizBankMetadata bank;
  final int setNumber;
}

class _QuizSubjectCard extends StatelessWidget {
  const _QuizSubjectCard({required this.subject, required this.onTap});

  final _QuizSubjectGroup subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = Color(subject.primaryBank.accentColor);
    final backgroundColor = Color.alphaBlend(
      accentColor.withValues(alpha: 0.08),
      colorScheme.surfaceContainerLow,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      color: backgroundColor,
      surfaceTintColor: accentColor.withValues(alpha: 0.18),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: 4,
                  color: accentColor.withValues(alpha: 0.55),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  subject.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizDeckCard extends StatelessWidget {
  const _QuizDeckCard({
    required this.label,
    required this.accentColor,
    required this.isEnabled,
    required this.onTap,
  });

  final String label;
  final Color accentColor;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = Color.alphaBlend(
      accentColor.withValues(alpha: 0.08),
      colorScheme.surfaceContainerLow,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      color: backgroundColor,
      surfaceTintColor: accentColor.withValues(alpha: 0.18),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: 4,
                  color: accentColor.withValues(alpha: 0.55),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizProgressStrip extends StatelessWidget {
  const _QuizProgressStrip({required this.session});

  final QuizSession session;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentQuestion = session.currentIndex + 1;
    final progress = session.questionCount == 0
        ? 0.0
        : currentQuestion / session.questionCount;

    return Card(
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Câu ${_formatCount(currentQuestion)}/${_formatCount(session.questionCount)}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).round()}%',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(value: progress, minHeight: 8),
            ),
          ],
        ),
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
  final VoidCallback onRestartSession;

  @override
  Widget build(BuildContext context) {
    final question = session.currentQuestion;
    final attempt = session.currentAttempt;
    final colorScheme = Theme.of(context).colorScheme;
    final isLastQuestion = session.currentIndex == session.questions.length - 1;

    return Card(
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _QuizTinyBadge(
              label:
                  'Câu ${_formatCount(session.currentIndex + 1)}/${_formatCount(session.questionCount)}',
              icon: Icons.confirmation_number_outlined,
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
                        ? onRestartSession
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
        Text(
          'Đi tới câu',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var index = 0; index < session.questions.length; index++)
              _QuizReviewChip(
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

class _QuizReviewChip extends StatelessWidget {
  const _QuizReviewChip({
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
    final textColor = switch (state) {
      _QuestionProgressState.correct => colorScheme.onPrimaryContainer,
      _QuestionProgressState.wrong => colorScheme.onErrorContainer,
      _QuestionProgressState.unanswered => colorScheme.onSurfaceVariant,
    };
    final borderColor = isSelected
        ? colorScheme.primary
        : colorScheme.outlineVariant;

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

class _QuizTinyBadge extends StatelessWidget {
  const _QuizTinyBadge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
      ),
    );
  }
}

class _QuizInlineNotice extends StatelessWidget {
  const _QuizInlineNotice({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
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
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<_QuizSubjectGroup> _buildQuizSubjects(
  List<QuizBankMetadata> banks,
  List<ProgramSubject> curriculumSubjects,
) {
  final grouped = <String, List<QuizBankMetadata>>{};
  for (final bank in banks) {
    final key = _quizSubjectKey(bank);
    grouped.putIfAbsent(key, () => <QuizBankMetadata>[]).add(bank);
  }

  return grouped.entries
      .where(
        (entry) => _quizSubjectMatchesCurriculum(
          entry.key,
          entry.value,
          curriculumSubjects,
        ),
      )
      .map((entry) {
        final subjectBanks = entry.value.toList()
          ..sort((left, right) {
            final leftPrimary = left.id == entry.key;
            final rightPrimary = right.id == entry.key;
            if (leftPrimary != rightPrimary) {
              return leftPrimary ? -1 : 1;
            }
            return left.id.compareTo(right.id);
          });

        final primary = subjectBanks.firstWhere(
          (bank) => bank.id == entry.key,
          orElse: () => subjectBanks.first,
        );
        final curriculumSubject = _quizMatchedCurriculumSubject(
          entry.key,
          subjectBanks,
          curriculumSubjects,
        );
        final curriculumTitle = curriculumSubject?.subjectName.trim();

        return _QuizSubjectGroup(
          key: entry.key,
          title: curriculumTitle == null || curriculumTitle.isEmpty
              ? primary.title
              : curriculumTitle,
          banks: subjectBanks,
        );
      })
      .toList(growable: false);
}

List<_QuizDeck> _buildQuizDecks(_QuizSubjectGroup subject) {
  final decks = <_QuizDeck>[];
  final primary = subject.primaryBank;
  final numberedDeckCount = _quizPracticeDeckCount(primary.questionCount);

  for (var index = 1; index <= numberedDeckCount; index++) {
    decks.add(_QuizDeck(label: 'Đề $index', bank: primary, setNumber: index));
  }

  final specialBanks = subject.banks.where((bank) => bank.id != primary.id);
  for (final bank in specialBanks) {
    decks.add(
      _QuizDeck(label: _quizSpecialDeckLabel(bank), bank: bank, setNumber: 1),
    );
  }

  return decks;
}

String _quizSubjectKey(QuizBankMetadata bank) {
  final id = bank.id;
  final hyphenIndex = id.indexOf('-');
  if (hyphenIndex == -1) {
    return id;
  }
  return id.substring(0, hyphenIndex);
}

String _quizSpecialDeckLabel(QuizBankMetadata bank) {
  final id = bank.id;
  final hyphenIndex = id.indexOf('-');
  final suffix = hyphenIndex == -1 ? id : id.substring(hyphenIndex + 1);
  return 'Đề $suffix';
}

bool _quizSubjectMatchesCurriculum(
  String subjectKey,
  List<QuizBankMetadata> banks,
  List<ProgramSubject> curriculumSubjects,
) {
  return _quizMatchedCurriculumSubject(subjectKey, banks, curriculumSubjects) !=
      null;
}

ProgramSubject? _quizMatchedCurriculumSubject(
  String subjectKey,
  List<QuizBankMetadata> banks,
  List<ProgramSubject> curriculumSubjects,
) {
  final quizTexts = <String>{
    _normalizeQuizText(subjectKey),
    for (final bank in banks) _normalizeQuizText(bank.id),
    for (final bank in banks) _normalizeQuizText(bank.code),
    for (final bank in banks) _normalizeQuizText(bank.title),
    ..._quizSubjectAliasTexts(subjectKey, banks),
  }.where((value) => value.isNotEmpty).toList(growable: false);

  if (quizTexts.isEmpty) {
    return null;
  }

  for (final subject in curriculumSubjects) {
    final curriculumTexts = <String>{
      _normalizeQuizText(subject.subjectCode),
      _normalizeQuizText(subject.subjectName),
      _normalizeQuizText(subject.knowledgeBlock),
      _normalizeQuizText(subject.curriculumGroup),
    }.where((value) => value.isNotEmpty).toList(growable: false);

    for (final quizText in quizTexts) {
      for (final curriculumText in curriculumTexts) {
        if (_quizTextMatches(quizText, curriculumText)) {
          return subject;
        }
      }
    }
  }

  return null;
}

Iterable<String> _quizSubjectAliasTexts(
  String subjectKey,
  List<QuizBankMetadata> banks,
) sync* {
  final normalizedKey = _normalizeQuizText(subjectKey);
  final normalizedTexts = <String>{
    normalizedKey,
    for (final bank in banks) _normalizeQuizText(bank.id),
    for (final bank in banks) _normalizeQuizText(bank.code),
    for (final bank in banks) _normalizeQuizText(bank.title),
  };

  if (normalizedTexts.any((text) => text.contains('ktct'))) {
    yield _normalizeQuizText('Kinh tế chính trị Mác -Lênin');
    yield _normalizeQuizText('Kinh tế chính trị Mác-Lênin');
    yield _normalizeQuizText('Kinh tế chính trị');
  }
}

int _quizPracticeDeckCount(int questionCount) {
  final derived = (questionCount / quizPracticeDeckSize).ceil();
  return derived.clamp(3, 12);
}

int _quizGridColumns(double maxWidth) {
  if (maxWidth >= 1120) {
    return 4;
  }
  if (maxWidth >= 840) {
    return 3;
  }
  return 2;
}

String _optionLabel(int index) {
  return String.fromCharCode('A'.codeUnitAt(0) + index);
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

bool _quizTextMatches(String left, String right) {
  if (left.isEmpty || right.isEmpty) {
    return false;
  }

  return left == right || left.contains(right) || right.contains(left);
}

String _normalizeQuizText(String value) {
  final lower = value.toLowerCase().trim();
  const replacements = {
    'à': 'a',
    'á': 'a',
    'ạ': 'a',
    'ả': 'a',
    'ã': 'a',
    'â': 'a',
    'ầ': 'a',
    'ấ': 'a',
    'ậ': 'a',
    'ẩ': 'a',
    'ẫ': 'a',
    'ă': 'a',
    'ằ': 'a',
    'ắ': 'a',
    'ặ': 'a',
    'ẳ': 'a',
    'ẵ': 'a',
    'è': 'e',
    'é': 'e',
    'ẹ': 'e',
    'ẻ': 'e',
    'ẽ': 'e',
    'ê': 'e',
    'ề': 'e',
    'ế': 'e',
    'ệ': 'e',
    'ể': 'e',
    'ễ': 'e',
    'ì': 'i',
    'í': 'i',
    'ị': 'i',
    'ỉ': 'i',
    'ĩ': 'i',
    'ò': 'o',
    'ó': 'o',
    'ọ': 'o',
    'ỏ': 'o',
    'õ': 'o',
    'ô': 'o',
    'ồ': 'o',
    'ố': 'o',
    'ộ': 'o',
    'ổ': 'o',
    'ỗ': 'o',
    'ơ': 'o',
    'ờ': 'o',
    'ớ': 'o',
    'ợ': 'o',
    'ở': 'o',
    'ỡ': 'o',
    'ù': 'u',
    'ú': 'u',
    'ụ': 'u',
    'ủ': 'u',
    'ũ': 'u',
    'ư': 'u',
    'ừ': 'u',
    'ứ': 'u',
    'ự': 'u',
    'ử': 'u',
    'ữ': 'u',
    'ỳ': 'y',
    'ý': 'y',
    'ỵ': 'y',
    'ỷ': 'y',
    'ỹ': 'y',
    'đ': 'd',
  };

  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(replacements[char] ?? char);
  }

  return buffer.toString().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

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

enum _QuizOptionState {
  neutral,
  selected,
  correctSelected,
  incorrectSelected,
  correctUnselected,
}

enum _QuestionProgressState { unanswered, correct, wrong }
