// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

Future<bool> openAttachmentFile({
  required String fileName,
  String? localPath,
  Uint8List? bytes,
}) async {
  Uint8List? effectiveBytes = bytes;

  if (effectiveBytes == null && localPath != null && localPath.startsWith('data:')) {
    final commaIndex = localPath.indexOf(',');
    if (commaIndex != -1) {
      effectiveBytes = base64Decode(localPath.substring(commaIndex + 1));
    }
  }

  if (effectiveBytes == null) return false;

  final blob = html.Blob([effectiveBytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..target = '_blank'
    ..download = fileName
    ..click();
  html.Url.revokeObjectUrl(url);
  return true;
}
