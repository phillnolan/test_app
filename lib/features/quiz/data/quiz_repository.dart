import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'quiz_models.dart';

/// Loads quiz bank metadata and questions from bundled assets.
abstract interface class QuizRepository {
  /// Returns the full catalog of available quiz banks.
  Future<List<QuizBankMetadata>> loadCatalog();

  /// Returns one loaded quiz bank with its questions.
  Future<QuizBank> loadBank(QuizBankMetadata metadata);
}

const String _defaultWorkerUrl =
    'https://sinhvien-worker.nkocpk99012.workers.dev';

/// Parses the quiz manifest and banks from Cloudflare Worker endpoints.
final class CloudflareQuizRepository implements QuizRepository {
  CloudflareQuizRepository({
    http.Client? client,
    QuizRepository? fallbackRepository,
    String? workerUrl,
  }) : _client = client ?? http.Client(),
       _fallbackRepository = fallbackRepository ?? AssetQuizRepository(),
       _workerUrl =
           (workerUrl ??
                   String.fromEnvironment(
                     'CLOUDFLARE_WORKER_URL',
                     defaultValue: _defaultWorkerUrl,
                   ))
               .trim();

  final http.Client _client;
  final QuizRepository _fallbackRepository;
  final String _workerUrl;

  List<QuizBankMetadata>? _catalogCache;
  final Map<String, Future<QuizBank>> _bankCache = <String, Future<QuizBank>>{};

  bool get isConfigured => _workerUrl.isNotEmpty;

  @override
  Future<List<QuizBankMetadata>> loadCatalog() async {
    final cached = _catalogCache;
    if (cached != null) {
      return cached;
    }

    if (!isConfigured) {
      final fallbackCatalog = await _fallbackRepository.loadCatalog();
      _catalogCache = fallbackCatalog;
      return fallbackCatalog;
    }

    try {
      final response = await _client.get(
        Uri.parse('$_workerUrl/quiz/catalog'),
        headers: const {'accept': 'application/json'},
      );
      if (response.statusCode >= 400 || response.body.isEmpty) {
        throw StateError(
          'Unexpected quiz catalog response: ${response.statusCode}',
        );
      }

      final banks = _parseQuizCatalogManifest(response.body);
      _catalogCache = banks;
      return banks;
    } catch (error, stackTrace) {
      debugPrint('CloudflareQuizRepository: loadCatalog failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      final fallbackCatalog = await _fallbackRepository.loadCatalog();
      _catalogCache = fallbackCatalog;
      return fallbackCatalog;
    }
  }

  @override
  Future<QuizBank> loadBank(QuizBankMetadata metadata) {
    final cached = _bankCache[metadata.id];
    if (cached != null) {
      return cached;
    }

    final future = _loadBank(metadata);
    final completer = Completer<QuizBank>();
    _bankCache[metadata.id] = completer.future;

    future.then(
      completer.complete,
      onError: (Object error, StackTrace stackTrace) {
        _bankCache.remove(metadata.id);
        completer.completeError(error, stackTrace);
      },
    );

    return completer.future;
  }

  Future<QuizBank> _loadBank(QuizBankMetadata metadata) async {
    if (!isConfigured) {
      return _fallbackRepository.loadBank(metadata);
    }

    try {
      final response = await _client.get(
        Uri.parse('$_workerUrl/quiz/banks/${Uri.encodeComponent(metadata.id)}'),
        headers: const {'accept': 'application/json'},
      );
      if (response.statusCode >= 400 || response.body.isEmpty) {
        throw StateError(
          'Unexpected quiz bank response: ${response.statusCode}',
        );
      }

      final questions = _parseQuizQuestions(response.body, bankId: metadata.id);
      return QuizBank(metadata: metadata, questions: questions);
    } catch (error, stackTrace) {
      debugPrint(
        'CloudflareQuizRepository: loadBank failed for ${metadata.id}: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return _fallbackRepository.loadBank(metadata);
    }
  }
}

/// Asset-backed implementation of [QuizRepository].
final class AssetQuizRepository implements QuizRepository {
  AssetQuizRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  List<QuizBankMetadata>? _catalogCache;
  final Map<String, Future<QuizBank>> _bankCache = <String, Future<QuizBank>>{};

  @override
  Future<List<QuizBankMetadata>> loadCatalog() async {
    final cached = _catalogCache;
    if (cached != null) {
      return cached;
    }

    const manifestPath = 'assets/quiz/quiz_manifest.json';
    final rawManifest = await _bundle.loadString(manifestPath);
    final banks = _parseQuizCatalogManifest(rawManifest);
    _catalogCache = banks;
    return banks;
  }

  @override
  Future<QuizBank> loadBank(QuizBankMetadata metadata) {
    final cached = _bankCache[metadata.id];
    if (cached != null) {
      return cached;
    }

    final future = _loadBank(metadata);
    final completer = Completer<QuizBank>();
    _bankCache[metadata.id] = completer.future;

    future.then(
      completer.complete,
      onError: (Object error, StackTrace stackTrace) {
        _bankCache.remove(metadata.id);
        completer.completeError(error, stackTrace);
      },
    );

    return completer.future;
  }

  Future<QuizBank> _loadBank(QuizBankMetadata metadata) async {
    final rawBank = await _bundle.loadString(metadata.assetPath);
    final questions = _parseQuizQuestions(rawBank, bankId: metadata.id);
    return QuizBank(metadata: metadata, questions: questions);
  }
}

List<QuizBankMetadata> _parseQuizCatalogManifest(String rawManifest) {
  final decodedManifest = jsonDecode(rawManifest);
  if (decodedManifest is! Map<String, dynamic>) {
    throw const FormatException('Quiz manifest must be a JSON object.');
  }

  final rawBanks = decodedManifest['banks'];
  if (rawBanks is! List<dynamic>) {
    throw const FormatException('Quiz manifest must contain a banks list.');
  }

  return rawBanks
      .map(
        (dynamic entry) =>
            QuizBankMetadata.fromJson(entry as Map<String, dynamic>),
      )
      .toList(growable: false);
}

List<QuizQuestion> _parseQuizQuestions(
  String rawBank, {
  required String bankId,
}) {
  final decodedBank = jsonDecode(rawBank);
  if (decodedBank is! List<dynamic>) {
    throw FormatException(
      'Quiz bank "$bankId" must be stored as a JSON array.',
    );
  }

  return decodedBank
      .map(
        (dynamic entry) => QuizQuestion.fromJson(entry as Map<String, dynamic>),
      )
      .toList(growable: false);
}
