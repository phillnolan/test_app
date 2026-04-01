import 'package:flutter/material.dart';

import '../models/grade_item.dart';
import '../models/student_event.dart';

class DemoData {
  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static List<StudentEvent> events() {
    final today = _today;
    return [
      StudentEvent(
        id: 'class-mobile',
        title: 'Lap trinh di dong',
        subtitle: 'GV: Nguyen Thi Lan',
        start: today.add(const Duration(hours: 7)),
        end: today.add(const Duration(hours: 9, minutes: 30)),
        type: StudentEventType.classSchedule,
        color: const Color(0xFFE2B93B),
        location: 'P. A3-201',
        note: 'Mang theo bai tap Flutter tuan 3.',
      ),
      StudentEvent(
        id: 'task-report',
        title: 'Nop bao cao nhom',
        subtitle: 'Mon Co so du lieu',
        start: today.add(const Duration(hours: 10, minutes: 30)),
        end: today.add(const Duration(hours: 11, minutes: 30)),
        type: StudentEventType.personalTask,
        color: const Color(0xFF9BB980),
        location: 'Google Drive',
      ),
      StudentEvent(
        id: 'class-ai',
        title: 'Tri tue nhan tao',
        subtitle: 'GV: Tran Duc Minh',
        start: today.add(const Duration(hours: 13)),
        end: today.add(const Duration(hours: 15, minutes: 30)),
        type: StudentEventType.classSchedule,
        color: const Color(0xFF9AA687),
        location: 'P. B1-402',
      ),
      StudentEvent(
        id: 'exam-web',
        title: 'Thi ket thuc hoc phan Web',
        subtitle: 'Ca 4 - Thi tren may',
        start: today.add(const Duration(days: 1, hours: 8)),
        end: today.add(const Duration(days: 1, hours: 9, minutes: 30)),
        type: StudentEventType.exam,
        color: const Color(0xFFB59ACC),
        location: 'Phong may C2-305',
        note: 'Den truoc 20 phut, mang the sinh vien.',
      ),
      StudentEvent(
        id: 'task-study',
        title: 'On tap giai thuat',
        subtitle: 'Muc tieu 3 chuong',
        start: today.add(const Duration(days: 2, hours: 19)),
        end: today.add(const Duration(days: 2, hours: 21)),
        type: StudentEventType.personalTask,
        color: const Color(0xFF86A37A),
        location: 'Thu vien',
      ),
    ];
  }

  static List<GradeItem> grades = const [
    GradeItem(
      subjectCode: 'IT4409',
      subjectName: 'Lap trinh di dong',
      credits: 3,
      mark10: 8.7,
      mark4: 3.7,
      letter: 'A',
    ),
    GradeItem(
      subjectCode: 'IT4082',
      subjectName: 'Co so du lieu',
      credits: 3,
      mark10: 8.1,
      mark4: 3.5,
      letter: 'B+',
    ),
    GradeItem(
      subjectCode: 'IT4511',
      subjectName: 'Tri tue nhan tao',
      credits: 3,
      mark10: 7.8,
      mark4: 3.0,
      letter: 'B',
    ),
    GradeItem(
      subjectCode: 'EN1120',
      subjectName: 'Tieng Anh chuyen nganh',
      credits: 2,
      mark10: 9.0,
      mark4: 4.0,
      letter: 'A',
    ),
  ];
}
