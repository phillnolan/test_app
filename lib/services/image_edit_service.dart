import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/event_attachment.dart';
import 'file_bytes_reader_stub.dart'
    if (dart.library.io) 'file_bytes_reader_io.dart';

class ImageEditDocument {
  const ImageEditDocument({required this.bytes, required this.previewImage});

  final Uint8List bytes;
  final ui.Image previewImage;
}

abstract class ImageOverlayAction {
  const ImageOverlayAction();
}

class ImageStrokeAction extends ImageOverlayAction {
  const ImageStrokeAction({
    required this.color,
    required this.thickness,
    required this.points,
  });

  final Color color;
  final double thickness;
  final List<Offset> points;

  ImageStrokeAction copyWith({
    Color? color,
    double? thickness,
    List<Offset>? points,
  }) {
    return ImageStrokeAction(
      color: color ?? this.color,
      thickness: thickness ?? this.thickness,
      points: points ?? this.points,
    );
  }
}

class ImageTextAction extends ImageOverlayAction {
  const ImageTextAction({
    required this.text,
    required this.position,
    required this.color,
    required this.fontSize,
  });

  final String text;
  final Offset position;
  final Color color;
  final double fontSize;

  ImageTextAction copyWith({
    String? text,
    Offset? position,
    Color? color,
    double? fontSize,
  }) {
    return ImageTextAction(
      text: text ?? this.text,
      position: position ?? this.position,
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

class ImageEditService {
  const ImageEditService();

  Future<ImageEditDocument> loadAttachment(EventAttachment attachment) async {
    final bytes = attachment.bytesBase64 != null
        ? base64Decode(attachment.bytesBase64!)
        : await readBytesFromPath(attachment.path);
    if (bytes == null || bytes.isEmpty) {
      throw const ImageEditException('Khong doc duoc du lieu anh.');
    }

    final previewImage = await _decodeUiImage(bytes);
    return ImageEditDocument(bytes: bytes, previewImage: previewImage);
  }

  Size containSize(Size source, Size bounds) {
    final sourceRatio = source.width / source.height;
    final boundsRatio = bounds.width / bounds.height;
    if (sourceRatio > boundsRatio) {
      return Size(bounds.width, bounds.width / sourceRatio);
    }
    return Size(bounds.height * sourceRatio, bounds.height);
  }

  int? hitTestAction(
    Offset normalized,
    Size canvasSize,
    List<ImageOverlayAction> actions,
  ) {
    for (var index = actions.length - 1; index >= 0; index--) {
      final action = actions[index];
      if (action is ImageTextAction) {
        if (textBounds(action, canvasSize).inflate(0.02).contains(normalized)) {
          return index;
        }
      } else if (action is ImageStrokeAction) {
        for (final point in action.points) {
          if ((point - normalized).distance <= 0.04) {
            return index;
          }
        }
      }
    }
    return null;
  }

  int? hitTestTextAction(
    Offset normalized,
    Size canvasSize,
    List<ImageOverlayAction> actions,
  ) {
    for (var index = actions.length - 1; index >= 0; index--) {
      final action = actions[index];
      if (action is! ImageTextAction) {
        continue;
      }
      if (textBounds(action, canvasSize).inflate(0.02).contains(normalized)) {
        return index;
      }
    }
    return null;
  }

  Rect textBounds(ImageTextAction action, Size canvasSize) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: action.text,
        style: TextStyle(
          fontSize: action.fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: canvasSize.width * 0.8);

    final widthRatio = textPainter.width / canvasSize.width;
    final heightRatio = textPainter.height / canvasSize.height;
    return Rect.fromLTWH(
      action.position.dx,
      action.position.dy,
      widthRatio.clamp(0.02, 0.9),
      heightRatio.clamp(0.02, 0.3),
    );
  }

  Offset? mapPointIntoCrop(Offset point, Rect cropRect, Size outputSize) {
    final dx = (point.dx - cropRect.left) / cropRect.width;
    final dy = (point.dy - cropRect.top) / cropRect.height;
    if (dx < -0.05 || dy < -0.05 || dx > 1.05 || dy > 1.05) {
      return null;
    }
    return Offset(dx * outputSize.width, dy * outputSize.height);
  }

  Future<EventAttachment> renderAttachment({
    required EventAttachment attachment,
    required Uint8List displayBytes,
    required Rect cropRect,
    required List<ImageOverlayAction> actions,
  }) async {
    final codec = await ui.instantiateImageCodec(displayBytes);
    final frame = await codec.getNextFrame();
    final decodedImage = frame.image;

    final cropLeft = (cropRect.left * decodedImage.width).round().clamp(
      0,
      decodedImage.width - 1,
    );
    final cropTop = (cropRect.top * decodedImage.height).round().clamp(
      0,
      decodedImage.height - 1,
    );
    final cropRight = (cropRect.right * decodedImage.width).round().clamp(
      cropLeft + 1,
      decodedImage.width,
    );
    final cropBottom = (cropRect.bottom * decodedImage.height).round().clamp(
      cropTop + 1,
      decodedImage.height,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final outputWidth = cropRight - cropLeft;
    final outputHeight = cropBottom - cropTop;
    final destination = Rect.fromLTWH(
      0,
      0,
      outputWidth.toDouble(),
      outputHeight.toDouble(),
    );
    final source = Rect.fromLTWH(
      cropLeft.toDouble(),
      cropTop.toDouble(),
      outputWidth.toDouble(),
      outputHeight.toDouble(),
    );

    canvas.drawImageRect(decodedImage, source, destination, Paint());

    for (final action in actions) {
      if (action is ImageStrokeAction) {
        final visiblePoints = action.points
            .map((point) => mapPointIntoCrop(point, cropRect, destination.size))
            .whereType<Offset>()
            .toList();
        if (visiblePoints.length < 2) {
          continue;
        }
        final paint = Paint()
          ..color = action.color
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..strokeWidth =
              action.thickness * (destination.width / 360).clamp(0.8, 3.2);
        final path = Path()
          ..moveTo(visiblePoints.first.dx, visiblePoints.first.dy);
        for (final point in visiblePoints.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
        canvas.drawPath(path, paint);
      } else if (action is ImageTextAction) {
        final point = mapPointIntoCrop(
          action.position,
          cropRect,
          destination.size,
        );
        if (point == null) {
          continue;
        }
        final textPainter = TextPainter(
          text: TextSpan(
            text: action.text,
            style: TextStyle(
              color: action.color,
              fontSize:
                  action.fontSize * (destination.width / 360).clamp(0.8, 2.8),
              fontWeight: FontWeight.w700,
              shadows: const [
                Shadow(
                  color: Colors.black38,
                  blurRadius: 2,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: destination.width * 0.8);
        textPainter.paint(canvas, point);
      }
    }

    final picture = recorder.endRecording();
    final renderedImage = await picture.toImage(outputWidth, outputHeight);
    final byteData = await renderedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) {
      throw const ImageEditException('Khong xuat duoc anh da chinh sua.');
    }
    final renderedBytes = byteData.buffer.asUint8List();

    renderedImage.dispose();
    decodedImage.dispose();
    codec.dispose();

    return attachment.copyWith(
      name: _replaceExtensionWithPng(attachment.name),
      path: '',
      remoteKey: null,
      bytesBase64: base64Encode(renderedBytes),
    );
  }

  Rect resizeCropRect({
    required Rect cropRect,
    required Offset normalized,
    required double minSize,
  }) {
    return Rect.fromLTRB(
      cropRect.left.clamp(0.0, 1.0),
      cropRect.top.clamp(0.0, 1.0),
      math.max(cropRect.left + minSize, normalized.dx).clamp(0.0, 1.0),
      math.max(cropRect.top + minSize, normalized.dy).clamp(0.0, 1.0),
    );
  }

  Future<ui.Image> _decodeUiImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec.dispose();
    }
  }

  String _replaceExtensionWithPng(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    final baseName = dotIndex == -1
        ? fileName
        : fileName.substring(0, dotIndex);
    return '$baseName.png';
  }
}

class ImageEditException implements Exception {
  const ImageEditException(this.message);

  final String message;
}
