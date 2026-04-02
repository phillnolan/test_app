import 'dart:math' as math;

import '../models/grade_item.dart';
import '../models/program_subject.dart';

class GradeMetricsSummary {
  const GradeMetricsSummary({
    required this.gradesForGpa,
    required this.totalCredits,
    required this.gpa,
  });

  final List<GradeItem> gradesForGpa;
  final int totalCredits;
  final double gpa;
}

class GoalPlanCalculation {
  const GoalPlanCalculation({this.result, this.validationError});

  final GoalPlanResult? result;
  final String? validationError;
}

class GoalPlanResult {
  const GoalPlanResult({
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
  final MarkBand remainingBand;
  final MarkBand thesisBand;
  final String note;
  final List<RetakeSuggestion> retakeSuggestions;
  final List<ProgramSubject> guaranteedASelections;
  final String thesisLabel;
}

class GoalPlanDefaults {
  const GoalPlanDefaults({
    required this.remainingCoreCredits,
    required this.remainingElectiveCredits,
    required this.thesisCredits,
    required this.hasGraduationProject,
    required this.thesisLabel,
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
  final List<ProgramSubject> selectableFutureSubjects;
  final List<GradeItem> retakeCandidates;
  final int completedElectiveCount;
  final int requiredElectiveCount;
}

class RetakeSuggestion {
  const RetakeSuggestion({required this.grade, required this.targetLetter});

  final GradeItem grade;
  final String targetLetter;
}

class MarkBand {
  const MarkBand({
    required this.scale4,
    required this.label4,
    required this.label10,
    required this.letter,
  });

  final double scale4;
  final String label4;
  final String label10;
  final String letter;

  factory MarkBand.fromScale4(double value) {
    if (value >= 3.5) {
      return MarkBand(
        scale4: value,
        label4: value.toStringAsFixed(2),
        label10: '8.5 - 10.0',
        letter: 'A',
      );
    }
    if (value >= 2.5) {
      return MarkBand(
        scale4: value,
        label4: value.toStringAsFixed(2),
        label10: '7.0 - 8.4',
        letter: 'B',
      );
    }
    if (value >= 1.5) {
      return MarkBand(
        scale4: value,
        label4: value.toStringAsFixed(2),
        label10: '5.5 - 6.4',
        letter: 'C',
      );
    }
    if (value >= 1.0) {
      return MarkBand(
        scale4: value,
        label4: value.toStringAsFixed(2),
        label10: '4.0 - 5.4',
        letter: 'D',
      );
    }
    return MarkBand(
      scale4: value,
      label4: value.toStringAsFixed(2),
      label10: 'Duoi 4.0',
      letter: 'F',
    );
  }
}

class _RetakeCandidate {
  const _RetakeCandidate({
    required this.suggestion,
    required this.extraQualityPoints,
    required this.priorityBucket,
  });

  final RetakeSuggestion suggestion;
  final double extraQualityPoints;
  final int priorityBucket;
}

GradeMetricsSummary calculateGradeMetrics({
  required List<GradeItem> grades,
  required List<ProgramSubject> curriculumSubjects,
}) {
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

  return GradeMetricsSummary(
    gradesForGpa: gradesForGpa,
    totalCredits: totalCredits,
    gpa: gpa,
  );
}

GoalPlanDefaults deriveGoalPlanDefaults({
  required List<GradeItem> grades,
  required List<ProgramSubject> curriculumSubjects,
}) {
  final passedGrades = _bestPassedGradesByCode(grades);
  final curriculum = _dedupedCurriculum(
    curriculumSubjects,
  ).where((item) => item.isCountedForGpa || item.isGraduationProject).toList();
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
  final retakeCandidates = passedGrades.values
      .where(
        (grade) =>
            isPassingGrade(grade) &&
            (grade.letter.startsWith('D') || grade.letter.startsWith('C')),
      )
      .toList();

  return GoalPlanDefaults(
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
    thesisLabel: thesisSubject?.subjectName ?? 'Do an tot nghiep',
    selectableFutureSubjects: selectableFutureSubjects,
    retakeCandidates: retakeCandidates,
    completedElectiveCount: completedElectives.length,
    requiredElectiveCount: requiredElectiveCount,
  );
}

GoalPlanCalculation calculateGoalPlan({
  required String targetGpaInput,
  required double currentGpa,
  required int completedCredits,
  required GoalPlanDefaults defaults,
  Set<String> guaranteedASubjectCodes = const <String>{},
}) {
  final targetText = targetGpaInput.trim().replaceAll(',', '.');
  if (targetText.isEmpty) {
    return const GoalPlanCalculation();
  }

  final targetGpa = double.tryParse(targetText);
  if (targetGpa == null || targetGpa < 0 || targetGpa > 4) {
    return const GoalPlanCalculation(
      validationError: 'GPA muc tieu phai nam trong khoang 0.00 den 4.00',
    );
  }

  final remainingCredits =
      defaults.remainingCoreCredits +
      defaults.remainingElectiveCredits +
      (defaults.hasGraduationProject ? defaults.thesisCredits : 0);
  final totalCredits = completedCredits + remainingCredits;
  final currentQualityPoints = currentGpa * completedCredits;
  final targetQualityPoints = targetGpa * totalCredits;

  var plannedQualityPoints =
      (defaults.remainingCoreCredits + defaults.remainingElectiveCredits) * 3.0;
  if (defaults.hasGraduationProject) {
    plannedQualityPoints += defaults.thesisCredits * 3.0;
  }

  final guaranteedASelections = defaults.selectableFutureSubjects
      .where((subject) => guaranteedASubjectCodes.contains(subject.subjectCode))
      .toList();
  for (final subject in guaranteedASelections) {
    plannedQualityPoints += subject.credits * 1.0;
  }

  final retakeSuggestions = <RetakeSuggestion>[];
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
    final remainingBand = MarkBand.fromScale4(
      (3.0 + extraPerCredit).clamp(0.0, 4.0),
    );
    return GoalPlanCalculation(
      result: GoalPlanResult(
        targetGpa: targetGpa,
        totalCredits: totalCredits,
        remainingCredits: remainingCredits,
        includeGraduationProject: defaults.hasGraduationProject,
        remainingBand: remainingBand,
        thesisBand: MarkBand.fromScale4(3.0),
        note:
            'Giu cac mon con lai o muc ${remainingBand.letter}, chi hoc lai ${retakeSuggestions.length} mon va uu tien cac mon D truoc.',
        retakeSuggestions: retakeSuggestions,
        guaranteedASelections: guaranteedASelections,
        thesisLabel: defaults.thesisLabel,
      ),
    );
  }

  return GoalPlanCalculation(
    result: GoalPlanResult(
      targetGpa: targetGpa,
      totalCredits: totalCredits,
      remainingCredits: remainingCredits,
      includeGraduationProject: defaults.hasGraduationProject,
      remainingBand: MarkBand.fromScale4(3.0),
      thesisBand: MarkBand.fromScale4(3.0),
      note: retakeSuggestions.isEmpty
          ? 'Co the dat muc tieu ma khong can hoc lai, chi can giu cac mon con lai o muc B.'
          : 'Co the dat muc tieu voi so mon hoc lai toi thieu, uu tien xu ly cac mon D truoc.',
      retakeSuggestions: retakeSuggestions,
      guaranteedASelections: guaranteedASelections,
      thesisLabel: defaults.thesisLabel,
    ),
  );
}

bool isPassingGrade(GradeItem grade) {
  return grade.mark4 >= 1.0 ||
      (grade.letter.isNotEmpty && !grade.letter.toUpperCase().startsWith('F'));
}

List<_RetakeCandidate> _buildRetakePool(List<GradeItem> retakeCandidates) {
  final pool = retakeCandidates.map((grade) {
    const target = 3.0;
    return _RetakeCandidate(
      suggestion: RetakeSuggestion(grade: grade, targetLetter: 'B'),
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

Map<String, GradeItem> _bestPassedGradesByCode(List<GradeItem> grades) {
  final best = <String, GradeItem>{};
  for (final grade in grades) {
    final code = grade.subjectCode.trim();
    if (code.isEmpty) continue;
    if (!isPassingGrade(grade)) continue;
    final current = best[code];
    if (current == null || grade.mark4 > current.mark4) {
      best[code] = grade;
    }
  }
  return best;
}

List<ProgramSubject> _dedupedCurriculum(
  List<ProgramSubject> curriculumSubjects,
) {
  final seen = <String>{};
  final deduped = <ProgramSubject>[];
  for (final subject in curriculumSubjects) {
    final key = subject.subjectCode.trim().isEmpty
        ? subject.subjectName.trim()
        : subject.subjectCode.trim();
    if (key.isEmpty || !seen.add(key)) continue;
    deduped.add(subject);
  }
  return deduped;
}
