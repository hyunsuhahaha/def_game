"""Build the authored biome boss entrance FX atlas on a fixed pixel grid."""
from pathlib import Path
from PIL import Image, ImageDraw
import math, random

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/fx/boss-entrance/boss-entrance-fx-atlas-pixel-v1.png'
CELL,FRAMES,ROWS=256,6,5
img=Image.new('RGBA',(CELL*FRAMES,CELL*ROWS),(0,0,0,0))

palettes=[
    ((49,30,19),(111,65,29),(201,126,48),(235,183,82)),
    ((31,49,25),(72,105,43),(155,157,61),(224,190,76)),
    ((21,53,49),(38,100,92),(70,158,147),(166,211,176)),
    ((72,38,22),(151,77,31),(224,139,48),(244,200,91)),
    ((36,72,76),(58,137,145),(151,211,190),(238,231,178)),
]

def poly(draw,pts,fill,outline=None,w=1):
    draw.polygon([(int(x),int(y)) for x,y in pts],fill=fill)
    if outline: draw.line([(int(x),int(y)) for x,y in pts+[pts[0]]],fill=outline,width=w,joint='curve')

for row in range(ROWS):
  colors=palettes[row]
  for frame in range(FRAMES):
    rng=random.Random(90210+row*1009+frame*67)
    tile=Image.new('RGBA',(CELL,CELL),(0,0,0,0));d=ImageDraw.Draw(tile)
    p=frame/(FRAMES-1); burst=math.sin(p*math.pi)
    cx,ground=128,190
    # Ground contact is an authored stepped ellipse, never a soft vector blur.
    rx=28+burst*88; ry=6+burst*17
    for band in range(4,0,-1):
      rr=band/4
      c=colors[band-1]+(int((.28+.12*band)*255*burst),)
      d.ellipse((cx-rx*rr,ground-ry*rr,cx+rx*rr,ground+ry*rr),outline=c,width=3)
    # Biome-specific silhouette language.
    if row in (0,1):
      for side in (-1,1):
        pts=[(cx+side*8,ground),(cx+side*(30+rx*.35),ground-7-burst*14),
             (cx+side*(58+rx*.45),ground+2),(cx+side*(86+rx*.5),ground-5)]
        d.line(pts,fill=colors[0]+(int(240*burst),),width=10)
        d.line(pts,fill=colors[2]+(int(210*burst),),width=4)
      if row==1:
        for i in range(13):
          a=rng.uniform(math.pi,math.pi*2);r=(30+rng.random()*86)*burst
          x,y=cx+math.cos(a)*r,ground-34+math.sin(a)*r*.48
          c=colors[1+i%3]+(int(230*burst),)
          poly(d,[(x,y-7),(x+7,y-2),(x+3,y+6),(x-6,y+4)],c,colors[0]+(190,),2)
    elif row==2:
      for i in range(7):
        x=cx+(i-3)*25; height=(35+(i%3)*19)*burst
        pts=[(x-13,ground),(x-8,ground-height*.48),(x,ground-height),(x+8,ground-height*.42),(x+14,ground)]
        poly(d,pts,colors[2]+(int(220*burst),),colors[0]+(220,),3)
        poly(d,[(x-6,ground-2),(x-2,ground-height*.38),(x+3,ground-height*.68),(x+6,ground-2)],colors[3]+(int(190*burst),))
    elif row==3:
      for i in range(18):
        a=rng.random()*math.pi*2;r=(24+rng.random()*105)*burst
        x,y=cx+math.cos(a)*r,ground-38+math.sin(a)*r*.5
        size=4+(i%4)*2
        c=colors[1+i%3]+(int(230*burst),)
        poly(d,[(x,y-size),(x+size,y),(x,y+size),(x-size,y)],c,colors[0]+(200,),2)
    else:
      for i in range(9):
        x=cx+(i-4)*23; lift=(18+(i%3)*10)*burst
        d.arc((x-23,ground-lift-13,x+23,ground-lift+13),190,350,fill=colors[3]+(int(245*burst),),width=6)
        d.arc((x-18,ground-lift-9,x+18,ground-lift+9),190,350,fill=colors[1]+(int(220*burst),),width=3)
    # Crisp foreground chips/droplets with stepped highlights.
    for i in range(18):
      a=rng.uniform(math.pi*1.08,math.pi*1.92);r=(28+rng.random()*104)*burst
      x,y=cx+math.cos(a)*r,ground+math.sin(a)*r*.7
      s=2+(i%4)
      c=colors[1+i%3]+(int(245*burst),)
      d.rectangle((int(x-s),int(y-s),int(x+s),int(y+s)),fill=colors[0]+(int(230*burst),))
      d.rectangle((int(x-s+2),int(y-s+1),int(x+s),int(y+s-1)),fill=c)
    img.alpha_composite(tile,(frame*CELL,row*CELL))

OUT.parent.mkdir(parents=True,exist_ok=True)
img.save(OUT,optimize=True)
print(OUT)
