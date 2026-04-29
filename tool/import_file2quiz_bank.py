#!/usr/bin/env python3
"""Convert a file2quiz-preprocessed JSON bank into data-quiz source files."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any


NOISE_PATTERNS = (
    re.compile(r"\s*messages\.downloaded_by\b.*$", re.IGNORECASE),
    re.compile(r"\s*Downloaded by\b.*$", re.IGNORECASE),
    re.compile(r"\s*lOMoARcPSD\|\d+.*$", re.IGNORECASE),
    re.compile(r"\s*lOMoARcPSD\b.*$", re.IGNORECASE),
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Convert a file2quiz JSON bank into a data-quiz bank folder."
        ),
    )
    parser.add_argument(
        "source_json",
        type=Path,
        help="Path to a preprocessed file2quiz JSON bank.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        required=True,
        help="Target bank folder under data-quiz.",
    )
    parser.add_argument("--bank-id", required=True, help="Bank id, e.g. triet.")
    parser.add_argument(
        "--code",
        required=True,
        help="Short bank code shown in the UI, e.g. TRIET.",
    )
    parser.add_argument(
        "--title",
        required=True,
        help="Display title for the quiz bank.",
    )
    parser.add_argument(
        "--description",
        required=True,
        help="Short bank description shown in the catalog.",
    )
    parser.add_argument(
        "--accent-color",
        default="0xFF7C3AED",
        help="Bank accent color as a decimal or hex integer.",
    )
    parser.add_argument(
        "--quiz-file",
        default="Quiz1.js",
        help="Quiz source file name to generate inside the output folder.",
    )
    return parser.parse_args()


def clean_text(value: Any) -> str:
    text = "" if value is None else str(value)
    text = text.replace("\xa0", " ").replace("\u200b", "")

    for pattern in NOISE_PATTERNS:
        text = pattern.sub("", text)

    text = re.sub(r"\s+", " ", text)
    return text.strip()


def parse_correct_answer(value: Any) -> int | None:
    if value is None or isinstance(value, bool):
        return None

    if isinstance(value, int):
        return value if value >= 0 else None

    if isinstance(value, float) and value.is_integer():
        normalized = int(value)
        return normalized if normalized >= 0 else None

    if isinstance(value, str):
        stripped = value.strip()
        if stripped.isdigit():
            return int(stripped)

    return None


def parse_source_id(raw_id: Any, fallback: int) -> int:
    if isinstance(raw_id, bool):
        return fallback

    if isinstance(raw_id, int):
        return raw_id

    if isinstance(raw_id, float) and raw_id.is_integer():
        return int(raw_id)

    if isinstance(raw_id, str):
        stripped = raw_id.strip()
        if stripped.isdigit():
            return int(stripped)

    return fallback


def load_source_questions(source_json: Path) -> list[dict[str, Any]]:
    raw_source = json.loads(source_json.read_text(encoding="utf-8"))
    if not isinstance(raw_source, dict):
        raise ValueError("file2quiz source must be a JSON object keyed by question id.")

    questions: list[dict[str, Any]] = []
    for fallback_index, (key, entry) in enumerate(
        sorted(raw_source.items(), key=lambda item: int(item[0])),
        start=1,
    ):
        if not isinstance(entry, dict):
            continue

        question = clean_text(entry.get("question"))
        options = [clean_text(answer) for answer in entry.get("answers", [])]
        correct_answer = parse_correct_answer(entry.get("correct_answer"))

        if not question or not options or any(not option for option in options):
            continue

        if correct_answer is not None and correct_answer >= len(options):
            continue

        question_entry: dict[str, Any] = {
            "id": parse_source_id(entry.get("id", key), fallback_index),
            "question": question,
            "options": options,
            "correctAnswer": correct_answer,
        }
        questions.append(question_entry)

    return questions


def parse_accent_color(value: str) -> int:
    return int(value, 0) & 0xFFFFFFFF


def main() -> int:
    args = parse_args()
    source_questions = load_source_questions(args.source_json)

    args.output_dir.mkdir(parents=True, exist_ok=True)

    bank_metadata = {
        "id": args.bank_id,
        "code": args.code,
        "title": args.title,
        "description": args.description,
        "accentColor": parse_accent_color(args.accent_color),
    }

    bank_json_path = args.output_dir / "bank.json"
    bank_json_path.write_text(
        f"{json.dumps(bank_metadata, ensure_ascii=False, indent=2)}\n",
        encoding="utf-8",
    )

    quiz_source = "export const sampleQuestions = " + json.dumps(
        source_questions,
        ensure_ascii=False,
        indent=2,
    ) + ";\n"
    quiz_file_path = args.output_dir / args.quiz_file
    quiz_file_path.write_text(quiz_source, encoding="utf-8")

    print(
        json.dumps(
            {
                "sourceFile": str(args.source_json),
                "outputDir": str(args.output_dir),
                "questionCount": len(source_questions),
            },
            ensure_ascii=False,
            indent=2,
        ),
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
