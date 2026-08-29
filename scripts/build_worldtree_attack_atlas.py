from pathlib import Path
from PIL import Image, ImageDraw
import math, random

ROOT=Path(__file__).resolve().parents[1]
CELL=256
OUT=ROOT/"assets/fx/worldtree/worldtree-attacks-atlas-v1.png"
PREVIEW=ROOT/"docs/previews/worldtree-attacks-v1-display-scale.png"
random.seed(42019)

atlas=Image.new("RGBA",(CELL*6,CELL*5),(0,0,0,0))

BARK_DEEP=(22,14,7,255);BARK_DARK=(37,24,12,255);BARK_SHADOW=(49,29,12,255);BARK_EDGE=(61,37,15,255)
BARK_RED=(79,44,17,255);BARK=(104,61,23,255);BARK_GOLD=(123,72,25,255);BARK_MID=(142,86,30,255)
BARK_WARM=(163,101,36,255);BARK_LIGHT=(190,126,46,255);BARK_PALE=(214,153,64,255)
SAP_DARK=(151,103,31,255);SAP=(221,174,67,255);SAP_LIGHT=(244,207,96,255)
LEAF_DEEP=(16,31,12,255);LEAF_DARK=(25,47,18,255);LEAF_SHADOW=(37,66,24,255)
LEAF=(52,91,31,255);LEAF_MID=(70,112,38,255);LEAF_LIGHT=(91,139,48,255);LEAF_PALE=(126,169,62,255)
SOIL_DEEP=(31,21,10,235);SOIL_DARK=(47,31,13,230);SOIL_SHADOW=(73,46,17,240)
SOIL=(112,72,25,245);SOIL_MID=(143,92,31,245);SOIL_LIGHT=(177,119,44,245);SOIL_PALE=(207,151,61,245)


def jagged_points(cx,cy,angle,length,segments,seed,bend=8):
    rng=random.Random(seed);points=[(cx,cy)]
    for i in range(1,segments+1):
        q=i/segments
        side=(rng.random()-.5)*bend*(1-q*.25)
        points.append((round(cx+math.cos(angle)*length*q+math.cos(angle+math.pi/2)*side),
                       round(cy+math.sin(angle)*length*q+math.sin(angle+math.pi/2)*side*.62)))
    return points


def dirt(draw,p,seed,wide=108,base_y=207):
    rng=random.Random(seed)
    for i in range(round(8+18*p)):
        x=128+rng.randint(-wide,wide);rise=rng.randint(2,round(10+48*p));y=base_y-rise
        size=rng.randint(2,5)
        draw.rectangle((x-size-1,y-size,x+size+1,y+size),fill=SOIL_DARK)
        draw.rectangle((x-size,y-size,x+size,y+size-1),fill=SOIL_LIGHT if i%4==0 else SOIL)


def root_frame(frame):
    p=(frame+1)/6
    im=Image.new("RGBA",(CELL,CELL),(0,0,0,0));d=ImageDraw.Draw(im)
    for i,a in enumerate((2.82,3.20,3.58,.05,.39)):
        pts=jagged_points(128,207,a,(36+70*p)*(1-abs(i-2)*.07),5,frame*31+i,10)
        d.line(pts,fill=SOIL_DEEP,width=6)
        d.line(pts,fill=SOIL_MID if i%2 else SOIL,width=2)
    root_count=1+round(p*4)
    for i in range(root_count):
        side=i-(root_count-1)/2
        height=(38+126*p)*(1-abs(side)*.11)
        base_x=128+side*24
        pts=[]
        for s in range(7):
            q=s/6;x=base_x+math.sin(q*5.4+i*1.7)*11*(1-q)+side*q*7;y=207-height*q
            pts.append((round(x),round(y)))
        d.line(pts,fill=BARK_DEEP,width=22,joint="curve")
        d.line(pts,fill=BARK_SHADOW,width=18,joint="curve")
        d.line(pts,fill=BARK_RED,width=14,joint="curve")
        d.line(pts,fill=BARK if i%2 else BARK_GOLD,width=10,joint="curve")
        d.line([(x-2,y) for x,y in pts],fill=BARK_WARM,width=5,joint="curve")
        d.line([(x-4,y) for x,y in pts[1:]],fill=BARK_PALE,width=2)
        for j,(x,y) in enumerate(pts[1:-1]):
            d.rectangle((x-3,y+j%2-1,x-1,y+j%2),fill=BARK_LIGHT if j%2 else BARK_MID)
        tip=pts[-1]
        d.polygon((tip,(tip[0]-7,tip[1]+15),(tip[0]+8,tip[1]+11)),fill=BARK_DARK)
        d.line((tip,(tip[0]+side*5,tip[1]+13)),fill=SAP_LIGHT if i%2 else SAP,width=2)
    dirt(d,p,900+frame)
    for i in range(32):
        x=48+(i*37+frame*11)%164;y=178+(i*19)%44
        if (i+frame)%3==0:d.point((x,y),fill=(SOIL_PALE[0],SOIL_PALE[1],SOIL_PALE[2],170))
    return im


