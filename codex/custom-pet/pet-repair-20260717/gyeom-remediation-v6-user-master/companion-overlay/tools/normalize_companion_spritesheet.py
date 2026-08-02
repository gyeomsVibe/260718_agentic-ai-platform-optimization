"""Build the Companion atlas at fixed 1:1 scale with audited full-row repairs."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image


CELL_WIDTH = 192
CELL_HEIGHT = 208
NORMALIZED_ROWS = {
    0: "idle",
    1: "running-right",
    2: "running-left",
    3: "waving",
    4: "jumping",
    5: "failed",
    6: "waiting",
    7: "running",
    8: "review",
}
REPAIR_ROWS = {
    3: ("waving", 4),
    8: ("review", 6),
}


def alpha_box(cell: Image.Image) -> tuple[int, int, int, int] | None:
    """Return the non-transparent bounding box for one RGBA sprite cell."""

    return cell.getchannel("A").getbbox()


def preserve_cell(cell: Image.Image) -> tuple[Image.Image, dict[str, object]]:
    """Return a pixel-identical frame and record its fixed-scale contract."""

    box = alpha_box(cell)
    if box is None:
        return cell, {"changed": False, "reason": "empty"}

    source_width = box[2] - box[0]
    source_height = box[3] - box[1]
    return cell.copy(), {
        "changed": True,
        "sourceBox": list(box),
        "sourceSize": [source_width, source_height],
        "targetSize": [source_width, source_height],
        "scaleX": 1.0,
        "scaleY": 1.0,
        "aspectRatioPreserved": True,
    }


def load_repair_cell(repairs_root: Path, state: str, column: int) -> Image.Image:
    """Load one approved repair frame without resizing or resampling it."""

    path = repairs_root / state / f"{column:02d}.png"
    if not path.is_file():
        raise FileNotFoundError(f"Missing required repair frame: {path}")
    cell = Image.open(path).convert("RGBA")
    if cell.size != (CELL_WIDTH, CELL_HEIGHT):
        raise ValueError(f"Repair frame must be 192x208, received {cell.size}: {path}")
    if alpha_box(cell) is None:
        raise ValueError(f"Repair frame is empty: {path}")
    return cell


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--report", required=True, type=Path)
    parser.add_argument("--repairs-root", required=True, type=Path)
    args = parser.parse_args()

    atlas = Image.open(args.input).convert("RGBA")
    expected = (CELL_WIDTH * 8, CELL_HEIGHT * 9)
    if atlas.size != expected:
        raise ValueError(f"Expected {expected}, received {atlas.size}")

    output = atlas.copy()
    rows: list[dict[str, object]] = []
    transparent = Image.new("RGBA", (CELL_WIDTH, CELL_HEIGHT), (0, 0, 0, 0))

    for row, state in NORMALIZED_ROWS.items():
        repair = REPAIR_ROWS.get(row)
        for column in range(8):
            left = column * CELL_WIDTH
            top = row * CELL_HEIGHT

            if repair is not None:
                repair_state, frame_count = repair
                if column >= frame_count:
                    output.paste(transparent, (left, top))
                    continue
                cell = load_repair_cell(args.repairs_root, repair_state, column)
                output.paste(transparent, (left, top))
                detail = preserve_cell(cell)[1]
                output.paste(cell, (left, top))
                detail.update(
                    {
                        "state": state,
                        "row": row,
                        "column": column,
                        "source": "audited-full-row-repair",
                        "repairPath": str(
                            args.repairs_root / repair_state / f"{column:02d}.png"
                        ),
                    }
                )
                rows.append(detail)
                continue

            cell = atlas.crop((left, top, left + CELL_WIDTH, top + CELL_HEIGHT))
            normalized, detail = preserve_cell(cell)
            if detail["changed"]:
                output.paste(normalized, (left, top))
                detail.update(
                    {
                        "state": state,
                        "row": row,
                        "column": column,
                        "source": "original-pixel-identical",
                    }
                )
                rows.append(detail)

    # Chroma extraction can leave invisible RGB values under alpha=0 pixels.
    # Canonical pet assets require those hidden channels to be zero as well.
    output.putdata(
        [
            (0, 0, 0, 0) if pixel[3] == 0 else pixel
            for pixel in output.get_flattened_data()
        ]
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    output.save(args.output)
    args.report.write_text(
        json.dumps(
            {
                "ok": True,
                "input": str(args.input),
                "output": str(args.output),
                "scalePolicy": "fixed-1.0-no-resampling",
                "aspectRatioPolicy": "source-preserved",
                "repairPolicy": "complete-audited-rows-only",
                "repairRows": {state: count for state, count in REPAIR_ROWS.values()},
                "normalizedStates": list(NORMALIZED_ROWS.values()),
                "cells": rows,
            },
            ensure_ascii=False,
            indent=2,
        ),
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
