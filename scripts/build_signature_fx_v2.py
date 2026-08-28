"""Bake authored source concepts into fixed-grid gameplay FX atlases."""
from __future__ import annotations

from pathlib import Path
import json

import numpy as np
from PIL import Image, ImageEnhance


ROOT = Path(__file__).resolve().parents[1]
FX = ROOT / "assets/fx"
CONCEPTS = FX / "concepts"
PREVIEWS = ROOT / "docs/previews"

REGROWTH_SOURCE = CONCEPTS / "regrowth-cast-fx-source-v2.png"
VEGAN_SOURCE = CONCEPTS / "vegan-fork-consume-fx-source-v2.png"
REGROWTH_ATLAS = FX / "regrowth-cast-atlas-v2.png"
VEGAN_IMPACT_ATLAS = FX / "vegan-fork-impact-atlas-v2.png"
VEGAN_CONSUME_ATLAS = FX / "vegan-fork-consume-atlas-v2.png"


def trim(image: Image.Image, threshold: int = 20) -> Image.Image:
    rgba = image.convert("RGBA")
    alpha = np.asarray(rgba.getchannel("A"))
    yy, xx = np.nonzero(alpha >= threshold)
    if not len(xx):
        raise ValueError("empty FX source cell")
    return rgba.crop((int(xx.min()), int(yy.min()), int(xx.max()) + 1, int(yy.max()) + 1))


