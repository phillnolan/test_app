import '../models/grade_item.dart';
import '../models/program_subject.dart';
import 'grade_metrics.dart';

class CurriculumPresentation {
  const CurriculumPresentation({
    required this.groupLabels,
    required this.subjectsByGroup,
  });

  final List<String> groupLabels;
  final Map<String, List<CurriculumSubjectPresentation>> subjectsByGroup;
}

class CurriculumSubjectPresentation {
  const CurriculumSubjectPresentation({
    required this.subject,
    required this.isCompleted,
    required this.gradeLetter,
  });

  final ProgramSubject subject;
  final bool isCompleted;
  final String? gradeLetter;
}

CurriculumPresentation buildCurriculumPresentation({
  required List<ProgramSubject> curriculumSubjects,
  required List<GradeItem> grades,
}) {
  final subjects = _dedupedSubjects(curriculumSubjects);
  final passedCodes = _passedCodesFor(grades);
  final gradeByCode = _bestGradesByCode(grades);

  final groupedSubjects = <String, List<ProgramSubject>>{};
  final representativeByGroup = <String, ProgramSubject>{};
  for (final subject in subjects) {
    final key = subject.curriculumGroup;
    groupedSubjects.putIfAbsent(key, () => []).add(subject);
    representativeByGroup.putIfAbsent(key, () => subject);
  }

  final orderedKeys = groupedSubjects.keys.toList()
    ..sort((left, right) {
      final leftSubject = representativeByGroup[left]!;
      final rightSubject = representativeByGroup[right]!;
      final priorityCompare = _groupPriority(
        leftSubject,
      ).compareTo(_groupPriority(rightSubject));
      if (priorityCompare != 0) return priorityCompare;
      return left.compareTo(right);
    });

  final subjectsByGroup = <String, List<CurriculumSubjectPresentation>>{};
  for (final group in orderedKeys) {
    final items = groupedSubjects[group]!
      ..sort((a, b) {
        final gpaCompare = (b.isCountedForGpa ? 1 : 0).compareTo(
          a.isCountedForGpa ? 1 : 0,
        );
        if (gpaCompare != 0) return gpaCompare;
        final semesterCompare = a.semesterIndex.compareTo(b.semesterIndex);
        if (semesterCompare != 0) return semesterCompare;
        return a.subjectName.compareTo(b.subjectName);
      });

    subjectsByGroup[group] = items
        .map(
          (subject) => CurriculumSubjectPresentation(
            subject: subject,
            isCompleted: passedCodes.contains(subject.subjectCode.trim()),
            gradeLetter: gradeByCode[subject.subjectCode.trim()]?.letter,
          ),
        )
        .toList();
  }

  return CurriculumPresentation(
    groupLabels: orderedKeys,
    subjectsByGroup: subjectsByGroup,
  );
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
    if (isPassingGrade(grade)) {
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

int _groupPriority(ProgramSubject subject) {
  if (_isCoreKnowledge(subject)) return 0;
  if (_isPoliticalTheory(subject)) return 1;
  if (subject.isElective) return 2;
  if (subject.isForeignLanguageRequirement) return 4;
  if (subject.isNationalDefense) return 5;
  if (subject.isPhysicalEducation) return 6;
  return 3;
}

bool _isCoreKnowledge(ProgramSubject subject) {
  return !subject.isElective &&
      !subject.isForeignLanguageRequirement &&
      !subject.isNationalDefense &&
      !subject.isPhysicalEducation &&
      !_isPoliticalTheory(subject);
}

bool _isPoliticalTheory(ProgramSubject subject) {
  return subject.normalizedSearchText.contains('ly luan chinh tri');
}
