"""Build map-authored foreground canopy and hanging-vine atlases."""
from pathlib import Path
import math
import random

from PIL import Image, ImageDraw, ImageOps


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "scenery" / "canopy"
PREVIEW = ROOT / "docs" / "previews" / "biome-canopy-atlases-v1.png"
W, H = 1024, 256

PALETTES = {
    "forest": {
        "leaf": ("#081611", "#10261b", "#183221", "#23472a", "#315b32", "#416a38", "#527641", "#789153"),
        "wood": ("#18110e", "#251b16", "#493224", "#705037", "#94704b", "#b08a5d"), "seed": 310, "density": 12,
    },
    "beginner": {
        "leaf": ("#102018", "#1b3020", "#294329", "#3c5d31", "#4e7139", "#628342", "#74934c", "#9eac68"),
        "wood": ("#201611", "#302219", "#59402b", "#805f3d", "#aa8053", "#c79b67"), "seed": 420, "density": 8,
    },
    "mangrove": {
        "leaf": ("#051c1d", "#092b29", "#103d37", "#145044", "#176052", "#217259", "#2b8064", "#61a178"),
        "wood": ("#171211", "#251d1b", "#45322b", "#684d3c", "#8c7150", "#b19567"), "seed": 530, "density": 14,
    },
    "madagascar": {
        "leaf": ("#17180f", "#282a18", "#393b22", "#50502d", "#666438", "#77703e", "#89804a", "#b0a365"),
        "wood": ("#1d1210", "#2e1c18", "#5a3526", "#865239", "#b37b52", "#d09a67"), "seed": 640, "density": 6,
    },
    "island": {
        "leaf": ("#041b17", "#072c24", "#0a3c2d", "#0f5538", "#176c45", "#22804e", "#30905a", "#69b773"),
        "wood": ("#1a1110", "#291c18", "#523528", "#79503a", "#a6764c", "#c99a62"), "seed": 750, "density": 15,
    },
}


