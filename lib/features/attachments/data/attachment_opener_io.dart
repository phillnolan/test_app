import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';

Future<bool> openAttachmentFile({
  required String fileName,
  String? localPath,
  Uint8List? bytes,
}) async {
  var targetPath = localPath ?? '';
  if ((targetPath.isEmpty || !await File(targetPath).exists()) && bytes != null) {
    final safeName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final file = File('${Directory.systemTemp.path}${Platform.pathSeparator}$safeName');
    await file.writeAsBytes(bytes, flush: true);
    targetPath = file.path;
  }

  if (targetPath.isEmpty || !await File(targetPath).exists()) {
    return false;
  }

  final result = await OpenFilex.open(targetPath);
  return result.type == ResultType.done;
}
