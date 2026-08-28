"""Author world-space climbing and ground-vine pixel sprites."""
from pathlib import Path
import random

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/scenery/biomes/world-vines-atlas-pixel-v1.png"
PREVIEW = ROOT / "docs/previews/world-vines-v1-assets.png"
CELL_W, CELL_H, FRAMES = 160, 224, 6

OUTLINE = (13, 28, 18, 255)
STEM_DEEP = (24, 48, 27, 255)
STEM_DARK = (38, 73, 34, 255)
STEM_MID = (58, 101, 43, 255)
STEM_LIGHT = (91, 132, 54, 255)
LEAF_DEEP = (20, 47, 29, 255)
LEAF_DARK = (35, 73, 38, 255)
LEAF_MID = (55, 105, 47, 255)
LEAF_GREEN = (78, 129, 55, 255)
LEAF_LIGHT = (113, 153, 65, 255)
LEAF_TIP = (151, 174, 75, 255)
BARK_DEEP = (48, 37, 27, 255)
BARK_MID = (83, 61, 37, 255)
BARK_LIGHT = (123, 86, 43, 255)
DRY_DARK = (68, 57, 35, 255)
DRY_LIGHT = (132, 112, 58, 255)


def draw_stem(draw, points, width=7):
    draw.line(points, fill=OUTLINE, width=width, joint="curve")
    draw.line(points, fill=STEM_DARK, width=width - 2, joint="curve")
    draw.line(points, fill=STEM_MID, width=max(2, width - 4), joint="curve")
    for index in range(len(points) - 1):
        x0, y0 = points[index]
        x1, y1 = points[index + 1]
        draw.line((x0 - 1, y0, x1 - 1, y1), fill=STEM_LIGHT, width=1)


