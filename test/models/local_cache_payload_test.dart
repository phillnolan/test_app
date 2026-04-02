import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinhvien_app/models/local_cache_payload.dart';
import 'package:sinhvien_app/models/student_event.dart';
import 'package:sinhvien_app/models/student_profile.dart';

void main() {
  test('LocalCachePayload round-trips with typed fields intact', () {
    final payload = LocalCachePayload(
      profile: const StudentProfile(
        username: 'student-1',
        displayName: 'Sinh Vien',
      ),
      curriculumRawItems: const [
        {'module': 'MATH101', 'credits': 3},
      ],
      syncedEvents: [
        StudentEvent(
          id: 'exam-1',
          title: 'Thi giua ky',
          start: DateTime(2026, 4, 12, 7, 0),
          end: DateTime(2026, 4, 12, 9, 0),
          type: StudentEventType.exam,
          color: const Color(0xFFFFDAD6),
        ),
      ],
      personalEvents: [
        StudentEvent(
          id: 'task-1',
          title: 'On bai',
          start: DateTime(2026, 4, 10, 8, 0),
          end: DateTime(2026, 4, 10, 9, 0),
          type: StudentEventType.personalTask,
          color: const Color(0xFFDDF4E4),
          note: 'Chuong 1',
          isDone: true,
        ),
      ],
      lastSyncedAt: DateTime(2026, 4, 2, 9, 30),
    );

    final decoded = LocalCachePayload.fromJson(payload.toJson());

    expect(decoded.profile?.username, 'student-1');
    expect(decoded.curriculumRawItems, hasLength(1));
    expect(decoded.syncedEvents.single.id, 'exam-1');
    expect(decoded.personalEvents.single.isDone, isTrue);
    expect(decoded.lastSyncedAt, DateTime(2026, 4, 2, 9, 30));
  });

  test('LocalCachePayload defensively ignores malformed list items', () {
    final decoded = LocalCachePayload.fromJson({
      'grades': ['bad-item'],
      'curriculumSubjects': [123],
      'curriculumRawItems': [
        {'module': 'ENG101'},
        'invalid',
      ],
      'syncedEvents': [null, 'oops'],
      'personalEvents': [
        {
          'id': 'task-1',
          'title': 'On bai',
          'start': '2026-04-10T08:00:00.000',
          'end': '2026-04-10T09:00:00.000',
          'type': 'personalTask',
          'color': 0xFFDDF4E4,
        },
        false,
      ],
      'lastSyncedAt': 'not-a-date',
    });

    expect(decoded.grades, isEmpty);
    expect(decoded.curriculumSubjects, isEmpty);
    expect(decoded.curriculumRawItems, hasLength(1));
    expect(decoded.syncedEvents, isEmpty);
    expect(decoded.personalEvents, hasLength(1));
    expect(decoded.lastSyncedAt, isNull);
  });
}