def fixed_cell(source: Image.Image, box: tuple[int, int, int, int], size: int,
               max_width: int, max_height: int, foot: int) -> Image.Image:
    art = trim(source.crop(box))
    scale = min(max_width / art.width, max_height / art.height)
    art = art.resize((max(1, round(art.width * scale)), max(1, round(art.height * scale))),
                     Image.Resampling.LANCZOS)
    # Lock the generated concept to the project's crisp fixed grid and material ramps.
    alpha = art.getchannel("A").point(lambda value: 255 if value >= 72 else 0)
    rgb = ImageEnhance.Color(ImageEnhance.Contrast(art.convert("RGB")).enhance(1.06)).enhance(1.04)
    art = rgb.quantize(colors=112, method=Image.Quantize.FASTOCTREE,
                       dither=Image.Dither.FLOYDSTEINBERG).convert("RGBA")
    art.putalpha(alpha)
    data = np.asarray(art).copy()
    data[data[:, :, 3] == 0, :3] = 0
    art = Image.fromarray(data, "RGBA")
    cell = Image.new("RGBA", (size, size))
    cell.alpha_composite(art, ((size - art.width) // 2, foot - art.height))
    return cell


def horizontal_atlas(cells: list[Image.Image]) -> Image.Image:
    size = cells[0].width
    atlas = Image.new("RGBA", (size * len(cells), size))
    for index, cell in enumerate(cells):
        atlas.alpha_composite(cell, (index * size, 0))
    alpha = atlas.getchannel("A")
    atlas = atlas.convert("RGB").quantize(colors=112, method=Image.Quantize.FASTOCTREE,
                                           dither=Image.Dither.FLOYDSTEINBERG).convert("RGBA")
    atlas.putalpha(alpha)
    data = np.asarray(atlas).copy()
    data[data[:, :, 3] == 0, :3] = 0
    return Image.fromarray(data, "RGBA")


def build_regrowth(source: Image.Image) -> Image.Image:
    width, height = source.size
    frame_width = width / 6
    cells = []
    for index in range(6):
        x0, x1 = round(index * frame_width), round((index + 1) * frame_width)
        cells.append(fixed_cell(source, (x0, 0, x1, height), 192, 178, 178, 187))
    return horizontal_atlas(cells)


def vegan_boxes(width: int, height: int) -> list[tuple[int, int, int, int]]:
    # The source deliberately overlaps speed trails; these hand-locked cuts preserve
    # eight readable poses rather than treating transparent gaps as frame boundaries.
    cuts = [0, 305, 590, 850, 1110, 1400, 1670, 1910, width]
    return [(cuts[i], 0, cuts[i + 1], height) for i in range(8)]


def build_vegan(source: Image.Image) -> tuple[Image.Image, Image.Image]:
    boxes = vegan_boxes(*source.size)
    consume = [fixed_cell(source, box, 160, 154, 148, 154) for box in boxes]
    impact_indices = [0, 1, 2, 4, 6, 7]
    impact = [fixed_cell(source, boxes[index], 128, 122, 116, 122)
              for index in impact_indices]
    return horizontal_atlas(impact), horizontal_atlas(consume)


def color_count(image: Image.Image) -> int:
    rgba = np.asarray(image.convert("RGBA"))
    return len({tuple(pixel[:3]) for pixel in rgba.reshape(-1, 4) if pixel[3]})


def frames(atlas: Image.Image, cell: int) -> list[Image.Image]:
    return [atlas.crop((index * cell, 0, (index + 1) * cell, cell))
            for index in range(atlas.width // cell)]


def motion_preview(atlas: Image.Image, cell: int, display: int, path: Path) -> None:
    output = []
    for frame in frames(atlas, cell):
        canvas = Image.new("RGBA", (display + 48, display + 48), (70, 103, 45, 255))
        sprite = frame.resize((display, display), Image.Resampling.NEAREST)
        canvas.alpha_composite(sprite, (24, 24))
        output.append(canvas.convert("RGB").quantize(colors=128, method=Image.Quantize.FASTOCTREE,
                                                      dither=Image.Dither.NONE))
    output[0].save(path, save_all=True, append_images=output[1:], duration=105,
                   loop=0, disposal=2)


def main() -> None:
    FX.mkdir(parents=True, exist_ok=True)
    PREVIEWS.mkdir(parents=True, exist_ok=True)
    regrowth = build_regrowth(Image.open(REGROWTH_SOURCE).convert("RGBA"))
    impact, consume = build_vegan(Image.open(VEGAN_SOURCE).convert("RGBA"))
    regrowth.save(REGROWTH_ATLAS)
    impact.save(VEGAN_IMPACT_ATLAS)
    consume.save(VEGAN_CONSUME_ATLAS)
    preview = Image.new("RGBA", (1152, 512), (24, 38, 23, 255))
    preview.alpha_composite(regrowth.resize((1152, 192), Image.Resampling.NEAREST), (0, 0))
    preview.alpha_composite(impact.resize((768, 128), Image.Resampling.NEAREST), (0, 210))
    preview.alpha_composite(consume.resize((1024, 128), Image.Resampling.NEAREST), (0, 360))
    preview.save(PREVIEWS / "signature-fx-v2-atlases.png")
    display = Image.new("RGBA", (960, 360), (70, 103, 45, 255))
    for index, frame in enumerate(frames(regrowth, 192)):
        display.alpha_composite(frame.resize((100, 100), Image.Resampling.NEAREST),
                                (30 + index * 150, 25))
    for index, frame in enumerate(frames(consume, 160)):
        display.alpha_composite(frame.resize((115, 115), Image.Resampling.NEAREST),
                                (12 + index * 118, 205))
    display.save(PREVIEWS / "signature-fx-v2-display-scale.png")
    motion_preview(regrowth, 192, 100, PREVIEWS / "regrowth-cast-v2-motion.gif")
    motion_preview(consume, 160, 115, PREVIEWS / "vegan-fork-consume-v2-motion.gif")
    report = {
        "regrowth": {"path": str(REGROWTH_ATLAS.relative_to(ROOT)), "cell": 192, "frames": 6,
                     "colors": color_count(regrowth)},
        "veganImpact": {"path": str(VEGAN_IMPACT_ATLAS.relative_to(ROOT)), "cell": 128, "frames": 6,
                        "colors": color_count(impact)},
        "veganConsume": {"path": str(VEGAN_CONSUME_ATLAS.relative_to(ROOT)), "cell": 160, "frames": 8,
                         "colors": color_count(consume)},
    }
    (PREVIEWS / "signature-fx-v2-build.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print("SIGNATURE_FX_V2_OK", report)


if __name__ == "__main__":
    main()
