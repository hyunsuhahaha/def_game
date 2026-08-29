"""Build the fixed colossal world-tree atlas from the approved v3 source.

The ImageGen source locks identity only.  Damage states, anchors, hard alpha,
palette and coherent leaf motion are authored deterministically here.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np
from collections import Counter

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'assets/enemies/concepts/worldtree-siege-cartoon-source-v4.png'
OUT=ROOT/'assets/enemies/arcade/worldtree-siege-atlas-v1.png'
DEBRIS_OUT=ROOT/'assets/fx/worldtree-siege-debris-atlas-v1.png'
PREVIEW=ROOT/'docs/previews/worldtree-siege-damage-states-v1.png'
CELL,FOOT=1024,992

def hard_source():
    src=Image.open(SOURCE).convert('RGBA')
    arr=np.asarray(src)
    # v4 uses an explicit magenta production key so no generated halo can
    # survive between canopy clumps or roots.
    key=(arr[:,:,0]>205)&(arr[:,:,1]<95)&(arr[:,:,2]>175)
    mask=Image.fromarray(np.where(~key,255,0).astype('uint8'))
    bbox=mask.getbbox(); assert bbox
    src=src.crop(bbox); mask=mask.crop(bbox)
    scale=min(760/src.width,960/src.height)
    size=(round(src.width*scale),round(src.height*scale))
    src=src.resize(size,Image.Resampling.NEAREST)
    mask=mask.resize(size,Image.Resampling.NEAREST)
    src.putalpha(mask)
    frame=Image.new('RGBA',(CELL,CELL))
    frame.alpha_composite(src,((CELL-size[0])//2,FOOT-size[1]))
    return frame

def erase(frame,polygons):
    a=frame.getchannel('A'); d=ImageDraw.Draw(a)
    for poly in polygons:d.polygon(poly,fill=0)
    frame.putalpha(a)

def broken_wood(frame,poly,inner):
    d=ImageDraw.Draw(frame)
    d.polygon(poly,fill=(51,35,21,255))
    d.polygon(inner,fill=(218,151,70,255))
    # Coarse stepped grain, not a smooth vector surface.
    x0=min(x for x,_ in inner);x1=max(x for x,_ in inner)
    y0=min(y for _,y in inner);y1=max(y for _,y in inner)
    for x in range(x0+5,x1,11):
        d.line((x,y0+5,x-3,y1-5),fill=(126,76,37,255),width=3)

def crack(frame,points,width=6):
    d=ImageDraw.Draw(frame)
    d.line(points,fill=(55,37,23,255),width=width)
    if width>4:d.line([(x+2,y) for x,y in points],fill=(111,65,32,255),width=2)

def damage(base,stage):
    f=base.copy()
    if stage>=1:
        erase(f,[[(185,100),(300,70),(337,105),(315,185),(246,205),(180,167)],
                 [(727,169),(849,156),(879,228),(824,303),(738,282)]])
        crack(f,[(490,694),(474,728),(486,758),(463,800)],5)
    if stage>=2:
        erase(f,[[(178,392),(352,390),(438,483),(407,610),(296,647),(176,581)],
                 [(304,48),(408,30),(432,112),(394,181),(302,168)]])
        broken_wood(f,[(382,493),(432,475),(450,516),(410,552),(373,534)],
                      [(389,500),(426,490),(438,516),(407,540),(383,529)])
        crack(f,[(548,594),(568,635),(551,674),(579,718),(562,760)],7)
    if stage>=3:
        erase(f,[[(621,388),(793,367),(881,432),(870,561),(760,624),(650,576)],
                 [(480,23),(615,18),(664,91),(626,176),(511,158)],
                 [(684,102),(806,84),(873,128),(858,205),(748,226)]])
        broken_wood(f,[(618,479),(666,468),(693,508),(667,551),(622,536)],
                      [(627,487),(661,480),(681,507),(660,538),(631,527)])
        # Widen the existing chop wound with a natural jagged raw-wood face.
        broken_wood(f,[(438,799),(494,774),(525,811),(511,894),(455,917),(421,875)],
                      [(446,808),(489,791),(511,816),(497,881),(457,901),(435,870)])
        crack(f,[(506,662),(493,713),(515,750),(498,798)],8)
    return f

def leaf_motion(frame,phase):
    if phase==0:return frame
    # Move only the upper crown one native pixel, keeping trunk and foot fixed.
    crown=frame.crop((100,0,924,360))
    a=crown.getchannel('A')
    shifted=Image.new('RGBA',frame.size)
    shifted.alpha_composite(crown,(100+phase,0))
    out=frame.copy()
    clear=Image.new('L',frame.size);clear.paste(a,(100,0))
    oa=out.getchannel('A');oa=np.asarray(oa).copy();cm=np.asarray(clear)>0;oa[cm]=0
    out.putalpha(Image.fromarray(oa.astype('uint8')))
    out.alpha_composite(shifted)
    return out

def approved_palette():
    counts=Counter()
    for name in ('broadleaf-tree-cartoon-v3.png','maple-tree-cartoon-v3.png','pine-tree-cartoon-v3.png'):
        im=np.asarray(Image.open(ROOT/'assets/trees'/name).convert('RGBA'))
        for color in map(tuple,im[:,:,:3][im[:,:,3]>0]):counts[color]+=1
    colors=[c for c,_ in counts.most_common(180)]
    green=[c for c in colors if c[1]>c[0]*.88 and c[1]>c[2]*1.12]
    bark=[c for c in colors if c[0]>c[1]*1.03 and c[0]>c[2]*1.14]
    dark=[c for c in colors if sum(map(int,c))<185]
    assert len(green)>=24 and len(bark)>=24 and len(dark)>=8
    # Never let yellow-green foliage choose a nearby orange maple color.
    return {"green":np.asarray(green[:64],dtype=np.int16),
            "bark":np.asarray(bark[:56],dtype=np.int16),
            "dark":np.asarray(dark[:24],dtype=np.int16)}

PALETTE=None
def quantize(frame):
    global PALETTE
    if PALETTE is None:PALETTE=approved_palette()
    # The concept contains sub-pixel-like 1 px chatter at this 1024 grid.
    # Coarsen to deliberate 2 px clusters before mapping to the exact v3 tree
    # palette; output remains 1024 and retains far more detail than small trees.
    frame=frame.resize((CELL//2,CELL//2),Image.Resampling.NEAREST).resize((CELL,CELL),Image.Resampling.NEAREST)
    arr=np.asarray(frame).copy();mask=arr[:,:,3]>=128
    pixels=arr[:,:,:3][mask].astype(np.int16)
    mapped=np.empty_like(pixels)
    for start in range(0,len(pixels),30000):
        chunk=pixels[start:start+30000]
        lum=chunk.sum(axis=1)
        green=(chunk[:,1]>chunk[:,0]*.88)&(chunk[:,1]>chunk[:,2]*1.12)&(lum>=150)
        dark=lum<150
        bark=~green&~dark
        result=np.empty_like(chunk)
        for selection,key in ((green,"green"),(bark,"bark"),(dark,"dark")):
            if not selection.any():continue
            part=chunk[selection];palette=PALETTE[key]
            distance=((part[:,None,:]-palette[None,:,:])**2).sum(axis=2)
            result[selection]=palette[distance.argmin(axis=1)]
        mapped[start:start+len(chunk)]=result
    arr[:,:,:3][mask]=mapped;arr[:,:,3]=np.where(mask,255,0)
    return Image.fromarray(arr.astype('uint8'),'RGBA')

def debris_atlas():
    cell=96; atlas=Image.new('RGBA',(cell*8,cell))
    leaf_ramps=[((30,48,24,255),(75,112,35,255),(151,174,50,255),(211,205,77,255)),
                ((38,55,25,255),(92,128,42,255),(172,181,56,255),(225,211,91,255))]
    for i in range(4):
        f=Image.new('RGBA',(cell,cell));d=ImageDraw.Draw(f);dark,mid,light,shine=leaf_ramps[i%2]
        cx,cy=48,52; pts=[(cx-25,cy),(cx-10,cy-19),(cx+18,cy-14),(cx+27,cy+2),(cx+8,cy+18),(cx-18,cy+13)]
        d.polygon(pts,fill=dark);d.polygon([(cx-18,cy-2),(cx-7,cy-14),(cx+16,cy-10),(cx+20,cy),(cx+4,cy+11),(cx-13,cy+8)],fill=mid)
        d.polygon([(cx-9,cy-6),(cx+9,cy-8),(cx+15,cy-1),(cx+1,cy+3)],fill=light);d.rectangle((cx+3,cy-7,cx+10,cy-4),fill=shine)
        d.line((cx-22,cy+10,cx+23,cy-9),fill=(93,66,30,255),width=4)
        atlas.alpha_composite(f,(i*cell,0))
    for i in range(4,8):
        f=Image.new('RGBA',(cell,cell));d=ImageDraw.Draw(f)
        y=48+(i%2)*4
        d.polygon([(10,y-13),(72,y-19),(87,y-6),(80,y+13),(18,y+18),(7,y+5)],fill=(48,31,20,255))
        d.polygon([(15,y-8),(69,y-13),(80,y-5),(75,y+7),(20,y+12),(13,y+4)],fill=(114,66,32,255))
        d.line((21,y-5,70,y-9),fill=(205,137,61,255),width=5);d.line((24,y+4,67,y),fill=(75,45,27,255),width=4)
        d.polygon([(79,y-8),(89,y-4),(87,y+7),(78,y+11)],fill=(224,157,72,255))
        atlas.alpha_composite(f,(i*cell,0))
    return atlas

def main():
    SOURCE.parent.mkdir(parents=True,exist_ok=True);OUT.parent.mkdir(parents=True,exist_ok=True);DEBRIS_OUT.parent.mkdir(parents=True,exist_ok=True);PREVIEW.parent.mkdir(parents=True,exist_ok=True)
    base=hard_source(); atlas=Image.new('RGBA',(CELL*6,CELL*2)); frames=[]
    for stage in range(4):
        damaged=damage(base,stage)
        for phase in (-1,0,1):
            frames.append(quantize(leaf_motion(damaged,phase)))
    for i,frame in enumerate(frames):atlas.alpha_composite(frame,((i%6)*CELL,(i//6)*CELL))
    atlas.save(OUT,optimize=True)
    debris_atlas().save(DEBRIS_OUT,optimize=True)
    board=Image.new('RGB',(1280,470),(48,57,35))
    for stage in range(4):
        thumb=frames[stage*3+1].resize((300,300),Image.Resampling.NEAREST)
        board.paste(thumb,(10+stage*315,14),thumb)
    board.save(PREVIEW)
    opaque=np.asarray(atlas)[:,:,3]>0
    colors=len({tuple(v) for v in np.asarray(atlas)[:,:,:3][opaque]})
    print(f'WORLDTREE_SIEGE_BUILD_OK atlas={atlas.size[0]}x{atlas.size[1]} cell={CELL} stages=4 frames=12 colors={colors}')

if __name__=='__main__':main()
