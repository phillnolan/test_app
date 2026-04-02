import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/event_attachment.dart';
import '../../screens/image_attachment_editor.dart';
import '../../services/file_bytes_reader_stub.dart'
    if (dart.library.io) '../../services/file_bytes_reader_io.dart';

Future<List<EventAttachment>> pickAttachments(BuildContext context) async {
  try {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
      withData: kIsWeb,
    );
    if (result == null) {
      return const [];
    }

    return result.files
        .map(_attachmentFromPlatformFile)
        .whereType<EventAttachment>()
        .toList();
  } catch (_) {
    if (!context.mounted) {
      return const [];
    }
    showAttachmentFailure(context, 'Không thể mở bộ chọn tệp.');
    return const [];
  }
}

Future<EventAttachment?> captureOrScanAttachment(
  BuildContext context, {
  required bool scanMode,
  ImagePicker? imagePicker,
}) async {
  final picker = imagePicker ?? ImagePicker();

  try {
    final file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 92,
    );
    if (file == null) {
      return null;
    }

    final attachment = await attachmentFromXFile(file);
    if (!context.mounted) {
      return null;
    }
    if (attachment == null) {
      showAttachmentFailure(context, 'Không thể đọc ảnh vừa chụp.');
      return null;
    }

    EventAttachment result = attachment;
    if (scanMode || attachment.isImage) {
      final edited = await editAttachment(context, attachment);
      if (!context.mounted) {
        return null;
      }
      if (edited == null) {
        return null;
      }
      result = edited;
    }

    if (scanMode) {
      final saveAsPdf = await askScanOutputMode(context);
      if (!context.mounted) {
        return null;
      }
      if (saveAsPdf != true) {
        return result;
      }
      result = await convertImageAttachmentToPdf(result);
    }

    return result;
  } catch (_) {
    if (!context.mounted) {
      return null;
    }
    showAttachmentFailure(
      context,
      scanMode ? 'Không thể quét tài liệu.' : 'Không thể chụp ảnh.',
    );
    return null;
  }
}

Future<EventAttachment?> editAttachment(
  BuildContext context,
  EventAttachment attachment,
) async {
  if (!attachment.isImage) {
    return attachment;
  }

  return Navigator.of(context).push<EventAttachment>(
    MaterialPageRoute(
      builder: (context) => ImageAttachmentEditor(attachment: attachment),
    ),
  );
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
    id: 'attachment-${DateTime.now().microsecondsSinceEpoch}-$fileName',
    name: fileName,
    path: kIsWeb ? '' : file.path,
    bytesBase64: kIsWeb || file.path.isEmpty ? base64Encode(bytes) : null,
  );
}

Future<bool?> askScanOutputMode(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lưu tài liệu dưới dạng',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Ảnh'),
              onTap: () => Navigator.of(context).pop(false),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('PDF'),
              onTap: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    ),
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
    id: 'attachment-${DateTime.now().microsecondsSinceEpoch}-$baseName-pdf',
    name: '$baseName.pdf',
    path: '',
    bytesBase64: base64Encode(pdfBytes),
  );
}

void showAttachmentFailure(BuildContext context, String message) {
  if (!context.mounted) {
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

EventAttachment? _attachmentFromPlatformFile(PlatformFile file) {
  final attachment = EventAttachment(
    id: 'attachment-${DateTime.now().microsecondsSinceEpoch}-${file.name}',
    name: file.name,
    path: file.path ?? '',
    bytesBase64: file.bytes == null ? null : base64Encode(file.bytes!),
  );

  if (attachment.path.isEmpty && attachment.bytesBase64 == null) {
    return null;
  }

  return attachment;
}
