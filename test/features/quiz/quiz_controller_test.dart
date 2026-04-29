import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinhvien_app/features/quiz/data/quiz_models.dart';
import 'package:sinhvien_app/features/quiz/data/quiz_repository.dart';
import 'package:sinhvien_app/features/quiz/ui/quiz_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('asset quiz repository loads the bundled catalog', () async {
    final repository = AssetQuizRepository();
    final catalog = await repository.loadCatalog();

    expect(catalog, hasLength(9));
    expect(catalog.any((bank) => bank.id == 'mmt'), isTrue);
    expect(
      catalog.firstWhere((bank) => bank.id == 'mmt').skippedQuestionCount,
      greaterThan(0),
    );
  });

  test(
    'cloudflare quiz repository loads quiz data from worker routes',
    () async {
      final client = _FakeHttpClient((request) async {
        final path = request.url.path;
        if (path == '/quiz/catalog') {
          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                jsonEncode({
                  'banks': [
                    {
                      'id': 'sample',
                      'code': 'SAMPLE',
                      'title': 'Sample Bank',
                      'description': 'Test bank',
                      'questionCount': 2,
                      'sourceQuestionCount': 2,
                      'skippedQuestionCount': 0,
                      'accentColor': 0xff123456,
                      'assetPath': 'assets/quiz/banks/sample.json',
                    },
                  ],
                }),
              ),
            ),
            200,
            request: request,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }

        if (path == '/quiz/banks/sample') {
          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                jsonEncode([
                  {
                    'id': 1,
                    'question': 'Question one?',
                    'options': ['A', 'B'],
                    'correctAnswer': 0,
                  },
                ]),
              ),
            ),
            200,
            request: request,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }

        return http.StreamedResponse(
          Stream.value(const <int>[]),
          404,
          request: request,
        );
      });

      final repository = CloudflareQuizRepository(
        client: client,
        workerUrl: 'https://worker.test',
        fallbackRepository: AssetQuizRepository(),
      );

      final catalog = await repository.loadCatalog();
      expect(catalog, hasLength(1));
      expect(catalog.single.id, 'sample');

      final bank = await repository.loadBank(catalog.single);
      expect(bank.metadata.id, 'sample');
      expect(bank.questions, hasLength(1));
      expect(bank.questions.single.question, 'Question one?');
    },
  );

  test('quiz question parser tolerates boolean explanation markers', () {
    final question = QuizQuestion.fromJson({
      'id': 1,
      'question': 'Sample question?',
      'options': ['A', 'B'],
      'correctAnswer': 0,
      'explanation': true,
    });

    expect(question.hasMeaningfulExplanation, isFalse);
    expect(question.explanationText, isNotEmpty);
  });

  test('quiz controller loads a catalog and scores a full session', () async {
    final repository = FakeQuizRepository(
      catalog: [
        QuizBankMetadata(
          id: 'sample',
          code: 'SAMPLE',
          title: 'Sample Bank',
          description: 'Test bank',
          questionCount: 2,
          sourceQuestionCount: 2,
          skippedQuestionCount: 0,
          accentColor: 0xff123456,
          assetPath: 'assets/quiz/banks/sample.json',
        ),
      ],
      banks: {
        'sample': QuizBank(
          metadata: QuizBankMetadata(
            id: 'sample',
            code: 'SAMPLE',
            title: 'Sample Bank',
            description: 'Test bank',
            questionCount: 2,
            sourceQuestionCount: 2,
            skippedQuestionCount: 0,
            accentColor: 0xff123456,
            assetPath: 'assets/quiz/banks/sample.json',
          ),
          questions: [
            QuizQuestion(
              sourceId: 1,
              question: 'Question one?',
              options: const ['A', 'B'],
              correctOptionIndices: const {0},
              explanation: 'Reason one',
            ),
            QuizQuestion(
              sourceId: 2,
              question: 'Question two?',
              options: const ['A', 'B', 'C'],
              correctOptionIndices: const {1, 2},
              explanation: 'Reason two',
            ),
          ],
        ),
      },
    );
    final container = ProviderContainer(
      overrides: [
        quizRepositoryProvider.overrideWithValue(repository),
        quizControllerProvider.overrideWith(
          () => QuizController(repository: repository),
        ),
      ],
    );
    addTearDown(container.dispose);

    final catalog = await container.read(quizCatalogProvider.future);
    expect(catalog, hasLength(1));
    expect(catalog.single.title, 'Sample Bank');

    final controller = container.read(quizControllerProvider.notifier);
    await controller.startQuiz(catalog.single, questionCount: 2, setNumber: 1);
    expect(controller.state.session, isNotNull);
    expect(controller.state.session!.questionCount, 2);
    expect(controller.state.session!.practiceSetNumber, 1);

    _answerCurrentQuestion(controller);
    controller.goToNextQuestion();
    _answerCurrentQuestion(controller);

    expect(controller.state.session!.isCompleted, isTrue);
    expect(controller.state.session!.correctCount, 2);
  });

  test(
    'quiz controller builds a 50-question practice set by default',
    () async {
      final repository = FakeQuizRepository(
        catalog: [
          QuizBankMetadata(
            id: 'sample-50',
            code: 'SAMPLE50',
            title: 'Sample 50',
            description: 'Practice bank',
            questionCount: 60,
            sourceQuestionCount: 60,
            skippedQuestionCount: 0,
            accentColor: 0xff123456,
            assetPath: 'assets/quiz/banks/sample-50.json',
          ),
        ],
        banks: {
          'sample-50': QuizBank(
            metadata: QuizBankMetadata(
              id: 'sample-50',
              code: 'SAMPLE50',
              title: 'Sample 50',
              description: 'Practice bank',
              questionCount: 60,
              sourceQuestionCount: 60,
              skippedQuestionCount: 0,
              accentColor: 0xff123456,
              assetPath: 'assets/quiz/banks/sample-50.json',
            ),
            questions: _sampleQuestions(60),
          ),
        },
      );
      final container = ProviderContainer(
        overrides: [
          quizRepositoryProvider.overrideWithValue(repository),
          quizControllerProvider.overrideWith(
            () => QuizController(repository: repository),
          ),
        ],
      );
      addTearDown(container.dispose);

      final catalog = await container.read(quizCatalogProvider.future);
      final controller = container.read(quizControllerProvider.notifier);
      await controller.startQuiz(catalog.single, setNumber: 2);

      expect(controller.state.session, isNotNull);
      expect(controller.state.session!.questionCount, quizPracticeDeckSize);
      expect(controller.state.session!.practiceSetNumber, 2);
    },
  );

  test('quiz controller restarts the active deck as a fresh session', () async {
    final repository = FakeQuizRepository(
      catalog: [
        QuizBankMetadata(
          id: 'sample-restart',
          code: 'SAMPLE-R',
          title: 'Sample Restart',
          description: 'Practice bank',
          questionCount: 4,
          sourceQuestionCount: 4,
          skippedQuestionCount: 0,
          accentColor: 0xff123456,
          assetPath: 'assets/quiz/banks/sample-restart.json',
        ),
      ],
      banks: {
        'sample-restart': QuizBank(
          metadata: QuizBankMetadata(
            id: 'sample-restart',
            code: 'SAMPLE-R',
            title: 'Sample Restart',
            description: 'Practice bank',
            questionCount: 4,
            sourceQuestionCount: 4,
            skippedQuestionCount: 0,
            accentColor: 0xff123456,
            assetPath: 'assets/quiz/banks/sample-restart.json',
          ),
          questions: _sampleQuestions(4),
        ),
      },
    );
    final container = ProviderContainer(
      overrides: [
        quizRepositoryProvider.overrideWithValue(repository),
        quizControllerProvider.overrideWith(
          () => QuizController(repository: repository),
        ),
      ],
    );
    addTearDown(container.dispose);

    final catalog = await container.read(quizCatalogProvider.future);
    final controller = container.read(quizControllerProvider.notifier);
    await controller.startQuiz(catalog.single, questionCount: 2, setNumber: 3);

    _answerCurrentQuestion(controller);
    expect(controller.state.session!.answeredCount, 1);

    await controller.restartSession();

    expect(controller.state.session, isNotNull);
    expect(controller.state.session!.questionCount, 2);
    expect(controller.state.session!.practiceSetNumber, 3);
    expect(controller.state.session!.currentIndex, 0);
    expect(controller.state.session!.answeredCount, 0);
    expect(controller.state.isStarting, isFalse);
  });
}

