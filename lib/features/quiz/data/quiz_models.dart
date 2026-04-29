// Quiz feature data models.

const Object _unset = Object();

/// The standard number of questions in each practice set.
const int quizPracticeDeckSize = 50;

/// Describes one quiz bank available in the app.
final class QuizBankMetadata {
  QuizBankMetadata({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.questionCount,
    required this.sourceQuestionCount,
    required this.skippedQuestionCount,
    required this.accentColor,
    required this.assetPath,
  });

  final String id;
  final String code;
  final String title;
  final String description;
  final int questionCount;
  final int sourceQuestionCount;
  final int skippedQuestionCount;
  final int accentColor;
  final String assetPath;

  bool get hasSkippedQuestions => skippedQuestionCount > 0;

  factory QuizBankMetadata.fromJson(Map<String, dynamic> json) {
    return QuizBankMetadata(
      id: json['id'] as String,
      code: json['code'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      questionCount: (json['questionCount'] as num).toInt(),
      sourceQuestionCount:
          (json['sourceQuestionCount'] as num?)?.toInt() ??
          (json['questionCount'] as num).toInt(),
      skippedQuestionCount:
          (json['skippedQuestionCount'] as num?)?.toInt() ?? 0,
      accentColor: (json['accentColor'] as num).toInt(),
      assetPath: json['assetPath'] as String,
    );
  }
}

/// Represents a single quiz question.
final class QuizQuestion {
  QuizQuestion({
    required this.sourceId,
    required this.question,
    required List<String> options,
    required Set<int> correctOptionIndices,
    required this.explanation,
  }) : options = List<String>.unmodifiable(options),
       correctOptionIndices = Set<int>.unmodifiable(correctOptionIndices);

  final int sourceId;
  final String question;
  final List<String> options;
  final Set<int> correctOptionIndices;
  final String explanation;

  bool get hasMultipleCorrectAnswers => correctOptionIndices.length > 1;

  bool get hasMeaningfulExplanation {
    final normalized = explanation.trim().toLowerCase();
    return normalized.isNotEmpty && normalized != 'true';
  }

  String get explanationText {
    if (hasMeaningfulExplanation) {
      return explanation.trim();
    }

    return 'Bộ câu hỏi gốc chưa có giải thích chi tiết cho câu này.';
  }

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final dynamic correctAnswer =
        json['correctAnswerIndices'] ?? json['correctAnswer'];
    final Set<int> correctOptionIndices = switch (correctAnswer) {
      final int index => {index},
      final List<dynamic> values =>
        values.map((dynamic value) => (value as num).toInt()).toSet(),
      final Iterable<dynamic> values =>
        values.map((dynamic value) => (value as num).toInt()).toSet(),
      _ => throw FormatException(
        'Quiz question is missing correct answer indices.',
      ),
    };

    return QuizQuestion(
      sourceId: (json['id'] as num).toInt(),
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>)
          .map((dynamic option) => option as String)
          .toList(growable: false),
      correctOptionIndices: correctOptionIndices,
      explanation: switch (json['explanation']) {
        String value => value,
        bool value => value ? 'true' : '',
        null => '',
        final value => value.toString(),
      },
    );
  }
}

/// A loaded quiz bank together with its questions.
final class QuizBank {
  QuizBank({required this.metadata, required List<QuizQuestion> questions})
    : questions = List<QuizQuestion>.unmodifiable(questions);

  final QuizBankMetadata metadata;
  final List<QuizQuestion> questions;
}

/// Stores the current answer state for a question.
final class QuizQuestionAttempt {
  QuizQuestionAttempt({
    Set<int> selectedOptionIndices = const <int>{},
    Set<int> submittedOptionIndices = const <int>{},
    this.isSubmitted = false,
    this.isCorrect = false,
  }) : selectedOptionIndices = Set<int>.unmodifiable(selectedOptionIndices),
       submittedOptionIndices = Set<int>.unmodifiable(submittedOptionIndices);

  final Set<int> selectedOptionIndices;
  final Set<int> submittedOptionIndices;
  final bool isSubmitted;
  final bool isCorrect;

  bool get hasSelection => selectedOptionIndices.isNotEmpty;

  QuizQuestionAttempt copyWith({
    Set<int>? selectedOptionIndices,
    Set<int>? submittedOptionIndices,
    bool? isSubmitted,
    bool? isCorrect,
  }) {
    return QuizQuestionAttempt(
      selectedOptionIndices:
          selectedOptionIndices ?? this.selectedOptionIndices,
      submittedOptionIndices:
          submittedOptionIndices ?? this.submittedOptionIndices,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }
}

/// A single active quiz session.
final class QuizSession {
  QuizSession({
    required this.bank,
    required List<QuizQuestion> questions,
    required List<QuizQuestionAttempt> attempts,
    required this.practiceSetNumber,
    required this.currentIndex,
    required this.startedAt,
    this.completedAt,
  }) : questions = List<QuizQuestion>.unmodifiable(questions),
       attempts = List<QuizQuestionAttempt>.unmodifiable(attempts);

  final QuizBankMetadata bank;
  final List<QuizQuestion> questions;
  final List<QuizQuestionAttempt> attempts;
  final int practiceSetNumber;
  final int currentIndex;
  final DateTime startedAt;
  final DateTime? completedAt;

  bool get isCompleted => completedAt != null;

  int get questionCount => questions.length;

  QuizQuestion get currentQuestion => questions[currentIndex];

  QuizQuestionAttempt get currentAttempt => attempts[currentIndex];

  int get answeredCount =>
      attempts.where((attempt) => attempt.isSubmitted).length;

  int get correctCount => attempts
      .where((attempt) => attempt.isSubmitted && attempt.isCorrect)
      .length;

  double get scorePercent {
    if (questionCount == 0) {
      return 0;
    }

    return correctCount / questionCount;
  }

  QuizSession copyWith({
    QuizBankMetadata? bank,
    List<QuizQuestion>? questions,
    List<QuizQuestionAttempt>? attempts,
    int? practiceSetNumber,
    int? currentIndex,
    Object? completedAt = _unset,
  }) {
    return QuizSession(
      bank: bank ?? this.bank,
      questions: questions ?? this.questions,
      attempts: attempts ?? this.attempts,
      practiceSetNumber: practiceSetNumber ?? this.practiceSetNumber,
      currentIndex: currentIndex ?? this.currentIndex,
      startedAt: startedAt,
      completedAt: completedAt == _unset
          ? this.completedAt
          : completedAt as DateTime?,
    );
  }
}

/// Immutable state used by the quiz controller.
final class QuizState {
  const QuizState({this.session, this.isStarting = false, this.errorMessage});

  final QuizSession? session;
  final bool isStarting;
  final String? errorMessage;

  bool get hasActiveSession => session != null;

  bool get isSessionCompleted => session?.isCompleted ?? false;

  int get answeredCount => session?.answeredCount ?? 0;

  int get correctCount => session?.correctCount ?? 0;

  int get questionCount => session?.questionCount ?? 0;

  double get scorePercent => session?.scorePercent ?? 0;

  QuizState copyWith({
    Object? session = _unset,
    bool? isStarting,
    Object? errorMessage = _unset,
  }) {
    return QuizState(
      session: session == _unset ? this.session : session as QuizSession?,
      isStarting: isStarting ?? this.isStarting,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