def draw_leaf(draw, x, y, direction, size, tone=0):
    tip_x, tip_y = x + direction * size, y - size // 3
    top = y - size * 2 // 3
    bottom = y + size // 2
    polygon = [(x, y), (x + direction * size // 3, top),
               (x + direction * size * 3 // 4, top + 1), (tip_x, tip_y),
               (x + direction * size * 3 // 4, bottom), (x + direction * size // 3, bottom - 1)]
    draw.polygon(polygon, fill=OUTLINE)
    inset = [(x + direction * 2, y), (x + direction * size // 3, top + 2),
             (x + direction * size * 2 // 3, top + 3), (tip_x - direction * 3, tip_y),
             (x + direction * size * 2 // 3, bottom - 2), (x + direction * size // 3, bottom - 2)]
    ramps = ((LEAF_DARK, LEAF_MID), (LEAF_MID, LEAF_GREEN), (LEAF_GREEN, LEAF_LIGHT))
    dark, light = ramps[tone % len(ramps)]
    draw.polygon(inset, fill=dark)
    draw.line((x + direction * 2, y, tip_x - direction * 3, tip_y), fill=light, width=1)
    if size >= 12:
        draw.point((tip_x - direction * 3, tip_y), fill=LEAF_TIP)
        draw.point((x + direction * size // 2, y + (1 if tone % 2 else -1)), fill=light)


def climbing(frame):
    image = Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random(20260831 + frame * 991)
    if frame == 0:
        path = [(77, 209), (68, 187), (76, 166), (66, 143), (78, 120),
                (71, 96), (83, 73), (79, 49), (91, 25)]
    else:
        path = [(86, 209), (92, 188), (82, 168), (94, 146), (84, 124),
                (91, 103), (80, 81), (88, 59), (77, 36)]
    # Sparse bark contact marks keep the vine integrated with a trunk without
    # painting a fake trunk over every tree species.
    for x, y in path[1:-1:2]:
        draw.rectangle((x - 5, y + 1, x + 4, y + 3), fill=BARK_DEEP)
        draw.line((x - 3, y + 1, x + 2, y + 1), fill=BARK_LIGHT, width=1)
    draw_stem(draw, path, 7)
    secondary = ([(82, 205), (94, 180), (89, 153), (101, 128), (94, 101)] if frame == 0
                 else [(79, 205), (68, 181), (73, 155), (63, 131), (70, 108)])
    draw_stem(draw, secondary, 4)
    for index, (x, y) in enumerate(secondary[1:]):
        direction = 1 if (index + frame) % 2 == 0 else -1
        draw_leaf(draw, x, y - 2, direction, 16 + index % 3 * 2, index + 1)
    for index, (x, y) in enumerate(path[1:-1]):
        direction = -1 if (index + frame) % 2 == 0 else 1
        branch_y = y + rng.randint(-3, 3)
        branch = [(x, y), (x + direction * 8, branch_y - 4), (x + direction * 14, branch_y - 7)]
        draw_stem(draw, branch, 4)
        draw_leaf(draw, branch[-1][0], branch[-1][1], direction, rng.randint(18, 25), index % 3)
        if index % 3 == 1:
            draw_leaf(draw, x + direction * 6, y - 5, -direction, rng.randint(15, 20), index + 1)
    draw.arc((58 if frame == 0 else 75, 70, 103 if frame == 0 else 120, 116),
             205 if frame == 0 else 150, 350 if frame == 0 else 295, fill=STEM_LIGHT, width=2)
    # Root curls at the foot make the attachment point readable.
    draw.arc((55, 198, 82, 218), 25, 185, fill=OUTLINE, width=5)
    draw.arc((57, 200, 80, 215), 25, 180, fill=STEM_MID, width=2)
    draw.arc((82, 199, 108, 217), 355, 155, fill=OUTLINE, width=5)
    draw.arc((84, 201, 106, 214), 355, 150, fill=STEM_LIGHT, width=2)
    return image


def ground_vine(state):
    image = Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    rng = random.Random(6121 + state * 733)
    if state == 3:  # permanently cut
        draw.line((24, 204, 57, 198, 91, 204, 126, 198, 141, 202), fill=OUTLINE, width=7)
        draw.line((25, 203, 57, 197, 91, 203, 126, 197, 140, 201), fill=DRY_DARK, width=4)
        for x, y, direction in ((38, 201, -1), (69, 200, 1), (103, 201, -1), (130, 200, 1)):
            draw.line((x, y, x + direction * 5, y - 8), fill=OUTLINE, width=4)
            draw.line((x, y, x + direction * 4, y - 7), fill=DRY_LIGHT, width=2)
        for x, y, direction in ((22, 209, -1), (82, 210, 1), (145, 207, 1)):
            draw_leaf(draw, x, y, direction, 11, 0)
        return image

    bend = 0 if state == 0 else (-12 if state == 1 else 12)
    main = [(18, 205), (45, 199), (74, 205), (104, 198), (142, 204)]
    lower = [(25, 211), (58, 205), (91, 211), (128, 205)]
    draw_stem(draw, main, 7);draw_stem(draw, lower, 5)
    roots = [(28, 203), (54, 200), (80, 203), (108, 199), (135, 203)]
    for index, (x, y) in enumerate(roots):
        lean = bend + rng.randint(-4, 4)
        top = (x + lean, y - rng.randint(15, 27))
        draw_stem(draw, [(x, y), top], 5)
        size = rng.randint(18, 24)
        draw_leaf(draw, top[0], top[1], -1, size, index % 3)
        draw_leaf(draw, top[0] + 1, top[1] + 2, 1, size - 2, index + 1)
    # Low curls and overlapping leaves read as groundcover instead of a fence.
    draw.arc((17, 184, 79, 216), 195, 350, fill=STEM_LIGHT, width=3)
    draw.arc((84, 183, 146, 214), 190, 345, fill=STEM_MID, width=3)
    draw_leaf(draw, 47+bend//3, 207, -1, 17, 1)
    draw_leaf(draw, 112+bend//3, 207, 1, 18, 2)
    return image


def main():
    atlas = Image.new("RGBA", (CELL_W * FRAMES, CELL_H), (0, 0, 0, 0))
    frames = [climbing(0), climbing(1), ground_vine(0), ground_vine(1), ground_vine(2), ground_vine(3)]
    for index, frame in enumerate(frames):
        atlas.alpha_composite(frame, (index * CELL_W, 0))
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(OUTPUT, optimize=True)

    board = Image.new("RGB", (CELL_W * 3, CELL_H * 2), (39, 51, 33))
    for index, frame in enumerate(frames):
        board.paste(frame, ((index % 3) * CELL_W, (index // 3) * CELL_H), frame)
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    board.save(PREVIEW, optimize=True)
    print(f"wrote {OUTPUT.relative_to(ROOT)} {atlas.size} and {PREVIEW.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
