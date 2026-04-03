import 'dart:convert';

import 'package:flutter/foundation.dart';
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
    final encoded = jsonEncode(payload.toJson());

    try {
      await prefs.setString(_cacheKey, encoded);
    } catch (error, stackTrace) {
      debugPrint(
        'LocalCacheService: direct save failed, retrying after clear: $error',
      );
      debugPrintStack(stackTrace: stackTrace);

      await prefs.remove(_cacheKey);
      await prefs.setString(_cacheKey, encoded);
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}
