import 'package:flutter_test/flutter_test.dart';
import 'package:sinhvien_app/controllers/grades_controller.dart';
import 'package:sinhvien_app/models/grade_item.dart';
import 'package:sinhvien_app/models/program_subject.dart';

void main() {
  test('GradesController tinh metrics va chon group dau tien mac dinh', () {
    final controller = GradesController(
      grades: const <GradeItem>[
        GradeItem(
          subjectCode: 'CS101',
          subjectName: 'Nhap mon',
          credits: 3,
          mark10: 8.5,
          mark4: 3.5,
          letter: 'A',
        ),
        GradeItem(
          subjectCode: 'PE101',
          subjectName: 'Giao duc the chat',
          credits: 2,
          mark10: 10,
          mark4: 4,
          letter: 'A',
        ),
      ],
      curriculumSubjects: const <ProgramSubject>[
        ProgramSubject(
          subjectCode: 'CS101',
          subjectName: 'Nhap mon',
          knowledgeBlock: 'Kien thuc nganh',
          semesterIndex: 1,
          credits: 3,
        ),
        ProgramSubject(
          subjectCode: 'PE101',
          subjectName: 'Giao duc the chat',
          knowledgeBlock: 'Giao duc the chat',
          semesterIndex: 1,
          credits: 2,
        ),
      ],
    );

    expect(controller.metrics.totalCredits, 3);
    expect(controller.metrics.gpa, closeTo(3.5, 0.001));
    expect(controller.selectedCurriculumGroup, isNotEmpty);
    expect(controller.selectedCurriculumSubjects, isNotEmpty);
    expect(
      controller.selectedCurriculumSubjects
          .firstWhere((item) => item.subject.subjectCode == 'CS101')
          .isCompleted,
      isTrue,
    );
  });

  test('GradesController cap nhat planner state va validate input', () {
    final controller = GradesController(
      grades: const <GradeItem>[
        GradeItem(
          subjectCode: 'SUB1',
          subjectName: 'Mon D',
          credits: 3,
          mark10: 4.5,
          mark4: 1.0,
          letter: 'D',
        ),
        GradeItem(
          subjectCode: 'SUB2',
          subjectName: 'Mon C',
          credits: 3,
          mark10: 6.0,
          mark4: 2.0,
          letter: 'C',
        ),
      ],
      curriculumSubjects: const <ProgramSubject>[
        ProgramSubject(
          subjectCode: 'SUB1',
          subjectName: 'Mon D',
          knowledgeBlock: 'Kien thuc nganh',
          semesterIndex: 1,
          credits: 3,
        ),
        ProgramSubject(
          subjectCode: 'SUB2',
          subjectName: 'Mon C',
          knowledgeBlock: 'Kien thuc nganh',
          semesterIndex: 1,
          credits: 3,
        ),
        ProgramSubject(
          subjectCode: 'CORE1',
          subjectName: 'Mon con lai 1',
          knowledgeBlock: 'Kien thuc nganh',
          semesterIndex: 7,
          credits: 3,
        ),
        ProgramSubject(
          subjectCode: 'CORE2',
          subjectName: 'Mon con lai 2',
          knowledgeBlock: 'Kien thuc nganh',
          semesterIndex: 7,
          credits: 3,
        ),
      ],
    );

    controller.setTargetGpaInput('4.5');
    expect(controller.goalPlanCalculation.result, isNull);
    expect(controller.goalPlanCalculation.validationError, isNotNull);

    controller.setTargetGpaInput('2.60');
    expect(controller.goalPlanCalculation.result, isNotNull);
    expect(
      controller.goalPlanCalculation.result!.retakeSuggestions,
      isNotEmpty,
    );
    expect(
      controller
          .goalPlanCalculation
          .result!
          .retakeSuggestions
          .first
          .grade
          .subjectCode,
      'SUB1',
    );
  });

  test(
    'GradesController reset filter va prune guaranteed A khi du lieu thay doi',
    () {
      final controller = GradesController(
        grades: const <GradeItem>[
          GradeItem(
            subjectCode: 'CS101',
            subjectName: 'Nhap mon',
            credits: 3,
            mark10: 8.5,
            mark4: 3.5,
            letter: 'A',
          ),
        ],
        curriculumSubjects: const <ProgramSubject>[
          ProgramSubject(
            subjectCode: 'CS101',
            subjectName: 'Nhap mon',
            knowledgeBlock: 'Kien thuc nganh',
            semesterIndex: 1,
            credits: 3,
          ),
          ProgramSubject(
            subjectCode: 'EL201',
            subjectName: 'Mon tu chon',
            knowledgeBlock: 'Tu chon',
            semesterIndex: 5,
            credits: 2,
          ),
          ProgramSubject(
            subjectCode: 'PE101',
            subjectName: 'Giao duc the chat',
            knowledgeBlock: 'Giao duc the chat',
            semesterIndex: 1,
            credits: 1,
          ),
        ],
      );

      controller.setGuaranteedASubjectCodes({'EL201', 'MISSING'});
      final alternateGroup = controller.curriculumPresentation.groupLabels.last;
      controller.selectCurriculumGroup(alternateGroup);

      expect(controller.guaranteedASubjectCodes, {'EL201'});
      expect(controller.selectedCurriculumGroup, alternateGroup);

      controller.updateData(
        grades: const <GradeItem>[],
        curriculumSubjects: const <ProgramSubject>[
          ProgramSubject(
            subjectCode: 'CS201',
            subjectName: 'Mon moi',
            knowledgeBlock: 'Kien thuc nganh',
            semesterIndex: 3,
            credits: 3,
          ),
        ],
      );

      expect(controller.guaranteedASubjectCodes, isEmpty);
      expect(controller.selectedCurriculumGroup, 'Kien thuc nganh');
    },
  );
}
