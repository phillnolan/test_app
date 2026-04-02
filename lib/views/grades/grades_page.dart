import 'package:flutter/material.dart';

import '../../../models/grade_item.dart';
import '../../../models/program_subject.dart';
import 'widgets/curriculum_subjects_section.dart';
import 'widgets/goal_planner_section.dart';

class GradesPage extends StatelessWidget {
  const GradesPage({
    super.key,
    required this.grades,
    required this.curriculumSubjects,
    required this.curriculumRawItems,
    required this.emptyState,
  });

  final List<GradeItem> grades;
  final List<ProgramSubject> curriculumSubjects;
  final List<Map<String, dynamic>> curriculumRawItems;
  final Widget emptyState;

  @override
  Widget build(BuildContext context) {
    final gpaCountedCodes = curriculumSubjects
        .where((subject) => subject.isCountedForGpa)
        .map((subject) => subject.subjectCode.trim())
        .where((code) => code.isNotEmpty)
        .toSet();
    final gradesForGpa = gpaCountedCodes.isEmpty
        ? grades
        : grades
              .where(
                (grade) => gpaCountedCodes.contains(grade.subjectCode.trim()),
              )
              .toList();
    final totalCredits = gradesForGpa.fold<int>(
      0,
      (sum, item) => sum + item.credits,
    );
    final gpa = totalCredits == 0
        ? 0.0
        : gradesForGpa.fold<double>(
                0,
                (sum, item) => sum + (item.mark4 * item.credits),
              ) /
              totalCredits;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _GradesHeader(
          curriculumSubjects: curriculumSubjects,
          grades: grades,
          curriculumRawItems: curriculumRawItems,
        ),
        const SizedBox(height: 16),
        if (grades.isEmpty)
          emptyState
        else ...[
          GradesHeroCard(
            gpa: gpa,
            totalCredits: totalCredits,
            gradeCount: grades.length,
          ),
          const SizedBox(height: 16),
          GoalPlannerSection(
            currentGpa: gpa,
            completedCredits: totalCredits,
            grades: gradesForGpa,
            curriculumSubjects: curriculumSubjects,
          ),
          const SizedBox(height: 16),
          ...grades.map(
            (grade) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GradeCard(grade: grade),
            ),
          ),
        ],
      ],
    );
  }
}

class _GradesHeader extends StatelessWidget {
  const _GradesHeader({
    required this.curriculumSubjects,
    required this.grades,
    required this.curriculumRawItems,
  });

  final List<ProgramSubject> curriculumSubjects;
  final List<GradeItem> grades;
  final List<Map<String, dynamic>> curriculumRawItems;

  static const String _title =
      'K\u1ebft qu\u1ea3 h\u1ecdc t\u1eadp';
  static const String _subtitle =
      'Theo d\u00f5i GPA, l\u00ean m\u1ee5c ti\u00eau v\u00e0 xem to\u00e0n b\u1ed9 ch\u01b0\u01a1ng tr\u00ecnh \u0111\u00e0o t\u1ea1o \u1edf m\u1ed9t ch\u1ed7.';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer.withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.35,
                    color: colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.84,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CurriculumDialogButton(
            curriculumSubjects: curriculumSubjects,
            grades: grades,
            curriculumRawItems: curriculumRawItems,
            foregroundColor: colorScheme.onPrimaryContainer,
            backgroundColor: colorScheme.surface.withValues(alpha: 0.46),
          ),
        ],
      ),
    );
  }
}

class GradesHeroCard extends StatelessWidget {
  const GradesHeroCard({
    super.key,
    required this.gpa,
    required this.totalCredits,
    required this.gradeCount,
  });

  final double gpa;
  final int totalCredits;
  final int gradeCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'T\u1ed5ng quan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            gpa.toStringAsFixed(2),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$gradeCount m\u00f4n \u0111\u00e3 c\u00f3 \u0111i\u1ec3m \u2022 $totalCredits t\u00edn ch\u1ec9',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class GradeCard extends StatelessWidget {
  const GradeCard({super.key, required this.grade});

  final GradeItem grade;

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
                  grade.subjectName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${grade.subjectCode} \u2022 ${grade.credits} t\u00edn ch\u1ec9',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                grade.mark10.toStringAsFixed(1),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                'H\u1ec7 4: ${grade.mark4.toStringAsFixed(1)} \u2022 ${grade.letter}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
