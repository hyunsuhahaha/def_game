"""Build the classic monkey-carried bomb atlas."""
from pathlib import Path
import math
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "automation"
PREVIEW = ROOT / "docs" / "previews"
S, CELL = 2, 128


def bomb(state: int) -> Image.Image:
    im = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    ink, black, mid, shine = (24, 20, 19, 255), (35, 35, 37, 255), (62, 62, 65, 255), (104, 103, 101, 255)
    rope, rope_hi = (129, 83, 42, 255), (211, 151, 79, 255)
    d.ellipse((9, 16, 53, 60), fill=ink)
    d.ellipse((12, 18, 51, 58), fill=black)
    d.polygon([(34, 16), (46, 14), (50, 21), (43, 27), (34, 24)], fill=ink)
    d.polygon([(36, 17), (45, 16), (47, 20), (42, 24), (36, 22)], fill=mid)
    d.polygon([(17, 24), (23, 20), (34, 20), (38, 23), (31, 27), (21, 27)], fill=mid)
    d.rectangle((19, 23, 29, 25), fill=shine)
    fuse = [(43, 18), (48, 14), (51, 10), (49, 6), (52, 3), (58, 4), (61, 1)]
    d.line(fuse, fill=ink, width=6, joint="curve")
    d.line(fuse, fill=rope, width=3, joint="curve")
    d.line([(45, 16), (49, 13), (52, 9), (51, 6), (53, 4), (58, 5)], fill=rope_hi, width=1)
    if state > 0:
        spark = (255, 77, 18, 255)
        hot = (255, 226, 76, 255)
        d.rectangle((59, 0, 62, 3), fill=hot)
        rays = [((58, 1), (55, 0)), ((62, 3), (63, 6)), ((59, 4), (57, 7)), ((62, 0), (63, 0))]
        for a, b in rays:
            d.line([a, b], fill=spark, width=2 if state == 2 else 1)
        if state == 2:
            d.rectangle((57, 0, 63, 5), fill=(255, 130, 22, 180))
            d.rectangle((59, 0, 62, 3), fill=hot)
            d.ellipse((7, 14, 55, 62), outline=(255, 82, 20, 110), width=2)
    return im.resize((CELL, CELL), Image.Resampling.NEAREST)


def explosion(frame: int) -> Image.Image:
    im = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = 64, 70
    progress = frame / 7
    if frame < 5:
        radius = [14, 29, 45, 56, 62][frame]
        colors = [(255, 246, 175, 255), (255, 218, 61, 255), (255, 137, 20, 255), (225, 63, 15, 255)]
        for layer, color in enumerate(reversed(colors)):
            rr = max(5, radius - layer * (7 + frame))
            points = []
            for i in range(24):
                angle = i * math.pi * 2 / 24
                jag = 1 + (((i * 17 + frame * 11) % 9) - 4) * .045
                if i % 4 == 0:
                    jag += .22 + frame * .025
                points.append((round(cx + math.cos(angle) * rr * jag), round(cy + math.sin(angle) * rr * jag * .82)))
            d.polygon(points, fill=color)
        if frame <= 2:
            d.ellipse((cx-radius//3, cy-radius//3, cx+radius//3, cy+radius//3), fill=(255, 255, 224, 255))
        for i in range(10):
            angle=i*math.pi*2/10+.2
            inner=radius*.72;outer=radius*(1.25+(i%3)*.12)
            d.line([(cx+math.cos(angle)*inner,cy+math.sin(angle)*inner*.82),
                    (cx+math.cos(angle)*outer,cy+math.sin(angle)*outer*.82)],fill=(255,166,24,255),width=3)
    if frame >= 3:
        smoke_age=frame-3
        smoke=(56,49,45,235) if frame<6 else (72,68,63,185)
        for i in range(9):
            angle=i*math.pi*2/9+.35
            spread=22+smoke_age*9+(i%3)*5
            x=cx+math.cos(angle)*spread
            y=cy-18-smoke_age*7+math.sin(angle)*spread*.48
            size=15+(i*7+frame*3)%11
            d.ellipse((x-size,y-size,x+size,y+size),fill=smoke)
            d.rectangle((round(x-size*.45),round(y-size*.45),round(x+size*.2),round(y-size*.2)),fill=(111,102,91,150))
        if frame < 6:
            d.ellipse((cx-25-frame*2,cy-24-frame*3,cx+25+frame*2,cy+22),fill=(255,94,14,230))
            d.ellipse((cx-14,cy-17-frame*3,cx+14,cy+12),fill=(255,220,48,245))
    for i in range(12):
        angle=i*math.pi*2/12+.17
        distance=(18+frame*10)*(1+(i%3)*.12)
        x=round(cx+math.cos(angle)*distance);y=round(cy+math.sin(angle)*distance*.72)
        size=3 if frame<5 else 2
        d.rectangle((x-size,y-size,x+size,y+size),fill=(255,151 if i%2 else 76,18,255 if frame<6 else 145))
    return im.resize((256, 256), Image.Resampling.NEAREST)


def build() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    PREVIEW.mkdir(parents=True, exist_ok=True)
    atlas = Image.new("RGBA", (CELL * 3, CELL), (0, 0, 0, 0))
    for i in range(3):
        atlas.alpha_composite(bomb(i), (i * CELL, 0))
    path = OUT / "monkey-bomb-atlas-pixel-v1.png"
    atlas.save(path)
    fx_dir = ROOT / "assets" / "fx"
    fx_dir.mkdir(parents=True, exist_ok=True)
    fx_atlas = Image.new("RGBA", (256 * 8, 256), (0, 0, 0, 0))
    for i in range(8):
        fx_atlas.alpha_composite(explosion(i), (i * 256, 0))
    fx_atlas.save(fx_dir / "monkey-bomb-explosion-atlas-pixel-v1.png")
    board = Image.new("RGBA", atlas.size, (43, 55, 35, 255))
    board.alpha_composite(atlas)
    board.resize((atlas.width * 2, atlas.height * 2), Image.Resampling.NEAREST).save(PREVIEW / "monkey-bomb-v1-2x.png")
    print(f"BOMB_MONKEY_ASSET_OK bomb={atlas.width}x{atlas.height} explosion={fx_atlas.width}x{fx_atlas.height}")


if __name__ == "__main__":
    build()
