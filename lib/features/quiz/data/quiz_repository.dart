import 'dart:convert';
import 'dart:async';

import 'package:flutter/services.dart';

import 'quiz_models.dart';

/// Loads quiz bank metadata and questions from bundled assets.
abstract interface class QuizRepository {
  /// Returns the full catalog of available quiz banks.
  Future<List<QuizBankMetadata>> loadCatalog();

  /// Returns one loaded quiz bank with its questions.
  Future<QuizBank> loadBank(QuizBankMetadata metadata);
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
    final decodedManifest = jsonDecode(rawManifest);
    if (decodedManifest is! Map<String, dynamic>) {
      throw const FormatException('Quiz manifest must be a JSON object.');
    }

    final rawBanks = decodedManifest['banks'];
    if (rawBanks is! List<dynamic>) {
      throw const FormatException('Quiz manifest must contain a banks list.');
    }

    final banks = rawBanks
        .map(
          (dynamic entry) =>
              QuizBankMetadata.fromJson(entry as Map<String, dynamic>),
        )
        .toList(growable: false);
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
    final decodedBank = jsonDecode(rawBank);
    if (decodedBank is! List<dynamic>) {
      throw FormatException(
        'Quiz bank "${metadata.id}" must be stored as a JSON array.',
      );
    }

    final questions = decodedBank
        .map(
          (dynamic entry) =>
              QuizQuestion.fromJson(entry as Map<String, dynamic>),
        )
        .toList(growable: false);
    return QuizBank(metadata: metadata, questions: questions);
  }
}
