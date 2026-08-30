"""Build the authored inhale/compress/gust atlases for the smoker vape route."""
from pathlib import Path
from PIL import Image,ImageDraw
import math,random

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/effects'
INK=(9,19,27,255);DEEP=(13,43,54,255)
CYAN=[(16,71,82,255),(20,111,126,255),(28,157,166,255),(45,204,201,255),(105,239,220,255),(220,255,238,255)]
AIR=[(54,104,123,90),(84,153,165,125),(143,211,207,165),(224,255,239,215)]
VIOLET=[(49,34,92,255),(83,57,145,255),(137,91,201,255)]
LEAF=[(18,52,30,255),(35,88,42,255),(61,128,48,255),(112,165,62,255),(180,203,91,255)]

def frame_xy(frame,cell): return frame*cell
def shifted(frame,cell,points): return [(frame_xy(frame,cell)+round(x),round(y)) for x,y in points]
def poly(draw,frame,cell,points,fill,outline=None,width=1):
    pts=shifted(frame,cell,points);draw.polygon(pts,fill=fill)
    if outline:draw.line(pts+[pts[0]],fill=outline,width=width)
def line(draw,frame,cell,points,fill,width):draw.line(shifted(frame,cell,points),fill=fill,width=width,joint='curve')
def ellipse(draw,frame,cell,box,fill,outline=None,width=1):
    x0,y0,x1,y1=box;off=frame_xy(frame,cell);draw.ellipse((off+round(x0),round(y0),off+round(x1),round(y1)),fill=fill,outline=outline,width=width)
def rect(draw,frame,cell,box,fill):
    x0,y0,x1,y1=box;off=frame_xy(frame,cell);draw.rectangle((off+round(x0),round(y0),off+round(x1),round(y1)),fill=fill)

# 24-frame inhale -> compression -> release-ready pulse, 256 px cells. This
# plays near 30 fps during the normal 0.9 second charge instead of stepping.
CCELL=256;FRAMES=24
charge=Image.new('RGBA',(CCELL*FRAMES,CCELL),(0,0,0,0));cd=ImageDraw.Draw(charge)
cx,cy=118,132
for f in range(FRAMES):
    t=f/(FRAMES-1)
    # Motes travel inward instead of expanding outward: readable inhalation.
    for i in range(18):
        phase=(i/18+t*1.25)%1
        if t<.48:
            x=235-(phase**1.45)*112;y=cy+math.sin(i*1.71+t*8)*42*(1-phase*.72)
        else:
            compression=(t-.48)/.52
            radius=(52*(1-compression)+11)*(.45+.55*phase)
            a=i*.79+t*11;x=cx+math.cos(a)*radius;y=cy+math.sin(a)*radius*.62
        size=2+(i+f)%5;color=CYAN[1+(i+f)%5]
        rect(cd,f,CCELL,(x-size,y-size,x+size,y+size),INK)
        rect(cd,f,CCELL,(x-size+1,y-size+1,x+size-1,y+size-1),color)
    # Stepped compression rings tighten around the tank/nozzle anchor.
    if t>.30:
        u=(t-.30)/.70;radius=56*(1-u)+10
        for ring in range(3):
            rr=radius+ring*8
            pts=[]
            for k in range(20):
                a=k/20*math.pi*2;step=2 if (k+f+ring)%4==0 else 0
                pts.append((cx+math.cos(a)*(rr+step),cy+math.sin(a)*(rr*.62+step)))
            line(cd,f,CCELL,pts+[pts[0]],AIR[min(3,ring+1)],3+ring)
    core=4+max(0,t-.55)*26
    ellipse(cd,f,CCELL,(cx-core,cy-core,cx+core,cy+core),CYAN[3],INK,3)
    ellipse(cd,f,CCELL,(cx-core*.48,cy-core*.48,cx+core*.48,cy+core*.48),CYAN[5])
    if f>=9:
        for i in range(10):
            a=i/10*math.pi*2+f*.13;r=core+12+(i%3)*5
            rect(cd,f,CCELL,(cx+math.cos(a)*r-2,cy+math.sin(a)*r-2,cx+math.cos(a)*r+2,cy+math.sin(a)*r+2),CYAN[4 if i%2 else 5])

