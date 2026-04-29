#!/usr/bin/env python3
"""Extract the Triet midterm quiz PDFs into separate data-quiz banks.

Each source PDF contains 50 questions. The question stems and options are
plain text, while the correct answer is marked by a yellow background fill in
the PDF content stream. This script reads those fills directly with PyMuPDF,
maps them back to the option bounding boxes, and writes app-ready quiz source
files under data-quiz/.
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


QUESTION_RE = re.compile(r'^C\u00e2u\s*(\d+)\s*[:\.\)]?\s*(.*)$', re.IGNORECASE)
QUESTION_CANON_RE = re.compile(r'^CAU\s*(\d+)\s*[:\.\)]?\s*(.*)$', re.IGNORECASE)
OPTION_RE = re.compile(r'^([ABCD])\s*[\.)]\s*(.*)$', re.IGNORECASE)

NOISE_MARKERS = (
    'messages.downloaded_by',
    'messages.pdf_cover_qr_code_label',
    'messages.studocu_not_sponsored_or_endorsed_by_college',
    'downloaded by',
    'scan to open on studeersnel',
    'lê văn quân-63ktpm2',
)

INLINE_NOISE_PATTERNS = (
    re.compile(r'\s*lOMoARcPSD(?:\|\d+)?\s*', re.IGNORECASE),
    re.compile(r'\s*Downloaded by[^A-Za-zÀ-ỹ]*', re.IGNORECASE),
    re.compile(r'\s*Lê Văn Quân-63KTPM2\s*', re.IGNORECASE),
)

DEFAULT_PDF_NAME_BY_BANK = {
    'triet-gk1': 'gk-triet-lan1-de-thi-giua-ky-mac-lenin-ve-triet-hoc-bien-chung.pdf',
    'triet-gk2': 'gk-triet-lan2-de-thi-giua-ky-triet-hoc-mac-lenin-2.pdf',
}

BANK_CONFIGS = (
    {
        'pdf_name': DEFAULT_PDF_NAME_BY_BANK['triet-gk1'],
        'folder_name': 'TRIET_GK1',
        'bank_id': 'triet-gk1',
        'code': 'TRIETGK1',
        'title': 'Triết GK 1',
        'description': 'Đề giữa kỳ Triết học Mác - Lênin lần 1.',
        'accent_color': 0xFFEF4444,
        'preprocessed_dir_name': 'triet_gk1',
    },
    {
        'pdf_name': DEFAULT_PDF_NAME_BY_BANK['triet-gk2'],
        'folder_name': 'TRIET_GK2',
        'bank_id': 'triet-gk2',
        'code': 'TRIETGK2',
        'title': 'Triết GK 2',
        'description': 'Đề giữa kỳ Triết học Mác - Lênin lần 2.',
        'accent_color': 0xFF0EA5E9,
        'preprocessed_dir_name': 'triet_gk2',
    },
)


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
    stem_parts: list[str] = field(default_factory=list)
    options: list[OptionDraft] = field(default_factory=list)


def configure_stdio() -> None:
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8')
    if hasattr(sys.stderr, 'reconfigure'):
        sys.stderr.reconfigure(encoding='utf-8')


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def locate_tri_folder(root: Path) -> Path:
    for path in root.iterdir():
        if path.is_dir() and path.name.startswith('Tri'):
            return path

    raise FileNotFoundError('Could not locate the Triet source folder.')


def strip_accents(text: str) -> str:
    normalized = ud.normalize('NFKD', text)
    normalized = normalized.replace('\u0110', 'D').replace('\u0111', 'd')
    return ''.join(char for char in normalized if not ud.combining(char))


def canonical(text: str) -> str:
    return re.sub(r'\s+', ' ', strip_accents(text)).upper().strip()


def clean_text(text: str) -> str:
    cleaned = text.replace('\xa0', ' ').replace('\u200b', '').replace('\u00ad', '')
    for pattern in INLINE_NOISE_PATTERNS:
        cleaned = pattern.sub(' ', cleaned)
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


def extract_questions(doc: fitz.Document) -> tuple[list[QuestionDraft], list[list[tuple[float, float, float, float]]]]:
    questions: list[QuestionDraft] = []
    page_highlights: list[list[tuple[float, float, float, float]]] = []
    current: QuestionDraft | None = None
    current_option: OptionDraft | None = None

    for page_index, page in enumerate(doc):
        page_highlights.append(page_highlight_rects(page))

        for line in iter_page_lines(page, page_index):
            if is_noise_line(line.text):
                continue

            question_match = QUESTION_RE.match(line.text) or QUESTION_CANON_RE.match(line.canon)
            if question_match is not None:
                if current is not None:
                    questions.append(current)

                current = QuestionDraft(number=int(question_match.group(1)))
                if question_match.group(2):
                    current.stem_parts.append(question_match.group(2))
                current_option = None
                continue

            if current is None:
                continue

            option_match = OPTION_RE.match(line.text) or OPTION_RE.match(line.canon)
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

    return 'ABCD'.index(scores[0][0]), scores[0][0], scores


def question_to_dict(question: QuestionDraft, correct_answer: int | None, answer_letter: str | None) -> dict:
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
        description='Extract the Triet GK PDFs into app-ready quiz banks.',
    )
    parser.add_argument(
        '--tri-folder',
        type=Path,
        default=locate_tri_folder(repo_root()),
        help='Folder containing the source Triet PDFs.',
    )
    parser.add_argument(
        '--data-quiz-root',
        type=Path,
        default=repo_root() / 'data-quiz',
        help='Root folder for data-quiz banks.',
    )
    parser.add_argument(
        '--preprocessed-root',
        type=Path,
        default=repo_root() / 'preprocessed' / 'triet_gk',
        help='Root folder for intermediate JSON outputs.',
    )
    return parser


def process_bank(
    tri_folder: Path,
    data_quiz_root: Path,
    preprocessed_root: Path,
    config: dict,
) -> dict:
    pdf_path = tri_folder / config['pdf_name']
    if not pdf_path.exists():
        raise FileNotFoundError(f'PDF file does not exist: {pdf_path}')

    output_bank_dir = data_quiz_root / config['folder_name']
    output_preprocessed_dir = preprocessed_root / config['preprocessed_dir_name']
    output_bank_dir.mkdir(parents=True, exist_ok=True)
    output_preprocessed_dir.mkdir(parents=True, exist_ok=True)

    with fitz.open(pdf_path) as doc:
        questions, page_highlights = extract_questions(doc)

    normalized_questions: list[dict] = []
    warnings: list[str] = []
    unresolved_questions: list[int] = []

    for question in questions:
        correct_answer, answer_letter, scores = resolve_question_answer(
            question,
            page_highlights,
        )

        if correct_answer is None:
            unresolved_questions.append(question.number)
            warnings.append(
                f'Question {question.number} in {config["bank_id"]} has no unique highlighted answer.'
            )

        normalized_questions.append(
            question_to_dict(question, correct_answer, answer_letter)
        )

        if len(question.options) != 4:
            warnings.append(
                f'Question {question.number} in {config["bank_id"]} has {len(question.options)} options.'
            )

    report = {
        'bankId': config['bank_id'],
        'pdfFile': config['pdf_name'],
        'questionCount': len(normalized_questions),
        'playableCount': sum(1 for question in normalized_questions if question['correctAnswer'] is not None),
        'unresolvedQuestions': unresolved_questions,
        'warnings': warnings,
    }

    write_json(output_preprocessed_dir / 'questions.json', normalized_questions)
    write_json(output_preprocessed_dir / 'report.json', report)

    write_json(
        output_bank_dir / 'bank.json',
        {
            'id': config['bank_id'],
            'code': config['code'],
            'title': config['title'],
            'description': config['description'],
            'accentColor': config['accent_color'],
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
            for question in normalized_questions
        ],
        ensure_ascii=False,
        indent=2,
    ) + ';\n'
    write_text(output_bank_dir / 'Quiz1.js', quiz_source)

    return report


def main() -> int:
    configure_stdio()
    parser = build_parser()
    args = parser.parse_args()

    tri_folder = args.tri_folder.expanduser().resolve()
    if not tri_folder.exists():
        parser.error(f'Triết folder does not exist: {tri_folder}')

    data_quiz_root = args.data_quiz_root.expanduser().resolve()
    preprocessed_root = args.preprocessed_root.expanduser().resolve()

    overall_report = []
    for config in BANK_CONFIGS:
        report = process_bank(tri_folder, data_quiz_root, preprocessed_root, config)
        overall_report.append(report)

        print(
            f"{config['bank_id']}: {report['questionCount']} questions, "
            f"{report['playableCount']} playable"
        )

    write_json(preprocessed_root / 'report.json', overall_report)
    print(f'Wrote {len(overall_report)} bank(s) to {data_quiz_root}')

    return 0


if __name__ == '__main__':
    raise SystemExit(main())
