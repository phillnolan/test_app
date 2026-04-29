#!/usr/bin/env python3
"""Preprocess PDF quiz banks into structured JSON using file2quiz.

This utility extracts text with ``pdftotext``, normalizes the quiz layout, and
lets the cloned ``file2quiz`` package parse the result into quiz JSON files.
The output is intended as an intermediate dataset for later conversion into the
app's quiz assets.
"""

from __future__ import annotations

import argparse
import contextlib
import io
import json
import os
import re
import subprocess
import sys
import tempfile
import unicodedata as ud
import shutil
from pathlib import Path


def strip_accents(text: str) -> str:
    normalized = ud.normalize('NFKD', text)
    return ''.join(char for char in normalized if not ud.combining(char))


def sanitize_subject_name(name: str) -> str:
    normalized = strip_accents(name).strip().lower()
    normalized = re.sub(r'[^a-z0-9]+', '-', normalized)
    normalized = re.sub(r'-{2,}', '-', normalized).strip('-')
    return normalized or 'quiz'


def normalize_question_prefixes(text: str) -> str:
    # Convert "Câu 12:" into a format the parser recognizes as a question id.
    return re.sub(
        r'(?mi)^\s*Câu\s*(\d+(?:\.\d+)*)\s*[:\)\-\.]?\s*',
        lambda match: f'{match.group(1)}. ',
        text,
    )


def detect_answer_token(text: str) -> str | None:
    # Avoid false positives from the title line "... VÀ ĐÁP ÁN".
    if 'GOI Y DAP AN' in strip_accents(text).upper():
        return r'(?m)^.*GỢI Ý.*ĐÁP.*ÁN.*$'

    return None


def load_file2quiz(file2quiz_path: Path):
    sys.path.insert(0, str(file2quiz_path))
    import file2quiz  # type: ignore

    return file2quiz


def extract_text(pdf_path: Path, working_dir: Path) -> Path:
    safe_stem = sanitize_subject_name(pdf_path.stem)
    local_pdf = working_dir / f'{safe_stem}.pdf'
    txt_path = working_dir / f'{safe_stem}.txt'
    shutil.copyfile(pdf_path, local_pdf)
    subprocess.run(
        ['pdftotext', '-layout', str(local_pdf), str(txt_path)],
        check=True,
        capture_output=True,
        text=True,
    )
    return txt_path


def split_question_and_answer_sections(
    file2quiz,
    text: str,
    allow_tail_heuristic: bool,
) -> tuple[str, str | None, str | None]:
    token_answer = detect_answer_token(text)
    if token_answer is None:
        if not allow_tail_heuristic:
            return text, None, None

        # Some PDFs render the answer key as a dense table near the end without a
        # stable heading. In that case, try a tail-based heuristic and keep the
        # chunk only if it actually looks like a solution table.
        for tail_size in (12000, 20000, 30000, 40000, 60000):
            if len(text) <= tail_size:
                break

            candidate = text[-tail_size:]
            with contextlib.redirect_stdout(io.StringIO()):
                candidate_solutions = file2quiz.parse_solutions(
                    candidate,
                    num_expected_answers=4,
                )

            if len(candidate_solutions) >= 20:
                return text[:-tail_size], candidate, None

        return text, None, None

    pattern = re.compile(token_answer, re.IGNORECASE | re.MULTILINE | re.DOTALL)
    match = pattern.search(text)
    if match is None:
        return text, None, None

    return text[: match.start()], text[match.start() :], token_answer


