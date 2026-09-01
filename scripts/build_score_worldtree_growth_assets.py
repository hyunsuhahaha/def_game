"""Build the tier 1-9 score-attack World Tree growth atlases.

The checked-in concept locks the three silhouettes.  This builder removes the
concept background, snaps the art to an authored two-pixel grid, maps it to the
approved forest palette, and creates deterministic damage/motion frames.
"""
from collections import Counter
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/enemies/concepts/score-worldtree-growth-concept-v1.png"
YOUNG_SOURCE = ROOT / "assets/enemies/concepts/score-worldtree-young-concept-v2.png"
OUT_DIR = ROOT / "assets/enemies/arcade"
PREVIEW = ROOT / "docs/previews/score-worldtree-growth-v2-contact-sheet.png"
CELL, FOOT = 512, 492

# Crops isolate the three authored identities in the concept board.  They are
# deliberately not resized versions of one another.
FORMS = (
    {"id": "young", "version": 2, "source": "young", "bg_limit": 48, "crop": (105, 72, 1148, 1164), "max_w": 316, "max_h": 392},
    {"id": "adolescent", "crop": (366, 278, 800, 964), "max_w": 348, "max_h": 430},
    {"id": "precursor", "crop": (794, 30, 1490, 974), "max_w": 430, "max_h": 470},
)


def approved_palette():
    counts = Counter()
    for name in ("broadleaf-tree-cartoon-v3.png", "maple-tree-cartoon-v3.png", "pine-tree-cartoon-v3.png"):
        arr = np.asarray(Image.open(ROOT / "assets/trees" / name).convert("RGBA"))
        for color in map(tuple, arr[:, :, :3][arr[:, :, 3] > 0]):
            counts[color] += 1
    colors = [c for c, _ in counts.most_common(260)]
    green = [c for c in colors if c[1] >= c[0] * .78 and c[1] > c[2] * 1.15]
    bark = [c for c in colors if c[0] > c[1] * 1.03 and c[0] > c[2] * 1.14]
    dark = [c for c in colors if sum(map(int, c)) < 190]
    assert len(green) >= 32 and len(bark) >= 24 and len(dark) >= 10
    return {
        "green": np.asarray(green[:72], dtype=np.int16),
        "bark": np.asarray(bark[:64], dtype=np.int16),
        "dark": np.asarray(dark[:32], dtype=np.int16),
    }


PALETTE = None


def remove_background(crop, bg_limit=15):
    arr = np.asarray(crop.convert("RGBA")).copy()
    rgb = arr[:, :, :3]
    # The generated board uses a near-black empty field.  Grow that field from
    # the edges, so equally dark bark pixels enclosed by the silhouette survive.
    high = np.max(rgb, axis=2)
    chroma = high - np.min(rgb, axis=2)
    # Generated concept boards use a neutral charcoal field.  Saturated dark
    # leaf/bark outlines remain foreground even when their value is low.
    bg_seed = (high <= bg_limit) if bg_limit <= 15 else ((high <= bg_limit) & (chroma <= 10))
    h, w = bg_seed.shape
    seen = np.zeros((h, w), dtype=bool)
    stack = []
    for x in range(w):
        if bg_seed[0, x]: stack.append((x, 0))
        if bg_seed[h - 1, x]: stack.append((x, h - 1))
    for y in range(h):
        if bg_seed[y, 0]: stack.append((0, y))
        if bg_seed[y, w - 1]: stack.append((w - 1, y))
    while stack:
        x, y = stack.pop()
        if seen[y, x] or not bg_seed[y, x]:
            continue
        seen[y, x] = True
        if x: stack.append((x - 1, y))
        if x + 1 < w: stack.append((x + 1, y))
        if y: stack.append((x, y - 1))
        if y + 1 < h: stack.append((x, y + 1))
    alpha = np.where(seen, 0, 255).astype("uint8")
    # Remove isolated generation dust without softening the silhouette.
    mask = Image.fromarray(alpha).filter(ImageFilter.MedianFilter(3))
    crop.putalpha(mask)
    bbox = crop.getbbox()
    assert bbox, "empty world-tree form"
    return crop.crop(bbox)


