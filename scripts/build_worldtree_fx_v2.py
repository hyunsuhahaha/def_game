"""Build the world-tree's authored cartoon-pixel combat and emergence FX.

The cells are drawn natively at their delivery resolution.  No low-resolution
source is enlarged and no opaque colour board is baked into either atlas.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import math, random

ROOT=Path(__file__).resolve().parents[1]
ATTACK=ROOT/"assets/fx/worldtree/worldtree-attacks-atlas-v2.png"
EMERGE=ROOT/"assets/fx/worldtree/worldtree-emergence-atlas-v2.png"
PREVIEW=ROOT/"docs/previews/worldtree-fx-v2-contact-sheet.png"
C=384; EW,EH=512,384

BARK=[(24,15,8,255),(43,26,12,255),(68,38,16,255),(94,52,19,255),(124,72,25,255),(158,98,35,255),(193,132,52,255),(224,174,83,255)]
SOIL=[(31,23,14,245),(57,39,20,245),(91,58,25,245),(132,82,31,245),(174,116,48,235),(213,158,78,220)]
LEAF=[(14,35,18,255),(24,60,26,255),(36,88,34,255),(56,119,43,255),(86,151,57,255),(132,184,78,255)]
SAP=[(126,78,18,255),(203,137,35,255),(247,203,76,255),(255,237,151,255)]

def jagged(cx,cy,ang,length,n,seed,bend):
    rng=random.Random(seed); pts=[]
    for i in range(n+1):
        q=i/n; off=(rng.random()-.5)*bend*(1-q*.35) if i not in (0,n) else 0
        pts.append((round(cx+math.cos(ang)*length*q+math.cos(ang+math.pi/2)*off),round(cy+math.sin(ang)*length*q+math.sin(ang+math.pi/2)*off)))
    return pts

def poly_leaf(d,x,y,ang,size,tone=3,alpha=255):
    c,s=math.cos(ang),math.sin(ang)
    def pt(a,b): return (round(x+c*a-s*b),round(y+s*a+c*b))
    d.polygon([pt(0,0),pt(-size*.65,-size*.45),pt(-size,0),pt(-size*.62,size*.46)],fill=(*LEAF[max(0,tone-2)][:3],alpha))
    d.polygon([pt(-1,0),pt(-size*.58,-size*.27),pt(-size*.88,0),pt(-size*.56,.08*size)],fill=(*LEAF[min(5,tone)][:3],alpha))
    d.line([pt(0,0),pt(-size*.84,0)],fill=(*LEAF[min(5,tone+1)][:3],alpha),width=1)

def chip(d,x,y,ang,size,tone=3,alpha=255):
    c,s=math.cos(ang),math.sin(ang)
    def pt(a,b):return(round(x+c*a-s*b),round(y+s*a+c*b))
    d.polygon([pt(-size,0),pt(-size*.3,-size*.35),pt(size,.05*size),pt(.3*size,.36*size)],fill=(*BARK[max(0,tone-2)][:3],alpha))
    d.polygon([pt(-size*.45,-size*.18),pt(-size*.15,-size*.28),pt(size*.72,0),pt(.1*size,.11*size)],fill=(*BARK[min(7,tone+1)][:3],alpha))

def soil_spray(d,cx,cy,amount,spread,rise,seed,progress=1):
    rng=random.Random(seed)
    for i in range(round(amount*progress)):
        x=cx+rng.uniform(-spread,spread); y=cy-rng.uniform(4,rise)*progress
        size=rng.randint(3,9); ang=rng.uniform(-1,1)
        chip(d,x,y,ang,size,2+i%4,round(135+110*progress))

def layered_root(d,pts,width,glow=False):
    d.line(pts,fill=BARK[0],width=width+8,joint="curve")
    d.line(pts,fill=BARK[1],width=width+3,joint="curve")
    d.line(pts,fill=BARK[3],width=width-3,joint="curve")
    d.line([(x,y-2) for x,y in pts],fill=BARK[5],width=max(3,width//3),joint="curve")
    d.line([(x,y-5) for x,y in pts],fill=BARK[7],width=max(1,width//10),joint="curve")
    if glow:d.line([(x+2,y+2) for x,y in pts],fill=SAP[2],width=2,joint="curve")
    for j,(x,y) in enumerate(pts[1:-1:2]):
        d.line((x-5,y+5,x+5,y-2),fill=BARK[2 if j%2 else 6],width=2)

def root_burst(f):
    p=(f+1)/6; im=Image.new("RGBA",(C,C));d=ImageDraw.Draw(im);cx,base=192,320
    for i,a in enumerate((2.72,2.98,3.28,3.55,.18,.43)):
        pts=jagged(cx,base,a,(52+78*p)*(1-(i%3)*.05),7,1100+f*41+i,13)
        d.line(pts,fill=SOIL[0],width=11);d.line(pts,fill=SOIL[4],width=3)
        if i%2==0:d.line(pts[1:],fill=SAP[1],width=1)
    count=1+round(p*5)
    for i in range(count):
        side=i-(count-1)/2; height=(64+182*p)*(1-abs(side)*.065); bx=cx+side*32
        pts=[]
        for n in range(10):
            q=n/9; pts.append((round(bx+math.sin(q*7+i)*14*(1-q)+side*q*5),round(base-height*q)))
        layered_root(d,pts,25-(i%2)*3,i%3==0)
        tip=pts[-1];d.polygon((tip,(tip[0]-11,tip[1]+20),(tip[0]+12,tip[1]+17)),fill=BARK[1])
    soil_spray(d,cx,base,34,145,95,1600+f,p)
    for i in range(round(13*p)):
        a=i*1.73+f*.27;r=32+(i*19)%130;poly_leaf(d,cx+math.cos(a)*r,base-35-math.sin(a)*35,a,8+i%5,3+i%3,220)
    return im

def vine(f):
    p=(f+1)/6;im=Image.new("RGBA",(C,C));d=ImageDraw.Draw(im);end=22+round(340*p);pts=[]
    for x in range(22,end+1,7):
        q=(x-22)/340;pts.append((x,round(192+math.sin(q*9+f*.34)*17+math.sin(q*22)*4)))
    if len(pts)>1:
        layered_root(d,pts,39,True)
        for i,(x,y) in enumerate(pts[2:-1:3]):
            side=-1 if i%2 else 1; ang=math.pi+(side*.62);poly_leaf(d,x-2,y+side*7,ang,15+i%6,3+i%3)
            d.polygon(((x+3,y),(x+12,y-side*14),(x+13,y+side*2)),fill=SAP[2] if i%3==0 else BARK[7])
        tip=pts[-1];d.polygon((tip,(tip[0]-27,tip[1]-18),(tip[0]-19,tip[1]+19)),fill=BARK[0]);d.polygon((tip,(tip[0]-18,tip[1]-9),(tip[0]-15,tip[1]+10)),fill=BARK[7])
        for i in range(f*2):
            x=55+(i*43+f*17)%290;y=125+(i*29)%110
            poly_leaf(d,x,y,-.2,8+i%4,4,160)
    return im

def slam(f):
    p=(f+1)/6;im=Image.new("RGBA",(C,C));d=ImageDraw.Draw(im);cx,cy=192,205
    for i in range(18):
        a=i/18*math.pi*2+.04*f;length=(46+(i%4)*31+105*p)*p
        pts=jagged(cx,cy,a,length,7,2100+f*31+i,13)
        d.line(pts,fill=SOIL[0],width=13-i%3*2);d.line(pts,fill=BARK[3+i%3],width=5);d.line(pts[1:],fill=SAP[1 if i%3 else 2],width=1)
        if p>.45 and i%2==0: poly_leaf(d,*pts[-1],a+math.pi,9+i%5,3+i%3,220)
    # Broken earthen plates, deliberately irregular rather than concentric circles.
    rng=random.Random(2500+f)
    for i in range(round(12+22*p)):
        a=rng.random()*math.pi*2;r=rng.uniform(38,156)*p;x=cx+math.cos(a)*r;y=cy+math.sin(a)*r*.58
        sz=rng.randint(5,13);d.polygon(((x-sz,y),(x-2,y-sz*.45),(x+sz,y-1),(x+3,y+sz*.38)),fill=SOIL[1+i%4]);d.line((x-sz*.6,y-1,x+sz*.4,y-2),fill=SOIL[5],width=1)
    return im

def branch(f):
    p=(f+1)/6;im=Image.new("RGBA",(C,C));d=ImageDraw.Draw(im);cy=182+round(p*27);pts=[]
    for i in range(23):
        q=i/22;pts.append((22+round(340*q),round(cy+math.sin(q*9+f*.27)*10)))
    layered_root(d,pts,46,False)
    for i,(x,y) in enumerate(pts[2:-2:3]):
        side=-1 if i%2 else 1;d.line((x,y,x-12,y+side*35),fill=BARK[1],width=9);d.line((x,y,x-12,y+side*35),fill=BARK[5],width=4)
        for j in range(3):poly_leaf(d,x-12-j*7,y+side*(20+j*8),math.pi-side*.5,13+j*2,3+(i+j)%3)
    for x,side in ((22,-1),(362,1)):
        d.polygon(((x,cy-20),(x+side*21,cy-7),(x+side*15,cy+19),(x,cy+22)),fill=BARK[0])
        for k in range(5):d.line((x,cy-14+k*7,x+side*(10+k%2*5),cy-12+k*7),fill=BARK[7] if k%2 else SAP[2],width=2)
    for i in range(5+f*2):
        x=28+(i*53+f*23)%330;y=45+(i*37)%95;poly_leaf(d,x,y,.8,8+i%6,3+i%3,190)
    return im

def impact(f):
    p=(f+1)/6;im=Image.new("RGBA",(C,C));d=ImageDraw.Draw(im);cx,cy=192,224;extent=105+round(65*p)
    crack=jagged(cx-extent,cy,0,extent*2,18,3100+f,12)
    d.line(crack,fill=SOIL[0],width=18);d.line(crack,fill=SOIL[3],width=7);d.line(crack,fill=SOIL[5],width=2)
    for i in range(15):
        q=i/14;x=cx-extent+2*extent*q;height=(18+86*p)*(1-abs(q-.5)*.65)
        d.polygon(((x-7,cy),(x-3,cy-height),(x+8,cy-height+10),(x+11,cy)),fill=SOIL[1+i%4]);d.line((x-2,cy-height+5,x+5,cy-height+12),fill=SOIL[5],width=2)
    soil_spray(d,cx,cy,44,180,150,3400+f,p)
    for i in range(round(10+20*p)):
        a=i*.89+f*.2;r=38+(i*23)%160
        if i%2:poly_leaf(d,cx+math.cos(a)*r,cy-math.sin(a)*r*.45-35*p,a,8+i%5,3+i%3,220)
        else:chip(d,cx+math.cos(a)*r,cy-math.sin(a)*r*.45-42*p,a,8+i%6,4+i%3,230)
    return im

attack=Image.new("RGBA",(C*6,C*5))
makers=(root_burst,vine,slam,branch,impact)
for row,maker in enumerate(makers):
    for f in range(6):attack.alpha_composite(maker(f),(f*C,row*C))
ATTACK.parent.mkdir(parents=True,exist_ok=True);attack.save(ATTACK)

def emergence(f):
    p=(f+1)/6;im=Image.new("RGBA",(EW,EH));d=ImageDraw.Draw(im);cx,cy=256,306
    for i in range(20):
        a=i/20*math.pi*2+(i%3)*.05;length=(65+(i%5)*38)*p
        pts=jagged(cx,cy,a,length,8,5200+f*37+i,18)
        d.line(pts,fill=SOIL[0],width=17-i%3*2);d.line(pts,fill=SOIL[3],width=6);d.line(pts[1:],fill=SAP[2] if i%4==0 else SOIL[5],width=2)
        if f>=2 and i%3==0:
            tip=pts[-1];root=jagged(tip[0],tip[1],a-math.pi/2,35+f*8,4,5800+i+f,8);layered_root(d,root,14,i%2==0)
    rng=random.Random(6200+f)
    for i in range(round(22+50*p)):
        a=rng.random()*math.pi*2;r=rng.uniform(40,238)*p;x=cx+math.cos(a)*r;y=cy+math.sin(a)*r*.37
        sz=rng.randint(5,14);d.polygon(((x-sz,y+4),(x-2,y-sz*.6),(x+sz,y),(x+3,y+sz*.45)),fill=SOIL[1+i%4]);d.line((x-sz*.4,y-1,x+sz*.45,y-3),fill=SOIL[5],width=1)
    soil_spray(d,cx,cy,70,244,170,6600+f,p)
    for i in range(round(20*p)):
        a=i*1.11+f*.23;r=75+(i*29)%190
        (poly_leaf if i%2 else chip)(d,cx+math.cos(a)*r,cy-30-math.sin(a)*r*.48,a,9+i%7,3+i%3,220)
    return im

em=Image.new("RGBA",(EW*6,EH))
for f in range(6):em.alpha_composite(emergence(f),(f*EW,0))
em.save(EMERGE)

# Contact sheet uses a varied forest-floor checker only for review; atlas alpha remains transparent.
board=Image.new("RGB",(C*6,C*5+EH),(54,79,35));bd=ImageDraw.Draw(board)
for y in range(0,board.height,24):
    for x in range(0,board.width,24):
        if (x//24+y//24)%3==0:bd.rectangle((x,y,x+23,y+23),fill=(58,84,38))
board.paste(attack,(0,0),attack)
em_scaled=em.resize((C*6,round(EH*C/EW)),Image.Resampling.NEAREST)
board.paste(em_scaled,(0,C*5),em_scaled)
PREVIEW.parent.mkdir(parents=True,exist_ok=True);board.save(PREVIEW)
print(ATTACK);print(EMERGE);print(PREVIEW)
