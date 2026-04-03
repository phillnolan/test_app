import 'current_tuition.dart';
import 'grade_item.dart';
import 'program_subject.dart';
import 'student_event.dart';
import 'student_profile.dart';

class SchoolSyncSnapshot {
  const SchoolSyncSnapshot({
    required this.profile,
    required this.currentTuition,
    required this.grades,
    required this.curriculumSubjects,
    required this.curriculumRawItems,
    required this.events,
    required this.syncedAt,
  });

  final StudentProfile profile;
  final CurrentTuition? currentTuition;
  final List<GradeItem> grades;
  final List<ProgramSubject> curriculumSubjects;
  final List<Map<String, dynamic>> curriculumRawItems;
  final List<StudentEvent> events;
  final DateTime syncedAt;

  Map<String, dynamic> toJson() {
    return {
      'profile': profile.toJson(),
      'currentTuition': currentTuition?.toJson(),
      'grades': grades.map((item) => item.toJson()).toList(),
      'curriculumSubjects': curriculumSubjects
          .map((item) => item.toJson())
          .toList(),
      'curriculumRawItems': curriculumRawItems,
      'events': events.map((item) => item.toJson()).toList(),
      'syncedAt': syncedAt.toIso8601String(),
    };
  }

  factory SchoolSyncSnapshot.fromJson(Map<String, dynamic> json) {
    return SchoolSyncSnapshot(
      profile: StudentProfile.fromJson(
        ((json['profile'] as Map?) ?? const {}).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      ),
      currentTuition: json['currentTuition'] is Map
          ? CurrentTuition.fromJson(
              (json['currentTuition'] as Map).map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            )
          : null,
      grades: ((json['grades'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) => GradeItem.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(),
      curriculumSubjects: ((json['curriculumSubjects'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) => ProgramSubject.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(),
      curriculumRawItems: ((json['curriculumRawItems'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) => item.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList(),
      events: ((json['events'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) => StudentEvent.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(),
      syncedAt:
          DateTime.tryParse((json['syncedAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
