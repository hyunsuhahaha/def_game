from pathlib import Path
from PIL import Image, ImageDraw
import math

ROOT = Path(__file__).resolve().parents[1]
atlas = Image.open(ROOT / "assets/enemies/arcade/worldtree-siege-atlas-v1.png").convert("RGBA")
fx_atlas = Image.open(ROOT / "assets/fx/boss-entrance/boss-entrance-fx-atlas-pixel-v1.png").convert("RGBA")
ground = Image.open(ROOT / "assets/forest-ground-tile-v1.png").convert("RGB")

PANEL_W, PANEL_H = 300, 390
CELL, FOOT = 1024, 992
SCALE = .34
PROGRESS = (.06, .24, .40, .59, .77, .96)


def smooth(value):
    value = max(0.0, min(1.0, value))
    return value * value * (3 - 2 * value)


def tiled_ground():
    panel = Image.new("RGB", (PANEL_W, PANEL_H), (73, 91, 38))
    for y in range(0, PANEL_H, ground.height):
        for x in range(0, PANEL_W, ground.width):
            panel.paste(ground, (x, y))
    shade = Image.new("RGBA", panel.size, (36, 48, 19, 38))
    return Image.alpha_composite(panel.convert("RGBA"), shade)


def warped_intact_tree(cell, p, cutoff):
    part = Image.new("RGBA", (CELL + 72, CELL), (0, 0, 0, 0))
    for y in range(CELL):
        local_v = y / CELL
        crown_weight = .22 + .78 * (1 - local_v)
        shift = round(math.sin((1 - local_v) * 7.2 + p * 8.4) * .026 * crown_weight * CELL)
        part.alpha_composite(cell.crop((0, y, CELL, y + 1)), (36 + shift, y))
    alpha = part.getchannel("A")
    pixels = alpha.load()
    upper = cutoff * CELL
    for y in range(CELL):
        if y > upper:
            for x in range(part.width):
                pixels[x, y] = 0
    part.putalpha(alpha)
    return part


def paste_intact_tree(panel, cell, p):
    rise = smooth((p - .04) / .84)
    lift = (1 - rise) * 1320
    scale_x = .86 + smooth((p - .04) / .66) * .14 + math.sin(p * math.pi) * .035
    scale_y = .92 + rise * .08 + math.sin(p * math.pi) * .022
    atlas_to_world = 820 / 639
    cutoff = max(0, min(.94, FOOT / CELL - (36 + lift) / (CELL * atlas_to_world * scale_y)))
    part = warped_intact_tree(cell, p, cutoff)
    authored_scale_x = SCALE * scale_x
    authored_scale_y = SCALE * scale_y
    part = part.resize((round(part.width * authored_scale_x), round(CELL * authored_scale_y)), Image.Resampling.NEAREST)
    alpha_amount = min(1, max(0, (p - .025) * 14))
    if alpha_amount < 1:
        alpha = part.getchannel("A").point(lambda value: round(value * alpha_amount))
        part.putalpha(alpha)
    world_scale = SCALE / atlas_to_world
    x = round(PANEL_W / 2 - part.width / 2)
    y = round(350 + lift * world_scale - FOOT * authored_scale_y)
    panel.alpha_composite(part, (x, y))


out = Image.new("RGB", (PANEL_W * len(PROGRESS), PANEL_H), (47, 64, 29))
for index, p in enumerate(PROGRESS):
    panel = tiled_ground()
    frame = int(p * 12) % 3
    cell = atlas.crop((frame * CELL, 0, (frame + 1) * CELL, CELL))

    fx_frame = min(5, int(p * 7))
    crack = fx_atlas.crop((fx_frame * 256, 0, (fx_frame + 1) * 256, 256))
    crack = crack.resize((270, 180), Image.Resampling.NEAREST)
    crack_alpha = min(1, p * 5, (1 - p) * 7 + .18)
    crack.putalpha(crack.getchannel("A").point(lambda value: round(value * crack_alpha)))
    panel.alpha_composite(crack, (15, 238))

    paste_intact_tree(panel, cell, p)

    curtain = max(0, min(1, (p - .14) / .12, (.94 - p) / .12))
    if curtain > 0:
        dirt = ImageDraw.Draw(panel)
        for i in range(22):
            px = PANEL_W // 2 - 154 + ((i * 73) % 309)
            lift = (5 + (i * 37) % 39) * curtain
            py = round(353 - lift + (i % 3) * 2)
            size = 1 + i % 3
            shadow = (38, 27, 9, round(180 * curtain))
            soil = (150, 99, 34, round(235 * curtain)) if i % 3 == 0 else (91, 61, 21, round(225 * curtain))
            dirt.rectangle((px-size-1, py-size, px+size+1, py+size), fill=shadow)
            dirt.rectangle((px-size, py-size, px+size, py+size-1), fill=soil)

    draw = ImageDraw.Draw(panel)
    draw.rectangle((8, 8, 72, 31), fill=(14, 19, 10, 205))
    draw.text((16, 12), f"{p * 3.35:0.2f}s", fill=(245, 232, 174, 255))
    out.paste(panel.convert("RGB"), (index * PANEL_W, 0))

path = ROOT / "docs/previews/worldtree-emergence-v2-display-scale.png"
out.save(path)
print(path)
