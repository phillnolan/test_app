import 'package:flutter/material.dart';

import '../../../../models/grade_item.dart';
import '../../../../models/program_subject.dart';

class CurriculumDialogButton extends StatelessWidget {
  const CurriculumDialogButton({
    super.key,
    required this.curriculumSubjects,
    required this.grades,
    required this.curriculumRawItems,
    this.foregroundColor,
    this.backgroundColor,
  });

  final List<ProgramSubject> curriculumSubjects;
  final List<GradeItem> grades;
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
      onPressed: curriculumSubjects.isEmpty
          ? null
          : () {
              showDialog<void>(
                context: context,
                builder: (context) => CurriculumSubjectsDialog(
                  curriculumSubjects: curriculumSubjects,
                  grades: grades,
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
    required this.curriculumSubjects,
    required this.grades,
    required this.curriculumRawItems,
  });

  final List<ProgramSubject> curriculumSubjects;
  final List<GradeItem> grades;
  final List<Map<String, dynamic>> curriculumRawItems;

  @override
  State<CurriculumSubjectsDialog> createState() =>
      _CurriculumSubjectsDialogState();
}

class _CurriculumSubjectsDialogState extends State<CurriculumSubjectsDialog> {
  late final List<ProgramSubject> _subjects;
  late final Set<String> _passedCodes;
  late final Map<String, GradeItem> _gradeByCode;
  late final Map<String, List<ProgramSubject>> _groupedSubjects;
  late String _selectedGroup;

  @override
  void initState() {
    super.initState();
    _subjects = _dedupedSubjects(widget.curriculumSubjects);
    _passedCodes = _passedCodesFor(widget.grades);
    _gradeByCode = _bestGradesByCode(widget.grades);
    _groupedSubjects = _groupSubjects(_subjects);
    _selectedGroup = _groupedSubjects.keys.isEmpty
        ? ''
        : _groupedSubjects.keys.first;
  }

  @override
  Widget build(BuildContext context) {
    final subjects =
        _groupedSubjects[_selectedGroup] ?? const <ProgramSubject>[];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                  children: _groupedSubjects.keys
                      .map(
                        (group) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(group),
                            selected: _selectedGroup == group,
                            onSelected: (_) => setState(() {
                              _selectedGroup = group;
                            }),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: subjects.isEmpty
                    ? const Center(child: Text('Ch\u01b0a c\u00f3 d\u1eef li\u1ec7u'))
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
                                    (subject) => SizedBox(
                                      width: itemWidth,
                                      child: _CurriculumSubjectCard(
                                        subject: subject,
                                        isCompleted: _passedCodes.contains(
                                          subject.subjectCode.trim(),
                                        ),
                                        gradeLetter:
                                            _gradeByCode[subject.subjectCode
                                                    .trim()]
                                                ?.letter,
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

List<ProgramSubject> _dedupedSubjects(List<ProgramSubject> curriculumSubjects) {
  final seen = <String>{};
  final items = <ProgramSubject>[];
  for (final subject in curriculumSubjects) {
    final key = subject.subjectCode.trim().isEmpty
        ? subject.subjectName.trim()
        : subject.subjectCode.trim();
    if (key.isEmpty || !seen.add(key)) continue;
    items.add(subject);
  }
  items.sort((a, b) {
    final semesterCompare = a.semesterIndex.compareTo(b.semesterIndex);
    if (semesterCompare != 0) return semesterCompare;
    return a.subjectName.compareTo(b.subjectName);
  });
  return items;
}

Set<String> _passedCodesFor(List<GradeItem> grades) {
  final passed = <String>{};
  for (final grade in grades) {
    final code = grade.subjectCode.trim();
    if (code.isEmpty) continue;
    if (grade.mark4 >= 1.0 ||
        (grade.letter.isNotEmpty &&
            !grade.letter.toUpperCase().startsWith('F'))) {
      passed.add(code);
    }
  }
  return passed;
}

Map<String, GradeItem> _bestGradesByCode(List<GradeItem> grades) {
  final best = <String, GradeItem>{};
  for (final grade in grades) {
    final code = grade.subjectCode.trim();
    if (code.isEmpty) continue;
    final current = best[code];
    if (current == null || grade.mark4 > current.mark4) {
      best[code] = grade;
    }
  }
  return best;
}

Map<String, List<ProgramSubject>> _groupSubjects(
  List<ProgramSubject> subjects,
) {
  const preferredOrder = ['Kiến thức ngành', 'Lý luận chính trị', 'Tự chọn'];
  const trailingOrder = [
    'Chuẩn đầu ra',
    'Giáo dục quốc phòng',
    'Giáo dục thể chất',
  ];
  final buckets = <String, List<ProgramSubject>>{};
  for (final subject in subjects) {
    final key = subject.curriculumGroup;
    buckets.putIfAbsent(key, () => []).add(subject);
  }

  final orderedKeys = <String>[
    ...preferredOrder.where(buckets.containsKey),
    ...buckets.keys
        .where(
          (key) =>
              !preferredOrder.contains(key) && !trailingOrder.contains(key),
        )
        .toList()
      ..sort(),
    ...trailingOrder.where(buckets.containsKey),
  ];

  return {
    for (final key in orderedKeys)
      key: buckets[key]!
        ..sort((a, b) {
          final gpaCompare = (b.isCountedForGpa ? 1 : 0).compareTo(
            a.isCountedForGpa ? 1 : 0,
          );
          if (gpaCompare != 0) return gpaCompare;
          final semesterCompare = a.semesterIndex.compareTo(b.semesterIndex);
          if (semesterCompare != 0) return semesterCompare;
          return a.subjectName.compareTo(b.subjectName);
        }),
  };
}
