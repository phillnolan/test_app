import { fileURLToPath } from 'node:url';
import fs from 'node:fs/promises';
import path from 'node:path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, '..');

const sourceRoot = path.join(repoRoot, 'data-quiz');
const outputRoot = path.join(repoRoot, 'assets', 'quiz');
const bankOutputRoot = path.join(outputRoot, 'banks');

const banks = [
  {
    id: 'cnpm',
    folder: 'CNPM',
    code: 'CNPM',
    title: 'Công nghệ phần mềm',
    description:
      'Ôn luyện quy trình phát triển, thiết kế, kiểm thử và quản lý phần mềm.',
    accentColor: 0xfff59e0b,
  },
  {
    id: 'lsd',
    folder: 'LSD',
    code: 'LSD',
    title: 'Lịch sử Đảng',
    description:
      'Câu hỏi tổng hợp về lịch sử, đại hội và các mốc phát triển của Đảng.',
    accentColor: 0xffef4444,
  },
  {
    id: 'mmt',
    folder: 'MMT',
    code: 'MMT',
    title: 'Mạng máy tính',
    description:
      'Ôn tập kiến thức mạng, giao thức và hạ tầng truyền thông số.',
    accentColor: 0xff0ea5e9,
  },
  {
    id: 'tthcm',
    folder: 'TTHCM',
    code: 'TTHCM',
    title: 'Tư tưởng Hồ Chí Minh',
    description:
      'Ngân hàng câu hỏi về tư tưởng, quan điểm và nền tảng lý luận.',
    accentColor: 0xff10b981,
  },
  {
    id: 'ttnt',
    folder: 'TTNT',
    code: 'TTNT',
    title: 'Trí tuệ nhân tạo',
    description:
      'Kiến thức nhập môn về AI, suy luận và xử lý thông minh.',
    accentColor: 0xff06b6d4,
  },
];

function parseQuestions(sourceText, sourceFile) {
  const prefix = 'export const sampleQuestions =';
  const prefixIndex = sourceText.indexOf(prefix);
  const endIndex = sourceText.lastIndexOf(']');

  if (prefixIndex < 0 || endIndex < 0 || endIndex <= prefixIndex) {
    throw new Error(`Could not parse quiz source file: ${sourceFile}`);
  }

  const arraySource = sourceText
    .slice(prefixIndex + prefix.length, endIndex + 1)
    .trim();
  const evaluate = new Function(`"use strict"; return (${arraySource});`);
  const questions = evaluate();
  if (!Array.isArray(questions)) {
    throw new Error(`Quiz source did not return an array: ${sourceFile}`);
  }

  const sourceQuestionCount = questions.length;
  const playableQuestions = questions
    .map((question) => normalizeQuestion(question, sourceFile))
    .filter((question) => question !== null);

  return {
    sourceQuestionCount,
    playableQuestions,
  };
}

function normalizeQuestion(question, sourceFile) {
  if (typeof question !== 'object' || question === null) {
    throw new Error(`Invalid question entry in ${sourceFile}`);
  }

  const correctAnswer = question.correctAnswer;
  if (correctAnswer == null) {
    return null;
  }

  const correctAnswerIndices = Array.isArray(correctAnswer)
    ? correctAnswer.map((value) => normalizeIndex(value, sourceFile))
    : [normalizeIndex(correctAnswer, sourceFile)];

  return {
    id: question.id,
    question: question.question,
    options: question.options,
    correctAnswerIndices,
    explanation: question.explanation ?? '',
  };
}

function normalizeIndex(value, sourceFile) {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value;
  }

  throw new Error(`Invalid correct answer index in ${sourceFile}`);
}

function sortQuizFiles(fileNames) {
  return [...fileNames].sort((left, right) => {
    const leftMatch = left.match(/Quiz(\d+)\.js$/);
    const rightMatch = right.match(/Quiz(\d+)\.js$/);
    const leftNumber = leftMatch ? Number(leftMatch[1]) : Number.MAX_SAFE_INTEGER;
    const rightNumber = rightMatch ? Number(rightMatch[1]) : Number.MAX_SAFE_INTEGER;

    if (leftNumber !== rightNumber) {
      return leftNumber - rightNumber;
    }

    return left.localeCompare(right);
  });
}

async function main() {
  await fs.mkdir(bankOutputRoot, { recursive: true });

  const manifest = {
    banks: [],
  };

  for (const bank of banks) {
    const sourceFolder = path.join(sourceRoot, bank.folder);
    const fileNames = sortQuizFiles(
      (await fs.readdir(sourceFolder)).filter((file) => file.endsWith('.js')),
    );

    const questions = [];
    let sourceQuestionCount = 0;
    for (const fileName of fileNames) {
      const sourceFile = path.join(sourceFolder, fileName);
      const sourceText = await fs.readFile(sourceFile, 'utf8');
      const parsed = parseQuestions(sourceText, sourceFile);
      sourceQuestionCount += parsed.sourceQuestionCount;
      questions.push(...parsed.playableQuestions);
    }

    const assetPath = path.posix.join('assets', 'quiz', 'banks', `${bank.id}.json`);
    const outputFile = path.join(bankOutputRoot, `${bank.id}.json`);

    await fs.writeFile(outputFile, `${JSON.stringify(questions, null, 2)}\n`, 'utf8');

    manifest.banks.push({
      id: bank.id,
      code: bank.code,
      title: bank.title,
      description: bank.description,
      questionCount: questions.length,
      sourceQuestionCount,
      skippedQuestionCount: sourceQuestionCount - questions.length,
      accentColor: bank.accentColor,
      assetPath,
    });
  }

  const manifestFile = path.join(outputRoot, 'quiz_manifest.json');
  await fs.writeFile(
    manifestFile,
    `${JSON.stringify(manifest, null, 2)}\n`,
    'utf8',
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