def leaf_cluster(draw, x, y, radius, colors, seed, tropical=False):
    rng = random.Random(seed)
    dark, shadow, mid, light, hi = colors[:5]
    count = 9 if tropical else 8
    blobs = []
    for index in range(count):
        angle = math.tau * index / count + rng.uniform(-.2, .2)
        distance = radius * rng.uniform(.22, .62)
        cx, cy = x + math.cos(angle) * distance, y + math.sin(angle) * distance * .62
        rx = radius * rng.uniform(.38, .57)
        ry = radius * rng.uniform(.26, .42)
        blobs.append((int(cx-rx), int(cy-ry), int(cx+rx), int(cy+ry)))
    for box in blobs:
        draw.ellipse(box, fill=dark)
    for index, box in enumerate(blobs):
        x0, y0, x1, y1 = box
        inset = max(2, min(4 + index % 2, (y1-y0)//4, (x1-x0)//4))
        draw.ellipse((x0+inset, y0+inset, x1-inset, y1-inset+1), fill=shadow)
        highlight_box=(x0+inset+3,y0+inset+2,x1-inset-2,max(y0+inset+2,y1-inset))
        if highlight_box[2]>=highlight_box[0] and highlight_box[3]>=highlight_box[1]:
            draw.pieslice(highlight_box,185,350,fill=mid)
        if index % 2 == 0:
            draw.rectangle((x0+inset+7, y0+inset+5, x0+inset+13, y0+inset+7), fill=light)
            draw.point((x0+inset+15, y0+inset+8), fill=hi)
    for _ in range(max(8, radius // 2)):
        px = int(x + rng.uniform(-radius*.72, radius*.72))
        py = int(y + rng.uniform(-radius*.35, radius*.35))
        draw.point((px, py), fill=rng.choice((mid, light, hi, *colors[5:])))


def branch_cell(spec, mirror=False):
    image = Image.new("RGBA", (320, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    leaf, wood = spec["leaf"], spec["wood"]
    seed, density = spec["seed"] + (19 if mirror else 0), spec["density"]
    rng = random.Random(seed)
    outline = [(0, -8), (69, -8), (104, 38), (181, 55), (278, 91), (271, 111), (170, 82), (91, 70), (43, 39), (0, 34)]
    inner = [(0, 2), (59, 1), (98, 47), (177, 64), (270, 99), (266, 105), (173, 74), (87, 62), (39, 31), (0, 26)]
    draw.polygon(outline, fill=wood[0]); draw.polygon(inner, fill=wood[1])
    draw.line(((18, 11), (91, 53), (177, 68), (254, 99)), fill=wood[2], width=4)
    draw.line(((31, 16), (103, 49), (159, 58)), fill=wood[4], width=2)
    for x in range(22, 254, 21):
        draw.rectangle((x, 51 + (x % 13), x+7, 54 + (x % 13)), fill=wood[0])
        draw.point((x+4, 50+(x%13)), fill=wood[5])
    tropical = density >= 14
    positions = [(15, 13), (66, 17), (119, 16), (177, 28), (231, 45), (286, 69), (42, 61), (111, 65), (203, 77)]
    if density > 10:
        positions += [(274, 25), (152, 84), (83, 91)]
    elif density < 7:
        positions = positions[::2] + [(245, 68)]
    for index, (x, y) in enumerate(positions):
        radius = rng.randint(25, 39) if density >= 8 else rng.randint(20, 30)
        leaf_cluster(draw, x, y, radius, leaf, seed + index * 37, tropical)
    if spec["seed"] == 640:
        for x in (92, 171, 250):
            draw.line((x, 68, x+18, 112), fill=wood[0], width=3)
            draw.line((x+18, 112, x+26, 105), fill=wood[2], width=2)
    if mirror:
        image = ImageOps.mirror(image)
    return image


def leaf_shape(draw, x, y, side, colors, size, tropical=False):
    dark, shadow, mid, light, hi = colors[:5]
    tip = x + side * size
    if tropical:
        points = [(x, y), (x+side*size*.34, y-size*.36), (tip, y-size*.10),
                  (x+side*size*.44, y+size*.26), (x, y+size*.16)]
    else:
        points = [(x, y), (x+side*size*.45, y-size*.28), (tip, y),
                  (x+side*size*.42, y+size*.30)]
    draw.polygon(points, fill=dark)
    inner = [(x+side*2, y), (x+side*size*.43, y-size*.19),
             (x+side*(size-4), y), (x+side*size*.40, y+size*.19)]
    draw.polygon(inner, fill=mid)
    draw.line((x+side*3, y, x+side*(size-6), y), fill=light, width=2)
    draw.point((int(x+side*size*.45), int(y-size*.12)), fill=hi)


def vine_cell(spec, variant):
    image = Image.new("RGBA", (128, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    leaf, wood = spec["leaf"], spec["wood"]
    rng = random.Random(spec["seed"] + variant * 97)
    dry = spec["seed"] == 640
    tropical = spec["seed"] in (530, 750)
    length = (140 if dry else 205) + variant * 18
    points = []
    for y in range(-4, length, 12):
        x = 64 + math.sin(y * .045 + variant * 1.3) * (8 + variant * 2)
        points.append((int(x), y))
    draw.line(points, fill=wood[0], width=7 if tropical else 5)
    draw.line(points, fill=wood[2], width=3 if tropical else 2)
    for index, (x, y) in enumerate(points[2:-2:2]):
        side = -1 if (index + variant) % 2 == 0 else 1
        size = rng.randint(22, 31) if tropical else (rng.randint(18, 27) if not dry else rng.randint(9, 15))
        leaf_shape(draw, x, y, side, leaf, size, tropical)
    end_x, end_y = points[-1]
    draw.arc((end_x-11, end_y-2, end_x+13, end_y+20), 10, 292, fill=wood[2], width=2)
    if tropical:
        draw.line((end_x+7, end_y+9, end_x+13, end_y+16), fill=leaf[3], width=2)
    return image


def tuft_cell(spec):
    image = Image.new("RGBA", (128, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    leaf, wood = spec["leaf"], spec["wood"]
    tropical = spec["seed"] in (530, 750)
    origin = (64, 5)
    for index, angle in enumerate((-2.65, -2.3, -1.95, -1.57, -1.18, -.82, -.47)):
        length = 72 + (index % 3) * 13
        end = (origin[0] + math.cos(angle) * length, origin[1] - math.sin(angle) * length)
        draw.line((origin, end), fill=wood[0], width=5)
        draw.line((origin, end), fill=wood[2], width=2)
        for step in (.28, .48, .68, .84):
            x = int(origin[0] + (end[0]-origin[0]) * step)
            y = int(origin[1] + (end[1]-origin[1]) * step)
            leaf_shape(draw, x, y, -1 if index % 2 else 1, leaf, 14 if tropical else 11, tropical)
    leaf_cluster(draw, 64, 13, 34, leaf, spec["seed"] + 333, tropical)
    return image


def build(name, spec):
    atlas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    atlas.alpha_composite(branch_cell(spec), (0, 0))
    atlas.alpha_composite(branch_cell(spec, True), (320, 0))
    atlas.alpha_composite(vine_cell(spec, 0), (640, 0))
    atlas.alpha_composite(vine_cell(spec, 1), (768, 0))
    atlas.alpha_composite(tuft_cell(spec), (896, 0))
    path = OUT / f"{name}-foreground-canopy-atlas-pixel-v1.png"
    atlas.save(path, optimize=True)
    return atlas


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    rows = []
    for name, spec in PALETTES.items():
        rows.append(build(name, spec))
    board = Image.new("RGBA", (W, H * len(rows)), (27, 39, 28, 255))
    for index, row in enumerate(rows):
        board.alpha_composite(row, (0, index * H))
    board.save(PREVIEW, optimize=True)
    print("BIOME_CANOPY_ASSETS_OK biomes=5 atlas=1024x256")


if __name__ == "__main__":
    main()
