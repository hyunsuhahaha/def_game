"""Build authored red pixel telegraphs for every world-tree attack.

The atlas contains complete danger footprints from frame one. Runtime scales
the native circle/capsule geometry from the same radius and half-width values
used by collision, so the warning never understates the damaging area.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import math
import random

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/fx/worldtree/worldtree-telegraphs-atlas-v1.png"
PREVIEW = ROOT / "docs/previews/worldtree-telegraphs-v1-contact-sheet.png"
C = 384
RED = [(43, 5, 8, 185), (82, 8, 12, 205), (132, 14, 18, 225),
       (190, 27, 24, 240), (239, 61, 35, 255), (255, 126, 70, 255)]


def segmented_ring(draw, cx, cy, radius, frame, seed, y_scale=1.0):
    rng = random.Random(seed + frame * 97)
    pulse = frame / 5
    # Sparse interior pixels communicate danger without becoming a flat disc.
    step = 10
    for y in range(int(cy-radius*y_scale), int(cy+radius*y_scale)+1, step):
        for x in range(int(cx-radius), int(cx+radius)+1, step):
            dx, dy = (x-cx)/radius, (y-cy)/(radius*y_scale)
            q = dx*dx + dy*dy
            if q < .91 and ((x//step + y//step + frame) % 3 == 0):
                tone = 1 + ((x//step + y//step) & 1)
                a = 30 + frame*4
                draw.rectangle((x, y, x+3, y+3), fill=(*RED[tone][:3], a))
    # Broken concentric contour: authored chunks, not a smooth runtime circle.
    for band in range(3):
        r = radius-band*5
        width = 3 if band == 0 else 2
        for i in range(28):
            if (i + band*3 + frame) % 7 == 0:
                continue
            a0 = i/28*math.tau + rng.uniform(-.012, .012)
            a1 = (i+.72)/28*math.tau
            color = RED[min(5, 2+band+(1 if pulse>.7 else 0))]
            box = (cx-r, cy-r*y_scale, cx+r, cy+r*y_scale)
            draw.arc(box, math.degrees(a0), math.degrees(a1), fill=color, width=width)
    # Radial warning cracks grow denser while the damage timing approaches.
    for i in range(7+frame*2):
        a = i*2.399 + seed*.01
        inner = radius*(.23 + (i%3)*.08)
        outer = radius*(.72 + (i%4)*.055)
        bend = (rng.random()-.5)*.12
        p0=(cx+math.cos(a)*inner, cy+math.sin(a)*inner*y_scale)
        pm=(cx+math.cos(a+bend)*(inner+outer)*.52, cy+math.sin(a+bend)*(inner+outer)*.52*y_scale)
        p1=(cx+math.cos(a)*outer, cy+math.sin(a)*outer*y_scale)
        draw.line((p0,pm,p1), fill=RED[3+(i+frame)%2], width=2)
        if frame>=4 and i%4==0:
            x,y=p1;draw.rectangle((x-2,y-2,x+2,y+2),fill=RED[5])


def capsule(draw, x0, x1, cy, half, frame, seed):
    rng=random.Random(seed+frame*131)
    # Dithered inner danger lane.
    for y in range(cy-half+8,cy+half-7,9):
        for x in range(x0+8,x1-7,10):
            if (x//10+y//9+frame)%3==0:
                draw.rectangle((x,y,x+4,y+2),fill=(*RED[2+(x//10&1)][:3],34+frame*5))
    # Jagged parallel rails stay exactly inside the gameplay half-width.
    for side in (-1,1):
        base=cy+side*(half-3)
        points=[]
        for i in range(18):
            q=i/17;x=x0+(x1-x0)*q
            y=base+side*(rng.randint(-2,2))
            points.append((round(x),round(y)))
        draw.line(points,fill=RED[1],width=7)
        draw.line(points,fill=RED[4 if frame<4 else 5],width=3)
        for i in range(1,17,3):
            if (i+frame)%5:
                x,y=points[i];draw.line((x,y,x+7,y-side*(7+frame)),fill=RED[3],width=2)
    # End caps and bark-like cross fractures make direction/reach readable.
    for x in (x0,x1):
        draw.line((x,cy-half+2,x,cy+half-2),fill=RED[1],width=7)
        draw.line((x,cy-half+4,x,cy+half-4),fill=RED[5],width=3)
    for i in range(4+frame):
        x=x0+20+(i*47+frame*13)%(x1-x0-40)
        y=cy+rng.randint(-half//2,half//2)
        draw.line((x-8,y-9,x,y,x+9,y-7),fill=RED[4],width=2)


def make_cell(row, frame):
    image=Image.new("RGBA",(C,C));draw=ImageDraw.Draw(image)
    if row==0: segmented_ring(draw,192,238,123,frame,1100,1.0)       # root burst
    elif row==1: capsule(draw,22,362,192,36,frame,2100)               # vine whip
    elif row==2: segmented_ring(draw,192,192,138,frame,3100,1.0)      # root slam
    else: capsule(draw,22,362,224,51,frame,4100)                      # branch fall
    return image


atlas=Image.new("RGBA",(C*6,C*4))
for row in range(4):
    for frame in range(6): atlas.alpha_composite(make_cell(row,frame),(frame*C,row*C))
OUT.parent.mkdir(parents=True,exist_ok=True);atlas.save(OUT)

board=Image.new("RGB",atlas.size,(49,75,34));bg=ImageDraw.Draw(board)
for y in range(0,board.height,24):
    for x in range(0,board.width,24):
        if (x//24+y//24)%3==0:bg.rectangle((x,y,x+23,y+23),fill=(55,82,38))
board.paste(atlas,(0,0),atlas);PREVIEW.parent.mkdir(parents=True,exist_ok=True);board.save(PREVIEW)
print(OUT);print(PREVIEW)
