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


def revealed_ribbon(cell, x0, width, cutoff):
    part = cell.crop((x0, 0, x0 + width, CELL)).copy()
    alpha = part.getchannel("A")
    pixels = alpha.load()
    upper = cutoff * CELL
    for y in range(CELL):
        if y > upper:
            for x in range(width):
                pixels[x, y] = 0
    part.putalpha(alpha)
    return part


def paste_ribbon(panel, cell, x0, width, progress, side, global_scale_x):
    if progress <= 0:
        return
    lift = (1 - progress) * 1320
    scale_x = (.94 + progress * .06 + math.sin(progress * math.pi) * .025) * global_scale_x
    scale_y = .95 + progress * .05
    cutoff = max(0, min(.94, FOOT / CELL - (36 + lift) / (CELL * (820 / 639) * scale_y)))
    part = revealed_ribbon(cell, x0, width, cutoff)
    authored_scale_x = SCALE * scale_x
    authored_scale_y = SCALE * scale_y
    part = part.resize((round(width * authored_scale_x), round(CELL * authored_scale_y)), Image.Resampling.NEAREST)
    if progress < .125:
        alpha = part.getchannel("A").point(lambda value: round(value * progress * 8))
        part.putalpha(alpha)
    x = round(PANEL_W / 2 + (x0 - CELL / 2) * authored_scale_x + side * math.sin(progress * math.pi) * 18 * SCALE)
    y = round(350 + lift * SCALE - FOOT * authored_scale_y)
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

    global_scale_x = .28 + smooth((p - .04) / .25) * .72
    starts = (.15, .09, .04, .11, .17)
    widths = (210, 190, 224, 190, 210)
    x0 = 0
    for ribbon, (start, width) in enumerate(zip(starts, widths)):
        rp = smooth((p - start) / (.76 - start * .25))
        paste_ribbon(panel, cell, x0, width, rp, (ribbon - 2) / 2, global_scale_x)
        x0 += width

    draw = ImageDraw.Draw(panel)
    draw.rectangle((8, 8, 72, 31), fill=(14, 19, 10, 205))
    draw.text((16, 12), f"{p * 3.35:0.2f}s", fill=(245, 232, 174, 255))
    out.paste(panel.convert("RGB"), (index * PANEL_W, 0))

path = ROOT / "docs/previews/worldtree-emergence-v2-display-scale.png"
out.save(path)
print(path)
