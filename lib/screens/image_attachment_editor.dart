import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/event_attachment.dart';
import '../services/file_bytes_reader_stub.dart'
    if (dart.library.io) '../services/file_bytes_reader_io.dart';

class ImageAttachmentEditor extends StatefulWidget {
  const ImageAttachmentEditor({super.key, required this.attachment});

  final EventAttachment attachment;

  @override
  State<ImageAttachmentEditor> createState() => _ImageAttachmentEditorState();
}

enum _EditorTool { crop, draw, text }

enum _CropInteraction { move, resize }

class _ImageAttachmentEditorState extends State<ImageAttachmentEditor> {
  Uint8List? _displayBytes;
  ui.Image? _previewImage;
  bool _isLoading = true;
  _EditorTool _tool = _EditorTool.crop;
  Rect _cropRect = const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8);
  final List<_OverlayAction> _actions = [];
  _StrokeAction? _activeStroke;
  final TextEditingController _textController = TextEditingController();
  Color _selectedColor = const Color(0xFFD32F2F);
  double _strokeWidth = 4;
  double _textSize = 24;
  _CropInteraction? _cropInteraction;
  Offset? _dragStartNormalized;
  Rect? _cropStartRect;
  int? _selectedActionIndex;
  int? _draggingTextIndex;
  Offset? _draggingTextStart;
  Offset? _draggingTextOrigin;

  @override
  void initState() {
    super.initState();
    unawaited(_loadImage());
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = widget.attachment.bytesBase64 != null
          ? base64Decode(widget.attachment.bytesBase64!)
          : await readBytesFromPath(widget.attachment.path);
      if (bytes == null || bytes.isEmpty) {
        throw const _ImageEditorException('Không đọc được dữ liệu ảnh.');
      }

      final previewImage = await _decodeUiImage(bytes);
      if (!mounted) return;
      setState(() {
        _displayBytes = bytes;
        _previewImage = previewImage;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_displayBytes == null || _previewImage == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chỉnh sửa ảnh')),
        body: const Center(child: Text('Không mở được ảnh để chỉnh sửa.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa ảnh'),
        actions: [
          IconButton(
            tooltip: 'Hoàn tác',
            onPressed: _actions.isNotEmpty || _activeStroke != null
                ? _undoLastAction
                : null,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'Xóa mục đang chọn',
            onPressed: _selectedActionIndex == null ? null : _deleteSelectedAction,
            icon: const Icon(Icons.delete_outline),
          ),
          TextButton(
            onPressed: _saveAttachment,
            child: const Text('Lưu'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final imageSize = Size(
                        _previewImage!.width.toDouble(),
                        _previewImage!.height.toDouble(),
                      );
                      final fitted = _containSize(
                        imageSize,
                        Size(constraints.maxWidth, constraints.maxHeight),
                      );
                      return Center(
                        child: SizedBox(
                          width: fitted.width,
                          height: fitted.height,
                          child: GestureDetector(
                            onTapUp: (details) =>
                                _handleTap(details.localPosition, fitted),
                            onPanStart: (details) =>
                                _handlePanStart(details.localPosition, fitted),
                            onPanUpdate: (details) =>
                                _handlePanUpdate(details.localPosition, fitted),
                            onPanEnd: (_) => _handlePanEnd(),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(_displayBytes!, fit: BoxFit.fill),
                                CustomPaint(
                                  painter: _ImageEditOverlayPainter(
                                    cropRect: _cropRect,
                                    actions: _activeStroke == null
                                        ? _actions
                                        : [..._actions, _activeStroke!],
                                    tool: _tool,
                                    selectedActionIndex: _selectedActionIndex,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            _buildToolbar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: SegmentedButton<_EditorTool>(
                  segments: const [
                    ButtonSegment(
                      value: _EditorTool.crop,
                      icon: Icon(Icons.crop_outlined),
                      label: Text('Crop'),
                    ),
                    ButtonSegment(
                      value: _EditorTool.draw,
                      icon: Icon(Icons.draw_outlined),
                      label: Text('Vẽ'),
                    ),
                    ButtonSegment(
                      value: _EditorTool.text,
                      icon: Icon(Icons.text_fields),
                      label: Text('Chữ'),
                    ),
                  ],
                  selected: {_tool},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _tool = selection.first;
                      _selectedActionIndex = null;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_tool == _EditorTool.crop)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _cropRect = const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8);
                      });
                    },
                    icon: const Icon(Icons.center_focus_strong),
                    label: const Text('Đặt lại khung'),
                  ),
                ),
              ],
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final color in const [
                  Color(0xFFD32F2F),
                  Color(0xFF1976D2),
                  Color(0xFF388E3C),
                  Color(0xFFF57C00),
                  Color(0xFF6A1B9A),
                ])
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == color
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (_tool == _EditorTool.draw) ...[
            Row(
              children: [
                const Icon(Icons.brush_outlined, size: 18),
                const SizedBox(width: 8),
                Text('Độ dày: ${_strokeWidth.toStringAsFixed(0)}'),
              ],
            ),
            Slider(
              value: _strokeWidth,
              min: 2,
              max: 18,
              divisions: 8,
              label: _strokeWidth.toStringAsFixed(0),
              onChanged: (value) => setState(() => _strokeWidth = value),
            ),
          ],
          if (_tool == _EditorTool.text) ...[
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Nội dung chữ',
                hintText: 'Nhập chữ rồi chạm lên ảnh để đặt',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.format_size, size: 18),
                const SizedBox(width: 8),
                Text('Cỡ chữ: ${_textSize.toStringAsFixed(0)}'),
              ],
            ),
            Slider(
              value: _textSize,
              min: 16,
              max: 42,
              divisions: 13,
              label: _textSize.toStringAsFixed(0),
              onChanged: (value) => setState(() => _textSize = value),
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Giữ và kéo chữ đã đặt để di chuyển.'),
            ),
          ],
        ],
      ),
    );
  }

  void _undoLastAction() {
    setState(() {
      _selectedActionIndex = null;
      if (_activeStroke != null) {
        _activeStroke = null;
        return;
      }
      if (_actions.isNotEmpty) {
        _actions.removeLast();
      }
    });
  }

  void _deleteSelectedAction() {
    if (_selectedActionIndex == null) return;
    setState(() {
      _actions.removeAt(_selectedActionIndex!);
      _selectedActionIndex = null;
    });
  }

  void _handleTap(Offset localPosition, Size canvasSize) {
    final normalized = _normalizePoint(localPosition, canvasSize);
    if (normalized == null) return;

    final tappedIndex = _hitTestAction(normalized, canvasSize);
    if (tappedIndex != null) {
      setState(() => _selectedActionIndex = tappedIndex);
      return;
    }

    if (_tool != _EditorTool.text) {
      setState(() => _selectedActionIndex = null);
      return;
    }

    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy nhập chữ trước khi đặt lên ảnh.')),
      );
      return;
    }

    setState(() {
      _actions.add(
        _TextAction(
          text: text,
          position: normalized,
          color: _selectedColor,
          fontSize: _textSize,
        ),
      );
      _selectedActionIndex = _actions.length - 1;
    });
  }

  void _handlePanStart(Offset localPosition, Size canvasSize) {
    final normalized = _normalizePoint(localPosition, canvasSize);
    if (normalized == null) return;

    final textIndex = _hitTestTextAction(normalized, canvasSize);
    if (textIndex != null) {
      final action = _actions[textIndex] as _TextAction;
      setState(() => _selectedActionIndex = textIndex);
      _draggingTextIndex = textIndex;
      _draggingTextStart = normalized;
      _draggingTextOrigin = action.position;
      return;
    }

    _draggingTextIndex = null;
    _draggingTextStart = null;
    _draggingTextOrigin = null;

    if (_tool == _EditorTool.text) return;

    if (_tool == _EditorTool.draw) {
      setState(() {
        _selectedActionIndex = null;
        _activeStroke = _StrokeAction(
          color: _selectedColor,
          thickness: _strokeWidth,
          points: [normalized],
        );
      });
      return;
    }

    final cropHandle = Offset(_cropRect.right, _cropRect.bottom);
    final nearHandle = (normalized - cropHandle).distance <= 0.06;
    if (nearHandle) {
      _cropInteraction = _CropInteraction.resize;
      _dragStartNormalized = normalized;
      _cropStartRect = _cropRect;
      return;
    }
    if (_cropRect.contains(normalized)) {
      _cropInteraction = _CropInteraction.move;
      _dragStartNormalized = normalized;
      _cropStartRect = _cropRect;
    }
  }

  void _handlePanUpdate(Offset localPosition, Size canvasSize) {
    final normalized = _normalizePoint(localPosition, canvasSize);
    if (normalized == null) return;

    if (_draggingTextIndex != null &&
        _draggingTextStart != null &&
        _draggingTextOrigin != null) {
      final delta = normalized - _draggingTextStart!;
      final next = Offset(
        (_draggingTextOrigin!.dx + delta.dx).clamp(0.02, 0.95),
        (_draggingTextOrigin!.dy + delta.dy).clamp(0.02, 0.95),
      );
      setState(() {
        _actions[_draggingTextIndex!] =
            (_actions[_draggingTextIndex!] as _TextAction).copyWith(
              position: next,
            );
        _selectedActionIndex = _draggingTextIndex;
      });
      return;
    }

    if (_tool == _EditorTool.text) return;

    if (_tool == _EditorTool.draw) {
      if (_activeStroke == null) return;
      setState(() {
        _activeStroke = _activeStroke!.copyWith(
          points: [..._activeStroke!.points, normalized],
        );
      });
      return;
    }

    if (_cropInteraction == null ||
        _dragStartNormalized == null ||
        _cropStartRect == null) {
      return;
    }

    final delta = normalized - _dragStartNormalized!;
    const minSize = 0.18;
    Rect nextRect;

    if (_cropInteraction == _CropInteraction.move) {
      nextRect = _cropStartRect!.shift(delta);
      if (nextRect.left < 0) nextRect = nextRect.shift(Offset(-nextRect.left, 0));
      if (nextRect.top < 0) nextRect = nextRect.shift(Offset(0, -nextRect.top));
      if (nextRect.right > 1) {
        nextRect = nextRect.shift(Offset(1 - nextRect.right, 0));
      }
      if (nextRect.bottom > 1) {
        nextRect = nextRect.shift(Offset(0, 1 - nextRect.bottom));
      }
    } else {
      nextRect = Rect.fromLTRB(
        _cropStartRect!.left,
        _cropStartRect!.top,
        math.max(_cropStartRect!.left + minSize, normalized.dx),
        math.max(_cropStartRect!.top + minSize, normalized.dy),
      );
      nextRect = Rect.fromLTRB(
        nextRect.left.clamp(0.0, 1.0),
        nextRect.top.clamp(0.0, 1.0),
        nextRect.right.clamp(0.0, 1.0),
        nextRect.bottom.clamp(0.0, 1.0),
      );
    }

    setState(() => _cropRect = nextRect);
  }

  void _handlePanEnd() {
    if (_draggingTextIndex != null) {
      _draggingTextIndex = null;
      _draggingTextStart = null;
      _draggingTextOrigin = null;
      return;
    }

    if (_tool == _EditorTool.draw) {
      if (_activeStroke != null && _activeStroke!.points.length > 1) {
        setState(() {
          _actions.add(_activeStroke!);
          _selectedActionIndex = _actions.length - 1;
          _activeStroke = null;
        });
      } else {
        setState(() => _activeStroke = null);
      }
      return;
    }

    _cropInteraction = null;
    _dragStartNormalized = null;
    _cropStartRect = null;
  }

  int? _hitTestAction(Offset normalized, Size canvasSize) {
    for (var index = _actions.length - 1; index >= 0; index--) {
      final action = _actions[index];
      if (action is _TextAction) {
        if (_textBounds(action, canvasSize).inflate(0.02).contains(normalized)) {
          return index;
        }
      } else if (action is _StrokeAction) {
        for (final point in action.points) {
          if ((point - normalized).distance <= 0.04) {
            return index;
          }
        }
      }
    }
    return null;
  }

  int? _hitTestTextAction(Offset normalized, Size canvasSize) {
    for (var index = _actions.length - 1; index >= 0; index--) {
      final action = _actions[index];
      if (action is! _TextAction) continue;
      if (_textBounds(action, canvasSize).inflate(0.02).contains(normalized)) {
        return index;
      }
    }
    return null;
  }

  Rect _textBounds(_TextAction action, Size canvasSize) {
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

  Offset? _normalizePoint(Offset point, Size canvasSize) {
    if (canvasSize.width <= 0 || canvasSize.height <= 0) return null;
    return Offset(
      (point.dx / canvasSize.width).clamp(0.0, 1.0),
      (point.dy / canvasSize.height).clamp(0.0, 1.0),
    );
  }

  Future<void> _saveAttachment() async {
    if (_displayBytes == null) return;
    final codec = await ui.instantiateImageCodec(_displayBytes!);
    final frame = await codec.getNextFrame();
    final decodedImage = frame.image;

    final cropLeft = (_cropRect.left * decodedImage.width)
        .round()
        .clamp(0, decodedImage.width - 1);
    final cropTop = (_cropRect.top * decodedImage.height)
        .round()
        .clamp(0, decodedImage.height - 1);
    final cropRight = (_cropRect.right * decodedImage.width)
        .round()
        .clamp(cropLeft + 1, decodedImage.width);
    final cropBottom = (_cropRect.bottom * decodedImage.height)
        .round()
        .clamp(cropTop + 1, decodedImage.height);

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

    for (final action in _actions) {
      if (action is _StrokeAction) {
        final visiblePoints = action.points
            .map((point) => _mapPointIntoCrop(point, _cropRect, destination.size))
            .whereType<Offset>()
            .toList();
        if (visiblePoints.length < 2) continue;
        final paint = Paint()
          ..color = action.color
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..strokeWidth = action.thickness * (destination.width / 360).clamp(0.8, 3.2);
        final path = Path()..moveTo(visiblePoints.first.dx, visiblePoints.first.dy);
        for (final point in visiblePoints.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
        canvas.drawPath(path, paint);
      } else if (action is _TextAction) {
        final point = _mapPointIntoCrop(action.position, _cropRect, destination.size);
        if (point == null) continue;
        final textPainter = TextPainter(
          text: TextSpan(
            text: action.text,
            style: TextStyle(
              color: action.color,
              fontSize: action.fontSize * (destination.width / 360).clamp(0.8, 2.8),
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
    final image = await picture.toImage(outputWidth, outputHeight);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final renderedBytes = byteData!.buffer.asUint8List();

    final updated = widget.attachment.copyWith(
      name: _replaceExtensionWithPng(widget.attachment.name),
      path: '',
      remoteKey: null,
      bytesBase64: base64Encode(renderedBytes),
    );

    if (!mounted) return;
    Navigator.of(context).pop(updated);
  }

  Offset? _mapPointIntoCrop(Offset point, Rect cropRect, Size outputSize) {
    final dx = (point.dx - cropRect.left) / cropRect.width;
    final dy = (point.dy - cropRect.top) / cropRect.height;
    if (dx < -0.05 || dy < -0.05 || dx > 1.05 || dy > 1.05) return null;
    return Offset(dx * outputSize.width, dy * outputSize.height);
  }

  Size _containSize(Size source, Size bounds) {
    final sourceRatio = source.width / source.height;
    final boundsRatio = bounds.width / bounds.height;
    if (sourceRatio > boundsRatio) {
      return Size(bounds.width, bounds.width / sourceRatio);
    }
    return Size(bounds.height * sourceRatio, bounds.height);
  }

  Future<ui.Image> _decodeUiImage(Uint8List bytes) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }

  String _replaceExtensionWithPng(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    final baseName = dotIndex == -1 ? fileName : fileName.substring(0, dotIndex);
    return '$baseName.png';
  }
}

abstract class _OverlayAction {
  const _OverlayAction();
}

class _StrokeAction extends _OverlayAction {
  const _StrokeAction({
    required this.color,
    required this.thickness,
    required this.points,
  });

  final Color color;
  final double thickness;
  final List<Offset> points;

  _StrokeAction copyWith({
    Color? color,
    double? thickness,
    List<Offset>? points,
  }) {
    return _StrokeAction(
      color: color ?? this.color,
      thickness: thickness ?? this.thickness,
      points: points ?? this.points,
    );
  }
}

class _TextAction extends _OverlayAction {
  const _TextAction({
    required this.text,
    required this.position,
    required this.color,
    required this.fontSize,
  });

  final String text;
  final Offset position;
  final Color color;
  final double fontSize;

  _TextAction copyWith({
    String? text,
    Offset? position,
    Color? color,
    double? fontSize,
  }) {
    return _TextAction(
      text: text ?? this.text,
      position: position ?? this.position,
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

class _ImageEditOverlayPainter extends CustomPainter {
  const _ImageEditOverlayPainter({
    required this.cropRect,
    required this.actions,
    required this.tool,
    required this.selectedActionIndex,
  });

  final Rect cropRect;
  final List<_OverlayAction> actions;
  final _EditorTool tool;
  final int? selectedActionIndex;

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < actions.length; index++) {
      final action = actions[index];
      final isSelected = selectedActionIndex == index;

      if (action is _StrokeAction) {
        if (action.points.length < 2) continue;
        final paint = Paint()
          ..color = action.color
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..strokeWidth = action.thickness;
        final path = Path()
          ..moveTo(
            action.points.first.dx * size.width,
            action.points.first.dy * size.height,
          );
        for (final point in action.points.skip(1)) {
          path.lineTo(point.dx * size.width, point.dy * size.height);
        }
        canvas.drawPath(path, paint);

        if (isSelected) {
          final highlight = Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = action.thickness + 2;
          canvas.drawPath(path, highlight);
        }
      } else if (action is _TextAction) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: action.text,
            style: TextStyle(
              color: action.color,
              fontSize: action.fontSize,
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
        )..layout(maxWidth: size.width * 0.8);
        final offset = Offset(
          action.position.dx * size.width,
          action.position.dy * size.height,
        );
        textPainter.paint(canvas, offset);

        if (isSelected) {
          final rect = offset & textPainter.size;
          final selectPaint = Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;
          canvas.drawRect(rect.inflate(4), selectPaint);
        }
      }
    }

    final rect = Rect.fromLTRB(
      cropRect.left * size.width,
      cropRect.top * size.height,
      cropRect.right * size.width,
      cropRect.bottom * size.height,
    );

    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.34);
    final fullPath = Path()..addRect(Offset.zero & size);
    final cropPath = Path()..addRect(rect);
    canvas.drawPath(
      Path.combine(PathOperation.difference, fullPath, cropPath),
      dimPaint,
    );

    final borderPaint = Paint()
      ..color = tool == _EditorTool.crop ? Colors.white : Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(rect, borderPaint);

    final handlePaint = Paint()..color = Colors.white;
    canvas.drawCircle(rect.bottomRight, 9, handlePaint);
  }

  @override
  bool shouldRepaint(covariant _ImageEditOverlayPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect ||
        oldDelegate.actions != actions ||
        oldDelegate.tool != tool ||
        oldDelegate.selectedActionIndex != selectedActionIndex;
  }
}

class _ImageEditorException implements Exception {
  const _ImageEditorException(this.message);

  final String message;
}
