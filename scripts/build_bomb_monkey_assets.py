"""Build the classic monkey-carried bomb atlas."""
from pathlib import Path
import math
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "automation"
PREVIEW = ROOT / "docs" / "previews"
S, CELL, FUSE_FRAMES = 2, 128, 24


def partial_fuse(points, remaining_ratio):
    lengths = [math.dist(points[i], points[i + 1]) for i in range(len(points) - 1)]
    target = sum(lengths) * remaining_ratio
    result = [points[0]]
    walked = 0
    for index, length in enumerate(lengths):
        if walked + length <= target:
            result.append(points[index + 1]);walked += length
        else:
            ratio = max(0, (target - walked) / length)
            x = points[index][0] + (points[index + 1][0] - points[index][0]) * ratio
            y = points[index][1] + (points[index + 1][1] - points[index][1]) * ratio
            result.append((round(x), round(y)))
            break
    return result


def bomb(burn_progress=None, phase=0) -> Image.Image:
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
    fuse = [(42, 18), (48, 15), (54, 12), (56, 8), (53, 5), (56, 2), (61, 4)]
    visible = fuse if burn_progress is None else partial_fuse(fuse, max(.03, 1-burn_progress))
    d.line(visible, fill=ink, width=6, joint="curve")
    d.line(visible, fill=rope, width=3, joint="curve")
    if len(visible)>1:d.line(visible[:-1], fill=rope_hi, width=1, joint="curve")
    if burn_progress is not None:
        spark = (255, 77, 18, 255)
        hot = (255, 226, 76, 255)
        x,y=visible[-1];jitter=(-1,0,1,0)[phase%4]
        d.rectangle((x-2,y-2,x+2,y+2),fill=(255,130,22,220))
        d.rectangle((x-1,y-1,x+1,y+1),fill=hot)
        rays=[((x-3,y+jitter),(x-6,y+jitter-2)),((x+3,y),(x+5,y-3)),((x,y+3),(x+jitter,y+6))]
        for a,b in rays:d.line([a,b],fill=spark,width=1)
        # The burnt end leaves a tiny smoke pixel behind while the live rope
        # visibly shortens toward the bomb neck.
        d.rectangle((x+2,y-4,x+3,y-3),fill=(92,88,83,150))
        if burn_progress>.72:
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
    atlas = Image.new("RGBA", (CELL * (FUSE_FRAMES + 1), CELL), (0, 0, 0, 0))
    atlas.alpha_composite(bomb(), (0, 0))
    for i in range(FUSE_FRAMES):
        atlas.alpha_composite(bomb(i/(FUSE_FRAMES-1)*.96, i), ((i+1)*CELL, 0))
    path = OUT / "monkey-bomb-atlas-pixel-v1.png"
    atlas.save(path)
    fx_dir = ROOT / "assets" / "fx"
    fx_dir.mkdir(parents=True, exist_ok=True)
    fx_atlas = Image.new("RGBA", (256 * 8, 256), (0, 0, 0, 0))
    for i in range(8):
        fx_atlas.alpha_composite(explosion(i), (i * 256, 0))
    fx_atlas.save(fx_dir / "monkey-bomb-explosion-atlas-pixel-v1.png")
    samples = [0, 1, 6, 12, 18, 24]
    board = Image.new("RGBA", (CELL*len(samples), CELL), (43, 55, 35, 255))
    for column,index in enumerate(samples):board.alpha_composite(atlas.crop((index*CELL,0,(index+1)*CELL,CELL)),(column*CELL,0))
    board.resize((board.width * 2, board.height * 2), Image.Resampling.NEAREST).save(PREVIEW / "monkey-bomb-v1-2x.png")
    gif_frames=[]
    for index in [0]*4+list(range(1,FUSE_FRAMES+1)):
        canvas=Image.new("RGB",(512,384),(34,66,29));draw=ImageDraw.Draw(canvas)
        draw.rectangle((0,235,512,384),fill=(55,100,42));draw.ellipse((204,293,308,318),fill=(28,48,26))
        cell=atlas.crop((index*CELL,0,(index+1)*CELL,CELL)).resize((192,192),Image.Resampling.NEAREST)
        canvas.paste(cell,(160,126),cell);gif_frames.append(canvas)
    for index in range(8):
        canvas=Image.new("RGB",(512,384),(34,66,29));draw=ImageDraw.Draw(canvas)
        draw.rectangle((0,235,512,384),fill=(55,100,42))
        cell=fx_atlas.crop((index*256,0,(index+1)*256,256)).resize((390,390),Image.Resampling.NEAREST)
        canvas.paste(cell,(61,-12),cell);gif_frames.append(canvas)
    gif_frames.extend([gif_frames[-1]]*4)
    gif_frames[0].save(PREVIEW/"bomb-fuse-explosion-v1.gif",save_all=True,append_images=gif_frames[1:],duration=100,loop=0,optimize=False)
    print(f"BOMB_MONKEY_ASSET_OK bomb={atlas.width}x{atlas.height} explosion={fx_atlas.width}x{fx_atlas.height}")


if __name__ == "__main__":
    build()
