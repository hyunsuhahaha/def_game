"""Bake clear-cut scenery and machinery at their real on-screen pixel size."""

from pathlib import Path

import numpy as np
from PIL import Image, ImageEnhance


ROOT = Path(__file__).resolve().parents[1]
SPECS = (
    ("assets/tree-v1.png", "assets/trees/broadleaf-tree-pixel-v2.png", (193, 208), 88, 0.88),
    ("assets/trees/pine-tree-v1.png", "assets/trees/pine-tree-pixel-v2.png", (151, 226), 88, 0.90),
    ("assets/trees/birch-tree-v1.png", "assets/trees/birch-tree-pixel-v2.png", (144, 216), 88, 0.86),
    ("assets/trees/maple-tree-v1.png", "assets/trees/maple-tree-pixel-v2.png", (151, 226), 96, 0.88),
    ("assets/characters/ingame/developer-bulldozer-v1.png", "assets/characters/ingame/developer-bulldozer-pixel-v2.png", (192, 140), 96, 1.04),
)


def bake(source_name: str, destination_name: str, size: tuple[int, int], colors: int, saturation: float) -> None:
    source = Image.open(ROOT / source_name).convert("RGBA")
    image = source.resize(size, Image.Resampling.LANCZOS)
    image = ImageEnhance.Contrast(image).enhance(1.08)
    image = ImageEnhance.Color(image).enhance(saturation)
    image = ImageEnhance.Brightness(image).enhance(1.02)

    array = np.asarray(image).copy()
    alpha = array[:, :, 3]
    array[:, :, 3] = np.where(alpha >= 76, 255, 0).astype(np.uint8)
    array[array[:, :, 3] == 0, :3] = 0
    image = Image.fromarray(array, "RGBA")
    hard_alpha = image.getchannel("A")
    image = image.quantize(colors=colors, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE).convert("RGBA")
    image.putalpha(hard_alpha)

    destination = ROOT / destination_name
    destination.parent.mkdir(parents=True, exist_ok=True)
    image.save(destination)
    print(f"saved={destination_name} size={size[0]}x{size[1]} colors={colors}")


for spec in SPECS:
    bake(*spec)
