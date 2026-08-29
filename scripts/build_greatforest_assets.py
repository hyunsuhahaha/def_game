"""Build authored native-pixel assets for the Great Forest operation."""
from pathlib import Path
import math
import random

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
TREE_DIR = ROOT / "assets/trees"
MAP_DIR = ROOT / "assets/maps"
PREVIEW = ROOT / "docs/previews/greatforest-assets-v1-2x.png"
FLOOR_OUT = ROOT / "assets/scenery/biomes/greatforest-floor-decal-atlas-pixel-v1.png"


def ellipse_cluster(draw, x, y, rx, ry, seed, palette):
    rng = random.Random(seed)
    draw.ellipse((x-rx, y-ry, x+rx, y+ry), fill=palette[0])
    for i in range(18):
        a, r = rng.random()*math.tau, math.sqrt(rng.random())
        cx, cy = x+math.cos(a)*rx*.72*r, y+math.sin(a)*ry*.68*r
        rr = rng.randrange(7, 15)
        color = palette[1 + (i*7 + seed) % (len(palette)-1)]
        draw.ellipse((round(cx-rr), round(cy-rr*.7), round(cx+rr), round(cy+rr*.7)), fill=color)
        if i % 4 == 0:
            draw.line((round(cx-rr*.45), round(cy-rr*.2), round(cx+rr*.25), round(cy-rr*.43)), fill=palette[-1], width=2)
    # Authored leaf-scale breakup: paired pixels follow the crown volume and
    # preserve stepped highlights instead of filling it with arbitrary noise.
    for i in range(46):
        a,r=rng.random()*math.tau,math.sqrt(rng.random())*.82
        px,py=round(x+math.cos(a)*rx*r),round(y+math.sin(a)*ry*r)
        if i%3==0:
            draw.line((px-2,py+1,px+2,py-1),fill=palette[-1],width=1)
            draw.point((px-1,py-1),fill=palette[-2])
        else:
            draw.rectangle((px,py,px+1,py+1),fill=palette[1+(i%3)])


