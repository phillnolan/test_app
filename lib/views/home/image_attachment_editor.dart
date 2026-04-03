import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../models/event_attachment.dart';
import '../../services/image_edit_service.dart';

class ImageAttachmentEditor extends StatefulWidget {
  const ImageAttachmentEditor({
    super.key,
    required this.attachment,
    this.imageEditService = const ImageEditService(),
  });

  final EventAttachment attachment;
  final ImageEditService imageEditService;

  @override
  State<ImageAttachmentEditor> createState() => _ImageAttachmentEditorState();
}

enum _EditorTool { crop, draw, text }

enum _CropInteraction { move, resize }

class _ImageAttachmentEditorState extends State<ImageAttachmentEditor> {
  static const Rect _defaultCropRect = Rect.fromLTWH(0.1, 0.1, 0.8, 0.8);

  Uint8List? _displayBytes;
  ui.Image? _previewImage;
  bool _isLoading = true;
  _EditorTool _tool = _EditorTool.crop;
  Rect _cropRect = _defaultCropRect;
  final List<ImageOverlayAction> _actions = [];
  ImageStrokeAction? _activeStroke;
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
    _previewImage?.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    try {
      final document = await widget.imageEditService.loadAttachment(
        widget.attachment,
      );
      if (!mounted) {
        document.previewImage.dispose();
        return;
      }
      setState(() {
        _displayBytes = document.bytes;
        _previewImage = document.previewImage;
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_displayBytes == null || _previewImage == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chỉnh sửa ảnh')),
        body: const Center(child: Text('Không thể mở ảnh để chỉnh sửa.')),
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
            onPressed: _selectedActionIndex == null
                ? null
                : _deleteSelectedAction,
            icon: const Icon(Icons.delete_outline),
          ),
          TextButton(onPressed: _saveAttachment, child: const Text('Lưu')),
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
                      final fitted = widget.imageEditService.containSize(
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
                                    imageEditService: widget.imageEditService,
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
                hintText: 'Nhập chữ rồi chạm vào ảnh để đặt',
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

    final tappedIndex = widget.imageEditService.hitTestAction(
      normalized,
      canvasSize,
      _actions,
    );
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
        ImageTextAction(
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

    final textIndex = widget.imageEditService.hitTestTextAction(
      normalized,
      canvasSize,
      _actions,
    );
    if (textIndex != null) {
      final action = _actions[textIndex] as ImageTextAction;
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
        _activeStroke = ImageStrokeAction(
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
            (_actions[_draggingTextIndex!] as ImageTextAction).copyWith(
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
      if (nextRect.left < 0) {
        nextRect = nextRect.shift(Offset(-nextRect.left, 0));
      }
      if (nextRect.top < 0) {
        nextRect = nextRect.shift(Offset(0, -nextRect.top));
      }
      if (nextRect.right > 1) {
        nextRect = nextRect.shift(Offset(1 - nextRect.right, 0));
      }
      if (nextRect.bottom > 1) {
        nextRect = nextRect.shift(Offset(0, 1 - nextRect.bottom));
      }
    } else {
      nextRect = widget.imageEditService.resizeCropRect(
        cropRect: _cropStartRect!,
        normalized: normalized,
        minSize: minSize,
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

  Offset? _normalizePoint(Offset point, Size canvasSize) {
    if (canvasSize.width <= 0 || canvasSize.height <= 0) return null;
    return Offset(
      (point.dx / canvasSize.width).clamp(0.0, 1.0),
      (point.dy / canvasSize.height).clamp(0.0, 1.0),
    );
  }

  Future<void> _saveAttachment() async {
    if (_displayBytes == null) {
      return;
    }

    if (!_hasPendingEdits) {
      Navigator.of(context).pop(widget.attachment);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lưu chỉnh sửa ảnh?'),
        content: const Text(
          'Ảnh này đã được chỉnh sửa. Bạn có muốn lưu thay đổi không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    try {
      final updated = await widget.imageEditService.renderAttachment(
        attachment: widget.attachment,
        displayBytes: _displayBytes!,
        cropRect: _cropRect,
        actions: _actions,
      );
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể lưu ảnh đã chỉnh sửa.')),
      );
    }
  }

  bool get _hasPendingEdits {
    return !_sameRect(_cropRect, _defaultCropRect) ||
        _actions.isNotEmpty ||
        (_activeStroke?.points.isNotEmpty ?? false);
  }

  bool _sameRect(Rect left, Rect right) {
    const tolerance = 0.0001;
    return (left.left - right.left).abs() < tolerance &&
        (left.top - right.top).abs() < tolerance &&
        (left.right - right.right).abs() < tolerance &&
        (left.bottom - right.bottom).abs() < tolerance;
  }
}

class _ImageEditOverlayPainter extends CustomPainter {
  const _ImageEditOverlayPainter({
    required this.cropRect,
    required this.actions,
    required this.tool,
    required this.selectedActionIndex,
    required this.imageEditService,
  });

  final Rect cropRect;
  final List<ImageOverlayAction> actions;
  final _EditorTool tool;
  final int? selectedActionIndex;
  final ImageEditService imageEditService;

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < actions.length; index++) {
      final action = actions[index];
      final isSelected = selectedActionIndex == index;

      if (action is ImageStrokeAction) {
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
      } else if (action is ImageTextAction) {
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
