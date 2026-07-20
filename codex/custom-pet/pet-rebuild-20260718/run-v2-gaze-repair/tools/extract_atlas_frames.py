#!/usr/bin/env python3
"""Extract all used frames from an 8x11 Codex Pet atlas for animation QA."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


CELL_WIDTH = 192
CELL_HEIGHT = 208
ROWS = [
    ("idle", 6),
    ("running-right", 8),
    ("running-left", 8),
    ("waving", 4),
    ("jumping", 5),
    ("failed", 8),
    ("waiting", 6),
    ("running", 6),
    ("review", 6),
    ("look-row-9", 8),
    ("look-row-10", 8),
]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("atlas")
    parser.add_argument("--output-dir", required=True)
    args = parser.parse_args()

    with Image.open(Path(args.atlas).resolve()) as opened:
        atlas = opened.convert("RGBA")
    if atlas.size != (8 * CELL_WIDTH, 11 * CELL_HEIGHT):
        raise SystemExit(f"unexpected atlas size: {atlas.size}")

    output_dir = Path(args.output_dir).resolve()
    for row, (state, count) in enumerate(ROWS):
        state_dir = output_dir / state
        state_dir.mkdir(parents=True, exist_ok=True)
        for column in range(count):
            frame = atlas.crop(
                (
                    column * CELL_WIDTH,
                    row * CELL_HEIGHT,
                    (column + 1) * CELL_WIDTH,
                    (row + 1) * CELL_HEIGHT,
                )
            )
            frame.save(state_dir / f"{column:02d}.png")


if __name__ == "__main__":
    main()
