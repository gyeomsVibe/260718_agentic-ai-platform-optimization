"""Create a fixed-background edge QA panel from one transparent Pet frame."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw


BACKGROUNDS = (
    ("WHITE", (255, 255, 255, 255)),
    ("MID GRAY", (128, 128, 128, 255)),
    ("CODEX DARK", (24, 24, 24, 255)),
)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    sprite = Image.open(args.input).convert("RGBA")
    panel_width, panel_height = sprite.size
    label_height = 24
    result = Image.new(
        "RGBA",
        (panel_width * len(BACKGROUNDS), panel_height + label_height),
        (0, 0, 0, 0),
    )

    for index, (label, color) in enumerate(BACKGROUNDS):
        panel = Image.new("RGBA", sprite.size, color)
        panel.alpha_composite(sprite)
        x = index * panel_width
        result.alpha_composite(panel, (x, label_height))
        draw = ImageDraw.Draw(result)
        draw.rectangle((x, 0, x + panel_width - 1, label_height - 1), fill=color)
        text_color = (16, 16, 16, 255) if sum(color[:3]) > 420 else (240, 240, 240, 255)
        draw.text((x + 6, 5), label, fill=text_color)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    result.convert("RGB").save(args.output, quality=95)
    print(args.output)


if __name__ == "__main__":
    main()
