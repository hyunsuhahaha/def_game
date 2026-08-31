"""Build the fixed-grid gray oil-cat companion and its drum prop."""
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "characters" / "companions"
CELL = 96
FRAMES = 6

INK = (34, 31, 35, 255)
DEEP = (63, 64, 70, 255)
SHADOW = (92, 94, 101, 255)
GRAY = (127, 130, 137, 255)
LIGHT = (158, 160, 165, 255)
CREAM = (222, 210, 191, 255)
PINK = (220, 137, 139, 255)
CYAN = (74, 190, 207, 255)
EYE = (25, 47, 54, 255)


def rect(d, box, fill):
    d.rectangle(tuple(int(v) for v in box), fill=fill)


def tail(d, points, width=7):
    d.line(points, fill=INK, width=width + 4)
    d.line(points, fill=DEEP, width=width)
    for index, (x, y) in enumerate(points[1:-1], 1):
        if index % 2:
            rect(d, (x - 2, y - 2, x + 2, y + 1), SHADOW)


def face(d, x, y):
    # Flat square face: tiny eyes and a two-pixel cat mouth, no projected snout.
    rect(d, (x - 13, y - 14, x + 13, y + 12), INK)
    rect(d, (x - 11, y - 12, x + 11, y + 10), GRAY)
    rect(d, (x - 9, y - 10, x + 8, y - 8), LIGHT)
    # stepped ears
    d.polygon(((x - 12, y - 12), (x - 10, y - 22), (x - 3, y - 13)), fill=INK)
    d.polygon(((x + 3, y - 13), (x + 10, y - 22), (x + 12, y - 12)), fill=INK)
    d.polygon(((x - 10, y - 13), (x - 9, y - 19), (x - 5, y - 13)), fill=PINK)
    d.polygon(((x + 5, y - 13), (x + 9, y - 19), (x + 10, y - 13)), fill=PINK)
    for stripe_x in (-5, 0, 5):
        rect(d, (x + stripe_x - 1, y - 12, x + stripe_x + 1, y - 7), DEEP)
    # cheeks stay flush with the face plane.
    rect(d, (x - 9, y + 1, x + 9, y + 8), CREAM)
    rect(d, (x - 7, y - 3, x - 4, y + 1), CYAN)
    rect(d, (x + 4, y - 3, x + 7, y + 1), CYAN)
    rect(d, (x - 6, y - 2, x - 5, y), EYE)
    rect(d, (x + 5, y - 2, x + 6, y), EYE)
    rect(d, (x - 5, y - 3, x - 5, y - 3), (238, 255, 255, 255))
    rect(d, (x + 6, y - 3, x + 6, y - 3), (238, 255, 255, 255))
    rect(d, (x - 1, y + 3, x + 1, y + 5), PINK)
    rect(d, (x - 3, y + 6, x - 1, y + 7), INK)
    rect(d, (x + 1, y + 6, x + 3, y + 7), INK)
    rect(d, (x - 2, y + 7, x + 2, y + 8), INK)
    rect(d, (x - 13, y - 1, x - 16, y), DEEP)
    rect(d, (x + 13, y - 1, x + 16, y), DEEP)