def parse_quiz(file2quiz, text: str, allow_tail_heuristic: bool) -> dict:
    question_text, answer_text, token_answer = split_question_and_answer_sections(
        file2quiz,
        text,
        allow_tail_heuristic,
    )

    question_text = file2quiz.preprocess_text(question_text, mode='auto')
    question_text = normalize_question_prefixes(question_text)
    with contextlib.redirect_stdout(io.StringIO()):
        question_blocks = file2quiz.parse_questions(
            question_text,
            num_expected_answers=4,
            mode='auto',
        )

    if answer_text is None:
        with contextlib.redirect_stdout(io.StringIO()):
            quiz = file2quiz.build_quiz(question_blocks, [])
        return quiz

    with contextlib.redirect_stdout(io.StringIO()):
        solutions = file2quiz.parse_solutions(answer_text, num_expected_answers=4)

    # file2quiz is quite chatty. Capture its diagnostics so our own report stays
    # readable.
    with contextlib.redirect_stdout(io.StringIO()):
        quiz = file2quiz.build_quiz(question_blocks, solutions)

    return quiz


def save_json(data, output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )


def preprocess_source_dir(
    file2quiz,
    source_dir: Path,
    output_dir: Path,
    working_root: Path,
) -> list[dict]:
    source_name = source_dir.name
    subject_slug = sanitize_subject_name(source_name)
    summary: list[dict] = []

    pdf_files = sorted(
        [path for path in source_dir.iterdir() if path.is_file() and path.suffix.lower() == '.pdf'],
        key=lambda path: path.name.lower(),
    )

    for pdf_path in pdf_files:
        working_dir = working_root / subject_slug
        working_dir.mkdir(parents=True, exist_ok=True)

        txt_path = extract_text(pdf_path, working_dir)
        text = txt_path.read_text(encoding='utf-8', errors='ignore')
        allow_tail_heuristic = subject_slug == 'triet' and (
            '511' in pdf_path.stem or 'ngan-hang' in pdf_path.stem
        )
        quiz = parse_quiz(file2quiz, text, allow_tail_heuristic)

        question_count = len(quiz)
        answer_count = sum(1 for question in quiz.values() if question.get('correct_answer') is not None)

        output_path = output_dir / subject_slug / f'{pdf_path.stem}.json'
        save_json(quiz, output_path)

        summary.append(
            {
                'source_dir': str(source_dir),
                'source_file': str(pdf_path),
                'output_file': str(output_path),
                'question_count': question_count,
                'answer_count': answer_count,
            }
        )

    return summary


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description='Preprocess PDF quiz banks into JSON using file2quiz.',
    )
    parser.add_argument(
        '--source-dir',
        action='append',
        required=True,
        help='Source directory containing PDF files. Can be repeated.',
    )
    parser.add_argument(
        '--output-dir',
        required=True,
        help='Directory where the JSON outputs will be written.',
    )
    parser.add_argument(
        '--file2quiz-path',
        default=os.environ.get('FILE2QUIZ_PATH'),
        help='Path to the cloned file2quiz repository.',
    )
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if not args.file2quiz_path:
        parser.error('Missing --file2quiz-path or FILE2QUIZ_PATH.')

    file2quiz_path = Path(args.file2quiz_path).expanduser().resolve()
    if not file2quiz_path.exists():
        parser.error(f'file2quiz path does not exist: {file2quiz_path}')

    file2quiz = load_file2quiz(file2quiz_path)

    output_dir = Path(args.output_dir).expanduser().resolve()
    working_root = output_dir / '_tmp'

    report: list[dict] = []
    for source_dir_arg in args.source_dir:
        source_dir = Path(source_dir_arg).expanduser().resolve()
        if not source_dir.exists() or not source_dir.is_dir():
            parser.error(f'Source directory does not exist: {source_dir}')

        report.extend(preprocess_source_dir(file2quiz, source_dir, output_dir, working_root))

    output_dir.mkdir(parents=True, exist_ok=True)
    save_json(report, output_dir / 'report.json')

    print(f'Wrote {len(report)} JSON file(s) to {output_dir}')
    for item in report:
        print(
            f"- {Path(item['source_file']).name}: "
            f"{item['question_count']} questions, {item['answer_count']} answers",
        )

    return 0


if __name__ == '__main__':
    raise SystemExit(main())
