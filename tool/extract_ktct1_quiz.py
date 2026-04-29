#!/usr/bin/env python3
"""Extract the KTCT1 quiz bank directly from the PDF source.

The PDF uses plain text for questions and options, while the correct answer is
marked by a yellow background fill in the page content stream. Red pen marks are
embedded as ink annotations and are ignored.

This script parses the PDF with PyMuPDF, keeps question state across pages,
scores each option by overlap with yellow highlight rectangles, and writes both
intermediate JSON outputs and the app-facing data-quiz source files.
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
except ImportError as exc:  # pragma: no cover - environment-specific.
    raise SystemExit(
        'PyMuPDF is required for this extractor. Install the "pymupdf" package first.'
    ) from exc


QUESTION_RE = re.compile(r'^(CAU|BAI)\s*(\d+)\s*[:\.\)]?\s*(.*)$', re.IGNORECASE)
OPTION_RE = re.compile(r'^([ABCDEF])\s*[:\.)]\s*(.*)$', re.IGNORECASE)

NOISE_MARKERS = (
    'downloaded by',
    'lOMoARcPSD'.lower(),
    'messages.',
    'scan to open on studeersnel',
    'studeersnel',
    'studocu is not sponsored or endorsed by any college or university',
    'dit document is beschikbaar op',
)

INLINE_NOISE_PATTERNS = (
    re.compile(r'\s*lOMoARcPSD(?:\|\d+)?\s*', re.IGNORECASE),
    re.compile(r'\s*Downloaded by[^\n]*', re.IGNORECASE),
    re.compile(r'\s*Dit document is beschikbaar op[^\n]*', re.IGNORECASE),
    re.compile(r'\s*Scan to open on Studeersnel\s*', re.IGNORECASE),
    re.compile(
        r'\s*Studocu is not sponsored or endorsed by any college or university\s*',
        re.IGNORECASE,
    ),
)

DEFAULT_PDF_NAME = 'KTCT1.pdf'
BANK_METADATA = {
    'id': 'ktct1',
    'code': 'KTCT1',
    'title': 'KTCT 1',
    'description': 'Đề thi cuối kì kinh tế chính trị Mác - Lênin (KTCT1).',
    'accent_color': 0xFF0EA5E9,
    'folder_name': 'KTCT1',
    'preprocessed_dir_name': 'ktct1',
}


@dataclass
class TextLine:
    text: str
    canon: str
    bbox: tuple[float, float, float, float]
    page_index: int


@dataclass
class LinePlacement:
    page_index: int
    bbox: tuple[float, float, float, float]


@dataclass
class OptionDraft:
    label: str
    parts: list[str] = field(default_factory=list)
    placements: list[LinePlacement] = field(default_factory=list)


@dataclass
class QuestionDraft:
    number: int
    label_type: str
    stem_parts: list[str] = field(default_factory=list)
    options: list[OptionDraft] = field(default_factory=list)


def configure_stdio() -> None:
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8')
    if hasattr(sys.stderr, 'reconfigure'):
        sys.stderr.reconfigure(encoding='utf-8')


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def locate_ktct_folder(root: Path) -> Path:
    direct = root / 'KTCT'
    if direct.is_dir():
        return direct

    for path in root.iterdir():
        if path.is_dir() and path.name.upper().startswith('KTCT'):
            return path

    raise FileNotFoundError('Could not locate the KTCT source folder.')


def default_pdf_path() -> Path:
    return locate_ktct_folder(repo_root()) / DEFAULT_PDF_NAME


def strip_accents(text: str) -> str:
    normalized = ud.normalize('NFKD', text)
    normalized = normalized.replace('\u0110', 'D').replace('\u0111', 'd')
    return ''.join(char for char in normalized if not ud.combining(char))


def canonical(text: str) -> str:
    return re.sub(r'\s+', ' ', strip_accents(text)).upper().strip()


def remove_inline_noise(text: str) -> str:
    cleaned = text
    for pattern in INLINE_NOISE_PATTERNS:
        cleaned = pattern.sub(' ', cleaned)
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


def iter_page_lines(page: fitz.Page, page_index: int) -> Iterable[TextLine]:
    page_dict = page.get_text('dict')
    for block in page_dict.get('blocks', []):
        if block.get('type') != 0:
            continue

        for line in block.get('lines', []):
            parts: list[str] = []
            for span in line.get('spans', []):
                text = str(span.get('text', ''))
                if text:
                    parts.append(text)

            text = clean_text(''.join(parts))
            if not text:
                continue

            yield TextLine(
                text=text,
                canon=canonical(text),
                bbox=tuple(float(value) for value in line['bbox']),
                page_index=page_index,
            )


def page_highlight_rects(page: fitz.Page) -> list[tuple[float, float, float, float]]:
    rects: list[tuple[float, float, float, float]] = []
    for drawing in page.get_drawings():
        if drawing.get('fill') != (1.0, 1.0, 0.0):
            continue

        rect = drawing.get('rect')
        if rect is None:
            continue

        rects.append(tuple(float(value) for value in rect))

    return rects


def extract_questions(
    doc: fitz.Document,
) -> tuple[list[QuestionDraft], list[list[tuple[float, float, float, float]]]]:
    questions: list[QuestionDraft] = []
    page_highlights: list[list[tuple[float, float, float, float]]] = []
    current: QuestionDraft | None = None
    current_option: OptionDraft | None = None

    for page_index, page in enumerate(doc):
        page_highlights.append(page_highlight_rects(page))

        for line in iter_page_lines(page, page_index):
            if is_noise_line(line.text):
                continue

            question_match = QUESTION_RE.match(line.canon)
            if question_match is not None:
                if current is not None:
                    questions.append(current)

                current = QuestionDraft(
                    number=int(question_match.group(2)),
                    label_type=question_match.group(1).upper(),
                )
                if question_match.group(3):
                    current.stem_parts.append(question_match.group(3))
                current_option = None
                continue

            if current is None:
                continue

            option_match = OPTION_RE.match(line.canon)
            if option_match is not None:
                current_option = OptionDraft(
                    label=option_match.group(1).upper(),
                    parts=[option_match.group(2)] if option_match.group(2) else [],
                    placements=[LinePlacement(page_index=line.page_index, bbox=line.bbox)],
                )
                current.options.append(current_option)
                continue

            if current_option is not None:
                current_option.parts.append(line.text)
                current_option.placements.append(
                    LinePlacement(page_index=line.page_index, bbox=line.bbox)
                )
            else:
                current.stem_parts.append(line.text)

    if current is not None:
        questions.append(current)

    return questions, page_highlights


def collapse_text(parts: Iterable[str]) -> str:
    text = ' '.join(part for part in parts if part)
    text = clean_text(text)
    return text.strip(' -–—')


def rect_overlap(a: tuple[float, float, float, float], b: tuple[float, float, float, float]) -> float:
    x0 = max(a[0], b[0])
    y0 = max(a[1], b[1])
    x1 = min(a[2], b[2])
    y1 = min(a[3], b[3])
    if x1 <= x0 or y1 <= y0:
        return 0.0
    return (x1 - x0) * (y1 - y0)


def resolve_question_answer(
    question: QuestionDraft,
    page_highlights: list[list[tuple[float, float, float, float]]],
) -> tuple[int | None, str | None, list[tuple[str, float]]]:
    scores: list[tuple[str, float]] = []
    for option in question.options:
        score = 0.0
        for placement in option.placements:
            score += sum(
                rect_overlap(placement.bbox, highlight)
                for highlight in page_highlights[placement.page_index]
            )
        scores.append((option.label, score))

    scores.sort(key=lambda item: item[1], reverse=True)
    if not scores or scores[0][1] <= 0:
        return None, None, scores

    top_score = scores[0][1]
    tied = [item for item in scores if abs(item[1] - top_score) < 1e-6]
    if len(tied) != 1:
        return None, None, scores

    return 'ABCDEF'.index(scores[0][0]), scores[0][0], scores


def question_to_dict(
    question: QuestionDraft,
    correct_answer: int | None,
    answer_letter: str | None,
) -> dict:
    return {
        'id': question.number,
        'question': collapse_text(question.stem_parts),
        'options': [
            collapse_text(option.parts)
            for option in question.options
        ],
        'answerLetter': answer_letter,
        'correctAnswer': correct_answer,
    }


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding='utf-8')


def write_json(path: Path, data: object) -> None:
    write_text(path, f'{json.dumps(data, ensure_ascii=False, indent=2)}\n')


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description='Extract the KTCT1 quiz bank from the PDF source.',
    )
    parser.add_argument(
        '--pdf',
        type=Path,
        default=default_pdf_path(),
        help='Path to the KTCT1 PDF file.',
    )
    parser.add_argument(
        '--output-bank',
        type=Path,
        default=repo_root() / 'data-quiz' / BANK_METADATA['folder_name'] / 'Quiz1.js',
        help='Destination data-quiz source file.',
    )
    parser.add_argument(
        '--output-preprocessed-dir',
        type=Path,
        default=repo_root() / 'preprocessed' / BANK_METADATA['preprocessed_dir_name'],
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
    output_bank_dir = output_bank.parent

    with fitz.open(pdf_path) as doc:
        question_drafts, page_highlights = extract_questions(doc)

    source_questions: list[dict] = []
    report_questions: list[dict] = []
    unresolved_questions: list[int] = []
    empty_option_questions: list[int] = []
    warnings: list[str] = []
    seen_numbers = {question.number for question in question_drafts}
    max_number = max(seen_numbers) if seen_numbers else 0
    missing_question_numbers = [
        number for number in range(1, max_number + 1) if number not in seen_numbers
    ]

    for question in question_drafts:
        correct_answer, answer_letter, scores = resolve_question_answer(
            question,
            page_highlights,
        )

        if correct_answer is None:
            unresolved_questions.append(question.number)
            if question.options:
                warnings.append(
                    f'Question {question.number} has no unique highlighted answer.'
                )
            else:
                empty_option_questions.append(question.number)
                warnings.append(
                    f'Question {question.number} has no options extracted.'
                )

        report_questions.append(
            {
                'number': question.number,
                'labelType': question.label_type,
                'question': collapse_text(question.stem_parts),
                'optionCount': len(question.options),
                'answerLetter': answer_letter,
                'correctAnswer': correct_answer,
                'scores': scores,
            }
        )

        source_questions.append(
            question_to_dict(question, correct_answer, answer_letter)
        )

    playable_count = sum(
        1 for question in source_questions if question['correctAnswer'] is not None
    )

    report = {
        'bankId': BANK_METADATA['id'],
        'pdfFile': pdf_path.name,
        'questionCount': len(question_drafts),
        'playableCount': playable_count,
        'missingQuestionNumbers': missing_question_numbers,
        'unresolvedQuestions': unresolved_questions,
        'emptyOptionQuestions': sorted(set(empty_option_questions)),
        'warnings': warnings,
    }

    write_json(output_preprocessed_dir / 'questions.json', report_questions)
    write_json(output_preprocessed_dir / 'report.json', report)

    write_json(
        output_bank_dir / 'bank.json',
        {
            'id': BANK_METADATA['id'],
            'code': BANK_METADATA['code'],
            'title': BANK_METADATA['title'],
            'description': BANK_METADATA['description'],
            'accentColor': BANK_METADATA['accent_color'],
        },
    )

    quiz_source = 'export const sampleQuestions = ' + json.dumps(
        [
            {
                'id': question['id'],
                'question': question['question'],
                'options': question['options'],
                'correctAnswer': question['correctAnswer'],
            }
            for question in source_questions
        ],
        ensure_ascii=False,
        indent=2,
    ) + ';\n'
    write_text(output_bank, quiz_source)

    print(
        f'Wrote {len(source_questions)} source questions to {output_bank} '
        f'and {output_preprocessed_dir}'
    )
    print(
        f"Totals: {report['questionCount']} source questions, "
        f"{report['playableCount']} playable"
    )

    if missing_question_numbers:
        print(f"Missing question numbers in the source text: {missing_question_numbers}")

    if unresolved_questions:
        print(f'Questions without a unique highlighted answer: {unresolved_questions}')

    if empty_option_questions:
        print(f'Questions with no options extracted: {sorted(set(empty_option_questions))}')

    if warnings:
        print('Warnings:')
        for warning in warnings:
            print(f'- {warning}')

    return 0


if __name__ == '__main__':
    raise SystemExit(main())