def body(d, x, y, width=38, height=23):
    rect(d, (x - width // 2 - 2, y - height, x + width // 2 + 2, y + 1), INK)
    rect(d, (x - width // 2, y - height + 2, x + width // 2, y - 1), GRAY)
    rect(d, (x - width // 2 + 3, y - height + 3, x + width // 2 - 4, y - height + 6), LIGHT)
    rect(d, (x - width // 2 + 2, y - 5, x + width // 2 - 2, y - 1), SHADOW)
    for stripe_x in (-9, 0, 9):
        rect(d, (x + stripe_x - 2, y - height + 4, x + stripe_x + 1, y - height + 10), DEEP)


def paw(d, x, y, lifted=0):
    rect(d, (x - 4, y - 7 - lifted, x + 4, y + 1 - lifted), INK)
    rect(d, (x - 2, y - 5 - lifted, x + 3, y - 1 - lifted), CREAM)


def draw_run(frame):
    image = Image.new("RGBA", (CELL, CELL))
    d = ImageDraw.Draw(image)
    bounce = (0, -2, -1, 0, -2, -1)[frame]
    phase = (frame % 3) - 1
    base = 78 + bounce
    body(d, 43, base - 3, 40, 22)
    tail(d, [(23, base - 17), (14, base - 25 - phase), (10, base - 36), (14, base - 43)])
    face(d, 66, base - 22)
    paw(d, 32 + phase * 3, base)
    paw(d, 50 - phase * 3, base)
    return image


def draw_push(frame):
    image = Image.new("RGBA", (CELL, CELL))
    d = ImageDraw.Draw(image)
    lean = (0, 2, 4, 6, 5, 2)[frame]
    base = 80
    tail(d, [(33, 64), (22, 57), (20, 45), (25, 38)])
    body(d, 42 + lean // 2, base - 4, 28, 33)
    face(d, 48 + lean, 43)
    paw(d, 66 + lean, 53, 2)
    paw(d, 69 + lean, 64, 2)
    paw(d, 35, base)
    paw(d, 48, base)
    return image


def draw_jump(frame):
    image = Image.new("RGBA", (CELL, CELL))
    d = ImageDraw.Draw(image)
    stretch = (0, 3, 6, 8, 4, 1)[frame]
    base = 72 - (0, 5, 10, 14, 8, 2)[frame]
    body(d, 43, base, 38 + stretch, 20)
    tail(d, [(23 - stretch // 2, base - 12), (15, base - 21), (13, base - 31), (17, base - 38)])
    face(d, 67 + stretch // 2, base - 18)
    paw(d, 33 - stretch // 2, base + 2, 2)
    paw(d, 49 + stretch // 2, base + 2, 2)
    return image


def build_cat():
    atlas = Image.new("RGBA", (CELL * FRAMES, CELL * 3))
    for row, drawer in enumerate((draw_run, draw_push, draw_jump)):
        for frame in range(FRAMES):
            atlas.alpha_composite(drawer(frame), (frame * CELL, row * CELL))
    atlas.save(OUT / "gray-oil-cat-atlas-pixel-v1.png")


def build_drum():
    image = Image.new("RGBA", (128, 128))
    d = ImageDraw.Draw(image)
    # Upright barrel, authored as hard stepped metal clusters.
    d.polygon(((35, 25), (91, 25), (98, 34), (94, 108), (34, 108), (30, 34)), fill=INK)
    rect(d, (36, 29, 90, 105), (53, 61, 65, 255))
    rect(d, (40, 33, 86, 102), (70, 79, 83, 255))
    rect(d, (43, 34, 52, 101), (94, 103, 105, 255))
    rect(d, (78, 34, 86, 102), (42, 49, 53, 255))
    for y in (34, 57, 87, 104):
        rect(d, (32, y - 3, 94, y + 3), INK)
        rect(d, (36, y - 1, 90, y + 1), (120, 88, 58, 255))
    rect(d, (47, 25, 79, 29), (112, 120, 120, 255))
    rect(d, (56, 68, 75, 85), (39, 45, 48, 255))
    rect(d, (59, 71, 72, 82), (188, 124, 50, 255))
    rect(d, (63, 73, 68, 80), (225, 166, 69, 255))
    # small rust chips, deliberately sparse
    for x, y in ((40, 43), (84, 53), (46, 94), (81, 97), (37, 72)):
        rect(d, (x, y, x + 3, y + 2), (134, 75, 42, 255))
    image.save(OUT / "oil-drum-pixel-v1.png")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    build_cat()
    build_drum()
    print("GRAY_OIL_CAT_ASSETS_OK atlas=576x288 cell=96x96 frames=18 drum=128x128")


if __name__ == "__main__":
    main()
