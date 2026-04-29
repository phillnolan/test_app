import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quiz_models.dart';
import '../data/quiz_repository.dart';

/// Provides the quiz repository used by the feature.
final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return AssetQuizRepository();
});

/// Loads the quiz catalog for the UI.
final quizCatalogProvider = FutureProvider<List<QuizBankMetadata>>((ref) {
  return ref.watch(quizRepositoryProvider).loadCatalog();
});

/// Provides the active quiz controller.
final quizControllerProvider = NotifierProvider<QuizController, QuizState>(
  QuizController.new,
);

/// Controls the active quiz session.
final class QuizController extends Notifier<QuizState> {
  QuizController({QuizRepository? repository})
    : _repository = repository ?? AssetQuizRepository();

  final QuizRepository _repository;

  @override
  QuizState build() {
    return const QuizState();
  }

  /// Clears the current session.
  void clearSession() {
    state = const QuizState();
  }

  /// Starts a quiz for [metadata].
  Future<void> startQuiz(
    QuizBankMetadata metadata, {
    int questionCount = quizPracticeDeckSize,
    int setNumber = 1,
  }) async {
    state = state.copyWith(isStarting: true, errorMessage: null);

    try {
      final bank = await _repository.loadBank(metadata);
      final questions = _buildPracticeQuestions(
        questions: bank.questions,
        questionCount: questionCount,
        bankId: bank.metadata.id,
        setNumber: setNumber,
      );
      if (questions.isEmpty) {
        throw StateError('Bank has no playable questions.');
      }
      final attempts = List<QuizQuestionAttempt>.generate(
        questions.length,
        (_) => QuizQuestionAttempt(),
        growable: false,
      );

      state = QuizState(
        session: QuizSession(
          bank: bank.metadata,
          questions: questions,
          attempts: attempts,
          practiceSetNumber: setNumber < 1 ? 1 : setNumber,
          currentIndex: 0,
          startedAt: DateTime.now(),
        ),
        isStarting: false,
      );
    } catch (error, stackTrace) {
      debugPrint('QuizController: startQuiz failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      state = state.copyWith(
        isStarting: false,
        errorMessage: 'Không thể tải bộ đề quiz lúc này. Vui lòng thử lại sau.',
      );
    }
  }

  /// Restarts the current session with the same bank, deck, and question count.
  Future<void> restartSession() async {
    final session = state.session;
    if (session == null) {
      return;
    }

    await startQuiz(
      session.bank,
      questionCount: session.questionCount,
      setNumber: session.practiceSetNumber,
    );
  }

  /// Selects or toggles an option for the current question.
  void selectOption(int optionIndex) {
    final session = state.session;
    if (session == null || session.isCompleted) {
      return;
    }

    final currentAttempt = session.currentAttempt;
    if (currentAttempt.isSubmitted) {
      return;
    }

    final question = session.currentQuestion;
    final selectedIndices = <int>{...currentAttempt.selectedOptionIndices};
    if (question.hasMultipleCorrectAnswers) {
      if (!selectedIndices.add(optionIndex)) {
        selectedIndices.remove(optionIndex);
      }
    } else {
      selectedIndices
        ..clear()
        ..add(optionIndex);
    }

    _updateCurrentAttempt(
      currentAttempt.copyWith(selectedOptionIndices: selectedIndices),
    );
  }

  /// Submits the current answer.
  void submitCurrentAnswer() {
    final session = state.session;
    if (session == null || session.isCompleted) {
      return;
    }

    final currentAttempt = session.currentAttempt;
    if (!currentAttempt.hasSelection || currentAttempt.isSubmitted) {
      return;
    }

    final selectedIndices = <int>{...currentAttempt.selectedOptionIndices};
    final correctIndices = session.currentQuestion.correctOptionIndices;
    final isCorrect = setEquals(selectedIndices, correctIndices);
    final updatedAttempt = currentAttempt.copyWith(
      selectedOptionIndices: selectedIndices,
      submittedOptionIndices: selectedIndices,
      isSubmitted: true,
      isCorrect: isCorrect,
    );

    final attempts = session.attempts.toList();
    attempts[session.currentIndex] = updatedAttempt;
    final isCompleted = attempts.every((attempt) => attempt.isSubmitted);

    state = state.copyWith(
      session: session.copyWith(
        attempts: attempts,
        completedAt: isCompleted ? DateTime.now() : session.completedAt,
      ),
    );
  }

  /// Moves to the next question when possible.
  void goToNextQuestion() {
    final session = state.session;
    if (session == null ||
        session.currentIndex >= session.questions.length - 1) {
      return;
    }

    final currentAttempt = session.currentAttempt;
    if (!currentAttempt.isSubmitted) {
      return;
    }

    state = state.copyWith(
      session: session.copyWith(currentIndex: session.currentIndex + 1),
    );
  }

  /// Moves to the previous question when possible.
  void goToPreviousQuestion() {
    final session = state.session;
    if (session == null || session.currentIndex == 0) {
      return;
    }

    state = state.copyWith(
      session: session.copyWith(currentIndex: session.currentIndex - 1),
    );
  }

  /// Jumps to [index] within the active session.
  void jumpToQuestion(int index) {
    final session = state.session;
    if (session == null || index < 0 || index >= session.questions.length) {
      return;
    }

    state = state.copyWith(session: session.copyWith(currentIndex: index));
  }

  void _updateCurrentAttempt(QuizQuestionAttempt attempt) {
    final session = state.session;
    if (session == null) {
      return;
    }

    final attempts = session.attempts.toList();
    attempts[session.currentIndex] = attempt;
    state = state.copyWith(session: session.copyWith(attempts: attempts));
  }

  List<QuizQuestion> _buildPracticeQuestions({
    required List<QuizQuestion> questions,
    required int questionCount,
    required String bankId,
    required int setNumber,
  }) {
    if (questions.isEmpty) {
      return const <QuizQuestion>[];
    }

    final normalizedCount = questionCount <= 0
        ? quizPracticeDeckSize
        : questionCount;
    final normalizedSetNumber = setNumber < 1 ? 1 : setNumber;
    final seededQuestions = questions.toList()
      ..shuffle(
        Random(_stableSeed(bankId: bankId, setNumber: normalizedSetNumber)),
      );

    final selected = normalizedCount <= seededQuestions.length
        ? seededQuestions.take(normalizedCount).toList(growable: false)
        : _repeatQuestions(
            questions: seededQuestions,
            questionCount: normalizedCount,
          );

    selected.shuffle(Random());
    return selected;
  }

  List<QuizQuestion> _repeatQuestions({
    required List<QuizQuestion> questions,
    required int questionCount,
  }) {
    final selected = <QuizQuestion>[];
    while (selected.length < questionCount) {
      selected.addAll(questions);
    }

    return selected.take(questionCount).toList(growable: false);
  }

  int _stableSeed({required String bankId, required int setNumber}) {
    var seed = 17;
    for (final unit in bankId.codeUnits) {
      seed = 37 * seed + unit;
    }
    seed = 37 * seed + setNumber;
    return seed & 0x7fffffff;
  }
}
