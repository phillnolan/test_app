import 'package:flutter/material.dart';

import 'event_attachment.dart';

enum StudentEventType { classSchedule, exam, personalTask }

const Object _studentEventUnset = Object();

class StudentEvent {
  const StudentEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.type,
    required this.color,
    this.subtitle,
    this.location,
    this.note,
    this.sourceNote,
    this.referenceCode,
    this.attachments = const [],
    this.isDone = false,
  });

  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final StudentEventType type;
  final Color color;
  final String? subtitle;
  final String? location;
  final String? note;
  final String? sourceNote;
  final String? referenceCode;
  final List<EventAttachment> attachments;
  final bool isDone;

  StudentEvent copyWith({
    String? id,
    String? title,
    DateTime? start,
    DateTime? end,
    StudentEventType? type,
    Color? color,
    Object? subtitle = _studentEventUnset,
    Object? location = _studentEventUnset,
    Object? note = _studentEventUnset,
    Object? sourceNote = _studentEventUnset,
    Object? referenceCode = _studentEventUnset,
    List<EventAttachment>? attachments,
    bool? isDone,
  }) {
    return StudentEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      start: start ?? this.start,
      end: end ?? this.end,
      type: type ?? this.type,
      color: color ?? this.color,
      subtitle: identical(subtitle, _studentEventUnset)
          ? this.subtitle
          : subtitle as String?,
      location: identical(location, _studentEventUnset)
          ? this.location
          : location as String?,
      note: identical(note, _studentEventUnset) ? this.note : note as String?,
      sourceNote: identical(sourceNote, _studentEventUnset)
          ? this.sourceNote
          : sourceNote as String?,
      referenceCode: identical(referenceCode, _studentEventUnset)
          ? this.referenceCode
          : referenceCode as String?,
      attachments: attachments ?? this.attachments,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'type': type.name,
      'color': color.toARGB32(),
      'subtitle': subtitle,
      'location': location,
      'note': note,
      'sourceNote': sourceNote,
      'referenceCode': referenceCode,
      'attachments': attachments.map((item) => item.toJson()).toList(),
      'isDone': isDone,
    };
  }

  factory StudentEvent.fromJson(Map<String, dynamic> json) {
    return StudentEvent(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      start:
          DateTime.tryParse((json['start'] ?? '').toString()) ?? DateTime.now(),
      end: DateTime.tryParse((json['end'] ?? '').toString()) ?? DateTime.now(),
      type: StudentEventType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => StudentEventType.personalTask,
      ),
      color: Color((json['color'] as num?)?.toInt() ?? 0xFFDDE7FF),
      subtitle: json['subtitle']?.toString(),
      location: json['location']?.toString(),
      note: json['note']?.toString(),
      sourceNote: json['sourceNote']?.toString(),
      referenceCode: json['referenceCode']?.toString(),
      attachments: ((json['attachments'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) => EventAttachment.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(),
      isDone: json['isDone'] == true,
    );
  }
}
