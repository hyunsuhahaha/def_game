"""Build the smoker oil-road FX atlas from the preserved generated source board."""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/fx/oil-trail/concepts/oil-trail-cutout-source-v1.png"
DESTINATION = ROOT / "assets/fx/oil-trail/oil-trail-atlas-pixel-v2.png"
ATLAS_PREVIEW = ROOT / "docs/previews/oil-trail-atlas-v2.png"
RUNTIME_PREVIEW = ROOT / "docs/previews/oil-trail-runtime-v2.png"
GROUND = ROOT / "assets/forest-ground-tile-v1.png"

COLUMNS, ROWS = 6, 2
SOURCE_CELL = (256, 512)
CELL = 128
BASELINE = 116
FIT = (
    ((116, 96), (116, 96), (116, 96), (92, 82), (106, 108), (96, 108)),
    ((120, 101), (120, 101), (120, 101), (114, 106), (104, 120), (98, 112)),
)


def remove_baked_checker(image: Image.Image) -> Image.Image:
    """Remove the generated near-neutral white checker while preserving colored FX."""
    rgba = np.asarray(image.convert("RGBA")).copy()
    rgb = rgba[:, :, :3].astype(np.int16)
    high = rgb.min(axis=2) >= 225
    neutral = rgb.max(axis=2) - rgb.min(axis=2) <= 18
    rgba[high & neutral, 3] = 0

    # Erase tiny pale matte fragments adjacent to transparency, without touching
    # oil highlights or warm flame cores.
    for _ in range(2):
        alpha = rgba[:, :, 3]
        clear = alpha == 0
        neighbor_clear = np.zeros_like(clear)
        neighbor_clear[1:] |= clear[:-1]
        neighbor_clear[:-1] |= clear[1:]
        neighbor_clear[:, 1:] |= clear[:, :-1]
        neighbor_clear[:, :-1] |= clear[:, 1:]
        pale = (rgb.min(axis=2) >= 210) & (rgb.max(axis=2) - rgb.min(axis=2) <= 24)
        rgba[pale & neighbor_clear, 3] = 0

    rgba[rgba[:, :, 3] < 96, 3] = 0
    rgba[rgba[:, :, 3] >= 96, 3] = 255
    rgba[rgba[:, :, 3] == 0, :3] = 0
    return Image.fromarray(rgba, "RGBA")


def crop_visible(image: Image.Image) -> Image.Image:
    box = image.getchannel("A").getbbox()
    if not box:
        raise RuntimeError("source cell became empty after checker removal")
    return image.crop(box)


def fit_sprite(image: Image.Image, maximum: tuple[int, int]) -> Image.Image:
    scale = min(maximum[0] / image.width, maximum[1] / image.height)
    size = (max(1, round(image.width * scale)), max(1, round(image.height * scale)))
    resized = image.resize(size, Image.Resampling.LANCZOS)
    data = np.asarray(resized).copy()
    data[:, :, 3] = np.where(data[:, :, 3] >= 92, 255, 0).astype(np.uint8)
    data[data[:, :, 3] == 0, :3] = 0
    return Image.fromarray(data, "RGBA")


def quantize_shared(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    result = image.quantize(colors=112, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE).convert("RGBA")
    result.putalpha(alpha)
    return result


def compose_runtime_preview(atlas: Image.Image) -> Image.Image:
    ground = Image.open(GROUND).convert("RGB").resize((960, 440), Image.Resampling.BICUBIC).convert("RGBA")
    overlay = Image.new("RGBA", ground.size, (0, 0, 0, 0))

    def frame(row: int, column: int) -> Image.Image:
        return atlas.crop((column * CELL, row * CELL, (column + 1) * CELL, (row + 1) * CELL))

    # Left: wet, connected trail. Right: same trail after the cigarette catches it.
    for index in range(20):
        x = 48 + index * 18
        y = 224 + round(np.sin(index * .72) * 20)
        sprite = frame(0, index % 3).resize((64, 64), Image.Resampling.NEAREST).rotate(-90, resample=Image.Resampling.NEAREST)
        overlay.alpha_composite(sprite, (x - 32, y - 54))
        if index in (2, 5):
            splash = frame(0, 4).resize((52, 52), Image.Resampling.NEAREST)
            overlay.alpha_composite(splash, (x - 26, y - 46))

    for index in range(20):
        x = 548 + index * 18
        y = 229 + round(np.sin(index * .64) * 18)
        oil = frame(0, index % 3).resize((64, 64), Image.Resampling.NEAREST)
        fire = frame(1, index % 3).resize((72, 72), Image.Resampling.NEAREST)
        overlay.alpha_composite(oil, (x - 32, y - 54))
        overlay.alpha_composite(fire, (x - 36, y - 65))
        if index in (1, 5):
            smoke = frame(1, 4).resize((66, 66), Image.Resampling.NEAREST)
            overlay.alpha_composite(smoke, (x - 33, y - 86))

    ground.alpha_composite(overlay)
    return ground


def build() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    expected = (SOURCE_CELL[0] * COLUMNS, SOURCE_CELL[1] * ROWS)
    if source.size != expected:
        raise SystemExit(f"unexpected source size {source.size}; expected {expected}")
    source = remove_baked_checker(source)
    atlas = Image.new("RGBA", (CELL * COLUMNS, CELL * ROWS), (0, 0, 0, 0))
    for row in range(ROWS):
        for column in range(COLUMNS):
            raw = source.crop((column * SOURCE_CELL[0], row * SOURCE_CELL[1], (column + 1) * SOURCE_CELL[0], (row + 1) * SOURCE_CELL[1]))
            sprite = fit_sprite(crop_visible(raw), FIT[row][column])
            x = column * CELL + (CELL - sprite.width) // 2
            y = row * CELL + BASELINE - sprite.height
            atlas.alpha_composite(sprite, (x, y))

    atlas = quantize_shared(atlas)
    DESTINATION.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(DESTINATION)
    ATLAS_PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    atlas.resize((atlas.width * 2, atlas.height * 2), Image.Resampling.NEAREST).save(ATLAS_PREVIEW)
    compose_runtime_preview(atlas).save(RUNTIME_PREVIEW)
    print(f"saved={DESTINATION} size={atlas.size} cells=12")
    print(f"preview={RUNTIME_PREVIEW}")


if __name__ == "__main__":
    build()
