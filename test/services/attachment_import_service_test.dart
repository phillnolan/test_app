import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:sinhvien_app/models/event_attachment.dart';
import 'package:sinhvien_app/services/attachment_import_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pickAttachments maps valid picked files into attachments', (
    WidgetTester tester,
  ) async {
    final service = AttachmentImportService(
      filePicker: () async => FilePickerResult([
        PlatformFile(
          name: 'notes.txt',
          size: 3,
          bytes: Uint8List.fromList(const [1, 2, 3]),
        ),
        PlatformFile(name: 'empty.bin', size: 0),
      ]),
    );

    final attachments = await service.pickAttachments();

    expect(attachments, hasLength(1));
    expect(attachments.single.name, 'notes.txt');
    expect(attachments.single.bytesBase64, isNotNull);
  });

  testWidgets('attachmentFromXFile keeps in-memory image bytes on the model', (
    WidgetTester tester,
  ) async {
    final service = AttachmentImportService();
    final pngBytes = _testPngBytes;
    final file = XFile.fromData(
      pngBytes,
      name: 'camera.png',
      mimeType: 'image/png',
    );

    final attachment = await service.attachmentFromXFile(file);

    expect(attachment, isNotNull);
    expect(attachment!.name, endsWith('.jpg'));
    expect(attachment.path, isEmpty);
    expect(base64Decode(attachment.bytesBase64!), pngBytes);
  });

  testWidgets('convertImageAttachmentToPdf returns a PDF attachment', (
    WidgetTester tester,
  ) async {
    final service = AttachmentImportService();
    final pngBytes = _testPngBytes;
    final attachment = EventAttachment(
      id: 'img-1',
      name: 'scan.png',
      path: '',
      bytesBase64: base64Encode(pngBytes),
    );

    final converted = await service.convertImageAttachmentToPdf(attachment);

    expect(converted.name, 'scan.pdf');
    expect(converted.path, isEmpty);
    expect(converted.bytesBase64, isNotNull);
    expect(
      base64Decode(converted.bytesBase64!).take(4),
      orderedEquals([37, 80, 68, 70]),
    );
  });
}

final Uint8List _testPngBytes = Uint8List.fromList(
  img.encodePng(_buildPngFixture()),
);

img.Image _buildPngFixture() {
  final image = img.Image(width: 4, height: 4);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      image.setPixelRgb(x, y, 25, 118, 210);
    }
  }
  return image;
}
