"""Build three coherent six-frame oil-fire objects without generated imagery."""
from pathlib import Path
import math
import random
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
ASSET=ROOT/"assets"/"fx"/"oil-trail"
PREVIEW=ROOT/"docs"/"previews"
CELL,COLS,ROWS=128,6,3

OUTLINE=(67,18,20,255)
RED=(127,25,18,255)
VERMILION=(190,41,13,255)
ORANGE=(238,72,8,255)
GOLD=(255,132,10,255)
YELLOW=(255,202,38,255)
CREAM=(255,239,142,255)
WHITE=(255,250,213,255)
COAL=(31,25,27,255)
SMOKE=((43,40,43,255),(57,52,53,255),(72,65,63,255),(91,80,74,255))


def poly(draw,points,color):
    draw.polygon([(round(x/2)*2,round(y/2)*2) for x,y in points],fill=color)


def tongue(draw,cx,base,height,width,lean,phase):
    sway=round(math.sin(phase)*5/2)*2
    outer=[(cx-width,base),(cx-width,base-height*.24),(cx-width*.58,base-height*.43),
           (cx-width*.34+sway,base-height*.67),(cx+lean+sway,base-height),
           (cx+width*.25+lean,base-height*.62),(cx+width*.62,base-height*.38),(cx+width,base)]
    poly(draw,outer,OUTLINE)
    poly(draw,[(cx-width+3,base-2),(cx-width*.55,base-height*.34),(cx-width*.18+sway,base-height*.58),
               (cx+lean+sway,base-height*.86),(cx+width*.31+lean,base-height*.49),(cx+width-3,base-2)],RED)
    poly(draw,[(cx-width*.80,base-3),(cx-width*.48,base-height*.31),(cx-width*.10+sway,base-height*.63),
               (cx+lean+sway*.8,base-height*.73),(cx+width*.30+lean,base-height*.40),(cx+width*.72,base-3)],VERMILION)
    poly(draw,[(cx-width*.68,base-4),(cx-width*.34,base-height*.30),(cx+sway*.55,base-height*.57),
               (cx+width*.25+lean,base-height*.38),(cx+width*.58,base-4)],ORANGE)
    poly(draw,[(cx-width*.54,base-5),(cx-width*.24,base-height*.25),(cx+sway*.42,base-height*.50),
               (cx+width*.20+lean*.4,base-height*.30),(cx+width*.46,base-5)],GOLD)
    poly(draw,[(cx-width*.42,base-5),(cx-width*.16,base-height*.22),(cx+sway*.35,base-height*.43),
               (cx+width*.20,base-height*.20),(cx+width*.36,base-5)],YELLOW)
    poly(draw,[(cx-width*.20,base-6),(cx,base-height*.19),(cx+width*.15,base-6)],CREAM)
    draw.rectangle((round(cx/2)*2-2,base-10,round(cx/2)*2+2,base-6),fill=WHITE)


def fire_cell(row,frame):
    image=Image.new("RGBA",(CELL,CELL))
    draw=ImageDraw.Draw(image)
    rng=random.Random(8309+row*503)
    base=108
    if row==0:
        specs=[(28,27,13,-2),(46,40,15,3),(66,31,13,-3),(84,44,16,4),(103,28,12,-2)]
    elif row==1:
        specs=[(35,48,17,-3),(57,68,20,4),(80,55,18,-4),(98,39,14,3)]
    else:
        specs=[(42,58,18,-4),(65,88,22,5),(89,64,18,-3)]
    for index,(cx,height,width,lean) in enumerate(specs):
        phase=frame*.92+index*1.41+row*.63
        animated_height=height+round(math.sin(phase)*7/2)*2
        animated_lean=lean+round(math.cos(phase*.77)*4/2)*2
        tongue(draw,cx,base,animated_height,width,animated_lean,phase)

    # Fixed roots keep the fire attached to oil while the upper silhouette moves.
    poly(draw,[(18,108),(29,101),(45,105),(61,100),(77,104),(95,99),(111,108),(103,114),(26,114)],OUTLINE)
    poly(draw,[(24,107),(39,103),(53,107),(69,102),(86,106),(102,103),(106,109),(29,110)],VERMILION)
    for x in range(30,105,8):
        color=GOLD if (x//8+frame)%3 else YELLOW
        draw.rectangle((x,106+(x//8)%2*2,x+4,108+(x//8)%2*2),fill=color)

    # Ordered flame texture follows the bodies instead of filling space randomly.
    pixels=image.load()
    for y in range(30,106,4):
        for x in range(20+(y//4)%2*2,111,6):
            r,g,b,a=pixels[x,y]
            if a and (x*3+y*5+frame*7+row*11)%19<4:
                pixels[x,y]=(min(255,r+28),min(255,g+18),b,a)

    # Detached embers rise on independent paths; no whole-object pulse.
    for index in range(7):
        ex=29+index*12+round(math.sin(frame*.8+index*1.7)*5/2)*2
        ey=69-row*7-((frame*7+index*11)%31)
        size=2 if index%3 else 4
        draw.rectangle((ex,ey,ex+size,ey+size),fill=YELLOW if index%2 else ORANGE)

    if row==2:
        for index in range(3):
            phase=frame*.66+index*1.9
            sx=52+index*18+round(math.sin(phase)*6/2)*2
            sy=22-index*9-((frame*3+index*5)%9)
            radius=8+index*2
            poly(draw,[(sx-radius,sy+5),(sx-radius*.72,sy-3),(sx-2,sy-radius),
                       (sx+radius*.62,sy-5),(sx+radius,sy+4),(sx+2,sy+radius)],SMOKE[(index+frame)%len(SMOKE)])
            draw.rectangle((sx-4,sy-2,sx+2,sy+2),fill=SMOKE[min(3,index+1)])
    return image


atlas=Image.new("RGBA",(CELL*COLS,CELL*ROWS))
cells=[]
for row in range(ROWS):
    cells.append([])
    for frame in range(COLS):
        cell=fire_cell(row,frame);cells[row].append(cell)
        atlas.alpha_composite(cell,(frame*CELL,row*CELL))
atlas.save(ASSET/"oil-fire-object-atlas-pixel-v3.png")

grass=(48,59,38,255)
board=Image.new("RGBA",(768,896),grass)
for row in range(ROWS):
    for frame in range(COLS):board.alpha_composite(cells[row][frame],(frame*CELL,row*128))
zoom=cells[1][3].resize((512,512),Image.Resampling.NEAREST)
board.alpha_composite(zoom,(128,384))
board.save(PREVIEW/"oil-fire-objects-v3-board.png")
print("OIL_FIRE_OBJECTS_V3_BUILT atlas=768x384 cell=128 frames=6 variants=3 alpha=hard")
