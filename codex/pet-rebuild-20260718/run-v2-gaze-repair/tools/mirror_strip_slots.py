#!/usr/bin/env python3
"""Mirror each sprite-strip slot independently without reversing frame order."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input")
    parser.add_argument("output")
    parser.add_argument("--frames", type=int, default=8)
    args = parser.parse_args()

    input_path = Path(args.input).resolve()
    output_path = Path(args.output).resolve()
    with Image.open(input_path) as opened:
        image = opened.convert("RGBA")

    result = Image.new("RGBA", image.size)
    for index in range(args.frames):
        left = round(index * image.width / args.frames)
        right = round((index + 1) * image.width / args.frames)
        slot = image.crop((left, 0, right, image.height))
        result.alpha_composite(
            slot.transpose(Image.Transpose.FLIP_LEFT_RIGHT),
            (left, 0),
        )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    result.save(output_path)


if __name__ == "__main__":
    main()
