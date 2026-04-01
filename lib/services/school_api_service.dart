import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/grade_item.dart';
import '../models/program_subject.dart';
import '../models/school_sync_snapshot.dart';
import '../models/student_event.dart';
import '../models/student_profile.dart';
import 'http_client_factory.dart';

class SchoolApiService {
  SchoolApiService({http.Client? client})
    : _client = client ?? buildPlatformHttpClient();

  final http.Client _client;
  static const Duration _requestTimeout = Duration(minutes: 1);

  static const _baseHost = 'https://sinhvien1.tlu.edu.vn/education';
  static const List<int> _examStudentRouteIds = [14];
  static const int _examSemesterStart = 66;
  static const int _examSemesterEnd = 66;

  Future<SchoolSyncSnapshot> sync({
    required String username,
    required String password,
  }) async {
    final accessToken = await _login(username: username, password: password);
    final headers = {
      'Accept': 'application/json, text/plain, */*',
      'Authorization': 'Bearer $accessToken',
    };

    final studentFuture = _getJsonWithRetry(
      '$_baseHost/api/student/getstudentbylogin',
      headers,
    );
    final marksFuture = _getJsonWithRetry(
      '$_baseHost/api/studentsubjectmark/getListMarkDetailStudent',
      headers,
    );
    final timetableFuture = _getJsonWithRetry(
      '$_baseHost/api/StudentCourseSubject/studentLoginUser/14',
      headers,
    );
    final examsFuture = _fetchExamsWithRetry(headers);

    final studentJson = await studentFuture;
    final curriculumProgramIds = _resolveCurriculumProgramIds(studentJson);
    final curriculumPayloads = <dynamic>[];
    for (final programId in curriculumProgramIds) {
      final curriculumJson = await _getJsonWithRetry(
        '$_baseHost/api/programsubject/tree/$programId/1/10000',
        headers,
      );
      curriculumPayloads.add(curriculumJson);
    }
    final marksJson = await marksFuture;
    final timetableJson = await timetableFuture;
    final examsJson = await examsFuture;

    final profile = StudentProfile.fromApi(
      studentJson is Map<String, dynamic> ? studentJson : null,
      username,
    );

    final grades = _parseGrades(marksJson);
    final curriculumRawItems = _flattenApiList(curriculumPayloads)
        .whereType<Map<String, dynamic>>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final curriculumSubjects = _parseCurriculum(curriculumPayloads);
    final timetableEvents = _parseTimetable(timetableJson);
    final examEvents = _parseExams(examsJson);
    final events = [...timetableEvents, ...examEvents]
      ..sort((a, b) => a.start.compareTo(b.start));

    return SchoolSyncSnapshot(
      profile: profile,
      grades: grades,
      curriculumSubjects: curriculumSubjects,
      curriculumRawItems: curriculumRawItems,
      events: events,
      syncedAt: DateTime.now(),
    );
  }

  Future<List<dynamic>> _fetchExamsWithRetry(
    Map<String, String> headers,
  ) async {
    final firstPass = await _fetchExams(headers);
    if (firstPass.isNotEmpty) return firstPass;

    await Future<void>.delayed(const Duration(milliseconds: 600));
    return _fetchExams(headers);
  }

