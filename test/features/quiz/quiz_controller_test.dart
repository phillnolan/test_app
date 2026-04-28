import 'dart:math';

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

    expect(catalog, hasLength(5));
    expect(catalog.any((bank) => bank.id == 'mmt'), isTrue);
    expect(
      catalog.firstWhere((bank) => bank.id == 'mmt').skippedQuestionCount,
      greaterThan(0),
    );
  });

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
          () => QuizController(repository: repository, random: Random(0)),
        ),
      ],
    );
    addTearDown(container.dispose);

    final catalog = await container.read(quizCatalogProvider.future);
    expect(catalog, hasLength(1));
    expect(catalog.single.title, 'Sample Bank');

    final controller = container.read(quizControllerProvider.notifier);
    await controller.startQuiz(catalog.single, questionCount: 2);
    expect(controller.state.session, isNotNull);
    expect(controller.state.session!.questionCount, 2);

    _answerCurrentQuestion(controller);
    controller.goToNextQuestion();
    _answerCurrentQuestion(controller);

    expect(controller.state.session!.isCompleted, isTrue);
    expect(controller.state.session!.correctCount, 2);
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
