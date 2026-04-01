import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/event_attachment.dart';
import '../models/student_event.dart';
import 'file_bytes_reader_stub.dart'
    if (dart.library.io) 'file_bytes_reader_io.dart';
import 'local_cache_service.dart';

class CloudSyncService {
  CloudSyncService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _defaultWorkerUrl =
      'https://sinhvien-worker.nkocpk99012.workers.dev';
  static const String _baseUrl = String.fromEnvironment(
    'CLOUDFLARE_WORKER_URL',
    defaultValue: _defaultWorkerUrl,
  );

  bool get isConfigured => _baseUrl.isNotEmpty;

  Future<void> upsertNote(StudentEvent event) async {
    final headers = await _authHeaders();
    if (headers == null) return;

    await _client.post(
      Uri.parse('$_baseUrl/notes'),
      headers: headers,
      body: jsonEncode({
        'id': event.id,
        'eventId': event.id,
        'eventType': event.type.name,
        'content': event.note ?? '',
      }),
    );
  }

  Future<void> upsertTask(StudentEvent event) async {
    final headers = await _authHeaders();
    if (headers == null) return;

    await _client.post(
      Uri.parse('$_baseUrl/tasks'),
      headers: headers,
      body: jsonEncode({
        'id': event.id,
        'title': event.title,
        'note': event.note ?? '',
        'startAt': event.start.toIso8601String(),
        'endAt': event.end.toIso8601String(),
        'isDone': event.isDone,
      }),
    );
  }

  Future<void> saveSyncCache(LocalCachePayload payload) async {
    final headers = await _authHeaders();
    if (headers == null) return;

    await _client.post(
      Uri.parse('$_baseUrl/sync-cache'),
      headers: headers,
      body: jsonEncode({
        'snapshotKey': 'dashboard',
        'payload': payload.toJson(),
        'ttlSeconds': 60 * 60 * 6,
      }),
    );
  }

  Future<LocalCachePayload?> fetchSyncCache({String snapshotKey = 'dashboard'}) async {
    final headers = await _authHeaders(includeJsonContentType: false);
    if (headers == null) return null;

    final response = await _client.get(
      Uri.parse('$_baseUrl/sync-cache?key=$snapshotKey'),
      headers: headers,
    );
    if (response.statusCode >= 400 || response.body.isEmpty) return null;

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;
    final data = decoded['data'];
    if (data is! Map) return null;

    return LocalCachePayload.fromJson(
      data.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  Future<EventAttachment> uploadAttachment({
    required EventAttachment attachment,
    required String eventId,
  }) async {
    final headers = await _authHeaders(includeJsonContentType: false);
    if (headers == null || attachment.remoteKey != null) return attachment;

    final bytes = attachment.bytesBase64 != null
        ? base64Decode(attachment.bytesBase64!)
        : await readBytesFromPath(attachment.path);
    if (bytes == null || bytes.isEmpty) return attachment;

    final request = http.Request(
      'POST',
      Uri.parse('$_baseUrl/attachments/upload'),
    );
    request.headers.addAll({
      ...headers,
      'x-file-name': attachment.name,
      'x-event-id': eventId,
      'content-type': _contentTypeForName(attachment.name),
    });
    request.bodyBytes = bytes;

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 400) return attachment;

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (json['data'] as Map?)?.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    final objectKey = data?['objectKey']?.toString();
    if (objectKey == null || objectKey.isEmpty) return attachment;

    return attachment.copyWith(remoteKey: objectKey);
  }

  Future<Uint8List?> downloadAttachmentBytes(EventAttachment attachment) async {
    final headers = await _authHeaders(includeJsonContentType: false);
    final objectKey = attachment.remoteKey;
    if (headers == null || objectKey == null || objectKey.isEmpty) {
      return attachment.bytesBase64 == null
          ? null
          : base64Decode(attachment.bytesBase64!);
    }

    final response = await _client.get(
      Uri.parse('$_baseUrl/attachments/download?key=${Uri.encodeQueryComponent(objectKey)}'),
      headers: headers,
    );
    if (response.statusCode >= 400) {
      return attachment.bytesBase64 == null
          ? null
          : base64Decode(attachment.bytesBase64!);
    }

    return response.bodyBytes;
  }

  Future<Map<String, String>?> _authHeaders({
    bool includeJsonContentType = true,
  }) async {
    if (!isConfigured) return null;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final token = await user.getIdToken();
    return {
      if (includeJsonContentType) 'content-type': 'application/json; charset=utf-8',
      'authorization': 'Bearer $token',
    };
  }

  String _contentTypeForName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'application/octet-stream';
  }
}
