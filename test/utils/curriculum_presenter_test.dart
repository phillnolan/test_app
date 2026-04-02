import 'package:flutter_test/flutter_test.dart';
import 'package:sinhvien_app/models/grade_item.dart';
import 'package:sinhvien_app/models/program_subject.dart';
import 'package:sinhvien_app/utils/curriculum_presenter.dart';

void main() {
  test('buildCurriculumPresentation dedupe, group va danh dau mon da qua', () {
    final curriculum = [
      const ProgramSubject(
        subjectCode: 'CS101',
        subjectName: 'Nhap mon',
        knowledgeBlock: 'Kien thuc nganh',
        semesterIndex: 1,
        credits: 3,
      ),
      const ProgramSubject(
        subjectCode: 'CS101',
        subjectName: 'Nhap mon',
        knowledgeBlock: 'Kien thuc nganh',
        semesterIndex: 1,
        credits: 3,
      ),
      const ProgramSubject(
        subjectCode: 'EL201',
        subjectName: 'Mon tu chon',
        knowledgeBlock: 'Tu chon',
        semesterIndex: 5,
        credits: 2,
      ),
      const ProgramSubject(
        subjectCode: 'PE101',
        subjectName: 'Giao duc the chat',
        knowledgeBlock: 'Giao duc the chat',
        semesterIndex: 1,
        credits: 1,
      ),
    ];
    final grades = [
      const GradeItem(
        subjectCode: 'CS101',
        subjectName: 'Nhap mon',
        credits: 3,
        mark10: 8.5,
        mark4: 3.5,
        letter: 'A',
      ),
    ];

    final presentation = buildCurriculumPresentation(
      curriculumSubjects: curriculum,
      grades: grades,
    );

    expect(presentation.groupLabels, isNotEmpty);
    expect(
      presentation.subjectsByGroup.values.expand((items) => items).length,
      3,
    );

    final firstGroup = presentation.groupLabels.first;
    final firstItem = presentation.subjectsByGroup[firstGroup]!.firstWhere(
      (item) => item.subject.subjectCode == 'CS101',
    );
    expect(firstItem.isCompleted, isTrue);
    expect(firstItem.gradeLetter, 'A');
  });
}
