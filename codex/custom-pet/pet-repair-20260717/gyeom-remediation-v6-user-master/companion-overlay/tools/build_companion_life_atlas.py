"""Build a fixed-body-scale Companion life-motion atlas from generated strips."""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
from statistics import median

from PIL import Image, ImageDraw


CELL_WIDTH = 192
CELL_HEIGHT = 256
CORE_CELL_HEIGHT = 208
FRAME_COUNTS = {
    "idle-breathe": 8,
    "idle-yawn": 6,
    "idle-stretch": 8,
    "idle-look": 8,
}


def color_distance(pixel: tuple[int, int, int, int], key: tuple[int, int, int]) -> float:
    return math.sqrt(sum((pixel[index] - key[index]) ** 2 for index in range(3)))


def remove_chroma(image: Image.Image, key: tuple[int, int, int], threshold: float) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            pixel = pixels[x, y]
            if color_distance(pixel, key) <= threshold:
                pixels[x, y] = (0, 0, 0, 0)
    return rgba


def extract_slots(strip: Image.Image, count: int) -> list[Image.Image]:
    frames: list[Image.Image] = []
    for index in range(count):
        left = round(index * strip.width / count)
        right = round((index + 1) * strip.width / count)
        crop = strip.crop((left, 0, right, strip.height))
        box = crop.getchannel("A").getbbox()
        if box is None:
            raise ValueError(f"frame {index} is empty after chroma extraction")
        frames.append(crop.crop(box))
    return frames


def canonical_metrics(core_atlas: Image.Image) -> tuple[int, int]:
    neutral = core_atlas.crop((0, 0, CELL_WIDTH, CORE_CELL_HEIGHT))
    box = neutral.getchannel("A").getbbox()
    if box is None:
        raise ValueError("canonical core idle frame is empty")
    return box[3] - box[1], box[3]


def normalize_clip(
    source: Path,
    count: int,
    canonical_height: int,
    target_baseline: int,
    chroma_key: tuple[int, int, int],
    threshold: float,
) -> tuple[list[Image.Image], dict[str, object]]:
    with Image.open(source) as opened:
        transparent = remove_chroma(opened, chroma_key, threshold)
    frames = extract_slots(transparent, count)
    neutral_heights = [frames[0].height, frames[-1].height]
    scale = canonical_height / median(neutral_heights)
    max_width = max(round(frame.width * scale) for frame in frames)
    max_height = max(round(frame.height * scale) for frame in frames)
    if max_width > CELL_WIDTH - 8 or max_height > CELL_HEIGHT - 8:
        raise ValueError(
            f"shared canonical scale does not fit: {max_width}x{max_height} in "
            f"{CELL_WIDTH}x{CELL_HEIGHT}; regenerate the complete strip"
        )

    outputs: list[Image.Image] = []
    details: list[dict[str, object]] = []
    for index, frame in enumerate(frames):
        width = max(1, round(frame.width * scale))
        height = max(1, round(frame.height * scale))
        resized = frame.resize((width, height), Image.Resampling.LANCZOS)
        cell = Image.new("RGBA", (CELL_WIDTH, CELL_HEIGHT), (0, 0, 0, 0))
        left = (CELL_WIDTH - width) // 2
        top = target_baseline - height
        if top < 4:
            raise ValueError(f"frame {index} clips above the life cell at canonical scale")
        cell.alpha_composite(resized, (left, top))
        outputs.append(cell)
        details.append(
            {
                "frame": index,
                "sourceSize": [frame.width, frame.height],
                "normalizedSize": [width, height],
                "bbox": [left, top, left + width, top + height],
            }
        )
    return outputs, {
        "source": str(source),
        "frameCount": count,
        "sharedScale": scale,
        "neutralHeight": canonical_height,
        "targetBaseline": target_baseline,
        "frames": details,
    }


def make_contact_sheet(atlas: Image.Image, output: Path) -> None:
    scale = 2
    label_height = 28
    sheet = Image.new(
        "RGB",
        (CELL_WIDTH * 8 * scale, len(FRAME_COUNTS) * (CELL_HEIGHT * scale + label_height)),
        (34, 34, 34),
    )
    draw = ImageDraw.Draw(sheet)
    for row, name in enumerate(FRAME_COUNTS):
        y = row * (CELL_HEIGHT * scale + label_height)
        draw.text((8, y + 6), name, fill=(255, 255, 255))
        strip = atlas.crop((0, row * CELL_HEIGHT, atlas.width, (row + 1) * CELL_HEIGHT))
        background = Image.new("RGBA", strip.size, (34, 34, 34, 255))
        background.alpha_composite(strip)
        resized = background.convert("RGB").resize(
            (strip.width * scale, strip.height * scale), Image.Resampling.NEAREST
        )
        sheet.paste(resized, (0, y + label_height))
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--core-atlas", required=True, type=Path)
    parser.add_argument("--sources", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--report", required=True, type=Path)
    parser.add_argument("--contact-sheet", required=True, type=Path)
    parser.add_argument("--key-threshold", type=float, default=110.0)
    args = parser.parse_args()

    core = Image.open(args.core_atlas).convert("RGBA")
    canonical_height, canonical_baseline = canonical_metrics(core)
    target_baseline = canonical_baseline + (CELL_HEIGHT - CORE_CELL_HEIGHT)
    if target_baseline >= CELL_HEIGHT:
        raise ValueError("canonical baseline does not fit the life cell")

    atlas = Image.new(
        "RGBA", (CELL_WIDTH * 8, CELL_HEIGHT * len(FRAME_COUNTS)), (0, 0, 0, 0)
    )
    clips: dict[str, object] = {}
    chroma_key = (0, 255, 0)
    for row, (name, count) in enumerate(FRAME_COUNTS.items()):
        source = args.sources / f"{name}.png"
        if not source.is_file():
            raise FileNotFoundError(source)
        frames, detail = normalize_clip(
            source,
            count,
            canonical_height,
            target_baseline,
            chroma_key,
            args.key_threshold,
        )
        for column, frame in enumerate(frames):
            atlas.alpha_composite(frame, (column * CELL_WIDTH, row * CELL_HEIGHT))
        clips[name] = {"row": row, **detail}

    atlas.putdata(
        [(0, 0, 0, 0) if pixel[3] == 0 else pixel for pixel in atlas.get_flattened_data()]
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(args.output)
    make_contact_sheet(atlas, args.contact_sheet)
    args.report.write_text(
        json.dumps(
            {
                "ok": True,
                "atlas": str(args.output),
                "atlasSize": list(atlas.size),
                "cellSize": [CELL_WIDTH, CELL_HEIGHT],
                "canonicalBodyHeight": canonical_height,
                "canonicalBaseline": canonical_baseline,
                "lifeBaseline": target_baseline,
                "chromaKey": "#00FF00",
                "keyThreshold": args.key_threshold,
                "clips": clips,
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
