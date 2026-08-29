"""Build authored, hard-edged pixel overlays for forest floor lighting."""
from pathlib import Path
import math
import random
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "assets/scenery/forest/forest-light-patterns-pixel-v1.png"
CELL, COLS, ROWS = 256, 3, 3


def q(value, step=2):
    return int(round(value / step) * step)


def organic_polygon(cx, cy, rx, ry, seed, points=28):
    rng = random.Random(seed)
    phase = rng.random() * math.tau
    result = []
    for i in range(points):
        angle = phase + i / points * math.tau
        wobble = 1 + math.sin(angle * 3 + phase) * .10 + math.sin(angle * 7 - phase) * .055
        wobble += rng.uniform(-.045, .045)
        result.append((q(cx + math.cos(angle) * rx * wobble), q(cy + math.sin(angle) * ry * wobble)))
    return result


def canopy(cell, seed):
    rng, draw = random.Random(seed), ImageDraw.Draw(cell)
    draw.polygon(organic_polygon(128, 130, 105, 77, seed), fill=(15, 34, 25, 37))
    for i in range(12):
        x, y = q(rng.uniform(48, 208)), q(rng.uniform(63, 193))
        rx, ry = q(rng.uniform(24, 48)), q(rng.uniform(18, 35))
        color = (13, 31, 23, rng.choice((24, 30, 36, 42)))
        draw.ellipse((x-rx, y-ry, x+rx, y+ry), fill=color)
        if i % 3 == 0:
            draw.arc((x-rx, y-ry, x+rx, y+ry), 195, 322, fill=(58, 82, 45, 24), width=3)
    # Broken holes make this read as overlapping leaves, not a dark oval.
    for _ in range(34):
        x, y = q(rng.uniform(30, 226)), q(rng.uniform(44, 212))
        rx, ry = rng.choice((2, 4, 6, 8)), rng.choice((2, 4, 6))
        draw.rectangle((x-rx, y-ry, x+rx, y+ry), fill=(0, 0, 0, 0))
    for _ in range(80):
        x, y = q(rng.uniform(28, 228)), q(rng.uniform(40, 216))
        if rng.random() < .52:
            draw.point((x, y), fill=(76, 93, 48, rng.choice((16, 22, 28))))


def sunlight(cell, seed):
    rng, draw = random.Random(seed), ImageDraw.Draw(cell)
    # Several separated shafts and leaf gaps; no smooth radial gradient.
    for i in range(10):
        angle = rng.uniform(-.18, .18)
        cx, cy = q(rng.uniform(44, 215)), q(rng.uniform(45, 210))
        rx, ry = q(rng.uniform(13, 37)), q(rng.uniform(8, 23))
        pts = organic_polygon(cx, cy, rx, ry, seed * 31 + i, 18)
        color = rng.choice(((255, 230, 145, 35), (245, 214, 118, 42), (255, 241, 178, 48)))
        draw.polygon(pts, fill=color)
        if i % 2 == 0:
            dx = q(math.sin(angle) * 14)
            draw.line((cx-rx+dx, cy, cx+rx+dx, cy), fill=(255, 246, 192, 42), width=2)
    for _ in range(95):
        x, y = q(rng.uniform(28, 228)), q(rng.uniform(30, 225))
        if rng.random() < .62:
            draw.rectangle((x, y, x+rng.choice((1, 2, 3)), y+rng.choice((1, 2))),
                           fill=(255, 233, 151, rng.choice((18, 24, 31))))


def damp(cell, seed):
    rng, draw = random.Random(seed), ImageDraw.Draw(cell)
    draw.polygon(organic_polygon(128, 142, 108, 66, seed, 34), fill=(12, 50, 45, 34))
    draw.polygon(organic_polygon(121, 145, 82, 45, seed + 73, 30), fill=(20, 60, 50, 25))
    for i in range(15):
        x, y = q(rng.uniform(35, 220)), q(rng.uniform(82, 200))
        length = q(rng.uniform(8, 28))
        color = rng.choice(((63, 96, 67, 26), (9, 42, 39, 31), (86, 106, 66, 18)))
        draw.line((x, y, x + length, y + rng.choice((-2, 0, 2))), fill=color, width=rng.choice((1, 2, 3)))
    for _ in range(70):
        x, y = q(rng.uniform(30, 228)), q(rng.uniform(70, 220))
        draw.point((x, y), fill=(8, 38, 35, rng.choice((16, 22, 28))))


def main():
    atlas = Image.new("RGBA", (CELL * COLS, CELL * ROWS), (0, 0, 0, 0))
    painters = (canopy, sunlight, damp)
    for row, painter in enumerate(painters):
        for col in range(COLS):
            cell = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
            painter(cell, 20260829 + row * 101 + col * 17)
            atlas.alpha_composite(cell, (col * CELL, row * CELL))
    DEST.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(DEST, optimize=True)
    print(f"FOREST_LIGHT_ATLAS_OK {DEST.relative_to(ROOT)} {atlas.width}x{atlas.height}")


if __name__ == "__main__":
    main()
