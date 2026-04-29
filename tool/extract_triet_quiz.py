#!/usr/bin/env python3
"""Extract the Triet quiz bank directly from the PDF source.

This script replaces the older file2quiz-based preprocessing flow for the
Triet bank. It reads the PDF with PyMuPDF, splits chapter/question/answer
sections, applies a small targeted override for one malformed question, and
writes both an intermediate JSON dataset and the app-facing data-quiz source.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata as ud
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable

try:
    import fitz  # type: ignore
except ImportError as exc:  # pragma: no cover - import error is environment-specific.
    raise SystemExit(
        'PyMuPDF is required for this extractor. Install the "pymupdf" package first.'
    ) from exc


QUESTION_START_RE = re.compile(r'^Câu\s*(\d+)\s*[:\.\)]?\s*(.*)$', re.IGNORECASE)
OPTION_LABEL_RE = re.compile(r'^([ABCD])\s*[\.)]\s*(.*)$', re.IGNORECASE)
BULLET_RE = re.compile(r'^[\u2022\u25cf\u2219\uf0b7\-]\s*(.*)$')
ANSWER_RE = re.compile(r'CAU\s*(\d+)\s*([ABCD])', re.IGNORECASE)

NOISE_MARKERS = (
    'messages.downloaded_by',
    'messages.pdf_cover_qr_code_label',
    'messages.studocu_not_sponsored_or_endorsed_by_college',
)

INLINE_NOISE_PATTERNS = (
    re.compile(r'messages\.[A-Za-z0-9_]+', re.IGNORECASE),
    re.compile(r'lOMoARcPSD(?:\|\d+)?', re.IGNORECASE),
)

MANUAL_OVERRIDES = {
    (3, 79): {
        'stem': (
            'Chọn phương án đúng nhất để điền từ thích hợp vào chỗ trống: '
            'Quan hệ sở hữu về …… là quan hệ giữa các tập đoàn người trong việc '
            'chiếm hữu, sử dụng các tư liệu sản xuất xã hội'
        ),
        'options': [
            'Tư liệu sinh hoạt',
            'Tư liệu sản xuất',
            'Tư liệu tiêu dùng',
            'Không có đáp án đúng',
        ],
    },
}

DEFAULT_PDF_NAME = 'ngan-hang-cau-hoi-trac-nghiem-triet-hoc-mac-lenin-511-cau-2023.pdf'


@dataclass
class Line:
    text: str
    bold: bool


@dataclass
class ChapterSection:
    question_lines: list[Line] = field(default_factory=list)
    answer_lines: list[str] = field(default_factory=list)


@dataclass
class QuestionDraft:
    number: int
    stem_parts: list[str] = field(default_factory=list)
    option_parts: list[list[str]] = field(default_factory=list)


def configure_stdio() -> None:
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8')
    if hasattr(sys.stderr, 'reconfigure'):
        sys.stderr.reconfigure(encoding='utf-8')


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def locate_triet_folder(root: Path) -> Path:
    for path in root.iterdir():
        if path.is_dir() and path.name.startswith('Tri'):
            return path

    raise FileNotFoundError('Could not locate the Triet source folder.')


def default_pdf_path() -> Path:
    return locate_triet_folder(repo_root()) / DEFAULT_PDF_NAME


def strip_accents(text: str) -> str:
    normalized = ud.normalize('NFKD', text)
    normalized = normalized.replace('\u0110', 'D').replace('\u0111', 'd')
    return ''.join(char for char in normalized if not ud.combining(char))


def canonical(text: str) -> str:
    return re.sub(r'\s+', ' ', strip_accents(text)).upper().strip()


def remove_inline_noise(text: str) -> str:
    cleaned = text
    for pattern in INLINE_NOISE_PATTERNS:
        cleaned = pattern.sub('', cleaned)
    return cleaned


def clean_text(text: str) -> str:
    cleaned = text.replace('\xa0', ' ').replace('\u200b', '').replace('\u00ad', '')
    cleaned = remove_inline_noise(cleaned)
    cleaned = re.sub(r'\s+', ' ', cleaned)
    cleaned = re.sub(r'\s+([,.;:!?])', r'\1', cleaned)
    return ud.normalize('NFC', cleaned).strip()


def is_noise_line(text: str) -> bool:
    lowered = text.lower()
    return any(marker in lowered for marker in NOISE_MARKERS)


def is_bold_span(span: dict) -> bool:
    font = str(span.get('font', ''))
    flags = int(span.get('flags', 0) or 0)
    return 'bold' in font.lower() or bool(flags & 16)


def iter_page_lines(page: fitz.Page) -> Iterable[Line]:
    page_dict = page.get_text('dict')
    for block in page_dict.get('blocks', []):
        if block.get('type') != 0:
            continue

        for line in block.get('lines', []):
            parts: list[str] = []
            bold = False
            for span in line.get('spans', []):
                text = str(span.get('text', ''))
                if not text:
                    continue
                parts.append(text)
                if is_bold_span(span):
                    bold = True

            text = clean_text(''.join(parts))
            if text:
                yield Line(text=text, bold=bold)


def extract_sections(doc: fitz.Document) -> dict[int, ChapterSection]:
    sections = {1: ChapterSection(), 2: ChapterSection(), 3: ChapterSection()}
    current_chapter = 1
    mode = 'question'

    for page in doc:
        for line in iter_page_lines(page):
            if is_noise_line(line.text):
                continue

            normalized = canonical(line.text)

            if normalized.startswith('GOI Y DAP AN'):
                mode = 'answer'
                continue

            chapter_match = re.search(r'CHUONG\s*([123])', normalized)
            if chapter_match:
                current_chapter = int(chapter_match.group(1))
                mode = 'question'
                continue

            if mode == 'question':
                sections[current_chapter].question_lines.append(line)
            else:
                sections[current_chapter].answer_lines.append(line.text)

    return sections


def collapse_text(parts: Iterable[str]) -> str:
    text = ' '.join(part for part in parts if part)
    text = clean_text(text)
    return text.strip(' -–—')


def parse_questions(lines: list[Line], chapter: int) -> list[dict]:
    questions: list[dict] = []
    current: QuestionDraft | None = None
    current_option_index: int | None = None

    def finalize(draft: QuestionDraft) -> dict:
        stem = collapse_text(draft.stem_parts)
        options: list[str] = []

        for option_parts in draft.option_parts:
            option_text = collapse_text(option_parts)
            option_text = re.sub(
                r'^[\u2022\u25cf\u2219\uf0b7\-\s]+',
                '',
                option_text,
            ).strip()
            if option_text and option_text != '•':
                options.append(option_text)

        override = MANUAL_OVERRIDES.get((chapter, draft.number))
        if override is not None:
            stem = override.get('stem', stem)
            options = list(override.get('options', options))

        return {
            'chapter': chapter,
            'number': draft.number,
            'stem': stem,
            'options': options,
        }

    for line in lines:
        question_match = QUESTION_START_RE.match(line.text)
        if line.bold and question_match is not None:
            if current is not None:
                questions.append(finalize(current))

            current = QuestionDraft(number=int(question_match.group(1)))
            if question_match.group(2):
                current.stem_parts.append(question_match.group(2))
            current_option_index = None
            continue

        if current is None:
            continue

        if line.bold:
            current.stem_parts.append(line.text)
            continue

        option_match = OPTION_LABEL_RE.match(line.text)
        if option_match is not None:
            current_option_index = len(current.option_parts)
            current.option_parts.append([option_match.group(2) or ''])
            continue

        bullet_match = BULLET_RE.match(line.text)
        if bullet_match is not None:
            current_option_index = len(current.option_parts)
            current.option_parts.append([bullet_match.group(1) or ''])
            continue

        if current_option_index is not None:
            current.option_parts[current_option_index].append(line.text)
        else:
            current.stem_parts.append(line.text)

    if current is not None:
        questions.append(finalize(current))

    return questions


def parse_answers(answer_lines: list[str]) -> dict[int, str]:
    answer_text = canonical(' '.join(answer_lines))
    pairs = ANSWER_RE.findall(answer_text)
    return {int(number): letter.upper() for number, letter in pairs}


def build_source_questions(
    chapter_questions: dict[int, list[dict]],
    answer_maps: dict[int, dict[int, str]],
) -> tuple[list[dict], dict]:
    bank_questions: list[dict] = []
    chapter_summaries: list[dict] = []
    warnings: list[str] = []
    source_id = 1

    for chapter in (1, 2, 3):
        questions = chapter_questions[chapter]
        answers = answer_maps[chapter]
        chapter_missing = []
        chapter_playable = 0

        for question in questions:
            answer_letter = answers.get(question['number'])
            correct_answer = None
            if answer_letter is not None:
                index = 'ABCD'.find(answer_letter)
                if index >= 0:
                    if index < len(question['options']):
                        correct_answer = index
                        chapter_playable += 1
                    else:
                        warnings.append(
                            f'Chapter {chapter} question {question["number"]} has an out-of-range answer.'
                        )
                else:
                    warnings.append(
                        f'Chapter {chapter} question {question["number"]} has an invalid answer letter.'
                    )

            if answer_letter is None:
                chapter_missing.append(question['number'])

            bank_questions.append(
                {
                    'chapter': chapter,
                    'number': question['number'],
                    'id': source_id,
                    'question': question['stem'],
                    'options': question['options'],
                    'answerLetter': answer_letter,
                    'correctAnswer': correct_answer,
                }
            )
            source_id += 1

        chapter_summaries.append(
            {
                'chapter': chapter,
                'questionCount': len(questions),
                'answerCount': len(answers),
                'playableCount': chapter_playable,
                'missingAnswers': chapter_missing,
            }
        )

    report = {
        'chapters': chapter_summaries,
        'totals': {
            'questionCount': len(bank_questions),
            'playableCount': sum(1 for question in bank_questions if question['correctAnswer'] is not None),
            'answerCount': sum(1 for answers in answer_maps.values() for _ in answers),
        },
        'manualOverrides': [
            {'chapter': chapter, 'number': number}
            for chapter, number in sorted(MANUAL_OVERRIDES)
        ],
        'warnings': warnings,
    }

    return bank_questions, report


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding='utf-8')


def write_json(path: Path, data: object) -> None:
    write_text(path, f'{json.dumps(data, ensure_ascii=False, indent=2)}\n')


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description='Extract the Triet quiz bank from the PDF source.',
    )
    parser.add_argument(
        '--pdf',
        type=Path,
        default=default_pdf_path(),
        help='Path to the Triet PDF file.',
    )
    parser.add_argument(
        '--output-bank',
        type=Path,
        default=repo_root() / 'data-quiz' / 'TRIET' / 'Quiz1.js',
        help='Destination data-quiz source file.',
    )
    parser.add_argument(
        '--output-preprocessed-dir',
        type=Path,
        default=repo_root() / 'preprocessed' / 'triet',
        help='Directory for intermediate JSON outputs.',
    )
    return parser


def main() -> int:
    configure_stdio()
    parser = build_parser()
    args = parser.parse_args()

    pdf_path = args.pdf.expanduser().resolve()
    if not pdf_path.exists():
        parser.error(f'PDF file does not exist: {pdf_path}')

    output_bank = args.output_bank.expanduser().resolve()
    output_preprocessed_dir = args.output_preprocessed_dir.expanduser().resolve()

    doc = fitz.open(pdf_path)
    sections = extract_sections(doc)

    chapter_questions = {
        chapter: parse_questions(section.question_lines, chapter)
        for chapter, section in sections.items()
    }
    answer_maps = {
        chapter: parse_answers(section.answer_lines)
        for chapter, section in sections.items()
    }

    source_questions, report = build_source_questions(chapter_questions, answer_maps)

    # Intermediate JSON for inspection and future reuse.
    intermediate_questions = [
        {
            'chapter': item['chapter'],
            'number': item['number'],
            'question': item['question'],
            'options': item['options'],
            'answerLetter': item['answerLetter'],
            'correctAnswer': item['correctAnswer'],
        }
        for item in source_questions
    ]
    write_json(output_preprocessed_dir / 'questions.json', intermediate_questions)
    write_json(output_preprocessed_dir / 'report.json', report)

    # App-facing source file.
    quiz_source = 'export const sampleQuestions = ' + json.dumps(
        [
            {
                'id': item['id'],
                'question': item['question'],
                'options': item['options'],
                'correctAnswer': item['correctAnswer'],
            }
            for item in source_questions
        ],
        ensure_ascii=False,
        indent=2,
    ) + ';\n'
    write_text(output_bank, quiz_source)

    print(
        f'Wrote {len(source_questions)} source questions to {output_bank} '
        f'and {output_preprocessed_dir}'
    )
    for chapter_summary in report['chapters']:
        print(
            f"Chapter {chapter_summary['chapter']}: "
            f"{chapter_summary['questionCount']} questions, "
            f"{chapter_summary['answerCount']} answers, "
            f"{chapter_summary['playableCount']} playable"
        )

    print(
        f"Totals: {report['totals']['questionCount']} questions, "
        f"{report['totals']['playableCount']} playable"
    )

    if report['warnings']:
        print('Warnings:')
        for warning in report['warnings']:
            print(f'- {warning}')

    return 0


if __name__ == '__main__':
    raise SystemExit(main())
