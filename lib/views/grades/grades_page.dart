import 'package:flutter/material.dart';

import '../../controllers/grades_controller.dart';
import '../../models/grade_item.dart';
import '../../models/program_subject.dart';
import 'widgets/curriculum_subjects_section.dart';
import 'widgets/goal_planner_section.dart';

class GradesPage extends StatefulWidget {
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
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  late final GradesController _controller = GradesController(
    grades: widget.grades,
    curriculumSubjects: widget.curriculumSubjects,
  );

  @override
  void didUpdateWidget(covariant GradesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.grades, widget.grades) &&
        identical(oldWidget.curriculumSubjects, widget.curriculumSubjects)) {
      return;
    }
    _controller.updateData(
      grades: widget.grades,
      curriculumSubjects: widget.curriculumSubjects,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final metrics = _controller.metrics;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _GradesHeader(
              controller: _controller,
              curriculumRawItems: widget.curriculumRawItems,
            ),
            const SizedBox(height: 16),
            if (_controller.grades.isEmpty)
              widget.emptyState
            else ...[
              GradesHeroCard(
                gpa: metrics.gpa,
                totalCredits: metrics.totalCredits,
                gradeCount: _controller.grades.length,
              ),
              const SizedBox(height: 16),
              GoalPlannerSection(controller: _controller),
              const SizedBox(height: 16),
              ..._controller.grades.map(
                (grade) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GradeCard(grade: grade),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _GradesHeader extends StatelessWidget {
  const _GradesHeader({
    required this.controller,
    required this.curriculumRawItems,
  });

  final GradesController controller;
  final List<Map<String, dynamic>> curriculumRawItems;

  static const String _title = 'Ket qua hoc tap';
  static const String _subtitle =
      'Theo doi GPA, len muc tieu va xem toan bo chuong trinh dao tao o mot cho.';

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
            controller: controller,
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
            'Tong quan',
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
            '$gradeCount mon da co diem • $totalCredits tin chi',
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
                  '${grade.subjectCode} • ${grade.credits} tin chi',
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
                'He 4: ${grade.mark4.toStringAsFixed(1)} • ${grade.letter}',
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