void _answerCurrentQuestion(QuizController controller) {
  final session = controller.state.session;
  expect(session, isNotNull);
  final question = session!.currentQuestion;
  for (final index in question.correctOptionIndices) {
    controller.selectOption(index);
  }
  controller.submitCurrentAnswer();
}

final class FakeQuizRepository implements QuizRepository {
  FakeQuizRepository({required this.catalog, required this.banks});

  final List<QuizBankMetadata> catalog;
  final Map<String, QuizBank> banks;

  @override
  Future<List<QuizBankMetadata>> loadCatalog() async => catalog;

  @override
  Future<QuizBank> loadBank(QuizBankMetadata metadata) async {
    final bank = banks[metadata.id];
    if (bank == null) {
      throw StateError('Missing fake quiz bank: ${metadata.id}');
    }
    return bank;
  }
}

final class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient(this._handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest request)
  _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _handler(request);
  }
}

List<QuizQuestion> _sampleQuestions(int count) {
  return List<QuizQuestion>.generate(
    count,
    (index) => QuizQuestion(
      sourceId: index,
      question: 'Question ${index + 1}?',
      options: const ['A', 'B', 'C', 'D'],
      correctOptionIndices: const {0},
      explanation: 'Reason ${index + 1}',
    ),
    growable: false,
  );
}
