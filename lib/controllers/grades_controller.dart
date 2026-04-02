import 'package:flutter/foundation.dart';

import '../models/grade_item.dart';
import '../models/program_subject.dart';
import '../utils/curriculum_presenter.dart';
import '../utils/grade_metrics.dart';

class GradesController extends ChangeNotifier {
  GradesController({
    List<GradeItem> grades = const <GradeItem>[],
    List<ProgramSubject> curriculumSubjects = const <ProgramSubject>[],
  }) {
    _applyData(
      grades: grades,
      curriculumSubjects: curriculumSubjects,
      notify: false,
    );
  }

  List<GradeItem> _grades = const <GradeItem>[];
  List<ProgramSubject> _curriculumSubjects = const <ProgramSubject>[];
  GradeMetricsSummary _metrics = const GradeMetricsSummary(
    gradesForGpa: <GradeItem>[],
    totalCredits: 0,
    gpa: 0,
  );
  GoalPlanDefaults _goalPlanDefaults = const GoalPlanDefaults(
    remainingCoreCredits: 0,
    remainingElectiveCredits: 0,
    thesisCredits: 10,
    hasGraduationProject: false,
    thesisLabel: 'Do an tot nghiep',
    selectableFutureSubjects: <ProgramSubject>[],
    retakeCandidates: <GradeItem>[],
    completedElectiveCount: 0,
    requiredElectiveCount: 0,
  );
  GoalPlanCalculation _goalPlanCalculation = const GoalPlanCalculation();
  CurriculumPresentation _curriculumPresentation = const CurriculumPresentation(
    groupLabels: <String>[],
    subjectsByGroup: <String, List<CurriculumSubjectPresentation>>{},
  );
  String _selectedCurriculumGroup = '';
  String _targetGpaInput = '';
  Set<String> _guaranteedASubjectCodes = <String>{};

  List<GradeItem> get grades => _grades;
  List<ProgramSubject> get curriculumSubjects => _curriculumSubjects;
  GradeMetricsSummary get metrics => _metrics;
  GoalPlanDefaults get goalPlanDefaults => _goalPlanDefaults;
  GoalPlanCalculation get goalPlanCalculation => _goalPlanCalculation;
  CurriculumPresentation get curriculumPresentation => _curriculumPresentation;
  String get selectedCurriculumGroup => _selectedCurriculumGroup;
  String get targetGpaInput => _targetGpaInput;
  Set<String> get guaranteedASubjectCodes =>
      Set<String>.unmodifiable(_guaranteedASubjectCodes);

  List<CurriculumSubjectPresentation> get selectedCurriculumSubjects =>
      _curriculumPresentation.subjectsByGroup[_selectedCurriculumGroup] ??
      const <CurriculumSubjectPresentation>[];

  void updateData({
    required List<GradeItem> grades,
    required List<ProgramSubject> curriculumSubjects,
  }) {
    _applyData(
      grades: grades,
      curriculumSubjects: curriculumSubjects,
      notify: true,
    );
  }

  void setTargetGpaInput(String value) {
    if (_targetGpaInput == value) return;
    _targetGpaInput = value;
    _goalPlanCalculation = _buildGoalPlanCalculation();
    notifyListeners();
  }

  void setGuaranteedASubjectCodes(Set<String> subjectCodes) {
    final validCodes = _goalPlanDefaults.selectableFutureSubjects
        .map((subject) => subject.subjectCode)
        .toSet();
    final filteredCodes = subjectCodes
        .map((code) => code.trim())
        .where((code) => code.isNotEmpty && validCodes.contains(code))
        .toSet();
    if (setEquals(filteredCodes, _guaranteedASubjectCodes)) return;
    _guaranteedASubjectCodes = filteredCodes;
    _goalPlanCalculation = _buildGoalPlanCalculation();
    notifyListeners();
  }

  void selectCurriculumGroup(String group) {
    if (!_curriculumPresentation.groupLabels.contains(group)) return;
    if (_selectedCurriculumGroup == group) return;
    _selectedCurriculumGroup = group;
    notifyListeners();
  }

  void _applyData({
    required List<GradeItem> grades,
    required List<ProgramSubject> curriculumSubjects,
    required bool notify,
  }) {
    _grades = List<GradeItem>.unmodifiable(grades);
    _curriculumSubjects = List<ProgramSubject>.unmodifiable(curriculumSubjects);
    _metrics = calculateGradeMetrics(
      grades: _grades,
      curriculumSubjects: _curriculumSubjects,
    );
    _goalPlanDefaults = deriveGoalPlanDefaults(
      grades: _metrics.gradesForGpa,
      curriculumSubjects: _curriculumSubjects,
    );
    _curriculumPresentation = buildCurriculumPresentation(
      curriculumSubjects: _curriculumSubjects,
      grades: _grades,
    );
    _syncDerivedState();
    _goalPlanCalculation = _buildGoalPlanCalculation();
    if (notify) {
      notifyListeners();
    }
  }

  void _syncDerivedState() {
    final validSelectableCodes = _goalPlanDefaults.selectableFutureSubjects
        .map((subject) => subject.subjectCode)
        .toSet();
    _guaranteedASubjectCodes = _guaranteedASubjectCodes
        .where(validSelectableCodes.contains)
        .toSet();

    if (_curriculumPresentation.groupLabels.contains(
      _selectedCurriculumGroup,
    )) {
      return;
    }
    _selectedCurriculumGroup = _curriculumPresentation.groupLabels.isEmpty
        ? ''
        : _curriculumPresentation.groupLabels.first;
  }

  GoalPlanCalculation _buildGoalPlanCalculation() {
    return calculateGoalPlan(
      targetGpaInput: _targetGpaInput,
      currentGpa: _metrics.gpa,
      completedCredits: _metrics.totalCredits,
      defaults: _goalPlanDefaults,
      guaranteedASubjectCodes: _guaranteedASubjectCodes,
    );
  }
}
