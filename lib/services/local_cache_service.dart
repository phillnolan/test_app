import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/grade_item.dart';
import '../models/student_event.dart';
import '../models/student_profile.dart';

class LocalCachePayload {
  const LocalCachePayload({
    this.profile,
    this.grades = const [],
    this.syncedEvents = const [],
    this.personalEvents = const [],
    this.lastSyncedAt,
  });

  final StudentProfile? profile;
  final List<GradeItem> grades;
  final List<StudentEvent> syncedEvents;
  final List<StudentEvent> personalEvents;
  final DateTime? lastSyncedAt;

  Map<String, dynamic> toJson() {
    return {
      'profile': profile?.toJson(),
      'grades': grades.map((item) => item.toJson()).toList(),
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

class LocalCacheService {
  static const _cacheKey = 'student_planner_local_cache_v1';

  Future<LocalCachePayload?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return LocalCachePayload.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(LocalCachePayload payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(payload.toJson()));
  }
}
