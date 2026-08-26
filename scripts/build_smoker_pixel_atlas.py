"""Build the smoker's production pixel atlas from one locked character sheet.

The source remains untouched. Every frame is resampled onto the same 96x192
pixel grid and quantized once as a whole atlas, so identity, palette and pixel
density cannot drift between animation frames.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image, ImageEnhance


COLUMNS, ROWS = 6, 2
SOURCE_CELL = (256, 512)
CELL = (96, 192)
FOOTLINE = 190


def resize_cell(cell: Image.Image) -> Image.Image:
    resized = cell.resize(CELL, Image.Resampling.LANCZOS)
    resized = ImageEnhance.Contrast(resized).enhance(1.08)
    resized = ImageEnhance.Color(resized).enhance(1.04)
    array = np.asarray(resized).copy()

    # Generated chroma-clean drafts retain an occasional green fringe. Replace
    # only those edge colors with the character's shared charcoal outline.
    red, green, blue, alpha = (array[:, :, index].astype(np.int16) for index in range(4))
    fringe = (alpha > 20) & (green > 72) & (green > red * 1.42) & (green > blue * 1.25)
    array[fringe, 0] = 20
    array[fringe, 1] = 15
    array[fringe, 2] = 21

    # True sprite pixels: no soft semi-transparent edge samples and no runtime
    # dependence on image downscaling.
    array[:, :, 3] = np.where(alpha >= 72, 255, 0).astype(np.uint8)
    array[array[:, :, 3] == 0, :3] = 0
    return Image.fromarray(array, "RGBA")


def draw_walk_cigarettes(atlas: Image.Image) -> None:
    # Hand-placed mouth anchors keep the cigarette readable and attached to the
    # face in every walk frame. The full sheet is mirrored by LÖVE when facing left.
    mouths = [(68, 29), (73, 29), (68, 42), (74, 29), (75, 36), (73, 29)]
    pixels = atlas.load()
    for column, (mouth_x, mouth_y) in enumerate(mouths):
        x0 = column * CELL[0] + mouth_x
        for offset, color in enumerate(((235, 224, 195, 255), (235, 224, 195, 255), (181, 117, 49, 255), (255, 92, 24, 255))):
            x = x0 + offset
            pixels[x, mouth_y,] = color
            if offset < 3:
                pixels[x, mouth_y + 1] = (43, 30, 27, 255) if offset == 0 else color
        pixels[x0 + 3, mouth_y - 1] = (255, 183, 55, 255)


def build(source_path: Path, destination_path: Path) -> None:
    source = Image.open(source_path).convert("RGBA")
    expected = (SOURCE_CELL[0] * COLUMNS, SOURCE_CELL[1] * ROWS)
    if source.size != expected:
        raise SystemExit(f"unexpected source size {source.size}; expected {expected}")

    atlas = Image.new("RGBA", (CELL[0] * COLUMNS, CELL[1] * ROWS), (0, 0, 0, 0))
    for row in range(ROWS):
        for column in range(COLUMNS):
            box = (
                column * SOURCE_CELL[0],
                row * SOURCE_CELL[1],
                (column + 1) * SOURCE_CELL[0],
                (row + 1) * SOURCE_CELL[1],
            )
            frame = resize_cell(source.crop(box))
            atlas.alpha_composite(frame, (column * CELL[0], row * CELL[1]))

    # One quantization pass creates one shared palette for all twelve frames.
    alpha = atlas.getchannel("A")
    atlas = atlas.quantize(colors=96, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE).convert("RGBA")
    atlas.putalpha(alpha)
    draw_walk_cigarettes(atlas)

    destination_path.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(destination_path)
    print(f"saved={destination_path} size={atlas.width}x{atlas.height} cell={CELL[0]}x{CELL[1]} footline={FOOTLINE}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    build(args.source, args.destination)


if __name__ == "__main__":
    main()
