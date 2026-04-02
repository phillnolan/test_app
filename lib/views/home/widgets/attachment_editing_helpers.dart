import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/event_attachment.dart';
import '../../../services/attachment_import_service.dart';
import '../../../services/image_edit_service.dart';
import '../image_attachment_editor.dart';

final AttachmentImportService _attachmentImportService =
    AttachmentImportService();

Future<List<EventAttachment>> pickAttachments(BuildContext context) async {
  try {
    return await _attachmentImportService.pickAttachments();
  } catch (_) {
    if (!context.mounted) {
      return const [];
    }
    showAttachmentFailure(context, 'Khong the mo bo chon tep.');
    return const [];
  }
}

Future<EventAttachment?> captureOrScanAttachment(
  BuildContext context, {
  required bool scanMode,
  ImagePicker? imagePicker,
  AttachmentImportService? attachmentImportService,
  ImageEditService imageEditService = const ImageEditService(),
}) async {
  final picker = imagePicker ?? ImagePicker();
  final importService = attachmentImportService ?? _attachmentImportService;

  try {
    final file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 92,
    );
    if (file == null) {
      return null;
    }

    final attachment = await importService.attachmentFromXFile(file);
    if (!context.mounted) {
      return null;
    }
    if (attachment == null) {
      showAttachmentFailure(context, 'Khong the doc anh vua chup.');
      return null;
    }

    EventAttachment result = attachment;
    if (scanMode || attachment.isImage) {
      final edited = await editAttachment(
        context,
        attachment,
        imageEditService: imageEditService,
      );
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
      result = await importService.convertImageAttachmentToPdf(result);
    }

    return result;
  } catch (_) {
    if (!context.mounted) {
      return null;
    }
    showAttachmentFailure(
      context,
      scanMode ? 'Khong the quet tai lieu.' : 'Khong the chup anh.',
    );
    return null;
  }
}

Future<EventAttachment?> editAttachment(
  BuildContext context,
  EventAttachment attachment, {
  ImageEditService imageEditService = const ImageEditService(),
}) async {
  if (!attachment.isImage) {
    return attachment;
  }

  return Navigator.of(context).push<EventAttachment>(
    MaterialPageRoute(
      builder: (context) => ImageAttachmentEditor(
        attachment: attachment,
        imageEditService: imageEditService,
      ),
    ),
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
              'Luu tai lieu duoi dang',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Anh'),
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

void showAttachmentFailure(BuildContext context, String message) {
  if (!context.mounted) {
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
