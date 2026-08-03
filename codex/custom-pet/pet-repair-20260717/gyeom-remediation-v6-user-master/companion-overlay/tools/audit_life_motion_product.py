"""Deterministically audit the Companion life-motion product assets."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image


CELL_WIDTH = 192
CELL_HEIGHT = 256
CLIPS = {"idle-breathe": 8, "idle-yawn": 6, "idle-stretch": 8, "idle-look": 8}


def edge_alpha_count(cell: Image.Image) -> int:
    alpha = cell.getchannel("A")
    edges = (
        alpha.crop((0, 0, CELL_WIDTH, 1)),
        alpha.crop((0, CELL_HEIGHT - 1, CELL_WIDTH, CELL_HEIGHT)),
        alpha.crop((0, 0, 1, CELL_HEIGHT)),
        alpha.crop((CELL_WIDTH - 1, 0, CELL_WIDTH, CELL_HEIGHT)),
    )
    return sum(sum(value > 0 for value in edge.get_flattened_data()) for edge in edges)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--overlay-root", required=True, type=Path)
    args = parser.parse_args()
    root = args.overlay_root
    qa = root / "qa"
    atlas_path = root / "assets" / "life-motions.png"
    normalization_path = qa / "life-motion-normalization.json"
    runtime_path = qa / "life-motion-runtime-observation.json"
    errors: list[str] = []

    atlas = Image.open(atlas_path).convert("RGBA")
    if atlas.size != (CELL_WIDTH * 8, CELL_HEIGHT * 4):
        errors.append(f"unexpected atlas size: {atlas.size}")
    normalization = json.loads(normalization_path.read_text(encoding="utf-8-sig"))
    runtime = json.loads(runtime_path.read_text(encoding="utf-8-sig"))
    if not normalization.get("ok"):
        errors.append("normalization report is not ok")
    if not runtime.get("ok"):
        errors.append("runtime observation is not ok")

    frames: list[dict[str, object]] = []
    for row, (name, count) in enumerate(CLIPS.items()):
        hashes: list[str] = []
        for column in range(8):
            cell = atlas.crop(
                (
                    column * CELL_WIDTH,
                    row * CELL_HEIGHT,
                    (column + 1) * CELL_WIDTH,
                    (row + 1) * CELL_HEIGHT,
                )
            )
            box = cell.getchannel("A").getbbox()
            if column >= count:
                if box is not None:
                    errors.append(f"{name}/{column:02d} unused cell is not transparent")
                continue
            if box is None:
                errors.append(f"{name}/{column:02d} is empty")
                continue
            edge_count = edge_alpha_count(cell)
            if edge_count:
                errors.append(f"{name}/{column:02d} touches the cell edge")
            digest = hashlib.sha256(cell.tobytes()).hexdigest()
            hashes.append(digest)
            frames.append(
                {
                    "clip": name,
                    "frame": column,
                    "bbox": list(box),
                    "bboxWidth": box[2] - box[0],
                    "bboxHeight": box[3] - box[1],
                    "edgeAlphaPixels": edge_count,
                }
            )
        if len(set(hashes)) < max(3, count // 2):
            errors.append(f"{name} has insufficient visual frame diversity")

    expected_runtime = {"idle-breathe", "idle-look", "idle-stretch", "idle-yawn", "waving", "review"}
    observed_runtime = {state for state, count in runtime.get("stateCounts", {}).items() if count > 0}
    missing_runtime = sorted(expected_runtime - observed_runtime)
    if missing_runtime:
        errors.append(f"runtime states missing: {', '.join(missing_runtime)}")
    if float(runtime.get("capturedDurationSeconds", 0)) < 55:
        errors.append("runtime capture is shorter than 55 seconds")

    required_evidence = (
        qa / "life-motion-contact-sheet.png",
        qa / "life-motion-runtime-contact-sheet.png",
        qa / "life-motion-ab-contact-sheet.png",
        qa / "life-motion-runtime-diagnostics.json",
        qa / "life-motion-final-60s-diagnostics.json",
        qa / "life-motion-independent-visual-qa.json",
    )
    for path in required_evidence:
        if not path.is_file() or path.stat().st_size == 0:
            errors.append(f"missing QA evidence: {path.name}")

    result = {
        "ok": not errors,
        "atlas": str(atlas_path),
        "atlasSize": list(atlas.size),
        "cellSize": [CELL_WIDTH, CELL_HEIGHT],
        "usedFrameCount": len(frames),
        "runtimeDurationSeconds": runtime.get("capturedDurationSeconds"),
        "runtimeStateCounts": runtime.get("stateCounts"),
        "missingRuntimeStates": missing_runtime,
        "errors": errors,
        "frames": frames,
    }
    output = qa / "life-motion-product-audit.json"
    output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({key: value for key, value in result.items() if key != "frames"}, ensure_ascii=False, indent=2))
    if errors:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
