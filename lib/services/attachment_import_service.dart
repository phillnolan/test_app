import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/event_attachment.dart';
import 'file_bytes_reader_stub.dart'
    if (dart.library.io) 'file_bytes_reader_io.dart';

typedef AttachmentFilePicker = Future<FilePickerResult?> Function();

class AttachmentImportService {
  AttachmentImportService({AttachmentFilePicker? filePicker})
    : _filePicker = filePicker ?? _defaultFilePicker;

  final AttachmentFilePicker _filePicker;

  Future<List<EventAttachment>> pickAttachments() async {
    final result = await _filePicker();
    if (result == null) {
      return const [];
    }

    return result.files
        .map(attachmentFromPlatformFile)
        .whereType<EventAttachment>()
        .toList();
  }

  Future<EventAttachment?> attachmentFromXFile(XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      return null;
    }

    final fileName = file.name.isEmpty
        ? 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg'
        : file.name;
    return EventAttachment(
      id: _attachmentId(fileName),
      name: fileName,
      path: kIsWeb ? '' : file.path,
      bytesBase64: kIsWeb || file.path.isEmpty ? base64Encode(bytes) : null,
    );
  }

  Future<EventAttachment> convertImageAttachmentToPdf(
    EventAttachment attachment,
  ) async {
    final bytes = attachment.bytesBase64 != null
        ? base64Decode(attachment.bytesBase64!)
        : await readBytesFromPath(attachment.path);
    if (bytes == null || bytes.isEmpty) {
      return attachment;
    }

    final document = pw.Document();
    final image = pw.MemoryImage(bytes);
    document.addPage(
      pw.Page(
        build: (_) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
      ),
    );
    final pdfBytes = await document.save();
    final baseName = attachment.name.replaceAll(RegExp(r'\.[^.]+$'), '');
    return EventAttachment(
      id: _attachmentId('$baseName-pdf'),
      name: '$baseName.pdf',
      path: '',
      bytesBase64: base64Encode(pdfBytes),
    );
  }

  EventAttachment? attachmentFromPlatformFile(PlatformFile file) {
    final attachment = EventAttachment(
      id: _attachmentId(file.name),
      name: file.name,
      path: file.path ?? '',
      bytesBase64: file.bytes == null ? null : base64Encode(file.bytes!),
    );

    if (attachment.path.isEmpty && attachment.bytesBase64 == null) {
      return null;
    }

    return attachment;
  }

  static Future<FilePickerResult?> _defaultFilePicker() {
    return FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
      withData: kIsWeb,
    );
  }

  String _attachmentId(String fileName) {
    return 'attachment-${DateTime.now().microsecondsSinceEpoch}-$fileName';
  }
}