def vine_frame(frame):
    p=(frame+1)/6
    im=Image.new("RGBA",(CELL,CELL),(0,0,0,0));d=ImageDraw.Draw(im)
    end=18+round(220*p);pts=[]
    for x in range(18,end+1,8):
        q=(x-18)/220;y=128+math.sin(q*8.2+frame*.35)*11+math.sin(q*19)*3
        pts.append((x,round(y)))
    if len(pts)<2:return im
    d.line(pts,fill=LEAF_DEEP,width=44,joint="curve")
    d.line(pts,fill=LEAF_SHADOW,width=38,joint="curve")
    d.line(pts,fill=BARK_DEEP,width=31,joint="curve")
    d.line(pts,fill=BARK_RED,width=25,joint="curve")
    d.line(pts,fill=BARK_GOLD,width=18,joint="curve")
    d.line([(x,y-4) for x,y in pts],fill=BARK_WARM,width=8,joint="curve")
    d.line([(x,y-7) for x,y in pts],fill=BARK_PALE,width=3)
    for i,(x,y) in enumerate(pts[1:-1:2]):
        side=-1 if i%2==0 else 1
        leaf=[(x,y),(x-10,y+side*5),(x-17,y+side*16),(x-2,y+side*12)]
        d.polygon(leaf,fill=LEAF_DEEP);d.polygon([(x-2,y+side*2),(x-9,y+side*6),(x-13,y+side*12)],fill=LEAF_MID if i%2 else LEAF)
        d.line((x,y,x-13,y+side*12),fill=LEAF_PALE if i%3==0 else LEAF_LIGHT,width=2)
        thorn=[(x+3,y),(x+10,y-side*10),(x+8,y+side*2)]
        d.polygon(thorn,fill=SAP_LIGHT if i%3==0 else SAP)
    tip=pts[-1];d.polygon((tip,(tip[0]-18,tip[1]-13),(tip[0]-13,tip[1]+14)),fill=BARK_DARK)
    d.polygon((tip,(tip[0]-13,tip[1]-7),(tip[0]-10,tip[1]+8)),fill=BARK_PALE)
    return im


def slam_frame(frame):
    p=(frame+1)/6
    im=Image.new("RGBA",(CELL,CELL),(0,0,0,0));d=ImageDraw.Draw(im)
    cx,cy=128,134
    for ring in range(3):
        rp=max(0,min(1,p*1.35-ring*.18));rx=(32+ring*30)*rp;ry=(16+ring*18)*rp
        if rx<=0:continue
        pts=[]
        for i in range(33):
            a=i/32*math.pi*2;jag=1+math.sin(i*4.7+frame+ring)*.08
            pts.append((round(cx+math.cos(a)*rx*jag),round(cy+math.sin(a)*ry*jag)))
        d.line(pts,fill=SOIL_DEEP,width=8,joint="curve")
        d.line(pts,fill=BARK_RED if ring%2 else BARK_EDGE,width=5,joint="curve")
        d.line(pts,fill=BARK_PALE if ring==0 else (BARK_WARM if ring==1 else BARK_MID),width=2)
    for i in range(12):
        a=i/12*math.pi*2+.13*frame;length=(42+(i%3)*22)*p
        pts=jagged_points(cx,cy,a,length,4,400+frame*17+i,7)
        d.line(pts,fill=SOIL_SHADOW,width=6);d.line(pts,fill=BARK_LIGHT if i%3==0 else BARK_MID,width=2)
        if p>.45:
            tip=pts[-1];d.polygon((tip,(tip[0]-4,tip[1]-9),(tip[0]+5,tip[1]-7)),fill=SAP_LIGHT if i%2 else SAP_DARK)
    dirt(d,p,1700+frame,112,176)
    for i in range(round(14*p)):
        a=i*.91+frame*.3;r=28+(i*17)%88
        x=round(cx+math.cos(a)*r);y=round(cy+math.sin(a)*r*.52)
        d.rectangle((x-2,y-2,x+2,y+2),fill=LEAF_PALE if i%4==0 else (SOIL_PALE if i%3==0 else SOIL_LIGHT))
    return im


