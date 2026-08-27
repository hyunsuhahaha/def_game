"""Build the fixed female vegan model, fork equipment, and comic fork/chomp FX."""
from __future__ import annotations

from collections import deque
from pathlib import Path
import json
import math

import numpy as np
from PIL import Image, ImageDraw, ImageEnhance


ROOT = Path(__file__).resolve().parents[1]
CONCEPTS = ROOT / "assets/characters/concepts"
INGAME = ROOT / "assets/characters/ingame"
FX = ROOT / "assets/fx"
PREVIEWS = ROOT / "docs/previews"
WOMAN_SOURCE = CONCEPTS / "vegan-woman-model-v3-source.png"
FORK_SOURCE = CONCEPTS / "vegan-fork-model-v1-source.png"
WOMAN_MODEL = CONCEPTS / "vegan-woman-model-v3.png"
ATLAS = INGAME / "vegan-atlas-pixel-v3.png"
FORK = INGAME / "vegan-fork-pixel-v1.png"
IMPACT = FX / "vegan-fork-impact-atlas-v1.png"
CHOMP = FX / "vegan-chomp-atlas-v1.png"


def edge_extract(image: Image.Image, eligible) -> Image.Image:
    array = np.asarray(image.convert("RGBA")).copy()
    height, width = array.shape[:2]
    mask = eligible(array)
    outside = np.zeros((height, width), dtype=bool)
    queue = deque()
    for x in range(width):
        queue.append((x, 0)); queue.append((x, height - 1))
    for y in range(height):
        queue.append((0, y)); queue.append((width - 1, y))
    while queue:
        x, y = queue.popleft()
        if x < 0 or x >= width or y < 0 or y >= height or outside[y, x] or not mask[y, x]:
            continue
        outside[y, x] = True
        queue.extend(((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))
    array[outside] = 0
    array[:, :, 3] = np.where(array[:, :, 3] >= 40, 255, 0).astype(np.uint8)
    array[array[:, :, 3] == 0, :3] = 0
    result = Image.fromarray(array, "RGBA")
    bounds = result.getchannel("A").getbbox()
    assert bounds
    return result.crop(bounds)


def checker(array: np.ndarray) -> np.ndarray:
    rgb = array[:, :, :3].astype(np.int16)
    return (rgb.min(axis=2) >= 225) & ((rgb.max(axis=2) - rgb.min(axis=2)) <= 18)


def black(array: np.ndarray) -> np.ndarray:
    return array[:, :, :3].max(axis=2) <= 12


def quantize_rgba(image: Image.Image, colors: int = 96) -> Image.Image:
    alpha = image.getchannel("A").point(lambda a: 255 if a >= 72 else 0)
    rgb = ImageEnhance.Color(ImageEnhance.Contrast(image.convert("RGB")).enhance(1.05)).enhance(1.05)
    result = rgb.quantize(colors=colors, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE).convert("RGBA")
    result.putalpha(alpha)
    data = np.asarray(result).copy(); data[data[:, :, 3] == 0, :3] = 0
    return Image.fromarray(data, "RGBA")


def body_frame(model: Image.Image, angle: float, sx: float, sy: float, dx: int, bob: int) -> Image.Image:
    target_w = max(1, round(88 * sx)); target_h = max(1, round(140 * sy))
    body = model.resize((target_w, target_h), Image.Resampling.LANCZOS)
    body = body.rotate(angle, resample=Image.Resampling.BICUBIC, expand=True)
    frame = Image.new("RGBA", (96, 192))
    frame.alpha_composite(body, ((96 - body.width) // 2 + dx, 190 - body.height - bob))
    return frame


def build_character(model: Image.Image) -> Image.Image:
    idle = [(-1, 1.00, 1.00, 0, 0), (0, .98, 1.01, -1, 1), (1, 1.01, .99, 1, 0),
            (0, 1.00, 1.00, 0, 2), (-1, .99, 1.01, -1, 1), (1, 1.01, .99, 1, 0)]
    # Same fixed body, leaning through wind-up -> fork contact -> pull-to-mouth -> cheeky recovery.
    action = [(-4, .98, 1.01, -2, 0), (-8, .96, 1.03, -3, 2), (8, 1.04, .95, 3, -1),
              (12, 1.07, .91, 5, -2), (4, 1.03, .95, 3, 0), (-2, 1.05, .92, 1, -1)]
    atlas = Image.new("RGBA", (576, 384))
    for row, poses in enumerate((idle, action)):
        for column, pose in enumerate(poses):
            atlas.alpha_composite(body_frame(model, *pose), (column * 96, row * 192))
    return quantize_rgba(atlas)


def build_fork(model: Image.Image) -> Image.Image:
    fitted = model.resize((248, max(1, round(model.height * 248 / model.width))), Image.Resampling.LANCZOS)
    if fitted.height > 88:
        fitted = fitted.resize((round(fitted.width * 88 / fitted.height), 88), Image.Resampling.LANCZOS)
    result = Image.new("RGBA", (256, 96))
    result.alpha_composite(fitted, ((256 - fitted.width) // 2, (96 - fitted.height) // 2))
    return quantize_rgba(result, 88)


def build_impact() -> Image.Image:
    atlas = Image.new("RGBA", (96 * 6, 96))
    colors = [(38, 25, 30, 255), (255, 245, 169, 255), (255, 191, 52, 255),
              (188, 242, 91, 255), (104, 170, 53, 255), (224, 233, 222, 255)]
    for frame in range(6):
        cell = Image.new("RGBA", (96, 96)); draw = ImageDraw.Draw(cell)
        radius = 7 + frame * 7
        alpha_step = max(0, 255 - frame * 38)
        points = []
        for i in range(16):
            angle = i * math.pi / 8
            length = radius * (1.25 if i % 2 == 0 else .52)
            points.append((48 + math.cos(angle) * length, 48 + math.sin(angle) * length))
        draw.polygon(points, fill=colors[0])
        inner = [(48 + (x - 48) * .72, 48 + (y - 48) * .72) for x, y in points]
        draw.polygon(inner, fill=(*colors[2][:3], alpha_step))
        core = max(2, 8 - frame); draw.rectangle((48-core, 48-core, 48+core, 48+core), fill=colors[1])
        for i in range(5):
            a = i * 1.27 + frame * .45; r = radius + 10 + i * 2
            x, y = round(48 + math.cos(a) * r), round(48 + math.sin(a) * r)
            draw.rectangle((x-2, y-1, x+2, y+1), fill=colors[3 if i % 2 else 5])
        atlas.alpha_composite(cell, (frame * 96, 0))
    return atlas


def build_chomp() -> Image.Image:
    atlas = Image.new("RGBA", (160 * 8, 160))
    for frame in range(8):
        cell = Image.new("RGBA", (160, 160)); draw = ImageDraw.Draw(cell)
        p = frame / 7
        ring = 24 + p * 48
        # Two blocky bite arcs close around the tree, then burst into salad-like leaf and wood chunks.
        jaw = max(4, round(28 * (1 - abs(p - .45) * 1.55)))
        dark, lime, mint, wood, cream = (23, 45, 25, 255), (142, 230, 55, 255), (101, 255, 168, 255), (156, 91, 40, 255), (255, 242, 178, 255)
        draw.polygon([(80-ring,80-jaw),(80-10,80-jaw//2),(80-22,80),(80-10,80+jaw//2),(80-ring,80+jaw)],fill=dark)
        draw.polygon([(80+ring,80-jaw),(80+10,80-jaw//2),(80+22,80),(80+10,80+jaw//2),(80+ring,80+jaw)],fill=dark)
        draw.rectangle((80-10,80-jaw//3,80+10,80+jaw//3),fill=cream)
        for i in range(18):
            a = i * 2.399 + frame * .38
            r = 14 + p * (28 + (i % 5) * 5)
            x, y = round(80 + math.cos(a) * r), round(80 + math.sin(a) * r * .72)
            size = 2 + (i % 3)
            color = (lime, mint, wood)[i % 3]
            draw.rectangle((x-size,y-size,x+size,y+size),fill=color)
            if i % 4 == 0: draw.point((x-size,y-size),fill=cream)
        atlas.alpha_composite(cell, (frame * 160, 0))
    return atlas


def main() -> None:
    INGAME.mkdir(parents=True, exist_ok=True); FX.mkdir(parents=True, exist_ok=True); PREVIEWS.mkdir(parents=True, exist_ok=True)
    woman = edge_extract(Image.open(WOMAN_SOURCE), checker); woman.save(WOMAN_MODEL)
    fork_model = edge_extract(Image.open(FORK_SOURCE), black)
    atlas = build_character(woman); atlas.save(ATLAS)
    fork = build_fork(fork_model); fork.save(FORK)
    impact, chomp = build_impact(), build_chomp(); impact.save(IMPACT); chomp.save(CHOMP)
    preview = Image.new("RGBA", (1152, 768), (10, 22, 24, 255))
    preview.alpha_composite(atlas.resize((1152, 768), Image.Resampling.NEAREST))
    preview.save(PREVIEWS / "vegan-fork-character-atlas-v3.png")
    report = {"atlas": str(ATLAS.relative_to(ROOT)), "atlasSize": atlas.size, "cell": [96,192], "frames": 12,
              "fork": str(FORK.relative_to(ROOT)), "forkSize": fork.size, "impactFrames": 6, "chompFrames": 8}
    (PREVIEWS / "vegan-fork-v3-build.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print("VEGAN_FORK_ASSETS_OK", report)


if __name__ == "__main__":
    main()
