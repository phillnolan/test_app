import 'dart:convert';

/// Saved connection details for a Teldrive instance.
final class TeldriveConnectionConfig {
  const TeldriveConnectionConfig({
    required this.baseUrl,
    required this.accessToken,
    required this.updatedAt,
  });

  final String baseUrl;
  final String accessToken;
  final DateTime updatedAt;

  Uri get baseUri => Uri.parse(baseUrl);

  Map<String, dynamic> toJson() {
    return {
      'baseUrl': baseUrl,
      'accessToken': accessToken,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TeldriveConnectionConfig.fromJson(Map<String, dynamic> json) {
    return TeldriveConnectionConfig(
      baseUrl: (json['baseUrl'] ?? '').toString(),
      accessToken: (json['accessToken'] ?? '').toString(),
      updatedAt:
          DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

/// Session data returned by Teldrive.
final class TeldriveSessionInfo {
  const TeldriveSessionInfo({
    required this.name,
    required this.userName,
    required this.userId,
    required this.isPremium,
    required this.hash,
    required this.expires,
    this.session,
  });

  final String name;
  final String userName;
  final int userId;
  final bool isPremium;
  final String hash;
  final DateTime expires;
  final String? session;

  bool get isExpired => DateTime.now().isAfter(expires);

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'userName': userName,
      'userId': userId,
      'isPremium': isPremium,
      'hash': hash,
      'expires': expires.toIso8601String(),
      'session': session,
    };
  }

  factory TeldriveSessionInfo.fromJson(Map<String, dynamic> json) {
    return TeldriveSessionInfo(
      name: (json['name'] ?? '').toString(),
      userName: (json['userName'] ?? '').toString(),
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      isPremium: json['isPremium'] == true,
      hash: (json['hash'] ?? '').toString(),
      expires:
          DateTime.tryParse((json['expires'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      session: json['session']?.toString(),
    );
  }
}

/// File part data returned by Teldrive uploads.
final class TeldriveUploadPartInfo {
  const TeldriveUploadPartInfo({
    required this.name,
    required this.partId,
    required this.partNo,
    required this.channelId,
    required this.size,
    required this.encrypted,
    this.salt,
  });

  final String name;
  final int partId;
  final int partNo;
  final int channelId;
  final int size;
  final bool encrypted;
  final String? salt;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'partId': partId,
      'partNo': partNo,
      'channelId': channelId,
      'size': size,
      'encrypted': encrypted,
      'salt': salt,
    };
  }

  factory TeldriveUploadPartInfo.fromJson(Map<String, dynamic> json) {
    return TeldriveUploadPartInfo(
      name: (json['name'] ?? '').toString(),
      partId: (json['partId'] as num?)?.toInt() ?? 0,
      partNo: (json['partNo'] as num?)?.toInt() ?? 0,
      channelId: (json['channelId'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
      encrypted: json['encrypted'] == true,
      salt: json['salt']?.toString(),
    );
  }
}

/// File part reference used when finalizing a file record.
final class TeldriveFilePart {
  const TeldriveFilePart({required this.id, this.salt});

  final int id;
  final String? salt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'salt': salt,
    };
  }

  factory TeldriveFilePart.fromUploadPart(TeldriveUploadPartInfo part) {
    return TeldriveFilePart(id: part.partId, salt: part.salt);
  }
}

/// File metadata returned by Teldrive.
final class TeldriveFileInfo {
  const TeldriveFileInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.updatedAt,
    this.uploadId,
    this.parts = const [],
    this.mimeType,
    this.channelId,
    this.path,
    this.parentId,
    this.size,
    this.encrypted,
    this.hash,
    this.category,
  });

  final String id;
  final String name;
  final String type;
  final String? uploadId;
  final List<TeldriveFilePart> parts;
  final String? mimeType;
  final int? channelId;
  final String? path;
  final String? parentId;
  final int? size;
  final bool? encrypted;
  final String? hash;
  final DateTime updatedAt;
  final String? category;

  bool get isFolder => type == 'folder';
  bool get isFile => type == 'file';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'uploadId': uploadId,
      'parts': parts.map((part) => part.toJson()).toList(),
      'mimeType': mimeType,
      'channelId': channelId,
      'path': path,
      'parentId': parentId,
      'size': size,
      'encrypted': encrypted,
      'hash': hash,
      'updatedAt': updatedAt.toIso8601String(),
      'category': category,
    };
  }

  factory TeldriveFileInfo.fromJson(Map<String, dynamic> json) {
    return TeldriveFileInfo(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? 'file').toString(),
      uploadId: json['uploadId']?.toString(),
      parts: ((json['parts'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) => TeldriveFilePart(
              id: (item['id'] as num?)?.toInt() ?? 0,
              salt: item['salt']?.toString(),
            ),
          )
          .toList(growable: false),
      mimeType: json['mimeType']?.toString(),
      channelId: (json['channelId'] as num?)?.toInt(),
      path: json['path']?.toString(),
      parentId: json['parentId']?.toString(),
      size: (json['size'] as num?)?.toInt(),
      encrypted: json['encrypted'] as bool?,
      hash: json['hash']?.toString(),
      updatedAt:
          DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      category: json['category']?.toString(),
    );
  }

  String? encodedName() {
    if (name.isEmpty) {
      return null;
    }
    return Uri.encodeComponent(name);
  }
}

/// File list response from Teldrive.
final class TeldriveFileList {
  const TeldriveFileList({required this.items});

  final List<TeldriveFileInfo> items;

  factory TeldriveFileList.fromJson(Map<String, dynamic> json) {
    final rawItems = ((json['items'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (item) => TeldriveFileInfo.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(growable: false);
    return TeldriveFileList(items: rawItems);
  }
}

String encodeTeldriveJson(Map<String, dynamic> json) {
  return jsonEncode(json);
}