def bark(draw, box, seed, palette, moss=False):
    x0,y0,x1,y1=box; rng=random.Random(seed)
    draw.polygon(((x0+8,y0),(x1-7,y0),(x1,y1-17),(x1-14,y1-7),((x0+x1)//2,y1),(x0+12,y1-6),(x0,y1-17)),fill=palette[0])
    draw.polygon(((x0+15,y0+2),(x1-13,y0+2),(x1-20,y1-15),((x0+x1)//2+2,y1-8),(x0+16,y1-16)),fill=palette[1])
    for i in range(22):
        x=rng.randrange(x0+8,x1-7); top=rng.randrange(y0+7,y0+34); bottom=rng.randrange(y1-42,y1-10)
        color=palette[2+i%2]
        draw.line((x,top,x+rng.randrange(-4,5),bottom),fill=color,width=2 if i%3 else 3)
        if i%4==0: draw.point((x+1,top+8),fill=palette[-1])
    for dx in (-22,-12,14,25):
        bx=(x0+x1)//2+dx; draw.polygon(((bx,y1-30),(bx-18,y1-5),(bx-30,y1),(bx-5,y1-2),(bx+5,y1-27)),fill=palette[0])
        draw.line((bx-3,y1-27,bx-15,y1-5),fill=palette[2],width=2)
    if moss:
        for i in range(18):
            x=rng.randrange(x0+5,x1-4); y=rng.randrange(y0+20,y1-12)
            if i%2==0: draw.rectangle((x,y,x+rng.randrange(2,6),y+rng.randrange(3,9)),fill=(76,105,47,255))
            else: draw.point((x,y),fill=(142,151,72,255))


def cedar():
    im=Image.new("RGBA",(224,360));d=ImageDraw.Draw(im)
    bark(d,(84,136,140,349),701,((43,27,20,255),(89,53,31,255),(121,72,39,255),(63,38,27,255),(181,119,61,255)),True)
    foliage=((13,31,24,255),(20,47,33,255),(24,56,39,255),(34,76,47,255),(49,96,54,255),(63,107,58,255),(77,117,62,255),(129,151,75,255))
    for i,(x,y,rx,ry) in enumerate(((112,54,55,42),(76,94,48,35),(147,101,50,38),(108,132,69,43),(61,145,43,32),(165,151,43,31))):
        ellipse_cluster(d,x,y,rx,ry,720+i,foliage)
    for x,y in ((71,72),(151,74),(49,132),(183,130)):
        d.line((112,154,x,y),fill=(48,31,22,255),width=7);d.line((111,153,x+2,y+2),fill=(119,72,38,255),width=3)
    d.line((62,122,58,160),fill=(86,130,74,255),width=2);d.point((58,141),fill=(157,171,88,255))
    return im


def hemlock():
    im=Image.new("RGBA",(208,350));d=ImageDraw.Draw(im)
    bark(d,(83,145,129,340),811,((38,27,23,255),(73,51,38,255),(113,77,51,255),(54,39,32,255),(174,128,76,255)),True)
    dark,mid,green,light=(10,28,27,255),(18,49,40,255),(30,72,51,255),(92,126,71,255)
    needle=((23,59,45,255),(36,80,54,255),(54,94,59,255),(116,139,78,255))
    d.polygon(((104,7),(84,45),(94,43),(65,88),(78,84),(40,138),(63,130),(25,192),(80,173),(78,216),(130,216),(128,174),(183,192),(146,132),(166,140),(129,84),(142,89),(113,43),(124,46)),fill=dark)
    layers=((104,19,30),(102,55,47),(100,93,66),(99,133,82),(100,174,94))
    for i,(cx,y,half) in enumerate(layers):
        d.polygon(((cx,y-15),(cx-half,y+35),(cx-7,y+27),(cx-half-8,y+43),(cx+2,y+32),(cx+half+7,y+43),(cx+9,y+26),(cx+half,y+35)),fill=mid)
        d.line((cx-4,y-8,cx-half+10,y+30),fill=green,width=4);d.line((cx+3,y-7,cx+half-9,y+29),fill=green,width=4)
        for dx in range(-half+11,half-8,12): d.point((cx+dx,y+28-abs(dx)//5),fill=light)
        for dx in range(-half+8,half-6,7):
            yy=y+30-abs(dx)//5+(dx%3)
            d.line((cx+dx-3,yy,cx+dx+3,yy-2),fill=needle[(dx//7+i)%len(needle)],width=1)
    for x,y,c in ((72,113,(68,105,65,255)),(132,82,(133,151,86,255)),(48,167,(42,88,58,255)),(151,152,(78,113,68,255))):
        d.line((x-3,y+1,x+4,y-1),fill=c,width=1)
    return im


def moss_oak():
    im=Image.new("RGBA",(252,330));d=ImageDraw.Draw(im)
    bark(d,(92,122,162,321),921,((47,31,22,255),(91,61,37,255),(132,91,49,255),(64,45,31,255),(191,145,75,255)),True)
    foliage=((18,37,23,255),(29,52,28,255),(39,67,34,255),(59,88,43,255),(72,99,47,255),(82,108,50,255),(112,133,61,255),(168,168,81,255))
    for i,(x,y,rx,ry) in enumerate(((62,84,51,42),(104,55,58,45),(157,62,61,47),(201,94,43,38),(118,104,73,49),(171,117,58,42))):
        ellipse_cluster(d,x,y,rx,ry,940+i,foliage)
    d.line((125,154,65,87),fill=(55,38,28,255),width=9);d.line((132,151,194,92),fill=(55,38,28,255),width=9)
    for x in (54,74,172,192):
        d.line((x,96,x-3,178),fill=(50,78,38,255),width=3)
        for y in range(112,174,14): d.rectangle((x-5,y,x+3,y+4),fill=(97,126,53,255))
    d.point((61,132),fill=(186,181,94,255));d.line((181,126,177,150),fill=(126,149,70,255),width=2)
    return im


def map_preview(trees):
    im=Image.new("RGBA",(384,216),(39,68,34,255));d=ImageDraw.Draw(im)
    for y in range(216):
        band=(y//12)%3;d.rectangle((0,y,383,y),fill=((39+band*3,68+band*4,34+band*2,255)))
    rng=random.Random(1267)
    for _ in range(170):
        x,y=rng.randrange(384),rng.randrange(216);c=rng.choice(((66,91,43,255),(87,104,49,255),(103,91,46,255),(46,78,39,255)))
        d.rectangle((x,y,x+rng.randrange(1,4),y+rng.randrange(1,3)),fill=c)
    d.polygon(((160,0),(212,0),(204,42),(220,84),(209,130),(233,216),(139,216),(169,145),(156,96),(174,51)),fill=(91,70,43,255))
    d.line((184,0,179,216),fill=(145,111,62,255),width=3)
    placements=((trees[1],58,156,.32),(trees[0],120,174,.31),(trees[2],288,178,.31),(trees[1],347,151,.25),(trees[0],222,118,.20),(trees[2],24,108,.19))
    for tree,x,y,s in placements:
        w,h=round(tree.width*s),round(tree.height*s);small=tree.resize((w,h),Image.Resampling.NEAREST);im.alpha_composite(small,(round(x-w/2),round(y-h*.96)))
    return im


def floor_atlas():
    atlas=Image.new("RGBA",(640,192)); rng=random.Random(4401)
    palettes=((31,52,28,255),(50,75,36,255),(71,91,43,255),(105,116,57,255),(148,137,72,255))
    for index in range(10):
        cell=Image.new("RGBA",(128,96));d=ImageDraw.Draw(cell)
        if index in (0,1,2):
            pts=((8,54),(20,32),(43,27),(60,18),(83,25),(111,31),(121,52),(106,68),(79,73),(54,68),(30,78),(12,65))
            d.polygon(pts,fill=palettes[index]);d.polygon(tuple((64+(x-64)*.78,49+(y-49)*.67) for x,y in pts),fill=palettes[index+1])
        if index==0: # root mat
            for off in (-24,-8,10,28): d.arc((12+off,20,113+off,82),185,340,fill=(74,48,31,255),width=5);d.arc((14+off,22,111+off,79),190,333,fill=(132,86,46,255),width=2)
        elif index==1: # hemlock needles
            for _ in range(62):
                x,y=rng.randrange(9,119),rng.randrange(26,75);d.line((x,y,x+rng.randrange(5,13),y+rng.randrange(-3,4)),fill=rng.choice(((58,61,35,255),(95,86,43,255),(136,111,52,255))),width=1)
        elif index==2: # moss
            for _ in range(35):
                x,y=rng.randrange(10,118),rng.randrange(24,75);r=rng.randrange(2,6);d.ellipse((x-r,y-r//2,x+r,y+r//2),fill=rng.choice(palettes[1:4]))
        elif index==3: # mushroom ring
            for a in range(0,360,30):
                x=64+round(math.cos(math.radians(a))*42);y=50+round(math.sin(math.radians(a))*22);d.rectangle((x-1,y,x+1,y+7),fill=(180,155,99,255));d.ellipse((x-6,y-3,x+6,y+3),fill=(104,58,39,255));d.line((x-4,y-2,x+2,y-3),fill=(194,112,65,255),width=2)
        elif index==4: # bark slabs
            for _ in range(12):
                x,y=rng.randrange(12,112),rng.randrange(23,73);d.polygon(((x-10,y-3),(x+8,y-6),(x+12,y+3),(x-7,y+7)),fill=(48,32,25,255));d.line((x-6,y-2,x+7,y-4),fill=(126,79,44,255),width=2)
        elif index==5: # lichen stones
            for _ in range(14):
                x,y=rng.randrange(12,116),rng.randrange(25,74);rx,ry=rng.randrange(4,10),rng.randrange(3,7);d.ellipse((x-rx,y-ry,x+rx,y+ry),fill=(63,69,59,255));d.arc((x-rx+1,y-ry+1,x+rx-1,y+ry-1),190,320,fill=(149,154,105,255),width=2)
        elif index==6: # nurse log
            d.polygon(((8,57),(17,43),(108,35),(122,46),(113,61),(23,69)),fill=(43,29,23,255));d.polygon(((14,53),(23,45),(107,39),(115,46),(107,54),(24,63)),fill=(98,67,39,255));d.line((27,47,103,41),fill=(150,105,56,255),width=2)
            for x in range(31,108,14): d.ellipse((x,43,x+8,49),fill=(72,109,50,255));d.point((x+3,43),fill=(158,165,78,255))
        elif index==7: # fern bed
            for x in range(18,118,18):
                d.line((x,71,x+rng.randrange(-5,6),28),fill=(33,65,36,255),width=2)
                for y in range(35,68,7): d.line((x,y,x-8,y-5),fill=(76,112,52,255),width=2);d.line((x,y+2,x+8,y-4),fill=(55,91,44,255),width=2)
        elif index==8: # pale sawdust
            for _ in range(120):
                x,y=rng.randrange(8,121),rng.randrange(29,72);d.point((x,y),fill=rng.choice(((139,91,47,255),(181,129,64,255),(219,171,91,255),(238,202,126,255))))
        else: # dragged root track
            for off in (-11,10):
                pts=[(x,49+off+round(math.sin(x*.11)*3)) for x in range(5,124,5)];d.line(pts,fill=(41,30,24,255),width=7);d.line([(x,y-2) for x,y in pts],fill=(111,72,40,255),width=2)
        atlas.alpha_composite(cell,((index%5)*128,(index//5)*96))
    return atlas


def stepped_material_finish(image):
    """Add restrained 2px ordered dithering inside existing material ramps."""
    out=image.copy();src=image.load();dst=out.load();levels=(-4,-2,2,4)
    for y in range(image.height):
        for x in range(image.width):
            r,g,b,a=src[x,y]
            if not a or max(r,g,b)<28: continue
            # Two-pixel clusters read as pixel texture at game scale; the
            # vertical term keeps crown/trunk lighting directional.
            pattern=((x//2)+(y//2)*3+(0 if y<image.height*.48 else 1))%7
            if pattern not in (0,4): continue
            index=((x//5)+(y//7))%4
            delta=levels[index]
            dst[x,y]=(max(0,min(255,r+delta)),max(0,min(255,g+delta)),max(0,min(255,b+delta)),a)
    return out


def main():
    TREE_DIR.mkdir(parents=True,exist_ok=True);MAP_DIR.mkdir(parents=True,exist_ok=True);PREVIEW.parent.mkdir(parents=True,exist_ok=True)
    trees=tuple(stepped_material_finish(tree) for tree in (cedar(),hemlock(),moss_oak()))
    names=("giantcedar","ancienthemlock","mossoak")
    for name,tree in zip(names,trees): tree.save(TREE_DIR/f"{name}-tree-pixel-v1.png",optimize=True)
    preview=map_preview(trees);preview.save(MAP_DIR/"greatforest-preview-v1.png",optimize=True)
    FLOOR_OUT.parent.mkdir(parents=True,exist_ok=True);floor_atlas().save(FLOOR_OUT,optimize=True)
    board=Image.new("RGBA",(780,720),(35,50,29,255))
    for i,tree in enumerate(trees): board.alpha_composite(tree.resize((tree.width*2,tree.height*2),Image.Resampling.NEAREST),(i*250+(250-tree.width*2)//2,0))
    board.save(PREVIEW,optimize=True)
    print("GREAT_FOREST_ASSETS_OK trees=3 preview=384x216 hard_alpha=true")


if __name__=="__main__": main()
