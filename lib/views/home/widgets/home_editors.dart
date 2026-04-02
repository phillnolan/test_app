import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../models/event_attachment.dart';
import '../../../../models/student_event.dart';
import 'attachment_editing_helpers.dart';
import 'home_sheet_models.dart';

class EnhancedNoteEditorSheet extends StatefulWidget {
  const EnhancedNoteEditorSheet({super.key, required this.event});

  final StudentEvent event;

  @override
  State<EnhancedNoteEditorSheet> createState() =>
      _EnhancedNoteEditorSheetState();
}

class _EnhancedNoteEditorSheetState extends State<EnhancedNoteEditorSheet> {
  final ImagePicker _imagePicker = ImagePicker();
  late final TextEditingController _titleController;
  late final TextEditingController _controller;
  late List<EventAttachment> _attachments;
  String? _titleErrorText;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _controller = TextEditingController(text: widget.event.note ?? '');
    _attachments = List<EventAttachment>.from(widget.event.attachments);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ghi chú', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          if (widget.event.type == StudentEventType.personalTask) ...[
            TextField(
              controller: _titleController,
              onChanged: (_) {
                if (_titleErrorText != null &&
                    _titleController.text.trim().isNotEmpty) {
                  setState(() => _titleErrorText = null);
                }
              },
              decoration: InputDecoration(
                labelText: 'Tiêu đề',
                hintText: 'Nhập tiêu đề ghi chú',
                errorText: _titleErrorText,
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Nhập ghi chú cho sự kiện này',
            ),
          ),
          const SizedBox(height: 12),
          _AttachmentEditorSection(
            attachments: _attachments,
            onAddFiles: _pickAttachments,
            onCapturePhoto: _capturePhotoAttachment,
            onScanDocument: _scanDocumentAttachment,
            onEdit: _editAttachment,
            onRemove: _removeAttachment,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (widget.event.type == StudentEventType.personalTask)
                TextButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Xóa ghi chú cá nhân?'),
                        content: const Text(
                          'Ghi chú này sẽ bị xóa khỏi thiết bị và cloud.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Hủy'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Xóa'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true || !context.mounted) {
                      return;
                    }

                    Navigator.of(
                      context,
                    ).pop(const NoteEditorResult(deleteEvent: true));
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Xóa ghi chú cá nhân'),
                ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  final title = _titleController.text.trim();
                  if (widget.event.type == StudentEventType.personalTask &&
                      title.isEmpty) {
                    setState(() {
                      _titleErrorText = 'Không được để trống tiêu đề';
                    });
                    return;
                  }

                  Navigator.of(context).pop(
                    NoteEditorResult(
                      title: widget.event.type == StudentEventType.personalTask
                          ? title
                          : null,
                      note: _controller.text,
                      attachments: _attachments,
                    ),
                  );
                },
                child: const Text('Lưu'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickAttachments() async {
    final additions = await pickAttachments(context);
    if (additions.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _attachments = [..._attachments, ...additions];
    });
  }

  Future<void> _capturePhotoAttachment() async {
    final attachment = await captureOrScanAttachment(
      context,
      scanMode: false,
      imagePicker: _imagePicker,
    );
    if (attachment == null || !mounted) {
      return;
    }

    setState(() {
      _attachments = [..._attachments, attachment];
    });
  }

  Future<void> _scanDocumentAttachment() async {
    final attachment = await captureOrScanAttachment(
      context,
      scanMode: true,
      imagePicker: _imagePicker,
    );
    if (attachment == null || !mounted) {
      return;
    }

    setState(() {
      _attachments = [..._attachments, attachment];
    });
  }

  void _removeAttachment(String attachmentId) {
    setState(() {
      _attachments = _attachments
          .where((attachment) => attachment.id != attachmentId)
          .toList();
    });
  }

  Future<void> _editAttachment(EventAttachment attachment) async {
    final edited = await editAttachment(context, attachment);
    if (edited == null || !mounted) {
      return;
    }

    setState(() {
      _attachments = _attachments
          .map((item) => item.id == attachment.id ? edited : item)
          .toList();
    });
  }
}

class EnhancedTaskEditorSheet extends StatefulWidget {
  const EnhancedTaskEditorSheet({super.key, required this.initialDate});

  final DateTime initialDate;

  @override
  State<EnhancedTaskEditorSheet> createState() =>
      _EnhancedTaskEditorSheetState();
}