  Future<String> _login({
    required String username,
    required String password,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$_baseHost/oauth/token'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'client_id': 'education_client',
            'grant_type': 'password',
            'username': username,
            'password': password,
            'client_secret': 'password',
          }),
        )
        .timeout(_requestTimeout);

    final json = _decodeJson(_decodeBody(response));
    if (json is! Map<String, dynamic> ||
        response.statusCode >= 400 ||
        json['access_token'] == null) {
      throw SchoolApiException(
        json is Map<String, dynamic>
            ? json['error_description']?.toString() ??
                  'Đăng nhập thất bại. Vui lòng kiểm tra tài khoản.'
            : 'Đăng nhập thất bại. Vui lòng kiểm tra tài khoản.',
      );
    }
    return json['access_token'].toString();
  }

  Future<List<dynamic>> _fetchExams(Map<String, String> headers) async {
    final aggregated = <dynamic>[];
    final seenExamPayloads = <String>{};

    for (final routeId in _examStudentRouteIds) {
      for (
        var semesterId = _examSemesterStart;
        semesterId <= _examSemesterEnd;
        semesterId++
      ) {
        try {
          final result = await _getJsonWithRetry(
            '$_baseHost/api/semestersubjectexamroom/getListRoomByStudentByLoginUser/$routeId/$semesterId/1',
            headers,
            attempts: 2,
          );
          for (final item in _normalizeList(result)) {
            final fingerprint = jsonEncode(item);
            if (seenExamPayloads.add(fingerprint)) {
              aggregated.add(item);
            }
          }
        } catch (_) {
          continue;
        }
      }
    }

    return aggregated;
  }

  Future<dynamic> _getJson(String url, Map<String, String> headers) async {
    final response = await _client
        .get(Uri.parse(url), headers: headers)
        .timeout(_requestTimeout);
    if (response.statusCode >= 400) {
      throw SchoolApiException('Không tải được dữ liệu từ cổng trường.');
    }
    return _decodeJson(_decodeBody(response));
  }

  Future<dynamic> _getJsonWithRetry(
    String url,
    Map<String, String> headers, {
    int attempts = 3,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        return await _getJson(url, headers);
      } catch (error) {
        lastError = error;
        if (attempt < attempts - 1) {
          await Future<void>.delayed(
            Duration(milliseconds: 450 * (attempt + 1)),
          );
        }
      }
    }
    throw lastError ??
        SchoolApiException('Không tải được dữ liệu từ cổng trường.');
  }

  List<int> _resolveCurriculumProgramIds(dynamic studentJson) {
    if (studentJson is! Map<String, dynamic>) {
      throw SchoolApiException(
        'Không lấy được chương trình đào tạo từ tài khoản sinh viên.',
      );
    }

    final ids = <int>{};

    final programs = _normalizeList(studentJson['programs']);
    for (final item in programs.whereType<Map<String, dynamic>>()) {
      final parsed = int.tryParse('${item['program']?['id'] ?? ''}');
      if (parsed != null && parsed > 0) {
        ids.add(parsed);
      }
    }

    if (ids.isEmpty) {
      throw SchoolApiException(
        'Tài khoản này chưa có thông tin chương trình đào tạo hợp lệ.',
      );
    }
    return ids.toList()..sort();
  }

  List<GradeItem> _parseGrades(dynamic data) {
    return _normalizeList(
      data,
    ).whereType<Map<String, dynamic>>().map(GradeItem.fromApi).toList();
  }

  List<ProgramSubject> _parseCurriculum(dynamic data) {
    final seen = <String>{};
    return _flattenApiList(data)
        .whereType<Map<String, dynamic>>()
        .map(ProgramSubject.fromApi)
        .where(
          (item) => item.subjectCode.isNotEmpty || item.subjectName.isNotEmpty,
        )
        .where(
          (item) => seen.add(
            item.subjectCode.isEmpty ? item.subjectName : item.subjectCode,
          ),
        )
        .toList()
      ..sort((a, b) {
        final semesterCompare = a.semesterIndex.compareTo(b.semesterIndex);
        if (semesterCompare != 0) return semesterCompare;
        return a.subjectName.compareTo(b.subjectName);
      });
  }

  List<StudentEvent> _parseTimetable(dynamic data) {
    final events = <StudentEvent>[];

    for (final rawCourse in _normalizeList(
      data,
    ).whereType<Map<String, dynamic>>()) {
      final title =
          (rawCourse['subjectCode'] ?? rawCourse['subjectName'] ?? 'Lịch học')
              .toString();
      final teacher =
          rawCourse['courseSubject']?['teacher']?['displayName']?.toString() ??
          rawCourse['displayName']?.toString();
      final timetables = _normalizeList(
        rawCourse['courseSubject']?['timetables'] ?? rawCourse['timetables'],
      );

      for (final slot in timetables.whereType<Map<String, dynamic>>()) {
        final occurrences = _expandTimetableOccurrences(slot);
        if (occurrences.isEmpty) continue;

        final room = slot['roomName']?.toString();
        final fromWeek = slot['fromWeek']?.toString();
        final toWeek = slot['toWeek']?.toString();
        final noteParts = <String>[];

        if (fromWeek != null && toWeek != null) {
          noteParts.add('Tuần $fromWeek - $toWeek');
        }

        final weekdayLabel = _weekdayLabelFromWeekIndex(slot['weekIndex']);
        if (weekdayLabel != null) {
          noteParts.add(weekdayLabel);
        }

        for (final occurrence in occurrences) {
          final start = occurrence.$1;
          final end = occurrence.$2;

          events.add(
            StudentEvent(
              id: 'class-${rawCourse['id'] ?? title}-${slot['id'] ?? start.toIso8601String()}',
              title: title,
              subtitle: teacher == null || teacher.isEmpty
                  ? 'Lịch học'
                  : teacher,
              start: start,
              end: end.isAfter(start)
                  ? end
                  : start.add(const Duration(hours: 2)),
              type: StudentEventType.classSchedule,
              color: const Color(0xFFDDE7FF),
              location: room,
              note: noteParts.isEmpty ? null : noteParts.join(' • '),
              referenceCode: null,
            ),
          );
        }
      }
    }

    return events;
  }

  List<StudentEvent> _parseExams(dynamic data) {
    final events = <StudentEvent>[];
    final seen = <String>{};

    for (final rawExam in _normalizeList(
      data,
    ).whereType<Map<String, dynamic>>()) {
      final examRoom = rawExam['examRoom'];
      final start = _combineDateAndClock(
        rawDate: examRoom?['examDate'] ?? rawExam['date'],
        displayTime:
            examRoom?['examHour']?['startString'] ?? rawExam['startHourName'],
        numericTime: examRoom?['examHour']?['start'] ?? rawExam['startHour'],
      );
      final end = _combineDateAndClock(
        rawDate: examRoom?['examDate'] ?? rawExam['date'],
        displayTime:
            examRoom?['examHour']?['endString'] ?? rawExam['endHourName'],
        numericTime: examRoom?['examHour']?['end'] ?? rawExam['endHour'],
      );
      if (start == null || end == null) continue;

      final title = (rawExam['subjectName'] ?? 'Lịch thi').toString();
      final room =
          examRoom?['room']?['name']?.toString() ?? rawExam['room']?.toString();
      final examName =
          (examRoom?['examHour']?['name'] ?? rawExam['examName'] ?? 'Ca thi')
              .toString();
      final period = rawExam['examPeriodCode']?.toString();
      final referenceCode = _firstNonEmptyString([
        rawExam['studentExamCode'],
        rawExam['candidateNumber'],
        rawExam['numberCode'],
        rawExam['examNumber'],
        rawExam['examCode'],
        rawExam['studentCode'],
        examRoom?['candidateNumber'],
      ]);
      final key = '$title-${start.toIso8601String()}-$room';
      if (!seen.add(key)) continue;

      events.add(
        StudentEvent(
          id: 'exam-$key',
          title: title,
          subtitle: examName,
          start: start,
          end: end.isAfter(start) ? end : start.add(const Duration(hours: 2)),
          type: StudentEventType.exam,
          color: const Color(0xFFFFDAD6),
          location: room,
          note: period,
          referenceCode: referenceCode,
        ),
      );
    }

    return events;
  }

  DateTime? _combineDateAndClock({
    required dynamic rawDate,
    required dynamic displayTime,
    required dynamic numericTime,
  }) {
    final baseDate = _parseDate(rawDate);
    if (baseDate == null) return null;

    final time = _parseClock(displayTime) ?? _parseClockFromEpoch(numericTime);
    if (time == null) {
      return DateTime(baseDate.year, baseDate.month, baseDate.day);
    }

    return DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      time.hour,
      time.minute,
    );
  }

  List<(DateTime, DateTime)> _expandTimetableOccurrences(
    Map<String, dynamic> slot,
  ) {
    final weekStart = _parseDate(slot['startDate']);
    final weekEnd = _parseDate(slot['endDate']);
    final dayOffset = _dayOffsetFromWeekIndex(slot['weekIndex']);
    if (weekStart == null || dayOffset == null) return const [];

    final startTime =
        _parseClock(slot['startHour']?['name'] ?? slot['startHourName']) ??
        _parseClockFromEpoch(slot['startHour']?['start'] ?? slot['startHour']);
    final endTime =
        _parseClock(slot['endHour']?['name'] ?? slot['endHourName']) ??
        _parseClockFromEpoch(slot['endHour']?['end'] ?? slot['endHour']);

    final firstDay = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    ).add(Duration(days: dayOffset));

    final lastDay = weekEnd == null
        ? firstDay
        : DateTime(weekEnd.year, weekEnd.month, weekEnd.day);
    if (firstDay.isAfter(lastDay)) return const [];

    final occurrences = <(DateTime, DateTime)>[];
    for (
      var day = firstDay;
      !day.isAfter(lastDay);
      day = day.add(const Duration(days: 7))
    ) {
      final start = startTime == null
          ? day
          : DateTime(
              day.year,
              day.month,
              day.day,
              startTime.hour,
              startTime.minute,
            );
      final end = endTime == null
          ? day.add(const Duration(hours: 2))
          : DateTime(
              day.year,
              day.month,
              day.day,
              endTime.hour,
              endTime.minute,
            );
      occurrences.add((start, end));
    }

    return occurrences;
  }

  DateTime? _parseDate(dynamic rawDate) {
    if (rawDate is int) {
      return DateTime.fromMillisecondsSinceEpoch(rawDate);
    }
    if (rawDate is double) {
      return DateTime.fromMillisecondsSinceEpoch(rawDate.round());
    }
    final text = rawDate?.toString();
    if (text == null || text.isEmpty) return null;
    final millis = int.tryParse(text);
    if (millis != null) {
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    return DateTime.tryParse(text);
  }

  TimeOfDay? _parseClock(dynamic displayTime) {
    final text = displayTime?.toString();
    if (text == null || text.isEmpty) return null;
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(text);
    if (match == null) return null;
    return TimeOfDay(
      hour: int.parse(match.group(1)!),
      minute: int.parse(match.group(2)!),
    );
  }

  TimeOfDay? _parseClockFromEpoch(dynamic rawClock) {
    if (rawClock is int) {
      final date = DateTime.fromMillisecondsSinceEpoch(rawClock);
      return TimeOfDay(hour: date.hour, minute: date.minute);
    }
    if (rawClock is double) {
      final date = DateTime.fromMillisecondsSinceEpoch(rawClock.round());
      return TimeOfDay(hour: date.hour, minute: date.minute);
    }
    final text = rawClock?.toString();
    if (text == null || text.isEmpty) return null;
    final millis = int.tryParse(text);
    if (millis == null) return null;
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    return TimeOfDay(hour: date.hour, minute: date.minute);
  }

  int? _dayOffsetFromWeekIndex(dynamic rawWeekIndex) {
    final weekIndex = rawWeekIndex is int
        ? rawWeekIndex
        : int.tryParse(rawWeekIndex?.toString() ?? '');

    return switch (weekIndex) {
      0 || 1 => 6,
      2 => 0,
      3 => 1,
      4 => 2,
      5 => 3,
      6 => 4,
      7 => 5,
      _ => null,
    };
  }

  String? _weekdayLabelFromWeekIndex(dynamic rawWeekIndex) {
    final weekIndex = rawWeekIndex is int
        ? rawWeekIndex
        : int.tryParse(rawWeekIndex?.toString() ?? '');

    return switch (weekIndex) {
      0 || 1 => 'Chủ nhật',
      2 => 'Thứ Hai',
      3 => 'Thứ Ba',
      4 => 'Thứ Tư',
      5 => 'Thứ Năm',
      6 => 'Thứ Sáu',
      7 => 'Thứ Bảy',
      _ => null,
    };
  }

  List<dynamic> _normalizeList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['content'] is List) {
      return data['content'] as List<dynamic>;
    }
    if (data is Map<String, dynamic> && data['data'] is List) {
      return data['data'] as List<dynamic>;
    }
    return const [];
  }

  List<dynamic> _flattenApiList(dynamic data) {
    if (data is List) {
      final flattened = <dynamic>[];
      for (final item in data) {
        flattened.addAll(_normalizeList(item));
      }
      return flattened;
    }
    return _normalizeList(data);
  }

  String? _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return null;
  }

  String _decodeBody(http.Response response) {
    return utf8.decode(response.bodyBytes);
  }

  dynamic _decodeJson(String body) {
    return jsonDecode(body);
  }
}

class SchoolApiException implements Exception {
  SchoolApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
