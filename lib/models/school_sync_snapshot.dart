import 'grade_item.dart';
import 'student_event.dart';
import 'student_profile.dart';

class SchoolSyncSnapshot {
  const SchoolSyncSnapshot({
    required this.profile,
    required this.grades,
    required this.events,
    required this.syncedAt,
  });

  final StudentProfile profile;
  final List<GradeItem> grades;
  final List<StudentEvent> events;
  final DateTime syncedAt;

  Map<String, dynamic> toJson() {
    return {
      'profile': profile.toJson(),
      'grades': grades.map((item) => item.toJson()).toList(),
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
      grades: ((json['grades'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) => GradeItem.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
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
