"""Build the authored pixel layers used by the pseudo-perspective sky view."""
from pathlib import Path
from PIL import Image, ImageDraw
import math
import random

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "scenery" / "skyview"
PREVIEW = ROOT / "docs" / "previews" / "skyview-v1-layers.png"
W = 1536


def mix(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def stepped_sky():
    h = 384
    im = Image.new("RGBA", (W, h), (0, 0, 0, 255))
    px = im.load()
    top, middle, low = (42, 116, 174), (79, 157, 202), (176, 211, 213)
    for y in range(h):
        t = y / (h - 1)
        c = mix(top, middle, min(1, t * 1.45)) if t < .69 else mix(middle, low, (t - .69) / .31)
        c2 = mix(c, (233, 228, 184), max(0, (t - .82) / .18) * .22)
        for x in range(W):
            # Ordered one-value dithering keeps the gradient pixel-authored.
            d = 2 if ((x // 2 + y // 2 * 3) % 11 == 0 and y > 28) else 0
            px[x, y] = (min(255, c2[0] + d), min(255, c2[1] + d), min(255, c2[2] + d), 255)

    draw = ImageDraw.Draw(im)
    rng = random.Random(21041)
    # Long, quiet cloud banks. They use stepped shadow/mid/highlight clusters.
    for cx, cy, scale in [(175, 92, .9), (630, 58, .62), (1090, 122, 1.12), (1405, 52, .55)]:
        shadow = (119, 176, 198, 205)
        mid = (191, 220, 220, 225)
        high = (231, 239, 224, 238)
        lobes = []
        for i in range(8):
            ox = (i - 3.5) * 30 * scale + rng.randint(-8, 8)
            oy = rng.randint(-8, 9) * scale
            rw = rng.randint(35, 62) * scale
            rh = rng.randint(12, 25) * scale
            lobes.append((cx + ox, cy + oy, rw, rh))
        draw.rectangle((cx - 125 * scale, cy + 5 * scale, cx + 135 * scale, cy + 25 * scale), fill=shadow)
        for x, y, rw, rh in lobes:
            draw.ellipse((x-rw, y-rh, x+rw, y+rh), fill=shadow)
        for x, y, rw, rh in lobes:
            draw.ellipse((x-rw*.9, y-rh*.9-3, x+rw*.9, y+rh*.55), fill=mid)
            draw.arc((x-rw*.62, y-rh*.76-4, x+rw*.62, y+rh*.22), 190, 345, fill=high, width=max(2, round(3*scale)))
    return im


def mountains():
    h = 160
    im = Image.new("RGBA", (W, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    rng = random.Random(8813)
    ridge = [(0, h)]
    x = -80
    while x < W + 100:
        width = rng.randint(150, 270)
        peak = rng.randint(36, 86)
        ridge.extend([(x, h), (x + width*.48, peak), (x + width, h)])
        x += width - rng.randint(18, 44)
    ridge.extend([(W, h), (0, h)])
    draw.polygon(ridge, fill=(72, 119, 126, 255))
    # Cool stepped faces and sparse sunlit shoulders.
    for i in range(15):
        x = i * 112 + rng.randint(-25, 25)
        y = rng.randint(67, 112)
        dark=(48+(i%3)*4,91+(i%4)*3,103+(i%2)*5,255)
        mid=(67+(i%4)*4,112+(i%3)*5,121+(i%5)*3,255)
        light=(103+(i%3)*6,144+(i%4)*4,143+(i%2)*6,235)
        draw.polygon([(x, h), (x+48, y), (x+82, h)], fill=dark)
        draw.polygon([(x+48, y), (x+82, h), (x+60, h)], fill=mid)
        draw.polygon([(x+48,y+5),(x+60,y+30),(x+55,y+54),(x+41,y+25)],fill=light)
        # Controlled scree clusters describe the slope instead of random noise.
        for step in range(4):
            sy=round(y+34+step*17)
            sx=round(x+22+step*8)
            draw.rectangle((sx,sy,sx+7+step*2,sy+2),fill=(82+(i%3)*5,128+(step%2)*6,130+(i%2)*5,210))
    return im


def forest():
    h = 120
    im = Image.new("RGBA", (W, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    rng = random.Random(6619)
    # Back row is mist-muted; front row has the project's colored dark outline.
    for row, base, color, outline in [(0, 112, (54, 106, 91, 235), (39, 83, 77, 235)),
                                      (1, 120, (34, 78, 58, 255), (22, 54, 45, 255))]:
        step = 24 if row == 0 else 31
        for x in range(-20 + row*9, W+24, step):
            height = rng.randint(35, 77) if row == 0 else rng.randint(27, 62)
            width = rng.randint(18, 32)
            y = base - height
            if rng.random() < .38:
                draw.polygon([(x, base), (x+width//2, y), (x+width, base)], fill=outline)
                draw.polygon([(x+3, base), (x+width//2, y+5), (x+width-3, base)], fill=color)
                draw.line((x+width//2, y+12, x+width//2, base), fill=(32, 61, 48, 255), width=2)
            else:
                draw.rectangle((x+width//2-2, base-height*.55, x+width//2+2, base), fill=outline)
                for ox, oy, radius in [(.5,.48,.48),(.25,.58,.35),(.75,.6,.36),(.48,.28,.30)]:
                    cx, cy = x+width*ox, base-height*oy
                    r = width*radius
                    draw.ellipse((cx-r, cy-r*.72, cx+r, cy+r*.72), fill=outline)
                    draw.ellipse((cx-r+2, cy-r*.72+2, cx+r-2, cy+r*.72-2), fill=color)
                    draw.arc((cx-r*.58,cy-r*.46,cx+r*.40,cy+r*.18),190,330,
                             fill=(58+row*8+(x//step)%9,112+row*7,88+row*5,220),width=2)
    return im


def mist():
    h = 96
    im = Image.new("RGBA", (W, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    rng = random.Random(4107)
    for band in range(4):
        y = 19 + band*15
        alpha = 54 - band*8
        points = [(-30, y+16)]
        for x in range(-30, W+60, 70):
            points.append((x, y + round(math.sin(x*.013+band)*6) + rng.randint(-2,2)))
        points.extend([(W+30, y+27), (-30, y+27)])
        draw.polygon(points, fill=(210, 228, 211, alpha))
    return im


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    layers = {
        "sky-clear-pixel-v1.png": stepped_sky(),
        "horizon-mountains-pixel-v1.png": mountains(),
        "horizon-forest-pixel-v1.png": forest(),
        "horizon-mist-pixel-v1.png": mist(),
    }
    for name, image in layers.items():
        image.save(OUT / name, optimize=True)

    board = Image.new("RGB", (W, 760), (26, 41, 36))
    board.paste(layers["sky-clear-pixel-v1.png"], (0, 0))
    board.paste(layers["horizon-mountains-pixel-v1.png"], (0, 384), layers["horizon-mountains-pixel-v1.png"])
    board.paste(layers["horizon-forest-pixel-v1.png"], (0, 544), layers["horizon-forest-pixel-v1.png"])
    board.paste(layers["horizon-mist-pixel-v1.png"], (0, 664), layers["horizon-mist-pixel-v1.png"])
    board.save(PREVIEW, optimize=True)
    print(f"SKYVIEW_ASSETS_OK layers={len(layers)} native={W}px")


if __name__ == "__main__":
    main()
