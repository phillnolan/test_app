import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../models/event_attachment.dart';
import '../../../models/local_cache_payload.dart';
import '../../../models/student_event.dart';
import '../../../services/teldrive_api_client.dart';
import '../../../services/teldrive_models.dart';
import '../../attachments/data/file_bytes_reader_stub.dart'
    if (dart.library.io) '../../attachments/data/file_bytes_reader_io.dart';

class CloudSyncService {
  CloudSyncService({TeldriveApiClient? client})
    : _client = client ?? TeldriveApiClient();

  final TeldriveApiClient _client;

  static const String _payloadFileName = 'sinhvien-app-dashboard.json';
  static const String _attachmentPrefix = 'sinhvien-app-attachment';

  bool get isConfigured => true;

  Future<void> upsertNote(StudentEvent event) async {
    _logTiming('upsertNote ${event.id}', elapsedMs: 0, extra: 'noop');
  }

  Future<void> upsertTask(StudentEvent event) async {
    _logTiming('upsertTask ${event.id}', elapsedMs: 0, extra: 'noop');
  }

  Future<void> upsertEventsBatch(List<StudentEvent> events) async {
    if (events.isEmpty) {
      return;
    }

    _logTiming(
      'upsertEventsBatch',
      elapsedMs: 0,
      extra: 'noop count=${events.length}',
    );
  }

  Future<void> saveSyncCache(LocalCachePayload payload) async {
    final stopwatch = Stopwatch()..start();
    final jsonBytes = utf8.encode(jsonEncode(payload.toJson()));
    await _replaceSingleFile(
      fileName: _payloadFileName,
      bytes: Uint8List.fromList(jsonBytes),
      contentType: 'application/json; charset=utf-8',
    );
    _logTiming(
      'saveSyncCache',
      elapsedMs: stopwatch.elapsedMilliseconds,
      extra:
          'synced=${payload.syncedEvents.length} personal=${payload.personalEvents.length}',
    );
  }

  Future<void> clearAccountData() async {
    await _client.deleteFilesByNamePrefix(_payloadFileName);
    await _client.deleteFilesByNamePrefix(_attachmentPrefix);
  }

  Future<LocalCachePayload?> fetchSyncCache({
    String snapshotKey = 'dashboard',
  }) async {
    final fileName = snapshotKey == 'dashboard'
        ? _payloadFileName
        : 'sinhvien-app-$snapshotKey.json';
    final file = await _client.findFileByName(fileName);
    if (file == null || file.id.isEmpty) {
      return null;
    }

    final bytes = await _client.downloadFileBytes(
      fileId: file.id,
      fileName: file.name,
    );
    if (bytes == null || bytes.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return LocalCachePayload.fromJson(decoded);
    } catch (error) {
      debugPrint('CloudSyncService: failed to decode sync cache: $error');
      return null;
    }
  }

  Future<EventAttachment> uploadAttachment({
    required EventAttachment attachment,
    required String eventId,
  }) async {
    final stopwatch = Stopwatch()..start();
    if (attachment.remoteKey != null) {
      _logTiming(
        'uploadAttachment skipped ${attachment.name}',
        elapsedMs: stopwatch.elapsedMilliseconds,
        extra: 'event=$eventId hasRemote=true',
      );
      return attachment;
    }

    final bytes = attachment.bytesBase64 != null
        ? base64Decode(attachment.bytesBase64!)
        : await readBytesFromPath(attachment.path);
    if (bytes == null || bytes.isEmpty) {
      _logTiming(
        'uploadAttachment empty ${attachment.name}',
        elapsedMs: stopwatch.elapsedMilliseconds,
        extra: 'event=$eventId',
      );
      return attachment;
    }

    final fileName = _buildAttachmentFileName(eventId, attachment);
    final created = await _client.createFile(
      name: fileName,
      type: 'file',
      mimeType: _contentTypeForName(attachment.name),
      encrypted: false,
      size: bytes.length,
    );
    final uploadId = created.uploadId ?? created.id;
    final uploadedPart = await _client.uploadFilePart(
      uploadId: uploadId,
      fileName: fileName,
      partName: fileName,
      partNo: 1,
      bytes: bytes,
      encrypted: false,
      contentType: _contentTypeForName(attachment.name),
    );
    await _client.finalizeFile(
      fileId: created.id,
      fileName: fileName,
      uploadId: uploadId,
      size: bytes.length,
      parts: [TeldriveFilePart.fromUploadPart(uploadedPart)],
      encrypted: false,
    );

    _logTiming(
      'uploadAttachment ${attachment.name}',
      elapsedMs: stopwatch.elapsedMilliseconds,
      extra: 'event=$eventId bytes=${bytes.length}',
    );

    return attachment.copyWith(remoteKey: created.id, bytesBase64: null);
  }

  Future<Uint8List?> downloadAttachmentBytes(EventAttachment attachment) async {
    final objectKey = attachment.remoteKey;
    if (objectKey == null || objectKey.isEmpty) {
      return attachment.bytesBase64 == null
          ? null
          : base64Decode(attachment.bytesBase64!);
    }

    final file = await _client.getFileById(objectKey);
    if (file == null) {
      return attachment.bytesBase64 == null
          ? null
          : base64Decode(attachment.bytesBase64!);
    }

    final bytes = await _client.downloadFileBytes(
      fileId: file.id,
      fileName: file.name,
    );
    if (bytes == null || bytes.isEmpty) {
      return attachment.bytesBase64 == null
          ? null
          : base64Decode(attachment.bytesBase64!);
    }

    return bytes;
  }

  Future<void> _replaceSingleFile({
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final existing = await _client.findFileByName(fileName);
    if (existing != null) {
      await _client.deleteFilesByIds([existing.id]);
    }

    final created = await _client.createFile(
      name: fileName,
      type: 'file',
      mimeType: contentType,
      encrypted: false,
      size: bytes.length,
    );
    final uploadId = created.uploadId ?? created.id;
    final uploadedPart = await _client.uploadFilePart(
      uploadId: uploadId,
      fileName: fileName,
      partName: fileName,
      partNo: 1,
      bytes: bytes,
      encrypted: false,
      contentType: contentType,
    );
    await _client.finalizeFile(
      fileId: created.id,
      fileName: fileName,
      uploadId: uploadId,
      size: bytes.length,
      parts: [TeldriveFilePart.fromUploadPart(uploadedPart)],
      encrypted: false,
    );
  }

  String _buildAttachmentFileName(
    String eventId,
    EventAttachment attachment,
  ) {
    final safeName = attachment.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return '$_attachmentPrefix-$eventId-${attachment.id}-$safeName';
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

  void _logTiming(String step, {required int elapsedMs, String? extra}) {
    if (!kDebugMode) {
      return;
    }

    debugPrint(
      '[TeldriveSyncTiming] $step took ${elapsedMs}ms'
      '${extra == null ? '' : ' | $extra'}',
    );
  }
}