# 24-frame expanding pressure front, 768x384. At 240x120 world units this
# retains the repository's required 3.2 texels per world unit.  The doubled
# temporal density is intentional: this is a 30 fps animated pressure blast,
# not a few static line drawings being stretched over the attack lifetime.
GCELL=768;GH=384;GFRAMES=24;GCOLS=8;GROWS=3
gust=Image.new('RGBA',(GCELL*GCOLS,GH*GROWS),(0,0,0,0));gd=ImageDraw.Draw(gust)
def gshift(frame,points):
    ox=(frame%GCOLS)*GCELL;oy=(frame//GCOLS)*GH
    return [(ox+round(x),oy+round(y)) for x,y in points]
def gpoly(frame,points,fill,outline=None,width=1):
    pts=gshift(frame,points);gd.polygon(pts,fill=fill)
    if outline:gd.line(pts+[pts[0]],fill=outline,width=width)
def gline(frame,points,fill,width):gd.line(gshift(frame,points),fill=fill,width=width,joint='curve')
def gellipse(frame,box,fill,outline=None,width=1):
    x0,y0,x1,y1=box;ox=(frame%GCOLS)*GCELL;oy=(frame//GCOLS)*GH
    gd.ellipse((ox+round(x0),oy+round(y0),ox+round(x1),oy+round(y1)),fill=fill,outline=outline,width=width)
def grect(frame,box,fill):
    x0,y0,x1,y1=box;ox=(frame%GCOLS)*GCELL;oy=(frame//GCOLS)*GH
    gd.rectangle((ox+round(x0),oy+round(y0),ox+round(x1),oy+round(y1)),fill=fill)
rng=random.Random(240831)
for f in range(GFRAMES):
    t=(f+1)/GFRAMES;front=105+(1-(1-t)**3)*610;fade=1 if t<.79 else (1-t)/.21
    # Dense compressed vapor remains at the muzzle and is not the damage read.
    for i in range(22):
        u=i/21;x=70+u*(120+f*5);y=192+math.sin(i*.93+f*.72)*(35*(1-u)+8)
        rr=8+(i%5)*3
        gellipse(f,(x-rr,y-rr*.55,x+rr,y+rr*.55),CYAN[1+(i+f)%5],INK if i%6==0 else None,2)
        if i%3==0:gellipse(f,(x-rr*.4,y-rr*.2,x+rr*.35,y+rr*.18),CYAN[5])
    # Three broad, translucent turbulence masses. Their gaps are deliberately
    # staggered and the dark contour is omitted: the eye reads moving air and
    # negative space, never a rib cage, grille, or fishing net.
    ribbon_gaps=(
        ((.02,.31),(.43,.72),(.82,1.0)),
        ((.02,.22),(.32,.58),(.70,1.0)),
        ((.02,.37),(.51,.79),(.89,1.0)),
    )
    for ribbon in range(3):
        side=ribbon-1
        phase=(f*.019+ribbon*.041)%0.055
        for seg,(base0,base1) in enumerate(ribbon_gaps[ribbon]):
            u0=max(.02,base0+phase-.025)
            u1=min(1,base1+phase-.018)
            if u0>=u1 or 82+u0*(front-82)>front-8:continue
            upper=[];lower=[]
            samples=9
            for k in range(samples):
                u=u0+(u1-u0)*k/(samples-1)
                x=82+u*(front-82)
                spread=side*(13+u*70)
                flutter=math.sin(u*13+ribbon*1.73+f*.27)*(4+u*9)
                center=192+spread+flutter
                thick=(19+u*29)*(1-.11*abs(side))
                step=((k+seg+ribbon+f//2)%3-1)*2
                upper.append((x,center-thick/2+step));lower.append((x,center+thick/2-step))
            color=AIR[1+ribbon][:3]+(max(22,round((75+ribbon*18)*fade)),)
            gpoly(f,upper+list(reversed(lower)),color)
            # A sparse stepped glint is confined to one edge, never boxed in.
            if seg==(f//5+ribbon)%3:
                gline(f,upper[2:-2],AIR[3][:3]+(round(145*fade),),3)

    # One dominant leading crescent and one faint echo. Broad curved pieces
    # sell an impulse travelling forward without repeated vertical bars.
    for arc in range(2):
        ax=front-arc*76;radius=72+arc*22+t*38;thickness=18-arc*5
        for piece in range(3):
            a0=-1.04+piece*.72+((f+piece)%3-1)*.012
            a1=a0+.48
            outer=[];inner=[]
            for k in range(5):
                a=a0+(a1-a0)*k/4
                outer.append((ax-math.cos(a)*(20+arc*4),192+math.sin(a)*radius))
                inner.append((ax-math.cos(a)*(20+arc*4)-thickness,192+math.sin(a)*(radius-thickness)))
            color=AIR[3-arc][:3]+(round((190-arc*72)*fade),)
            gpoly(f,outer+list(reversed(inner)),color)
            if arc==0:gline(f,outer,AIR[3][:3]+(round(220*fade),),3)

    # Short speed dashes advance at staggered rates. None connects to another.
    for i in range(34):
        phase=((i*17+f*7)%101)/101
        x=108+phase*max(70,front-122)
        spread=18+phase*112
        y=192+math.sin(i*2.13+f*.29)*spread
        length=9+(i*11)%25
        color=AIR[1+i%3][:3]+(round((90+i%3*25)*fade),)
        gline(f,[(x-length,y+((i+f)%3-1)*2),(x,y)],color,2+(i%2))
    # Detached condensation and leaf flecks accelerate with the pressure front.
    for i in range(44):
        u=((i*37+f*11)%100)/100;x=110+u*max(80,front-120);spread=24+u*112
        y=192+(rng.random()*2-1)*spread
        if i%4==0:
            size=5+(i%3)*2;color=LEAF[1+(i+f)%4]
            gpoly(f,[(x-size,y),(x,y-size*.5),(x+size,y),(x,y+size*.5)],color,INK,2)
        else:
            size=1+(i+f)%3;grect(f,(x-size,y-size,x+size,y+size),CYAN[2+(i+f)%4])

# Eight authored leaf rotations for per-tree debris.
LCELL=64;LFRAMES=8
leaves=Image.new('RGBA',(LCELL*LFRAMES,LCELL),(0,0,0,0));ld=ImageDraw.Draw(leaves)
for f in range(LFRAMES):
    a=f/LFRAMES*math.pi;rx=18*abs(math.cos(a))+3;ry=8+3*math.sin(a*2);cx=cy=32
    pts=[(cx-rx,cy),(cx,cy-ry),(cx+rx,cy),(cx,cy+ry)]
    poly(ld,f,LCELL,pts,LEAF[2+f%3],INK,3)
    line(ld,f,LCELL,[(cx-rx+4,cy),(cx+rx-4,cy)],LEAF[4],2)
    line(ld,f,LCELL,[(cx,cy),(cx-rx*.45,cy-ry*.52)],LEAF[1],2)

OUT.mkdir(parents=True,exist_ok=True)
charge.save(OUT/'smoker-vape-charge-fx-v2.png')
gust.save(OUT/'smoker-vape-pressure-fx-v2.png')
leaves.save(OUT/'smoker-vape-leaves-fx-v2.png')
print(f'WROTE vape pressure v2 charge={charge.size}/{FRAMES}f gust={gust.size}/{GFRAMES}f leaves={leaves.size}')
