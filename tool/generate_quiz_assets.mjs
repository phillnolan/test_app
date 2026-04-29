import { fileURLToPath } from 'node:url';
import fs from 'node:fs/promises';
import path from 'node:path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, '..');

const sourceRoot = path.join(repoRoot, 'data-quiz');
const outputRoot = path.join(repoRoot, 'assets', 'quiz');
const bankOutputRoot = path.join(outputRoot, 'banks');

const fallbackAccentColors = [
  0xfff59e0b,
  0xffef4444,
  0xff0ea5e9,
  0xff10b981,
  0xff06b6d4,
  0xff8b5cf6,
  0xfff97316,
  0xff14b8a6,
];

async function main() {
  await fs.mkdir(bankOutputRoot, { recursive: true });

  const bankFolders = await discoverBankFolders(sourceRoot);
  const manifest = { banks: [] };

  for (const folderName of bankFolders) {
    const sourceFolder = path.join(sourceRoot, folderName);
    const metadata = await loadBankMetadata(sourceFolder, folderName);
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

    const assetPath = path.posix.join(
      'assets',
      'quiz',
      'banks',
      `${metadata.id}.json`,
    );
    const outputFile = path.join(bankOutputRoot, `${metadata.id}.json`);

    await fs.writeFile(
      outputFile,
      `${JSON.stringify(questions, null, 2)}\n`,
      'utf8',
    );

    manifest.banks.push({
      id: metadata.id,
      code: metadata.code,
      title: metadata.title,
      description: metadata.description,
      questionCount: questions.length,
      sourceQuestionCount,
      skippedQuestionCount: sourceQuestionCount - questions.length,
      accentColor: metadata.accentColor,
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

async function discoverBankFolders(root) {
  const entries = await fs.readdir(root, { withFileTypes: true });
  return entries
    .filter((entry) => entry.isDirectory() && !entry.name.startsWith('.'))
    .map((entry) => entry.name)
    .sort((left, right) => left.localeCompare(right));
}

async function loadBankMetadata(sourceFolder, folderName) {
  const metadataPath = path.join(sourceFolder, 'bank.json');
  try {
    const rawMetadata = await fs.readFile(metadataPath, 'utf8');
    const decodedMetadata = JSON.parse(rawMetadata);
    return normalizeBankMetadata(decodedMetadata, folderName);
  } catch (error) {
    if (
      error &&
      typeof error === 'object' &&
      'code' in error &&
      error.code === 'ENOENT'
    ) {
      return buildDefaultBankMetadata(folderName);
    }
    throw error;
  }
}

function normalizeBankMetadata(rawMetadata, folderName) {
  if (
    rawMetadata === null ||
    typeof rawMetadata !== 'object' ||
    Array.isArray(rawMetadata)
  ) {
    throw new Error(`Quiz bank metadata must be a JSON object: ${folderName}`);
  }

  const fallback = buildDefaultBankMetadata(folderName);

  return {
    id: normalizeText(rawMetadata.id) ?? fallback.id,
    code: normalizeText(rawMetadata.code) ?? fallback.code,
    title: normalizeText(rawMetadata.title) ?? fallback.title,
    description: normalizeText(rawMetadata.description) ?? fallback.description,
    accentColor: parseAccentColor(rawMetadata.accentColor, fallback.accentColor),
  };
}

function buildDefaultBankMetadata(folderName) {
  const title = prettifyBankTitle(folderName);
  return {
    id: normalizeBankId(folderName),
    code: deriveBankCode(folderName),
    title,
    description: `On luyen bo cau hoi ${title}.`,
    accentColor: pickAccentColor(folderName),
  };
}

function normalizeText(value) {
  if (typeof value !== 'string') {
    return null;
  }

  const trimmed = value.trim();
  return trimmed.length === 0 ? null : trimmed;
}

function normalizeBankId(folderName) {
  const normalized = folderName
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
  return normalized.length === 0 ? 'quiz-bank' : normalized;
}

function deriveBankCode(folderName) {
  const words = folderName
    .trim()
    .split(/[^A-Za-z0-9]+/)
    .filter(Boolean);

  if (words.length === 0) {
    return 'QUIZ';
  }

  if (words.length === 1) {
    const word = words[0];
    if (/^[A-Z0-9]+$/.test(word)) {
      return word;
    }

    return word.replace(/[^A-Za-z0-9]/g, '').toUpperCase();
  }

  return words.map((word) => word[0]).join('').toUpperCase();
}

function prettifyBankTitle(folderName) {
  const trimmed = folderName.trim();
  if (/^[A-Z0-9]+$/.test(trimmed)) {
    return trimmed;
  }

  return trimmed
    .replace(/[_-]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
    .split(' ')
    .map((part) => {
      if (/^[A-Z0-9]+$/.test(part)) {
        return part;
      }

      return `${part[0].toUpperCase()}${part.slice(1).toLowerCase()}`;
    })
    .join(' ');
}

function pickAccentColor(value) {
  const hash = hashString(value);
  return fallbackAccentColors[hash % fallbackAccentColors.length];
}

function hashString(value) {
  let hash = 0;
  for (const char of value) {
    hash = (hash * 31 + char.charCodeAt(0)) >>> 0;
  }
  return hash;
}

function parseAccentColor(value, fallback) {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value >>> 0;
  }

  if (typeof value === 'string') {
    const trimmed = value.trim();
    if (trimmed.length > 0) {
      if (/^\d+$/.test(trimmed)) {
        return Number(trimmed) >>> 0;
      }

      const normalized = trimmed.startsWith('#')
        ? trimmed.slice(1)
        : trimmed.startsWith('0x') || trimmed.startsWith('0X')
          ? trimmed.slice(2)
          : trimmed;
      const parsed = Number.parseInt(normalized, 16);
      if (Number.isFinite(parsed)) {
        return parsed >>> 0;
      }
    }
  }

  return fallback >>> 0;
}

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

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
