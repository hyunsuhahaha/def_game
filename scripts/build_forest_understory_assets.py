from pathlib import Path
from PIL import Image, ImageDraw
import random

ROOT=Path(__file__).resolve().parents[1]
OUTPUT=ROOT/"assets/scenery/forest/grass-understory-atlas-pixel-v1.png"
W,H=128,96
OUTLINE=(12,22,15,255);DEEP=(25,48,27,255);DARK=(39,76,35,255)
MID=(64,105,43,255);GREEN=(84,128,48,255);LIGHT=(118,151,57,255);TIP=(151,171,67,255)

def blade(draw,x,y,height,lean,width,tone):
    tx=x+lean;sy=y-height*2//3;bx=x+lean*2//5
    colors=[(DEEP,DARK,MID),(DARK,MID,GREEN),(MID,GREEN,LIGHT)][tone]
    draw.polygon([(x-width-1,y),(bx-width-1,sy),(tx,y-height-2),(bx+width+1,sy),(x+width+1,y)],fill=OUTLINE)
    draw.polygon([(x-width,y-1),(bx-width,sy),(tx,y-height),(bx+width,sy+1),(x+width,y-1)],fill=colors[1])
    draw.line((x,y-3,bx,sy+2,tx,y-height+3),fill=colors[2],width=1)
    if height>30:draw.point((tx,y-height+1),fill=TIP)

def tuft(frame):
    im=Image.new("RGBA",(W,H),(0,0,0,0));d=ImageDraw.Draw(im);rng=random.Random(42071);roots=[]
    for gx,gy,count in ((43,84,12),(82,86,11),(63,88,7)):
        for _ in range(count):roots.append((gx+rng.randint(-22,22),gy+rng.randint(-3,3),rng.randint(22,49),rng.randint(-13,13),rng.randint(1,2),rng.randint(0,2)))
    if frame==3:
        for x,y,height,lean,width,tone in roots:blade(d,x,y,6+height%9,lean//4,1,min(tone,1))
        d.ellipse((28,82,100,91),fill=(18,37,21,150))
        for x in (36,51,68,84,94):d.line((x,87,x+x%5-2,78+x%6),fill=MID,width=2)
        return im
    bend=0 if frame==0 else (-13 if frame==1 else 13)
    for x,y,height,lean,width,tone in sorted(roots,key=lambda v:v[2]):blade(d,x,y,height-(3 if frame else 0),round(lean+bend*(height/49)),width,tone)
    d.arc((24,80,104,94),188,350,fill=DEEP,width=2)
    return im

atlas=Image.new("RGBA",(W*4,H),(0,0,0,0))
for frame in range(4):atlas.alpha_composite(tuft(frame),(frame*W,0))
OUTPUT.parent.mkdir(parents=True,exist_ok=True);atlas.save(OUTPUT,optimize=True)
print(f"wrote {OUTPUT.relative_to(ROOT)} {atlas.size}")
