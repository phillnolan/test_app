import 'grade_item.dart';
import 'program_subject.dart';
import 'student_event.dart';
import 'student_profile.dart';

class LocalCachePayload {
  const LocalCachePayload({
    this.profile,
    this.grades = const [],
    this.curriculumSubjects = const [],
    this.curriculumRawItems = const [],
    this.syncedEvents = const [],
    this.personalEvents = const [],
    this.lastSyncedAt,
  });

  final StudentProfile? profile;
  final List<GradeItem> grades;
  final List<ProgramSubject> curriculumSubjects;
  final List<Map<String, dynamic>> curriculumRawItems;
  final List<StudentEvent> syncedEvents;
  final List<StudentEvent> personalEvents;
  final DateTime? lastSyncedAt;

  bool get hasData =>
      profile != null ||
      grades.isNotEmpty ||
      syncedEvents.isNotEmpty ||
      personalEvents.isNotEmpty;

  LocalCachePayload copyWith({
    StudentProfile? profile,
    List<GradeItem>? grades,
    List<ProgramSubject>? curriculumSubjects,
    List<Map<String, dynamic>>? curriculumRawItems,
    List<StudentEvent>? syncedEvents,
    List<StudentEvent>? personalEvents,
    DateTime? lastSyncedAt,
  }) {
    return LocalCachePayload(
      profile: profile ?? this.profile,
      grades: grades ?? this.grades,
      curriculumSubjects: curriculumSubjects ?? this.curriculumSubjects,
      curriculumRawItems: curriculumRawItems ?? this.curriculumRawItems,
      syncedEvents: syncedEvents ?? this.syncedEvents,
      personalEvents: personalEvents ?? this.personalEvents,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile': profile?.toJson(),
      'grades': grades.map((item) => item.toJson()).toList(),
      'curriculumSubjects': curriculumSubjects
          .map((item) => item.toJson())
          .toList(),
      'curriculumRawItems': curriculumRawItems,
      'syncedEvents': syncedEvents.map((item) => item.toJson()).toList(),
      'personalEvents': personalEvents.map((item) => item.toJson()).toList(),
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    };
  }

  factory LocalCachePayload.fromJson(Map<String, dynamic> json) {
    return LocalCachePayload(
      profile: json['profile'] is Map
          ? StudentProfile.fromJson(
              (json['profile'] as Map).map(
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
      syncedEvents: ((json['syncedEvents'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) => StudentEvent.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(),
      personalEvents: ((json['personalEvents'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) => StudentEvent.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(),
      lastSyncedAt: json['lastSyncedAt'] == null
          ? null
          : DateTime.tryParse(json['lastSyncedAt'].toString()),
    );
  }
}
