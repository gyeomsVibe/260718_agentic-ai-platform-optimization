#!/usr/bin/env python3
"""Render alpha-preserving APNG and lossless animated WebP Pet previews."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageChops


ROW_DURATIONS = {
    "idle": [280, 110, 110, 140, 140, 320],
    "running-right": [120, 120, 120, 120, 120, 120, 120, 220],
    "running-left": [120, 120, 120, 120, 120, 120, 120, 220],
    "waving": [140, 140, 140, 280],
    "jumping": [140, 140, 140, 140, 280],
    "failed": [140, 140, 140, 140, 140, 140, 140, 240],
    "waiting": [150, 150, 150, 150, 150, 260],
    "running": [120, 120, 120, 120, 120, 220],
    "review": [150, 150, 150, 150, 150, 280],
    "look-row-9": [180, 180, 180, 180, 180, 180, 180, 280],
    "look-row-10": [180, 180, 180, 180, 180, 180, 180, 280],
}


def load_frames(frames_root: Path, state: str, count: int) -> list[Image.Image]:
    files = sorted((frames_root / state).glob("*.png"))
    if len(files) != count:
        raise SystemExit(f"{state}: expected {count} frames, found {len(files)}")
    frames: list[Image.Image] = []
    for path in files:
        with Image.open(path) as opened:
            frames.append(opened.convert("RGBA"))
    return frames


def save_apng(frames: list[Image.Image], durations: list[int], output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    frames[0].save(
        output,
        format="PNG",
        save_all=True,
        append_images=frames[1:],
        duration=durations,
        loop=0,
        disposal=[0] * len(frames),
        blend=[0] * len(frames),
        optimize=False,
    )


def save_webp(frames: list[Image.Image], durations: list[int], output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    frames[0].save(
        output,
        format="WEBP",
        save_all=True,
        append_images=frames[1:],
        duration=durations,
        loop=0,
        lossless=True,
        quality=100,
        method=6,
        exact=True,
        minimize_size=False,
        background=(0, 0, 0, 0),
    )


def verify_animation(path: Path, expected: list[Image.Image]) -> dict[str, object]:
    frame_results = []
    partial_alpha = 0
    transparent_rgb_residue = 0
    with Image.open(path) as opened:
        actual_count = getattr(opened, "n_frames", 1)
        for index in range(actual_count):
            opened.seek(index)
            actual = opened.convert("RGBA")
            alpha = actual.getchannel("A")
            histogram = alpha.histogram()
            partial_alpha += sum(histogram[1:255])
            red, green, blue, _ = actual.split()
            rgb_max = ImageChops.lighter(ImageChops.lighter(red, green), blue)
            transparent_mask = alpha.point(lambda value: 255 if value == 0 else 0)
            residue = ImageChops.multiply(rgb_max, transparent_mask)
            transparent_rgb_residue += sum(residue.histogram()[1:])
            if index < len(expected):
                expected_frame = expected[index]
                raw_exact = actual.tobytes() == expected_frame.tobytes()
                alpha_exact = (
                    actual.getchannel("A").tobytes()
                    == expected_frame.getchannel("A").tobytes()
                )
                visible_mismatch_pixels = sum(
                    1
                    for actual_pixel, expected_pixel in zip(
                        actual.getdata(), expected_frame.getdata()
                    )
                    if (actual_pixel[3] or expected_pixel[3])
                    and actual_pixel != expected_pixel
                )
                frame_results.append(
                    {
                        "frame": index,
                        "raw_exact": raw_exact,
                        "alpha_exact": alpha_exact,
                        "visible_exact": visible_mismatch_pixels == 0,
                        "visible_mismatch_pixels": visible_mismatch_pixels,
                    }
                )
    return {
        "path": str(path),
        "frames": actual_count,
        "expected_frames": len(expected),
        "frame_count_ok": actual_count == len(expected),
        "raw_pixel_exact": all(item["raw_exact"] for item in frame_results),
        "alpha_exact": all(item["alpha_exact"] for item in frame_results),
        "visible_pixel_exact": all(item["visible_exact"] for item in frame_results),
        "partial_alpha_pixels": partial_alpha,
        "transparent_rgb_residue_pixels": transparent_rgb_residue,
        "frame_results": frame_results,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--frames-root", required=True)
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--json-out", required=True)
    parser.add_argument("--verify-only", action="store_true")
    parser.add_argument(
        "--states",
        default="all",
        help="Comma-separated states to render or verify, or all.",
    )
    args = parser.parse_args()

    frames_root = Path(args.frames_root).resolve()
    output_dir = Path(args.output_dir).resolve()
    results = []
    selected = (
        set(ROW_DURATIONS)
        if args.states == "all"
        else {item.strip() for item in args.states.split(",") if item.strip()}
    )
    unknown = selected - set(ROW_DURATIONS)
    if unknown:
        raise SystemExit(f"unknown states: {', '.join(sorted(unknown))}")
    for state, durations in ROW_DURATIONS.items():
        if state not in selected:
            continue
        frames = load_frames(frames_root, state, len(durations))
        apng = output_dir / "apng" / f"{state}.png"
        webp = output_dir / "webp" / f"{state}.webp"
        if not args.verify_only:
            save_apng(frames, durations, apng)
            save_webp(frames, durations, webp)
        results.append(
            {
                "state": state,
                "apng": verify_animation(apng, frames),
                "webp": verify_animation(webp, frames),
            }
        )

    ok = all(
        result["apng"]["frame_count_ok"]
        and result["apng"]["raw_pixel_exact"]
        and result["apng"]["transparent_rgb_residue_pixels"] == 0
        and result["webp"]["frame_count_ok"]
        and result["webp"]["alpha_exact"]
        and result["webp"]["visible_pixel_exact"]
        for result in results
    )
    report = {"ok": ok, "states": results}
    json_out = Path(args.json_out).resolve()
    json_out.parent.mkdir(parents=True, exist_ok=True)
    json_out.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"ok": ok, "states": len(results), "report": str(json_out)}, indent=2))
    raise SystemExit(0 if ok else 1)


if __name__ == "__main__":
    main()
