import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../models/grade_item.dart';
import '../../../../models/program_subject.dart';

class GoalPlannerSection extends StatefulWidget {
  const GoalPlannerSection({
    super.key,
    required this.currentGpa,
    required this.completedCredits,
    required this.grades,
    required this.curriculumSubjects,
  });

  final double currentGpa;
  final int completedCredits;
  final List<GradeItem> grades;
  final List<ProgramSubject> curriculumSubjects;

  @override
  State<GoalPlannerSection> createState() => _GoalPlannerSectionState();
}

class _GoalPlannerSectionState extends State<GoalPlannerSection> {
  final TextEditingController _targetGpaController = TextEditingController();
  final Set<String> _guaranteedASubjectCodes = <String>{};
  String? _goalInputError;

  @override
  void dispose() {
    _targetGpaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaults = _deriveGoalDefaults();
    final result = _calculateGoalPlan(defaults: defaults);
    final colorScheme = Theme.of(context).colorScheme;

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
              Icon(Icons.flag_outlined, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Mục tiêu',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _targetGpaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) {
              setState(() {
                _goalInputError = null;
              });
            },
            decoration: InputDecoration(
              labelText: 'GPA mục tiêu hệ 4',
              hintText: 'Ví dụ: 3.20',
              errorText: _goalInputError,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: defaults.selectableFutureSubjects.isEmpty
                ? null
                : () => _openGuaranteedASelector(defaults),
            icon: const Icon(Icons.checklist_rtl_outlined),
            label: Text(
              _guaranteedASubjectCodes.isEmpty
                  ? 'Ch\u1ecdn c\u00e1c m\u00f4n ch\u1eafc A'
                  : 'Chỉnh danh sách chắc A (${_guaranteedASubjectCodes.length})',
            ),
          ),
          const SizedBox(height: 12),
          if (result == null)
            Text(
              'Nhập GPA mục tiêu để xem lộ trình.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else ...[
            _GoalSummaryCard(result: result),
            const SizedBox(height: 12),
            _GoalRecommendationTile(
              title: 'Học phần còn lại',
              subtitle:
                  'Giữ quanh ${result.remainingBand.label4} (${result.remainingBand.letter}).',
            ),
            if (result.retakeSuggestions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Nên học lại tối thiểu',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Column(
                children: result.retakeSuggestions
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RetakeSuggestionCard(item: item),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (result.includeGraduationProject) ...[
              const SizedBox(height: 10),
              _GoalRecommendationTile(
                title: result.thesisLabel,
                subtitle:
                    'Giữ tối thiểu ${result.thesisBand.label4} (${result.thesisBand.letter}).',
              ),
            ],
            const SizedBox(height: 12),
            Text(
              result.note,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openGuaranteedASelector(_GoalDefaults defaults) async {
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => _GuaranteedASelectorDialog(
        subjects: defaults.selectableFutureSubjects,
        initialSelection: _guaranteedASubjectCodes,
        completedElectiveCount: defaults.completedElectiveCount,
        requiredElectiveCount: defaults.requiredElectiveCount,
      ),
    );
    if (result == null) return;
    setState(() {
      _guaranteedASubjectCodes
        ..clear()
        ..addAll(result);
    });
  }

  _GoalPlanResult? _calculateGoalPlan({required _GoalDefaults defaults}) {
    final targetText = _targetGpaController.text.trim().replaceAll(',', '.');
    if (targetText.isEmpty) return null;

    final targetGpa = double.tryParse(targetText);
    if (targetGpa == null || targetGpa < 0 || targetGpa > 4) {
      _goalInputError = 'GPA mục tiêu phải nằm trong khoảng 0.00 đến 4.00';
      return null;
    }

    final remainingCredits =
        defaults.remainingCoreCredits +
        defaults.remainingElectiveCredits +
        (defaults.hasGraduationProject ? defaults.thesisCredits : 0);
    final totalCredits = widget.completedCredits + remainingCredits;
    final currentQualityPoints = widget.currentGpa * widget.completedCredits;
    final targetQualityPoints = targetGpa * totalCredits;

    double plannedQualityPoints =
        (defaults.remainingCoreCredits + defaults.remainingElectiveCredits) *
        3.0;
    if (defaults.hasGraduationProject) {
      plannedQualityPoints += defaults.thesisCredits * 3.0;
    }

    final guaranteedASelections = defaults.selectableFutureSubjects
        .where(
          (subject) => _guaranteedASubjectCodes.contains(subject.subjectCode),
        )
        .toList();
    for (final subject in guaranteedASelections) {
      plannedQualityPoints += subject.credits * 1.0;
    }

    final retakeSuggestions = <_RetakeSuggestion>[];
    final retakePool = _buildRetakePool(defaults.retakeCandidates);

    var neededQualityPoints =
        targetQualityPoints - currentQualityPoints - plannedQualityPoints;

    for (final candidate in retakePool) {
      if (neededQualityPoints <= 0) break;
      retakeSuggestions.add(candidate.suggestion);
      neededQualityPoints -= candidate.extraQualityPoints;
    }

    if (neededQualityPoints > 0) {
      final extraPerCredit = remainingCredits <= 0
          ? 0.0
          : (neededQualityPoints / remainingCredits).clamp(0.0, 1.0);
      final remainingBand = _MarkBand.fromScale4(
        (3.0 + extraPerCredit).clamp(0.0, 4.0),
      );
      return _GoalPlanResult(
        targetGpa: targetGpa,
        totalCredits: totalCredits,
        remainingCredits: remainingCredits,
        includeGraduationProject: defaults.hasGraduationProject,
        remainingBand: remainingBand,
        thesisBand: _MarkBand.fromScale4(3.0),
        note:
            'Giữ các môn còn lại ở mức ${remainingBand.letter}, chỉ học lại ${retakeSuggestions.length} môn và ưu tiên các môn D trước.',
        retakeSuggestions: retakeSuggestions,
        guaranteedASelections: guaranteedASelections,
        thesisLabel: defaults.thesisLabel,
      );
    }

    return _GoalPlanResult(
      targetGpa: targetGpa,
      totalCredits: totalCredits,
      remainingCredits: remainingCredits,
      includeGraduationProject: defaults.hasGraduationProject,
      remainingBand: _MarkBand.fromScale4(3.0),
      thesisBand: _MarkBand.fromScale4(3.0),
      note: retakeSuggestions.isEmpty
          ? 'C\u00f3 th\u1ec3 \u0111\u1ea1t m\u1ee5c ti\u00eau m\u00e0 kh\u00f4ng c\u1ea7n h\u1ecdc l\u1ea1i, ch\u1ec9 c\u1ea7n gi\u1eef c\u00e1c m\u00f4n c\u00f2n l\u1ea1i \u1edf m\u1ee9c B.'
          : 'Có thể đạt mục tiêu với số môn học lại tối thiểu, ưu tiên xử lý các môn D trước.',
      retakeSuggestions: retakeSuggestions,
      guaranteedASelections: guaranteedASelections,
      thesisLabel: defaults.thesisLabel,
    );
  }

  List<_RetakeCandidate> _buildRetakePool(List<GradeItem> retakeCandidates) {
    final pool = retakeCandidates.map((grade) {
      const target = 3.0;
      return _RetakeCandidate(
        suggestion: _RetakeSuggestion(grade: grade, targetLetter: 'B'),
        extraQualityPoints:
            math.max(0.0, target - grade.mark4).toDouble() * grade.credits,
        priorityBucket: grade.letter.startsWith('D') ? 0 : 1,
      );
    }).toList();

    pool.sort((a, b) {
      final bucketCompare = a.priorityBucket.compareTo(b.priorityBucket);
      if (bucketCompare != 0) return bucketCompare;
      final gainCompare = b.extraQualityPoints.compareTo(a.extraQualityPoints);
      if (gainCompare != 0) return gainCompare;
      return b.suggestion.grade.credits.compareTo(a.suggestion.grade.credits);
    });
    return pool;
  }

  _GoalDefaults _deriveGoalDefaults() {
    final passedGrades = _bestPassedGradesByCode();
    final curriculum = _dedupedCurriculum()
        .where((item) => item.isCountedForGpa || item.isGraduationProject)
        .toList();
    final thesisSubjects = curriculum
        .where((item) => item.isGraduationProject)
        .toList();
    final electiveSubjects = curriculum
        .where((item) => item.isElective && !item.isGraduationProject)
        .toList();
    final coreSubjects = curriculum
        .where((item) => !item.isElective && !item.isGraduationProject)
        .toList();

    final completedElectives = electiveSubjects
        .where((item) => passedGrades.containsKey(item.subjectCode))
        .toList();
    final requiredElectiveCount = electiveSubjects.isEmpty
        ? 6
        : electiveSubjects.length < 6
        ? electiveSubjects.length
        : 6;
    final remainingElectiveSlots =
        (requiredElectiveCount - completedElectives.length).clamp(
          0,
          requiredElectiveCount,
        );

    final remainingCore = coreSubjects
        .where((item) => !passedGrades.containsKey(item.subjectCode))
        .toList();
    final remainingElectives = electiveSubjects
        .where((item) => !passedGrades.containsKey(item.subjectCode))
        .toList();
    final thesisSubject = thesisSubjects.isEmpty
        ? null
        : thesisSubjects.firstWhere(
            (item) => item.credits >= 10,
            orElse: () => thesisSubjects.first,
          );
    final thesisCompleted =
        thesisSubject != null &&
        passedGrades.containsKey(thesisSubject.subjectCode);

    final selectableFutureSubjects = <ProgramSubject>[
      ...remainingCore,
      if (thesisSubject != null && !thesisCompleted) thesisSubject,
      ...remainingElectives,
    ];

    final countedRemainingElectives = remainingElectives
        .take(remainingElectiveSlots)
        .toList();

    final remainingSubjects = <ProgramSubject>[
      ...remainingCore,
      ...countedRemainingElectives,
      if (thesisSubject != null && !thesisCompleted) thesisSubject,
    ];

    final retakeCandidates = passedGrades.values
        .where(
          (grade) =>
              _isPassingGrade(grade) &&
              (grade.letter.startsWith('D') || grade.letter.startsWith('C')),
        )
        .toList();

    return _GoalDefaults(
      remainingCoreCredits: remainingCore.fold<int>(
        0,
        (sum, item) => sum + item.credits,
      ),
      remainingElectiveCredits: countedRemainingElectives.fold<int>(
        0,
        (sum, item) => sum + item.credits,
      ),
      thesisCredits: thesisSubject?.credits ?? 10,
      hasGraduationProject: thesisSubject != null && !thesisCompleted,
      thesisLabel: thesisSubject == null
          ? '\u0110\u1ed3 \u00e1n t\u1ed1t nghi\u1ec7p'
          : thesisSubject.subjectName,
      remainingSubjects: remainingSubjects,
      selectableFutureSubjects: selectableFutureSubjects,
      retakeCandidates: retakeCandidates,
      completedElectiveCount: completedElectives.length,
      requiredElectiveCount: requiredElectiveCount,
    );
  }

  Map<String, GradeItem> _bestPassedGradesByCode() {
    final best = <String, GradeItem>{};
    for (final grade in widget.grades) {
      final code = grade.subjectCode.trim();
      if (code.isEmpty) continue;
      if (!_isPassingGrade(grade)) continue;
      final current = best[code];
      if (current == null || grade.mark4 > current.mark4) {
        best[code] = grade;
      }
    }
    return best;
  }

  List<ProgramSubject> _dedupedCurriculum() {
    final seen = <String>{};
    final deduped = <ProgramSubject>[];
    for (final subject in widget.curriculumSubjects) {
      final key = subject.subjectCode.trim().isEmpty
          ? subject.subjectName.trim()
          : subject.subjectCode.trim();
      if (key.isEmpty || !seen.add(key)) continue;
      deduped.add(subject);
    }
    return deduped;
  }

  bool _isPassingGrade(GradeItem grade) {
    return grade.mark4 >= 1.0 ||
        (grade.letter.isNotEmpty &&
            !grade.letter.toUpperCase().startsWith('F'));
  }
}

class _GuaranteedASelectorDialog extends StatefulWidget {
  const _GuaranteedASelectorDialog({
    required this.subjects,
    required this.initialSelection,
    required this.completedElectiveCount,
    required this.requiredElectiveCount,
  });

  final List<ProgramSubject> subjects;
  final Set<String> initialSelection;
  final int completedElectiveCount;
  final int requiredElectiveCount;

  @override
  State<_GuaranteedASelectorDialog> createState() =>
      _GuaranteedASelectorDialogState();
}

class _GuaranteedASelectorDialogState
    extends State<_GuaranteedASelectorDialog> {
  late final Set<String> _selectedCodes;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedCodes = {...widget.initialSelection};
  }

  @override
  Widget build(BuildContext context) {
    final coreSubjects = widget.subjects
        .where((item) => !item.isElective)
        .toList();
    final electiveSubjects = widget.subjects
        .where((item) => item.isElective)
        .toList();
    final electiveSelectedCount = electiveSubjects
        .where((item) => _selectedCodes.contains(item.subjectCode))
        .length;
    final maxElectiveSelection = math.max(
      0,
      widget.requiredElectiveCount - widget.completedElectiveCount,
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chọn các môn chắc A',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tự chọn còn được chọn $maxElectiveSelection môn.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorText!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SelectorSection(
                        title: 'Bắt buộc',
                        subjects: coreSubjects,
                        selectedCodes: _selectedCodes,
                        onToggle: _toggle,
                      ),
                      if (electiveSubjects.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _SelectorSection(
                          title: 'Tự chọn',
                          subjects: electiveSubjects,
                          selectedCodes: _selectedCodes,
                          onToggle: (subject) {
                            final alreadySelected = _selectedCodes.contains(
                              subject.subjectCode,
                            );
                            if (!alreadySelected &&
                                electiveSelectedCount >= maxElectiveSelection) {
                              setState(() {
                                _errorText =
                                    'Bạn chỉ có thể chọn tối đa $maxElectiveSelection môn tự chọn.';
                              });
                              return;
                            }
                            _toggle(subject);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_selectedCodes),
                  child: const Text('Lưu chọn'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggle(ProgramSubject subject) {
    setState(() {
      _errorText = null;
      if (_selectedCodes.contains(subject.subjectCode)) {
        _selectedCodes.remove(subject.subjectCode);
      } else {
        _selectedCodes.add(subject.subjectCode);
      }
    });
  }
}

class _SelectorSection extends StatelessWidget {
  const _SelectorSection({
    required this.title,
    required this.subjects,
    required this.selectedCodes,
    required this.onToggle,
  });

  final String title;
  final List<ProgramSubject> subjects;
  final Set<String> selectedCodes;
  final ValueChanged<ProgramSubject> onToggle;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final itemWidth = screenWidth < 520 ? double.infinity : 220.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: subjects
              .map(
                (subject) => SizedBox(
                  width: itemWidth,
                  child: _SelectableSubjectCard(
                    subject: subject,
                    selected: selectedCodes.contains(subject.subjectCode),
                    onTap: () => onToggle(subject),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _SelectableSubjectCard extends StatelessWidget {
  const _SelectableSubjectCard({
    required this.subject,
    required this.selected,
    required this.onTap,
  });

  final ProgramSubject subject;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primaryContainer.withValues(alpha: 0.9)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      subject.subjectName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${subject.credits} tín chỉ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 20,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalSummaryCard extends StatelessWidget {
  const _GoalSummaryCard({required this.result});

  final _GoalPlanResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: _GoalMetric(
              label: 'Mục tiêu',
              value: result.targetGpa.toStringAsFixed(2),
            ),
          ),
          Expanded(
            child: _GoalMetric(
              label: 'Còn lại',
              value: '${result.remainingCredits} tín',
            ),
          ),
          Expanded(
            child: _GoalMetric(
              label: 'Học lại',
              value: '${result.retakeSuggestions.length} môn',
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalMetric extends StatelessWidget {
  const _GoalMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _GoalRecommendationTile extends StatelessWidget {
  const _GoalRecommendationTile({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _RetakeSuggestionCard extends StatelessWidget {
  const _RetakeSuggestionCard({required this.item});

  final _RetakeSuggestion item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.grade.subjectName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ban đầu: ${item.grade.letter}  •  Cần: ${item.targetLetter}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalPlanResult {
  const _GoalPlanResult({
    required this.targetGpa,
    required this.totalCredits,
    required this.remainingCredits,
    required this.includeGraduationProject,
    required this.remainingBand,
    required this.thesisBand,
    required this.note,
    required this.retakeSuggestions,
    required this.guaranteedASelections,
    required this.thesisLabel,
  });

  final double targetGpa;
  final int totalCredits;
  final int remainingCredits;
  final bool includeGraduationProject;
  final _MarkBand remainingBand;
  final _MarkBand thesisBand;
  final String note;
  final List<_RetakeSuggestion> retakeSuggestions;
  final List<ProgramSubject> guaranteedASelections;
  final String thesisLabel;
}

class _GoalDefaults {
  const _GoalDefaults({
    required this.remainingCoreCredits,
    required this.remainingElectiveCredits,
    required this.thesisCredits,
    required this.hasGraduationProject,
    required this.thesisLabel,
    required this.remainingSubjects,
    required this.selectableFutureSubjects,
    required this.retakeCandidates,
    required this.completedElectiveCount,
    required this.requiredElectiveCount,
  });

  final int remainingCoreCredits;
  final int remainingElectiveCredits;
  final int thesisCredits;
  final bool hasGraduationProject;
  final String thesisLabel;
  final List<ProgramSubject> remainingSubjects;
  final List<ProgramSubject> selectableFutureSubjects;
  final List<GradeItem> retakeCandidates;
  final int completedElectiveCount;
  final int requiredElectiveCount;
}

class _RetakeSuggestion {
  const _RetakeSuggestion({required this.grade, required this.targetLetter});

  final GradeItem grade;
  final String targetLetter;
}

class _RetakeCandidate {
  const _RetakeCandidate({
    required this.suggestion,
    required this.extraQualityPoints,
    required this.priorityBucket,
  });

  final _RetakeSuggestion suggestion;
  final double extraQualityPoints;
  final int priorityBucket;
}

class _MarkBand {
  const _MarkBand({
    required this.scale4,
    required this.label4,
    required this.label10,
    required this.letter,
  });

  final double scale4;
  final String label4;
  final String label10;
  final String letter;

  factory _MarkBand.fromScale4(double value) {
    if (value >= 3.5) {
      return _MarkBand(
        scale4: value,
        label4: value.toStringAsFixed(2),
        label10: '8.5 - 10.0',
        letter: 'A',
      );
    }
    if (value >= 2.5) {
      return _MarkBand(
        scale4: value,
        label4: value.toStringAsFixed(2),
        label10: '7.0 - 8.4',
        letter: 'B',
      );
    }
    if (value >= 1.5) {
      return _MarkBand(
        scale4: value,
        label4: value.toStringAsFixed(2),
        label10: '5.5 - 6.4',
        letter: 'C',
      );
    }
    if (value >= 1.0) {
      return _MarkBand(
        scale4: value,
        label4: value.toStringAsFixed(2),
        label10: '4.0 - 5.4',
        letter: 'D',
      );
    }
    return _MarkBand(
      scale4: value,
      label4: value.toStringAsFixed(2),
      label10: 'Dưới 4.0',
      letter: 'F',
    );
  }
}