class _EnhancedTaskEditorSheetState extends State<EnhancedTaskEditorSheet> {
  final ImagePicker _imagePicker = ImagePicker();
  late DateTime _date;
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  List<EventAttachment> _attachments = const [];
  String? _titleErrorText;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thêm việc cá nhân',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            onChanged: (_) {
              if (_titleErrorText != null &&
                  _titleController.text.trim().isNotEmpty) {
                setState(() => _titleErrorText = null);
              }
            },
            decoration: InputDecoration(
              labelText: 'Tiêu đề',
              hintText: 'Ví dụ: Ôn thi giữa kỳ',
              errorText: _titleErrorText,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      locale: const Locale('vi', 'VN'),
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked == null) {
                      return;
                    }

                    setState(() {
                      _date = DateTime(picked.year, picked.month, picked.day);
                    });
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('${_date.day}/${_date.month}/${_date.year}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _time,
                    );
                    if (picked == null) {
                      return;
                    }

                    setState(() => _time = picked);
                  },
                  icon: const Icon(Icons.access_time),
                  label: Text(
                    '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Ghi chú',
              hintText: 'Những điều quan trọng cần nhớ',
            ),
          ),
          const SizedBox(height: 12),
          _AttachmentEditorSection(
            attachments: _attachments,
            onAddFiles: _pickAttachments,
            onCapturePhoto: _capturePhotoAttachment,
            onScanDocument: _scanDocumentAttachment,
            onEdit: _editAttachment,
            onRemove: _removeAttachment,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () {
                final title = _titleController.text.trim();
                if (title.isEmpty) {
                  setState(() {
                    _titleErrorText = 'Không được để trống tiêu đề';
                  });
                  return;
                }

                Navigator.of(context).pop(
                  TaskEditorResult(
                    title: title,
                    note: _noteController.text.trim(),
                    date: _date,
                    hour: _time,
                    attachments: _attachments,
                  ),
                );
              },
              child: const Text('Tạo việc'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAttachments() async {
    final additions = await pickAttachments(context);
    if (additions.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _attachments = [..._attachments, ...additions];
    });
  }

  Future<void> _capturePhotoAttachment() async {
    final attachment = await captureOrScanAttachment(
      context,
      scanMode: false,
      imagePicker: _imagePicker,
    );
    if (attachment == null || !mounted) {
      return;
    }

    setState(() {
      _attachments = [..._attachments, attachment];
    });
  }

  Future<void> _scanDocumentAttachment() async {
    final attachment = await captureOrScanAttachment(
      context,
      scanMode: true,
      imagePicker: _imagePicker,
    );
    if (attachment == null || !mounted) {
      return;
    }

    setState(() {
      _attachments = [..._attachments, attachment];
    });
  }

  void _removeAttachment(String attachmentId) {
    setState(() {
      _attachments = _attachments
          .where((attachment) => attachment.id != attachmentId)
          .toList();
    });
  }

  Future<void> _editAttachment(EventAttachment attachment) async {
    final edited = await editAttachment(context, attachment);
    if (edited == null || !mounted) {
      return;
    }

    setState(() {
      _attachments = _attachments
          .map((item) => item.id == attachment.id ? edited : item)
          .toList();
    });
  }
}

class _AttachmentEditorSection extends StatelessWidget {
  const _AttachmentEditorSection({
    required this.attachments,
    required this.onAddFiles,
    required this.onCapturePhoto,
    required this.onScanDocument,
    required this.onEdit,
    required this.onRemove,
  });

  final List<EventAttachment> attachments;
  final Future<void> Function() onAddFiles;
  final Future<void> Function() onCapturePhoto;
  final Future<void> Function() onScanDocument;
  final Future<void> Function(EventAttachment attachment) onEdit;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: onAddFiles,
              icon: const Icon(Icons.attach_file),
              label: const Text('Tệp'),
            ),
            OutlinedButton.icon(
              onPressed: onCapturePhoto,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Chụp ảnh'),
            ),
            OutlinedButton.icon(
              onPressed: onScanDocument,
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Quét tài liệu'),
            ),
          ],
        ),
        if (attachments.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: attachments
                .map(
                  (attachment) => InputChip(
                    avatar: Icon(
                      attachment.isPdf
                          ? Icons.picture_as_pdf_outlined
                          : attachment.isImage
                          ? Icons.image_outlined
                          : Icons.description_outlined,
                      size: 18,
                    ),
                    label: Text(attachment.name),
                    onPressed: attachment.isImage
                        ? () => onEdit(attachment)
                        : null,
                    tooltip: attachment.isImage
                        ? 'Chỉnh sửa ảnh'
                        : attachment.name,
                    onDeleted: () => onRemove(attachment.id),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