def quantize(frame):
    global PALETTE
    if PALETTE is None:
        PALETTE = approved_palette()
    # Fixed 2 px clusters retain dense bark/leaf information without subpixel noise.
    frame = frame.resize((CELL // 2, CELL // 2), Image.Resampling.NEAREST).resize((CELL, CELL), Image.Resampling.NEAREST)
    arr = np.asarray(frame).copy()
    mask = arr[:, :, 3] >= 128
    pixels = arr[:, :, :3][mask].astype(np.int16)
    mapped = np.empty_like(pixels)
    for start in range(0, len(pixels), 24000):
        chunk = pixels[start:start + 24000]
        lum = chunk.sum(axis=1)
        foliage = (chunk[:, 1] >= chunk[:, 0] * .78) & (chunk[:, 1] > chunk[:, 2] * 1.15) & (lum >= 150)
        dark = lum < 150
        bark = ~foliage & ~dark
        result = np.empty_like(chunk)
        for selection, key in ((foliage, "green"), (bark, "bark"), (dark, "dark")):
            if not selection.any():
                continue
            part = chunk[selection]
            palette = PALETTE[key]
            distance = ((part[:, None, :] - palette[None, :, :]) ** 2).sum(axis=2)
            result[selection] = palette[distance.argmin(axis=1)]
        mapped[start:start + len(chunk)] = result
    arr[:, :, :3][mask] = mapped
    arr[:, :, 3] = np.where(mask, 255, 0)
    return Image.fromarray(arr.astype("uint8"), "RGBA")


def base_frame(src, spec):
    art = remove_background(src.crop(spec["crop"]), spec.get("bg_limit", 15))
    scale = min(spec["max_w"] / art.width, spec["max_h"] / art.height)
    size = (round(art.width * scale), round(art.height * scale))
    art = art.resize(size, Image.Resampling.NEAREST)
    frame = Image.new("RGBA", (CELL, CELL))
    frame.alpha_composite(art, ((CELL - size[0]) // 2, FOOT - size[1]))
    return quantize(frame)


def erase_ellipse(frame, box):
    alpha = frame.getchannel("A")
    ImageDraw.Draw(alpha).ellipse(box, fill=0)
    frame.putalpha(alpha)


def damage(base, stage, form_index):
    frame = base.copy()
    # Damage travels from outer crown into branches and finally the trunk.  The
    # positions are form-relative but remain deterministic for every rebuild.
    bites = (
        ((112, 126, 220, 224), (302, 132, 410, 230)),
        ((82, 214, 232, 330), (290, 74, 448, 208)),
        ((260, 238, 444, 382), (72, 92, 250, 246)),
    )[form_index]
    if stage >= 1:
        erase_ellipse(frame, bites[0])
    if stage >= 2:
        erase_ellipse(frame, bites[1])
    d = ImageDraw.Draw(frame)
    if stage >= 1:
        d.line((258, 326, 245, 355, 261, 380), fill=(54, 36, 22, 255), width=6)
        d.line((260, 326, 249, 354), fill=(153, 92, 39, 255), width=2)
    if stage >= 2:
        d.line((236, 376, 266, 398, 247, 426, 274, 452), fill=(48, 31, 19, 255), width=8)
        d.polygon(((217, 298), (245, 286), (264, 304), (245, 323), (220, 317)), fill=(50, 32, 18, 255))
        d.polygon(((224, 300), (244, 293), (254, 304), (242, 315), (226, 311)), fill=(216, 145, 64, 255))
    if stage >= 3:
        erase_ellipse(frame, (332, 202, 474, 344))
        d.line((278, 342, 294, 377, 276, 408, 302, 444), fill=(43, 29, 18, 255), width=9)
        d.line((281, 344, 292, 376), fill=(177, 105, 43, 255), width=3)
    return frame


def leaf_motion(frame, phase):
    if phase == 0:
        return frame
    # Only the upper crown shifts two native pixels.  Roots/foot stay locked.
    out = frame.copy()
    crown = frame.crop((42, 28, 470, 274))
    alpha = crown.getchannel("A")
    clear = out.getchannel("A")
    mask = Image.new("L", out.size)
    mask.paste(alpha, (42, 28))
    clear_arr = np.asarray(clear).copy()
    clear_arr[np.asarray(mask) > 0] = 0
    out.putalpha(Image.fromarray(clear_arr.astype("uint8")))
    out.alpha_composite(crown, (42 + phase * 2, 28))
    return out


def main():
    sources = {"growth": Image.open(SOURCE).convert("RGBA"),
               "young": Image.open(YOUNG_SOURCE).convert("RGBA")}
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    preview = Image.new("RGB", (1440, 620), (35, 43, 27))
    all_colors = set()
    for form_index, spec in enumerate(FORMS):
        base = base_frame(sources[spec.get("source", "growth")], spec)
        atlas = Image.new("RGBA", (CELL * 6, CELL * 2))
        frames = []
        for stage in range(4):
            hurt = quantize(damage(base, stage, form_index))
            for phase in (-1, 0, 1):
                frames.append(leaf_motion(hurt, phase))
        for index, frame in enumerate(frames):
            atlas.alpha_composite(frame, ((index % 6) * CELL, (index // 6) * CELL))
        out = OUT_DIR / f"score-worldtree-{spec['id']}-atlas-v{spec.get('version', 1)}.png"
        atlas.save(out, optimize=True)
        opaque = np.asarray(atlas)[:, :, 3] > 0
        all_colors.update(map(tuple, np.asarray(atlas)[:, :, :3][opaque]))
        thumb = frames[1].resize((440, 440), Image.Resampling.NEAREST)
        preview.paste(thumb, (20 + form_index * 470, 38), thumb)
        # Small strip proves that all four damage states remain visually distinct.
        for stage in range(4):
            mini = frames[stage * 3 + 1].resize((104, 104), Image.Resampling.NEAREST)
            preview.paste(mini, (22 + form_index * 470 + stage * 108, 500), mini)
    preview.save(PREVIEW, optimize=True)
    print(f"SCORE_WORLDTREE_GROWTH_BUILD_OK forms=3 cell={CELL} frames=36 colors={len(all_colors)}")


if __name__ == "__main__":
    main()
