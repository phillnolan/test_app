import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/local_cache_payload.dart';

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