def falling_branch_frame(frame):
    p=(frame+1)/6
    im=Image.new("RGBA",(CELL,CELL),(0,0,0,0));d=ImageDraw.Draw(im)
    # Long, readable branch with stepped bark planes, leafy twigs and a
    # separated fall trail. It is authored horizontally so runtime rotation
    # can align the footprint exactly toward the player.
    cy=120+round(20*p);left,right=15,241
    pts=[]
    for i in range(15):
        q=i/14;x=left+(right-left)*q;y=cy+math.sin(q*8.5+frame*.22)*7
        pts.append((round(x),round(y)))
    d.line(pts,fill=BARK_DEEP,width=34,joint="curve")
    d.line(pts,fill=BARK_SHADOW,width=29,joint="curve")
    d.line(pts,fill=BARK_RED,width=23,joint="curve")
    d.line([(x,y-3) for x,y in pts],fill=BARK_GOLD,width=15,joint="curve")
    d.line([(x,y-7) for x,y in pts],fill=BARK_WARM,width=7,joint="curve")
    d.line([(x,y-9) for x,y in pts],fill=BARK_PALE,width=2)
    for i,(x,y) in enumerate(pts[1:-1]):
        if i%2==0:d.rectangle((x-5,y+5,x+3,y+7),fill=BARK_DARK)
        if i%3==0:d.rectangle((x-3,y-8,x+5,y-6),fill=BARK_LIGHT)
    # Broken pale fibres at the torn ends make the falling object unmistakable.
    for side,x in ((-1,left),(1,right)):
        d.polygon(((x,y:=cy-14),(x+side*13,cy-4),(x+side*9,cy+13),(x,cy+16)),fill=BARK_DEEP)
        for k in range(4):
            yy=cy-9+k*6;d.line((x,yy,x+side*(7+k%2*4),yy+side),fill=SAP_LIGHT if k%2 else BARK_PALE,width=2)
    for i in range(7):
        q=.12+i*.125;x=round(left+(right-left)*q);y=round(cy+math.sin(q*8.5+frame*.22)*7)
        side=-1 if i%2==0 else 1
        d.line((x,y,x-7,y+side*24),fill=BARK_DARK,width=6)
        d.line((x,y,x-7,y+side*24),fill=BARK_WARM,width=3)
        for j in range(3):
            lx=x-7-j*5;ly=y+side*(13+j*5)
            leaf=((lx,ly),(lx-9,ly+side*3),(lx-12,ly+side*10),(lx-1,ly+side*8))
            d.polygon(leaf,fill=LEAF_DEEP);d.polygon(((lx-2,ly),(lx-8,ly+side*4),(lx-8,ly+side*8)),fill=LEAF_LIGHT if (i+j)%3==0 else LEAF_MID)
    # Detached leaves and vertical speed streaks intensify across frames.
    for i in range(4+frame*2):
        x=25+(i*47+frame*19)%208;y=26+(i*31+frame*7)%68
        d.line((x,y,x-3,y+10+frame*2),fill=(LEAF_PALE[0],LEAF_PALE[1],LEAF_PALE[2],190),width=2)
        d.rectangle((x-4,y+12+frame*2,x+1,y+16+frame*2),fill=LEAF_MID)
    return im


def branch_impact_frame(frame):
    p=(frame+1)/6
    im=Image.new("RGBA",(CELL,CELL),(0,0,0,0));d=ImageDraw.Draw(im)
    cx,cy=128,146
    # Exact long landing footprint, first as a pulsing split in the soil and
    # then as an authored burst of earth, splinters and leaves.
    extent=70+round(46*p)
    crack=jagged_points(cx-extent,cy,0,extent*2,12,5100+frame,7)
    d.line(crack,fill=SOIL_DEEP,width=10)
    d.line(crack,fill=SOIL_MID,width=4)
    d.line(crack,fill=SOIL_PALE,width=2)
    for i in range(10):
        q=i/9;x=round(cx-extent+extent*2*q);height=round((12+55*p)*(1-abs(q-.5)*.8))
        d.polygon(((x,cy-2),(x-5,cy-height),(x+6,cy-height+6)),fill=SOIL_DARK)
        d.polygon(((x,cy-4),(x-2,cy-height+7),(x+3,cy-height+10)),fill=SOIL_LIGHT if i%3 else SOIL_PALE)
    for i in range(round(8+18*p)):
        a=(i*.83+frame*.31);r=32+(i*17)%94
        x=round(cx+math.cos(a)*r);y=round(cy+math.sin(a)*r*.34-18*p)
        color=LEAF_PALE if i%5==0 else (BARK_PALE if i%3==0 else SOIL_LIGHT)
        d.rectangle((x-3,y-3,x+3,y+3),fill=color)
    return im


for frame in range(6):
    atlas.alpha_composite(root_frame(frame),(frame*CELL,0))
    atlas.alpha_composite(vine_frame(frame),(frame*CELL,CELL))
    atlas.alpha_composite(slam_frame(frame),(frame*CELL,CELL*2))
    atlas.alpha_composite(falling_branch_frame(frame),(frame*CELL,CELL*3))
    atlas.alpha_composite(branch_impact_frame(frame),(frame*CELL,CELL*4))

OUT.parent.mkdir(parents=True,exist_ok=True);atlas.save(OUT)

board=Image.new("RGBA",(CELL*6,CELL*5),(44,66,28,255))
for y in range(0,board.height,32):
    ImageDraw.Draw(board).line((0,y,board.width,y),fill=(55,78,34,255),width=1)
board.alpha_composite(atlas)
PREVIEW.parent.mkdir(parents=True,exist_ok=True);board.convert("RGB").save(PREVIEW)
print(OUT)
print(PREVIEW)
