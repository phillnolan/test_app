import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/event_attachment.dart';
import '../models/student_event.dart';

class AttachmentStorageService {
  Future<List<StudentEvent>> persistEvents(List<StudentEvent> events) async {
    if (kIsWeb) return events;

    final updated = <StudentEvent>[];
    for (final event in events) {
      final attachments = <EventAttachment>[];
      for (final attachment in event.attachments) {
        attachments.add(await persistAttachment(attachment));
      }
      updated.add(event.copyWith(attachments: attachments));
    }
    return updated;
  }

  Future<EventAttachment> persistAttachment(EventAttachment attachment) async {
    if (kIsWeb) return attachment;
    if (attachment.path.isNotEmpty &&
        await File(attachment.path).exists() &&
        attachment.bytesBase64 == null) {
      return attachment;
    }

    final bytesBase64 = attachment.bytesBase64;
    if (bytesBase64 == null || bytesBase64.isEmpty) return attachment;

    final bytes = base64Decode(bytesBase64);
    final directory = await _attachmentsDirectory();
    final safeName = _safeFileName(attachment.name, attachment.id);
    final file = File('${directory.path}${Platform.pathSeparator}$safeName');
    await file.writeAsBytes(bytes, flush: true);

    return attachment.copyWith(path: file.path, bytesBase64: null);
  }

  Future<Uint8List?> readAttachmentBytes(EventAttachment attachment) async {
    if (attachment.bytesBase64 != null) {
      return base64Decode(attachment.bytesBase64!);
    }
    if (kIsWeb || attachment.path.isEmpty) return null;

    final file = File(attachment.path);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  Future<Directory> _attachmentsDirectory() async {
    final baseDirectory = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${baseDirectory.path}${Platform.pathSeparator}attachments_cache',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  String _safeFileName(String fileName, String fallbackId) {
    final cleaned = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    if (cleaned.trim().isEmpty) return fallbackId;
    return '${fallbackId}_$cleaned';
  }
}
