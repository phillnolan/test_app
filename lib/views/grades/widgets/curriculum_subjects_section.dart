import 'package:flutter/material.dart';

import '../../../controllers/grades_controller.dart';
import '../../../models/program_subject.dart';

class CurriculumDialogButton extends StatelessWidget {
  const CurriculumDialogButton({
    super.key,
    required this.controller,
    required this.curriculumRawItems,
    this.foregroundColor,
    this.backgroundColor,
  });

  final GradesController controller;
  final List<Map<String, dynamic>> curriculumRawItems;
  final Color? foregroundColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: 'Chương trình đào tạo',
      style: IconButton.styleFrom(
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
      ),
      onPressed: controller.curriculumSubjects.isEmpty
          ? null
          : () {
              showDialog<void>(
                context: context,
                builder: (context) => CurriculumSubjectsDialog(
                  controller: controller,
                  curriculumRawItems: curriculumRawItems,
                ),
              );
            },
      icon: const Icon(Icons.account_tree_outlined),
    );
  }
}

class CurriculumSubjectsDialog extends StatefulWidget {
  const CurriculumSubjectsDialog({
    super.key,
    required this.controller,
    required this.curriculumRawItems,
  });

  final GradesController controller;
  final List<Map<String, dynamic>> curriculumRawItems;

  @override
  State<CurriculumSubjectsDialog> createState() =>
      _CurriculumSubjectsDialogState();
}

class _CurriculumSubjectsDialogState extends State<CurriculumSubjectsDialog> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final presentation = widget.controller.curriculumPresentation;
        final subjects = widget.controller.selectedCurriculumSubjects;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820, maxHeight: 760),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Chương trình đào tạo',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: presentation.groupLabels
                          .map(
                            (group) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(group),
                                selected:
                                    widget.controller.selectedCurriculumGroup ==
                                    group,
                                onSelected: (_) {
                                  widget.controller.selectCurriculumGroup(
                                    group,
                                  );
                                },
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: subjects.isEmpty
                        ? const Center(child: Text('Chưa có dữ liệu'))
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final isNarrow = constraints.maxWidth < 560;
                              final itemWidth = isNarrow
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - 12) / 2;
                              return SingleChildScrollView(
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: subjects
                                      .map(
                                        (item) => SizedBox(
                                          width: itemWidth,
                                          child: _CurriculumSubjectCard(
                                            subject: item.subject,
                                            isCompleted: item.isCompleted,
                                            gradeLetter: item.gradeLetter,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CurriculumSubjectCard extends StatelessWidget {
  const _CurriculumSubjectCard({
    required this.subject,
    required this.isCompleted,
    required this.gradeLetter,
  });

  final ProgramSubject subject;
  final bool isCompleted;
  final String? gradeLetter;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = isCompleted
        ? const Color(0xFF2E7D32)
        : colorScheme.primary;
    final showLetter =
        gradeLetter != null &&
        gradeLetter!.trim().isNotEmpty &&
        gradeLetter != '--';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            subject.subjectName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            subject.subjectCode,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        if (!subject.isCountedForGpa) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.remove_circle_outline,
                            size: 16,
                            color: colorScheme.error,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${subject.credits} tín chỉ • HK ${subject.semesterIndex}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (showLetter) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    gradeLetter!,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
