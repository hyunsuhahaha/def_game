from pathlib import Path
from PIL import Image, ImageDraw, ImageOps
import math, random

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"assets/scenery/north_backdrops"
PREVIEW=ROOT/"docs/previews/north-backdrops-v1.png"
W,H=2048,640
RW,RH=2048,256
random.seed(91827)

PALETTES={
    "forest": {"sky":(132,190,181),"far":(75,139,129),"mid":(43,105,85),"near":(26,72,49),"light":(126,167,74),"rock":(102,112,86),"water":(69,145,155)},
    "mangrove":{"sky":(116,190,178),"far":(62,137,119),"mid":(31,101,78),"near":(18,70,51),"light":(100,157,73),"rock":(100,103,72),"water":(44,135,143)},
    "madagascar":{"sky":(193,171,124),"far":(157,112,73),"mid":(116,78,51),"near":(68,55,34),"light":(158,145,63),"rock":(139,103,72),"water":(68,132,137)},
    "island":{"sky":(121,196,201),"far":(57,146,157),"mid":(34,112,112),"near":(22,75,55),"light":(127,177,73),"rock":(123,118,83),"water":(35,141,166)},
}

def mix(a,b,t): return tuple(round(a[i]*(1-t)+b[i]*t) for i in range(3))
def stepped_sky(im,p):
    d=ImageDraw.Draw(im)
    for y in range(H):
        band=(y//8)*8/(H*.72)
        c=mix(mix(p["sky"],(205,224,185),.32),p["far"],min(1,band))
        d.line((0,y,W,y),fill=(*c,255))
    for i in range(95):
        x=(i*193+71)%W;y=18+(i*67)%185
        if i%3==0:d.rectangle((x,y,x+3+(i%4),y+1),fill=(218,232,199,95))

def ridge_points(base,amp,freq,phase,step=16):
    pts=[(0,H)]
    for x in range(0,W+step,step):
        y=base+math.sin(x/freq+phase)*amp+math.sin(x/(freq*.39)+phase*1.7)*amp*.28
        pts.append((x,round(y/2)*2))
    pts.extend(((W,H),(0,H)))
    return pts

def forest_mass(d,base,color,seed,density,tree_scale=1):
    rng=random.Random(seed)
    for i in range(density):
        x=rng.randint(-30,W+30);y=base+rng.randint(-30,95);r=rng.randint(10,24)*tree_scale
        dark=mix(color,(6,20,17),.28);light=mix(color,(177,190,93),.26)
        d.rectangle((x-2,y,x+2,y+r+10),fill=(*dark,255))
        for ox,oy,rr in ((0,-r*.25,r),(r*.58,0,r*.66),(-r*.58,r*.08,r*.72),(0,r*.35,r*.78)):
            box=(round(x+ox-rr),round(y+oy-rr*.55),round(x+ox+rr),round(y+oy+rr*.55))
            d.ellipse(box,fill=(*dark,255))
            d.pieslice(box,190,350,fill=(*color,255))
            if i%3==0:d.rectangle((x+round(ox)-2,y+round(oy)-round(rr*.35),x+round(ox)+3,y+round(oy)-round(rr*.18)),fill=(*light,255))

def draw_river(d,p,kind):
    if kind=="madagascar": return
    points=[];half=[]
    center=W*(.70 if kind=="forest" else (.45 if kind=="mangrove" else .52))
    for y in range(220,H+20,12):
        q=(y-220)/(H-220);x=center+math.sin(y/83)*105*(1-q)+math.sin(y/29)*20
        width=16+q*(110 if kind=="forest" else 180)
        points.append((x-width,y));half.append((x+width,y))
    poly=points+half[::-1]
    d.polygon(poly,fill=(*mix(p["water"],(16,59,68),.22),255))
    d.line([(round((a[0]+b[0])/2),a[1]) for a,b in zip(points,half)],fill=(*mix(p["water"],(210,232,195),.46),210),width=5)
    if kind=="mangrove":
        for shift in (-430,390):
            d.line([(x+shift,y) for x,y in [(round((a[0]+b[0])/2),a[1]) for a,b in zip(points,half)]],fill=(*p["water"],190),width=18)

def baobab(d,x,y,scale,p):
    trunk=mix(p["rock"],(83,48,26),.42);light=mix(trunk,(222,169,87),.34);leaf=p["near"]
    d.polygon(((x-10*scale,y),(x-20*scale,y+44*scale),(x+22*scale,y+44*scale),(x+11*scale,y)),fill=(*trunk,255))
    d.rectangle((x-4*scale,y+4*scale,x+5*scale,y+38*scale),fill=(*light,255))
    for ox,oy,r in ((0,0,22),(-20,4,15),(21,5,16),(0,-8,16)):
        d.ellipse((x+(ox-r)*scale,y+(oy-r*.45)*scale,x+(ox+r)*scale,y+(oy+r*.45)*scale),fill=(*leaf,255))

def panorama(kind):
    p=PALETTES[kind];im=Image.new("RGBA",(W,H),(0,0,0,255));stepped_sky(im,p);d=ImageDraw.Draw(im)
    d.polygon(ridge_points(205,42,255,.7),fill=(*mix(p["far"],p["sky"],.34),255))
    d.line(ridge_points(205,42,255,.7)[1:-2],fill=(*mix(p["far"],(220,224,173),.22),255),width=4)
    d.polygon(ridge_points(285,55,182,2.1),fill=(*p["far"],255))
    draw_river(d,p,kind)
    d.polygon(ridge_points(390,52,132,.2),fill=(*p["mid"],255))
    forest_mass(d,350,p["mid"],300+len(kind),110,1)
    if kind=="madagascar":
        for i in range(18):baobab(d,70+i*116+(i%3)*17,340+(i%4)*23,.62+(i%3)*.12,p)
        d.polygon([(0,500),(W,455),(W,H),(0,H)],fill=(*mix(p["light"],(123,68,37),.35),255))
    elif kind=="island":
        d.rectangle((0,425,W,H),fill=(*p["water"],255))
        for i in range(12):
            x=80+i*173;y=455+(i%3)*36
            d.ellipse((x-70,y-22,x+75,y+24),fill=(*mix(p["light"],(210,184,105),.34),255))
            forest_mass(d,y-20,p["near"],710+i,9,.52)
    else: forest_mass(d,450,p["near"],620+len(kind),150,1.15)
    # Pixel clusters create material depth without blurred noise.
    for i in range(520):
        x=(i*149+31)%W;y=250+(i*83)%365
        c=p["light"] if i%4==0 else mix(p["mid"],p["near"],(i%5)/7)
        d.rectangle((x,y,x+2+(i%5),y+1+(i%3)),fill=(*c,150))
    return im

def boundary_ridge(kind):
    p=PALETTES[kind];im=Image.new("RGBA",(RW,RH),(0,0,0,0));d=ImageDraw.Draw(im);rng=random.Random(4400+len(kind))
    # Irregular undergrowth silhouette; transparent above and below.
    top=[]
    for x in range(0,RW+12,12):top.append((x,150+round((math.sin(x/47)+math.sin(x/19)*.35)*12)))
    d.polygon(top+[(RW,236),(0,236)],fill=(*mix(p["near"],(8,22,17),.22),255))
    for i in range(105):
        x=rng.randint(-20,RW+20);y=rng.randint(128,190);r=rng.randint(12,31)
        dark=mix(p["near"],(5,16,13),.32);mid=mix(p["near"],p["light"],.22)
        d.ellipse((x-r,y-r//2,x+r,y+r//2),fill=(*dark,255))
        d.pieslice((x-r+3,y-r//2+2,x+r-3,y+r//2-2),185,350,fill=(*mid,255))
        if i%4==0:d.rectangle((x-r//3,y-r//3,x+r//5,y-r//3+3),fill=(*p["light"],255))
    x=18
    while x<RW-18:
        x+=rng.randint(48,118)
        if x>=RW-18:break
        y=rng.randint(168,204);r=rng.randint(17,29)
        rock=mix(p["rock"],(45,50,42),.18);hi=mix(p["rock"],(207,198,139),.28)
        d.polygon(((x-r,y+18),(x-r//2,y-r//2),(x+r//3,y-r),(x+r,y+14)),fill=(*mix(rock,(20,25,20),.34),255))
        d.polygon(((x-r//2,y+9),(x-r//3,y-r//3),(x+r//4,y-r+4),(x+r//2,y+6)),fill=(*hi,255))
    # Exposed roots and fallen twigs keep the transition from reading as a tile.
    for _ in range(18):
        x=rng.randint(24,RW-80);y=rng.randint(184,229);length=rng.randint(28,82);bend=rng.randint(-12,12)
        d.line(((x,y),(x+length//2,y+bend),(x+length,y+rng.randint(-5,8))),fill=(*mix(p["near"],(58,36,24),.58),255),width=rng.randint(3,6))
        if rng.random()<.55:
            d.line(((x+length//2,y+bend),(x+length//2+rng.randint(-14,16),y+bend-rng.randint(9,20))),fill=(*mix(p["near"],(91,57,31),.62),255),width=3)
    for i in range(150):
        x=(i*113+17)%RW;y=148+(i*47)%82
        d.rectangle((x,y,x+2+(i%4),y+2),fill=(*mix(p["light"],p["near"],.45),255))
    return im

OUT.mkdir(parents=True,exist_ok=True)
boards=[]
for kind in PALETTES:
    runtime=OUT/f"{kind}-panorama-pixel-v2.png"
    back=Image.open(runtime).convert("RGBA") if runtime.exists() else panorama(kind)
    ridge=boundary_ridge(kind)
    ridge.save(OUT/f"{kind}-ridge-pixel-v1.png")
    back=ImageOps.fit(back,(W,H),method=Image.Resampling.NEAREST,centering=(.5,.5))
    panel=Image.new("RGBA",(W,H+RH),(28,42,24,255));panel.alpha_composite(back);panel.alpha_composite(ridge,(0,H-78));boards.append(panel)
board=Image.new("RGB",(W*2,(H+RH)*2),(28,42,24))
for i,panel in enumerate(boards):board.paste(panel,((i%2)*W,(i//2)*(H+RH)),panel)
PREVIEW.parent.mkdir(parents=True,exist_ok=True);board.resize((W,(H+RH)),Image.Resampling.NEAREST).save(PREVIEW)
print(OUT);print(PREVIEW)
