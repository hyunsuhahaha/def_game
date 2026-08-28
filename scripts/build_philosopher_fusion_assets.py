from pathlib import Path
import math
import random

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "fx" / "philosopher"
OUT.mkdir(parents=True, exist_ok=True)


def jagged_oval(cx, cy, rx, ry, seed, count=72):
    rng = random.Random(seed)
    points = []
    for i in range(count):
        a = math.tau * i / count
        rough = 1 + rng.uniform(-0.035, 0.035) + math.sin(a * 7 + seed) * 0.018
        points.append((round(cx + math.cos(a) * rx * rough), round(cy + math.sin(a) * ry * rough)))
    return points


def broken_ellipse(draw, box, color, width, seed, coverage=.72):
    rng = random.Random(seed)
    start = rng.randint(0, 40)
    cursor = start
    while cursor < start + int(360 * coverage):
        run = rng.randint(14, 34)
        draw.arc(box, cursor, min(cursor + run, start + int(360 * coverage)), fill=color, width=width)
        cursor += run + rng.randint(5, 13)


def build_eternal_return():
    cell_w, cell_h, frames = 384, 256, 6
    atlas = Image.new("RGBA", (cell_w * frames, cell_h), (0, 0, 0, 0))
    for frame in range(frames):
        im = Image.new("RGBA", (cell_w, cell_h), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        rng = random.Random(6100 + frame)
        cx, cy = 192, 181
        settle = [0.55, .84, 1, 1, 1, .92][frame]
        rx, ry = 145 * settle, 53 * settle

        # Soft contact shadow and earthen edge keep the field attached to the floor.
        d.polygon(jagged_oval(cx, cy + 8, rx + 10, ry + 8, 90 + frame), fill=(19, 35, 30, 78))
        d.polygon(jagged_oval(cx, cy + 3, rx + 5, ry + 4, 190 + frame), fill=(39, 70, 61, 190))
        d.polygon(jagged_oval(cx, cy, rx, ry, 290 + frame), fill=(70, 126, 118, 218))
        d.polygon(jagged_oval(cx, cy - 2, rx - 5, ry - 5, 390 + frame), fill=(91, 157, 145, 215))

        # Clear-water tiles: clustered pixels, not a smooth procedural gradient.
        for _ in range(155):
            x = rng.randint(round(cx-rx+8), round(cx+rx-8))
            y = rng.randint(round(cy-ry+4), round(cy+ry-4))
            nx, ny = (x-cx)/max(1, rx), (y-cy)/max(1, ry)
            if nx*nx + ny*ny < .9:
                light = rng.random() < .42
                col = (131, 196, 177, rng.randint(70, 145)) if light else (42, 102, 100, rng.randint(65, 125))
                w = rng.choice((2, 3, 4, 6)); h = rng.choice((1, 2))
                d.rectangle((x, y, x+w, y+h), fill=col)

        # Recurring ripples and cream sentence fragments travel back toward center.
        phase = frame * 17
        for ring, alpha in ((1, 225), (2, 205), (3, 175)):
            rr_x = rx * (.20 + ring * .19)
            rr_y = ry * (.20 + ring * .19)
            broken_ellipse(d, (cx-rr_x, cy-rr_y, cx+rr_x, cy+rr_y), (208, 226, 176, alpha), 3, 700+frame*11+ring, .84)
            broken_ellipse(d, (cx-rr_x+2, cy-rr_y+2, cx+rr_x-2, cy+rr_y-2), (128, 188, 171, 185), 2, 800+frame*13+ring, .66)
        for i in range(30):
            a = (i / 30) * math.tau + phase * .025
            radial = .62 + .12 * math.sin(i * 2.3 + frame)
            x = cx + math.cos(a) * rx * radial
            y = cy + math.sin(a) * ry * radial
            length = 3 + (i % 4) * 2
            d.rectangle((round(x), round(y), round(x+length), round(y+2)), fill=(238, 226, 171, 220))
            if i % 5 == 0:
                d.rectangle((round(x+length+2), round(y+1), round(x+length+4), round(y+3)), fill=(243, 239, 197, 190))

        # First two frames have a crisp clean impact splash, never viscous strands.
        if frame < 2:
            height = 67 if frame == 0 else 37
            for i in range(9):
                a = math.pi + (i / 8) * math.pi
                base_x = cx + math.cos(a) * (15 + i % 3 * 7)
                tip_x = cx + math.cos(a) * (42 + i % 2 * 12)
                tip_y = cy - height * (.65 + .35 * math.sin((i+1)*.8))
                d.polygon([(round(base_x-4), cy-5), (round(base_x+4), cy-5), (round(tip_x), round(tip_y))], fill=(173, 222, 199, 230))
                d.line([(round(base_x), cy-7), (round(tip_x), round(tip_y+4))], fill=(237, 241, 203, 220), width=2)
        if frame == 5:
            fade = Image.new("RGBA", im.size, (0, 0, 0, 0))
            # The runtime alpha completes the fade; sparse erasure makes the last cel distinct.
            pix = im.load()
            for y in range(cell_h):
                for x in range(cell_w):
                    if (x * 5 + y * 3) % 11 < 3:
                        r, g, b, a = pix[x, y]
                        pix[x, y] = (r, g, b, a // 3)
        atlas.alpha_composite(im, (frame * cell_w, 0))
    path = OUT / "eternal-return-field-atlas-pixel-v1.png"
    atlas.save(path, optimize=True)
    return path


def paper(draw, x, y, flip=1, scale=1):
    pts = [(x-14*flip*scale,y-10*scale),(x+12*flip*scale,y-7*scale),(x+15*flip*scale,y+8*scale),(x-11*flip*scale,y+11*scale)]
    draw.polygon([(round(a),round(b)) for a,b in pts], fill=(242, 219, 164, 235))
    draw.line([(round(x-8*flip*scale),round(y-3*scale)),(round(x+8*flip*scale),round(y-1*scale))], fill=(133, 89, 45, 220), width=max(1,round(2*scale)))
    draw.line([(round(x-6*flip*scale),round(y+3*scale)),(round(x+6*flip*scale),round(y+5*scale))], fill=(133, 89, 45, 190), width=max(1,round(scale)))


def build_revival_chorus():
    cell = 256
    atlas = Image.new("RGBA", (cell * 6, cell), (0, 0, 0, 0))
    for frame in range(6):
        im = Image.new("RGBA", (cell, cell), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        rng = random.Random(9800 + frame)
        if frame < 3:
            # A compact travelling sermon: parchment, amber syllable blocks, teal beats.
            spread = 16 + frame * 12
            paper(d, 108-frame*8, 124-frame*3, 1, .75)
            for i in range(12 + frame * 4):
                x = 92 + i * 5 + rng.randint(-2, 2)
                y = 112 + rng.randint(-spread, spread)
                col = (247, 169, 55, 245) if i % 3 else (255, 226, 145, 245)
                d.rectangle((x, y, x+rng.choice((3,5,7)), y+3), fill=col)
                if i % 4 == 0: d.rectangle((x+1, y-6, x+3, y+2), fill=(207, 112, 40, 220))
            for side in (-1,1):
                bx = 76 if side < 0 else 181
                for j in range(3):
                    off=j*7+frame*3
                    d.arc((bx-off,102-off//3,bx+24+off,151+off//3),-55 if side<0 else 125,55 if side<0 else 235,fill=(67,191,183,210-j*45),width=3)
            d.rectangle((180,119,205+frame*5,124),fill=(246,233,198,190))
        else:
            p = frame - 3
            # Contact lives at the target: narrow white cuts with warm/teal debris.
            center_x, ground_y = 128, 174
            reach = (68, 88, 62)[p]
            for i in range(7):
                x = center_x + (i-3)*8
                top = ground_y - reach + abs(i-3)*7 + p*5
                d.polygon([(x-2,ground_y),(x+3,ground_y),(x+rng.randint(-7,7),top),(x+1,ground_y-18)], fill=(251,245,220,235 if p<2 else 165))
                d.line((x,ground_y-4,x+rng.randint(-6,6),top+5),fill=(255,255,246,255 if p<2 else 190),width=2)
            d.ellipse((69,165,187,190),fill=(50,67,55,95))
            d.arc((62,142,194,198),198,342,fill=(71,193,184,220-p*45),width=4)
            d.arc((78,151,178,191),200,340,fill=(247,169,55,235-p*40),width=3)
            for i in range(24-p*5):
                a=rng.uniform(math.pi,math.tau);r=rng.uniform(24,76)
                x=center_x+math.cos(a)*r;y=ground_y+math.sin(a)*r*.48
                col=(246,166,53,235) if i%3 else (235,219,169,235)
                d.rectangle((round(x),round(y),round(x+rng.choice((2,4,6))),round(y+rng.choice((2,3)))),fill=col)
            if p==2:
                # Broken last cel; runtime alpha handles the final disappearance.
                pix=im.load()
                for y in range(cell):
                    for x in range(cell):
                        if (x*3+y*7)%13<5:
                            r,g,b,a=pix[x,y];pix[x,y]=(r,g,b,a//3)
        atlas.alpha_composite(im,(frame*cell,0))
    path = OUT / "revival-chorus-atlas-pixel-v1.png"
    atlas.save(path, optimize=True)
    return path


if __name__ == "__main__":
    for built in (build_eternal_return(), build_revival_chorus()):
        print(built.relative_to(ROOT))
