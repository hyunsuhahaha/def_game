"""Build the coin-miner mole atlas from authored ImageGen key art.

The source strips preserve the user's squat mole identity. This script only
removes the preview checkerboard, normalises the shared baseline, quantises a
shared palette, and packs the runtime 6x2 atlas. It does not redraw anatomy.
"""

from __future__ import annotations

from pathlib import Path
from statistics import median

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
WALK_SOURCE = ROOT / "assets/characters/concepts/coin-miner-mole-walk-source-v3.png"
ACTION_SOURCE = ROOT / "assets/characters/concepts/coin-miner-mole-action-source-v3.png"
OUT = ROOT / "assets/characters/ingame/coin-miner-mole-atlas-pixel-v3.png"
PREVIEW = ROOT / "docs/previews/coin-miner-mole-atlas-v3.png"
RUNTIME = ROOT / "docs/previews/coin-miner-mole-runtime-v3.png"
GAMEPLAY = ROOT / "docs/previews/coin-miner-burrow-gameplay-v3.png"
TREE = ROOT / "assets/trees/broadleaf-tree-pixel-v2.png"

CELL_W, CELL_H, COLUMNS, FOOT = 192, 384, 6, 380
TARGET_BODY_HEIGHT = 178


def remove_preview_background(source: Image.Image) -> Image.Image:
    """Convert the generator's near-white checker preview to hard alpha."""
    rgb = source.convert("RGB")
    out = Image.new("RGBA", rgb.size)
    src, dst = rgb.load(), out.load()
    for y in range(rgb.height):
        for x in range(rgb.width):
            r, g, b = src[x, y]
            is_preview = min(r, g, b) >= 224 and max(r, g, b) - min(r, g, b) <= 15
            dst[x, y] = (r, g, b, 0 if is_preview else 255)
    return out


def source_cells(path: Path) -> list[Image.Image]:
    image = remove_preview_background(Image.open(path))
    cells: list[Image.Image] = []
    for index in range(COLUMNS):
        left = round(index * image.width / COLUMNS)
        right = round((index + 1) * image.width / COLUMNS)
        segment = image.crop((left, 0, right, image.height))
        box = segment.getchannel("A").getbbox()
        if not box:
            raise RuntimeError(f"empty generated cell {index} in {path.name}")
        cells.append(segment.crop(box))
    return cells


def pack_cells(walk: list[Image.Image], action: list[Image.Image]) -> Image.Image:
    # One scale is shared by every frame. Squashes, diving and dirt mounds keep
    # their authored relative sizes instead of pumping independently.
    scale = TARGET_BODY_HEIGHT / median(frame.height for frame in walk)
    atlas = Image.new("RGBA", (CELL_W * COLUMNS, CELL_H * 2))
    for row, frames in enumerate((walk, action)):
        for column, frame in enumerate(frames):
            local_scale = min(scale, (CELL_W - 8) / frame.width, (CELL_H - 8) / frame.height)
            size = (max(1, round(frame.width * local_scale)), max(1, round(frame.height * local_scale)))
            cooked = frame.resize(size, Image.Resampling.NEAREST)
            x = column * CELL_W + (CELL_W - cooked.width) // 2
            y = row * CELL_H + FOOT - cooked.height
            atlas.alpha_composite(cooked, (x, y))
    return atlas


def shared_palette(atlas: Image.Image) -> Image.Image:
    alpha = atlas.getchannel("A")
    opaque_on_black = Image.new("RGB", atlas.size, (0, 0, 0))
    opaque_on_black.paste(atlas.convert("RGB"), mask=alpha)
    quantized = opaque_on_black.quantize(colors=112, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGBA")
    quantized.putalpha(alpha.point(lambda value: 255 if value else 0))
    return quantized


def make_runtime_preview(atlas: Image.Image) -> Image.Image:
    canvas = Image.new("RGB", (1180, 500), (89, 126, 61))
    draw = ImageDraw.Draw(canvas)
    for x in range(0, canvas.width, 16):
        for y in range(0, canvas.height, 16):
            delta = 3 if (x // 16 + y // 16) % 2 else -3
            draw.rectangle((x, y, x + 15, y + 15), fill=(89 + delta, 126 + delta, 61 + delta))
    for row in range(2):
        for column in range(COLUMNS):
            cell = atlas.crop((column * CELL_W, row * CELL_H, (column + 1) * CELL_W, (row + 1) * CELL_H))
            shown = cell.resize((round(CELL_W * .48), round(CELL_H * .48)), Image.Resampling.NEAREST)
            canvas.paste(shown, (28 + column * 190, 20 + row * 236), shown)
    return canvas


def make_gameplay_preview(atlas: Image.Image) -> Image.Image:
    canvas = Image.new("RGB", (1000, 480), (87, 125, 60))
    draw = ImageDraw.Draw(canvas)
    for x in range(0, canvas.width, 16):
        for y in range(0, canvas.height, 16):
            delta = 3 if (x // 16 + y // 16) % 2 else -3
            draw.rectangle((x, y, x + 15, y + 15), fill=(87 + delta, 125 + delta, 60 + delta))
    tree = Image.open(TREE).convert("RGBA")
    ground = 410
    # Standing target tree, underground travelling mound, airborne sideways
    # tree and a second target make scale/readability mismatches obvious.
    canvas.paste(tree, (232, ground - round(tree.height * .91)), tree)
    canvas.paste(tree, (835, ground - round(tree.height * .91)), tree)
    scratch = atlas.crop((2 * CELL_W, CELL_H, 3 * CELL_W, CELL_H * 2)).resize((92, 184), Image.Resampling.NEAREST)
    mound = atlas.crop((5 * CELL_W, CELL_H, 6 * CELL_W, CELL_H * 2)).resize((92, 184), Image.Resampling.NEAREST)
    canvas.paste(scratch, (116, ground - round(FOOT * .48)), scratch)
    canvas.paste(mound, (475, ground - round(FOOT * .48)), mound)
    draw.ellipse((635, 390, 755, 412), fill=(31, 42, 22))
    airborne = tree.resize((round(tree.width * .82), round(tree.height * .82)), Image.Resampling.NEAREST).rotate(-28, resample=Image.Resampling.NEAREST, expand=True)
    canvas.paste(airborne, (620, 138), airborne)
    return canvas


def main() -> None:
    walk, action = source_cells(WALK_SOURCE), source_cells(ACTION_SOURCE)
    atlas = shared_palette(pack_cells(walk, action))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(OUT)
    atlas.resize((atlas.width * 2, atlas.height * 2), Image.Resampling.NEAREST).save(PREVIEW)
    make_runtime_preview(atlas).save(RUNTIME)
    make_gameplay_preview(atlas).save(GAMEPLAY)

    pixels = list(atlas.get_flattened_data())
    colors = {pixel[:3] for pixel in pixels if pixel[3]}
    assert atlas.size == (CELL_W * COLUMNS, CELL_H * 2)
    assert all(pixel[3] in (0, 255) for pixel in pixels)
    assert 70 <= len(colors) <= 112, len(colors)
    for row in range(2):
        for column in range(COLUMNS):
            box = atlas.crop((column * CELL_W, row * CELL_H, (column + 1) * CELL_W, (row + 1) * CELL_H)).getchannel("A").getbbox()
            assert box and box[3] >= FOOT - 2, (row, column, box)
    print(f"COIN_MINER_MOLE_BUILD_OK atlas={atlas.size} frames=12 colors={len(colors)} foot={FOOT}")
    print(OUT)


if __name__ == "__main__":
    main()
