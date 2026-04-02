import 'package:flutter_test/flutter_test.dart';
import 'package:sinhvien_app/models/grade_item.dart';
import 'package:sinhvien_app/models/program_subject.dart';
import 'package:sinhvien_app/utils/grade_metrics.dart';

void main() {
  test(
    'calculateGradeMetrics chi tinh GPA cho mon duoc count khi co curriculum',
    () {
      final grades = [
        const GradeItem(
          subjectCode: 'MATH101',
          subjectName: 'Giai tich',
          credits: 3,
          mark10: 8.0,
          mark4: 3.5,
          letter: 'B+',
        ),
        const GradeItem(
          subjectCode: 'PE101',
          subjectName: 'Giao duc the chat',
          credits: 2,
          mark10: 10.0,
          mark4: 4.0,
          letter: 'A',
        ),
      ];
      final curriculum = [
        const ProgramSubject(
          subjectCode: 'MATH101',
          subjectName: 'Giai tich',
          knowledgeBlock: 'Kien thuc nganh',
          semesterIndex: 1,
          credits: 3,
        ),
        const ProgramSubject(
          subjectCode: 'PE101',
          subjectName: 'Giao duc the chat',
          knowledgeBlock: 'Giao duc the chat',
          semesterIndex: 1,
          credits: 2,
        ),
      ];

      final result = calculateGradeMetrics(
        grades: grades,
        curriculumSubjects: curriculum,
      );

      expect(result.gradesForGpa, hasLength(1));
      expect(result.gradesForGpa.single.subjectCode, 'MATH101');
      expect(result.totalCredits, 3);
      expect(result.gpa, closeTo(3.5, 0.001));
    },
  );

  test('calculateGoalPlan tra ve loi validate cho input khong hop le', () {
    final defaults = deriveGoalPlanDefaults(
      grades: const [],
      curriculumSubjects: const [],
    );

    final result = calculateGoalPlan(
      targetGpaInput: '4.5',
      currentGpa: 3.0,
      completedCredits: 90,
      defaults: defaults,
    );

    expect(result.result, isNull);
    expect(result.validationError, isNotNull);
  });

  test('calculateGoalPlan uu tien hoc lai mon D truoc mon C', () {
    final grades = [
      const GradeItem(
        subjectCode: 'SUB1',
        subjectName: 'Mon D',
        credits: 3,
        mark10: 4.5,
        mark4: 1.0,
        letter: 'D',
      ),
      const GradeItem(
        subjectCode: 'SUB2',
        subjectName: 'Mon C',
        credits: 3,
        mark10: 6.0,
        mark4: 2.0,
        letter: 'C',
      ),
    ];
    final curriculum = [
      const ProgramSubject(
        subjectCode: 'CORE1',
        subjectName: 'Mon con lai 1',
        knowledgeBlock: 'Kien thuc nganh',
        semesterIndex: 7,
        credits: 3,
      ),
      const ProgramSubject(
        subjectCode: 'CORE2',
        subjectName: 'Mon con lai 2',
        knowledgeBlock: 'Kien thuc nganh',
        semesterIndex: 7,
        credits: 3,
      ),
    ];

    final defaults = deriveGoalPlanDefaults(
      grades: grades,
      curriculumSubjects: curriculum,
    );
    final result = calculateGoalPlan(
      targetGpaInput: '2.60',
      currentGpa: 2.0,
      completedCredits: 60,
      defaults: defaults,
    );

    expect(result.result, isNotNull);
    expect(result.result!.retakeSuggestions, isNotEmpty);
    expect(result.result!.retakeSuggestions.first.grade.subjectCode, 'SUB1');
  });
}
