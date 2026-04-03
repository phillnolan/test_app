import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/student_sync_credentials.dart';

class StudentSyncCredentialsService {
  static const _credentialsKey = 'student_sync_credentials_v1';

  Future<StudentSyncCredentials?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_credentialsKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return StudentSyncCredentials.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(StudentSyncCredentials credentials) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_credentialsKey, jsonEncode(credentials.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_credentialsKey);
  }
}
