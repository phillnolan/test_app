import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'teldrive_models.dart';

class TeldriveApiException implements Exception {
  TeldriveApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    if (statusCode == null) {
      return message;
    }
    return '[$statusCode] $message';
  }
}

final class TeldriveApiClient {
  TeldriveApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const _storageKey = 'teldrive_connection_config_v1';

  final http.Client _client;

  Future<TeldriveConnectionConfig?> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final config = TeldriveConnectionConfig.fromJson(decoded);
      if (config.baseUrl.trim().isEmpty || config.accessToken.trim().isEmpty) {
        return null;
      }
      return config;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveConfig(TeldriveConnectionConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(config.toJson()));
  }

  Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<TeldriveSessionInfo?> fetchSession() async {
    final config = await loadConfig();
    if (config == null) {
      return null;
    }

    return _fetchSessionForConfig(config);
  }

  Future<TeldriveSessionInfo> connect({
    required String baseUrl,
    required String accessToken,
  }) async {
    final normalizedConfig = TeldriveConnectionConfig(
      baseUrl: _normalizeBaseUrl(baseUrl),
      accessToken: accessToken.trim(),
      updatedAt: DateTime.now(),
    );
    final session = await _fetchSessionForConfig(normalizedConfig);
    if (session == null) {
      throw TeldriveApiException(
        'Không thể xác thực với Teledrive. Hãy kiểm tra lại URL và access token.',
      );
    }

    await saveConfig(normalizedConfig);

    return session;
  }

  Future<void> disconnect() async {
    await clearConfig();
  }

  Future<TeldriveFileInfo> createFile({
    required String name,
    required String type,
    String? path,
    String? parentId,
    String? mimeType,
    int? channelId,
    bool? encrypted,
    String? uploadId,
    int? size,
    List<TeldriveFilePart>? parts,
  }) async {
    final config = await _requireConfig();
    final response = await _sendJsonRequest<Map<String, dynamic>>(
      config: config,
      method: 'POST',
      path: 'files',
      body: {
        'name': name,
        'type': type,
        ..._compactMap({
          'path': path,
          'parentId': parentId,
          'mimeType': mimeType,
          'channelId': channelId,
          'encrypted': encrypted,
          'uploadId': uploadId,
          'size': size,
          'parts': parts?.map((part) => part.toJson()).toList(),
        }),
      },
      expectJsonObject: true,
    );
    if (response == null) {
      throw TeldriveApiException('Teldrive không trả về dữ liệu file.');
    }

    return TeldriveFileInfo.fromJson(response);
  }

  Future<TeldriveFileInfo> finalizeFile({
    required String fileId,
    required String fileName,
    required String uploadId,
    required int size,
    required List<TeldriveFilePart> parts,
    String? path,
    String? parentId,
    int? channelId,
    bool encrypted = false,
  }) async {
    final config = await _requireConfig();
    final response = await _sendJsonRequest<Map<String, dynamic>>(
      config: config,
      method: 'PATCH',
      path: 'files/$fileId',
      body: {
        'name': fileName,
        'uploadId': uploadId,
        'parts': parts.map((part) => part.toJson()).toList(),
        'size': size,
        'encrypted': encrypted,
        ..._compactMap({
          'path': path,
          'parentId': parentId,
          'channelId': channelId,
        }),
      },
      expectJsonObject: true,
    );
    if (response == null) {
      throw TeldriveApiException('Teldrive không xác nhận cập nhật file.');
    }

    return TeldriveFileInfo.fromJson(response);
  }

  Future<TeldriveFileInfo?> getFileById(String fileId) async {
    final config = await _requireConfig();
    final response = await _sendJsonRequest<Map<String, dynamic>>(
      config: config,
      method: 'GET',
      path: 'files/$fileId',
      expectJsonObject: true,
    );
    if (response == null) {
      return null;
    }

    return TeldriveFileInfo.fromJson(response);
  }

  Future<TeldriveUploadPartInfo> uploadFilePart({
    required String uploadId,
    required String fileName,
    required Uint8List bytes,
    int partNo = 1,
    String? partName,
    int? channelId,
    bool encrypted = false,
    bool hashing = true,
    String contentType = 'application/octet-stream',
  }) async {
    final config = await _requireConfig();
    final request = http.Request(
      'POST',
      _buildUri(
        config,
        'uploads/$uploadId',
        queryParameters: <String, String>{
          'partName': partName ?? fileName,
          'fileName': fileName,
          'partNo': partNo.toString(),
          if (channelId != null) 'channelId': channelId.toString(),
          'encrypted': encrypted.toString(),
          'hashing': hashing.toString(),
        },
      ),
    );
    request.headers.addAll(
      <String, String>{
        ...await _authHeaders(config),
        'content-type': contentType,
        'content-length': bytes.length.toString(),
      },
    );
    request.bodyBytes = bytes;

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 400) {
      throw TeldriveApiException(
        _describeResponse(response),
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw TeldriveApiException('Teldrive trả về phản hồi tải lên không hợp lệ.');
    }

    return TeldriveUploadPartInfo.fromJson(decoded);
  }

  Future<TeldriveFileInfo?> findFileByName(String name) async {
    final files = await listFiles(
      name: name,
      query: name,
      limit: 50,
    );
    if (files.isEmpty) {
      return null;
    }

    final exactMatches = files.where((file) => file.name == name).toList();
    if (exactMatches.isNotEmpty) {
      exactMatches.sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
      return exactMatches.first;
    }

    files.sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    return files.first;
  }

  Future<List<TeldriveFileInfo>> listFiles({
    String? name,
    String? query,
    String? path,
    int? limit = 100,
    int? page,
    bool? deepSearch,
  }) async {
    final config = await _requireConfig();
    final response = await _sendJsonRequest<Map<String, dynamic>>(
      config: config,
      method: 'GET',
      path: 'files',
      queryParameters: <String, String>{
        if (name != null && name.isNotEmpty) 'name': name,
        if (query != null && query.isNotEmpty) 'query': query,
        if (path != null && path.isNotEmpty) 'path': path,
        if (limit != null) 'limit': limit.toString(),
        if (page != null) 'page': page.toString(),
        if (deepSearch != null) 'deepSearch': deepSearch.toString(),
        'order': 'desc',
      },
      expectJsonObject: true,
    );
    if (response == null) {
      return const <TeldriveFileInfo>[];
    }

    final fileList = TeldriveFileList.fromJson(response);
    return fileList.items;
  }

  Future<Uint8List?> downloadFileBytes({
    required String fileId,
    required String fileName,
  }) async {
    final config = await _requireConfig();
    final response = await _client.get(
      _buildUri(
        config,
        'files/$fileId/${Uri.encodeComponent(fileName)}',
        queryParameters: const <String, String>{'download': '1'},
      ),
      headers: await _authHeaders(config),
    );
    if (response.statusCode >= 400) {
      return null;
    }

    return response.bodyBytes;
  }

  Future<void> deleteFilesByIds(List<String> ids) async {
    if (ids.isEmpty) {
      return;
    }

    final config = await _requireConfig();
    await _sendJsonRequest<Map<String, dynamic>>(
      config: config,
      method: 'POST',
      path: 'files/delete',
      body: {'ids': ids},
      expectJsonObject: false,
    );
  }

  Future<void> deleteFilesByNamePrefix(String prefix) async {
    final files = await listFiles(query: prefix, limit: 1000, deepSearch: true);
    final ids = files
        .where((file) => file.name.startsWith(prefix))
        .map((file) => file.id)
        .toList(growable: false);
    await deleteFilesByIds(ids);
  }

  Future<TeldriveConnectionConfig> _requireConfig() async {
    final config = await loadConfig();
    if (config == null) {
      throw TeldriveApiException(
        'Chưa liên kết với Teledrive. Hãy nhập URL và access token trước.',
      );
    }
    return config;
  }

  Future<TeldriveSessionInfo?> _fetchSessionForConfig(
    TeldriveConnectionConfig config,
  ) async {
    final response = await _sendJsonRequest<Map<String, dynamic>>(
      config: config,
      method: 'GET',
      path: 'auth/session',
      expectJsonObject: true,
    );
    if (response == null) {
      return null;
    }

    try {
      return TeldriveSessionInfo.fromJson(response);
    } catch (error) {
      debugPrint('TeldriveApiClient: invalid session payload: $error');
      return null;
    }
  }

  Future<Map<String, String>> _authHeaders(
    TeldriveConnectionConfig config, {
    bool includeJsonContentType = true,
  }) async {
    return <String, String>{
      if (includeJsonContentType) 'content-type': 'application/json; charset=utf-8',
      'authorization': 'Bearer ${config.accessToken}',
      'accept': 'application/json',
    };
  }

  Uri _buildUri(
    TeldriveConnectionConfig config,
    String path, {
    Map<String, String>? queryParameters,
  }) {
    final relative = Uri(
      path: path,
      queryParameters: queryParameters == null || queryParameters.isEmpty
          ? null
          : queryParameters,
    );
    return config.baseUri.resolveUri(relative);
  }

  String _normalizeBaseUrl(String baseUrl) {
    final trimmed = baseUrl.trim();
    if (trimmed.isEmpty) {
      throw TeldriveApiException('URL Teledrive không được để trống.');
    }

    final parsed = Uri.parse(trimmed);
    if (parsed.scheme.isEmpty || parsed.host.isEmpty) {
      throw TeldriveApiException('URL Teledrive không hợp lệ.');
    }

    final normalizedPath = parsed.path.endsWith('/')
        ? parsed.path
        : '${parsed.path}/';
    return parsed.replace(path: normalizedPath).toString();
  }

  Future<Map<String, dynamic>?> _sendJsonRequest<T>({
    required TeldriveConnectionConfig config,
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    required bool expectJsonObject,
  }) async {
    final request = http.Request(
      method,
      _buildUri(config, path, queryParameters: queryParameters),
    );
    request.headers.addAll(await _authHeaders(config));
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 400) {
      throw TeldriveApiException(
        _describeResponse(response),
        statusCode: response.statusCode,
      );
    }

    if (response.body.isEmpty) {
      return expectJsonObject ? null : <String, dynamic>{};
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }

    return expectJsonObject ? null : <String, dynamic>{};
  }

  String _describeResponse(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) {
      return 'Teledrive trả về mã ${response.statusCode}.';
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message =
            decoded['message'] ??
            decoded['error'] ??
            decoded['error_description'] ??
            decoded['detail'];
        if (message != null) {
          return message.toString();
        }
      }
    } catch (_) {
      // Fall back to the raw body below.
    }

    return body;
  }

  Map<String, dynamic> _compactMap(Map<String, dynamic> values) {
    final result = <String, dynamic>{};
    for (final entry in values.entries) {
      final value = entry.value;
      if (value != null) {
        result[entry.key] = value;
      }
    }
    return result;
  }
}
