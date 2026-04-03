const Object _eventAttachmentUnset = Object();

class EventAttachment {
  const EventAttachment({
    required this.id,
    required this.name,
    required this.path,
    this.remoteKey,
    this.bytesBase64,
  });

  final String id;
  final String name;
  final String path;
  final String? remoteKey;
  final String? bytesBase64;

  String get extension {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == name.length - 1) return '';
    return name.substring(dotIndex + 1).toLowerCase();
  }

  bool get isImage => const {
    'png',
    'jpg',
    'jpeg',
    'gif',
    'webp',
    'bmp',
    'heic',
  }.contains(extension);

  bool get isPdf => extension == 'pdf';

  EventAttachment copyWith({
    String? id,
    String? name,
    String? path,
    Object? remoteKey = _eventAttachmentUnset,
    Object? bytesBase64 = _eventAttachmentUnset,
  }) {
    return EventAttachment(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      remoteKey: identical(remoteKey, _eventAttachmentUnset)
          ? this.remoteKey
          : remoteKey as String?,
      bytesBase64: identical(bytesBase64, _eventAttachmentUnset)
          ? this.bytesBase64
          : bytesBase64 as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'remoteKey': remoteKey,
      'bytesBase64': bytesBase64,
    };
  }

  factory EventAttachment.fromJson(Map<String, dynamic> json) {
    return EventAttachment(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      path: (json['path'] ?? '').toString(),
      remoteKey: json['remoteKey']?.toString(),
      bytesBase64: json['bytesBase64']?.toString(),
    );
  }
}
