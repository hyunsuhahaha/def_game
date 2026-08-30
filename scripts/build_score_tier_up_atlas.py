"""Build the regeneration-tier transition atlas on the project's fixed FX grid."""
from __future__ import annotations

from pathlib import Path
import math
import random
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"assets/fx/score-tier-up-atlas-pixel-v1.png"
W,H,FRAMES=768,384,12
INK=(24,48,27,255)
LEAF=[(39,79,39,255),(63,116,49,255),(91,151,59,255),(139,192,74,255),(202,220,99,255)]
GOLD=[(109,64,19,255),(186,111,22,255),(241,174,39,255),(255,225,105,255),(255,249,190,255)]
CYAN=[(24,87,75,255),(43,151,116,255),(93,222,157,255),(191,255,191,255)]

def rect(d,x,y,w,h,c):
    x,y=int(round(x)),int(round(y));d.rectangle((x,y,x+w-1,y+h-1),fill=c)

def leaf(d,x,y,size,angle,ramp=LEAF):
    ca,sa=math.cos(angle),math.sin(angle)
    pts=[]
    for px,py in ((-size,0),(0,-size*.46),(size,0),(0,size*.46)):
        pts.append((int(x+px*ca-py*sa),int(y+px*sa+py*ca)))
    d.polygon(pts,fill=INK)
    inner=[(int(x+(px*.72)*ca-(py*.72)*sa),int(y+(px*.72)*sa+(py*.72)*ca)) for px,py in ((-size,0),(0,-size*.46),(size,0),(0,size*.46))]
    d.polygon(inner,fill=ramp[2])
    rect(d,x-size*.15,y-size*.19,max(2,int(size*.55)),max(2,int(size*.18)),ramp[4])

def shard(d,x,y,size,angle,ramp=GOLD):
    ca,sa=math.cos(angle),math.sin(angle)
    pts=[]
    for px,py in ((0,-size),(size*.42,0),(0,size),(-size*.42,0)):
        pts.append((int(x+px*ca-py*sa),int(y+px*sa+py*ca)))
    d.polygon(pts,fill=ramp[0]);
    inner=[(int(x+(px*.66)*ca-(py*.66)*sa),int(y+(px*.66)*sa+(py*.66)*ca)) for px,py in ((0,-size),(size*.42,0),(0,size),(-size*.42,0))]
    d.polygon(inner,fill=ramp[min(2,len(ramp)-1)]);rect(d,x-2,y-size*.48,5,max(3,int(size*.48)),ramp[-1])

def frame(i):
    im=Image.new("RGBA",(W,H));d=ImageDraw.Draw(im);t=i/(FRAMES-1);cx,cy=W//2,H//2
    rng=random.Random(52000+i)
    # Pixel-authored broken rings. Their gaps and stepped widths avoid a runtime-circle look.
    ring=min(1,t*2.8)*150
    fade=max(0,min(1,(1-t)*2.5))
    for k in range(32):
        if (k+i)%7==0: continue
        a=k*math.tau/32+i*.035
        x=cx+math.cos(a)*ring;y=cy+math.sin(a)*ring*.43
        size=8+(k%3)*2
        leaf(d,x,y,size,a+math.pi*.5,LEAF)
    # Leaves first converge, then reverse into a crown burst.
    for k in range(18):
        a=k*math.tau/18+(k%3)*.11
        if t<.34:
            q=1-t/.34;radius=70+q*(190+(k%4)*15)
        else:
            q=(t-.34)/.66;radius=48+q*(155+(k%5)*10)
        x=cx+math.cos(a)*radius;y=cy+math.sin(a)*radius*.45
        leaf(d,x,y,11+(k%3)*3,a+(i*.17)*(1 if k%2 else -1),LEAF)
    # Central seed/prism: stepped facets and asymmetric highlights.
    pulse=max(0,min(1,(t-.08)*5))*fade
    size=42+math.sin(min(1,t/.48)*math.pi)*18
    shard(d,cx,cy,size,0,GOLD);shard(d,cx,cy,size*.62,math.pi*.5,CYAN)
    rect(d,cx-8,cy-size*.48,12,max(4,int(size*.33)),GOLD[4])
    # Upward energy and detached motes sell the level jump without covering play.
    for k in range(14):
        q=min(1,max(0,t-.18)*(1.25+(k%4)*.08))
        x=cx+(k-6.5)*17+math.sin(k*2.1+i*.8)*9
        y=cy+82-q*(175+(k%3)*22)
        color=CYAN[2+(k%2)] if k%3 else GOLD[3+(k%2)]
        rect(d,x,y,5+(k%3)*2,8+(k%2)*3,color)
    # Small dither chips give material density at the native atlas scale.
    for k in range(44):
        a=rng.random()*math.tau;r=(55+rng.random()*145)*min(1,t*3)
        x=cx+math.cos(a)*r;y=cy+math.sin(a)*r*.43
        rect(d,x,y,3+(k%3),3+(k%2),LEAF[1+(k%4)])
    return im

def main():
    atlas=Image.new("RGBA",(W*FRAMES,H))
    for i in range(FRAMES): atlas.alpha_composite(frame(i),(i*W,0))
    OUT.parent.mkdir(parents=True,exist_ok=True);atlas.save(OUT,optimize=True)
    print(f"wrote {OUT.relative_to(ROOT)} {atlas.width}x{atlas.height}")

if __name__=="__main__":main()
