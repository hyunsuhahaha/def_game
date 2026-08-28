"""Build the authored native-pixel forest-floor decal atlas."""
from pathlib import Path
import math
import random

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/scenery/forest/forest-floor-decal-atlas-pixel-v1.png"
CELL_W, CELL_H, COLS, ROWS = 128, 96, 5, 2


def clustered_points(seed: int, count: int, rx: int = 52, ry: int = 30):
    rng = random.Random(seed)
    for _ in range(count):
        angle = rng.random() * math.tau
        radius = math.sqrt(rng.random())
        yield round(64 + math.cos(angle) * rx * radius), round(49 + math.sin(angle) * ry * radius), rng


def soil(draw: ImageDraw.ImageDraw):
    dark, edge, mid, warm, light = "#4a381f", "#5d4826", "#70572d", "#806837", "#9a8048"
    draw.polygon([(7,50),(18,33),(38,30),(49,19),(72,24),(88,20),(101,33),(120,42),(113,61),(96,65),(83,77),(61,71),(42,78),(27,66),(11,63)],fill=edge)
    draw.polygon([(19,49),(30,36),(48,35),(58,27),(76,31),(91,28),(103,40),(111,51),(99,60),(84,62),(72,69),(55,64),(40,70),(29,59)],fill=mid)
    draw.polygon([(36,45),(48,37),(64,40),(78,34),(94,43),(90,52),(73,55),(60,61),(44,56)],fill=warm)
    for x,y,rng in clustered_points(3,52,56,34):
        color=rng.choice([dark,mid,warm,light])
        draw.rectangle((x,y,x+rng.choice([1,2,3]),y+rng.choice([1,1,2])),fill=color)
    draw.line([(22,56),(39,58),(52,56)],fill=dark,width=1)
    draw.line([(67,46),(81,44),(95,47)],fill=light,width=1)
    draw.line([(43,35),(55,37),(63,35)],fill=light,width=1)


def leaves(draw: ImageDraw.ImageDraw):
    palettes=[("#46271b","#7c3b22","#b15a2e","#d07836"),("#43301b","#716026","#9c8434","#c0a84d")]
    for x,y,rng in clustered_points(11,68,56,34):
        outline,shadow,mid,light=palettes[rng.randrange(2)]
        angle=rng.randrange(4)
        if angle%2:
            draw.polygon([(x,y-3),(x+3,y),(x,y+4),(x-2,y)],fill=outline)
            draw.polygon([(x,y-2),(x+2,y),(x,y+2)],fill=mid)
            draw.point((x,y-2),fill=light)
        else:
            draw.polygon([(x-4,y),(x,y-2),(x+4,y),(x,y+3)],fill=outline)
            draw.polygon([(x-2,y),(x,y-1),(x+2,y),(x,y+1)],fill=mid)
            draw.point((x-1,y-1),fill=light)


def short_grass(draw: ImageDraw.ImageDraw):
    colors=["#203b18","#31531f","#4c6b29","#68843a","#84994d"]
    for x,y,rng in clustered_points(19,38,56,30):
        base=y+3; height=rng.randrange(4,10)
        dark,mid,light=colors[0],rng.choice(colors[1:4]),colors[4]
        draw.line([(x-3,base),(x-1,base-height+2)],fill=dark,width=2)
        draw.line([(x,base),(x,base-height)],fill=mid,width=2)
        draw.line([(x+3,base),(x+5,base-height+3)],fill=dark,width=2)
        draw.point((x,base-height),fill=light)


def trampled(draw: ImageDraw.ImageDraw):
    colors=["#435026","#5d642e","#77743a","#918044","#b19a5b"]
    draw.polygon([(8,52),(20,34),(43,28),(62,34),(79,25),(103,32),(120,47),(110,65),(88,70),(68,65),(49,74),(27,68),(12,63)],fill=colors[0])
    draw.polygon([(18,49),(31,38),(49,35),(63,40),(80,32),(103,39),(111,49),(101,59),(82,63),(66,57),(48,66),(29,60)],fill=colors[1])
    for x,y,rng in clustered_points(23,46,57,31):
        length=rng.randrange(7,17); slope=rng.choice([-2,-1,1,2])
        draw.line([(x-length//2,y-slope),(x+length//2,y+slope)],fill=colors[0],width=3)
        draw.line([(x-length//2+1,y-slope-1),(x+length//2-2,y+slope-1)],fill=rng.choice(colors[2:]),width=1)


def ferns(draw: ImageDraw.ImageDraw):
    for x,y,rng in clustered_points(31,7,48,24):
        dark,mid,light="#193a23","#356442","#6c9160"
        height=rng.randrange(13,22)
        draw.line([(x,y+9),(x,y-height)],fill=dark,width=2)
        for step in range(3, height, 4):
            width=max(3,9-step//3)
            yy=y+8-step
            draw.line([(x,yy),(x-width,yy-3)],fill=mid,width=2)
            draw.line([(x,yy-1),(x+width,yy-4)],fill=mid,width=2)
            draw.point((x-width,yy-3),fill=light);draw.point((x+width,yy-4),fill=light)


def branches(draw: ImageDraw.ImageDraw):
    for x,y,rng in clustered_points(37,5,45,23):
        length=rng.randrange(20,38); dark,mid,light="#302019","#644226","#987044"
        draw.line([(x-length//2,y+3),(x+length//2,y-3)],fill=dark,width=5)
        draw.line([(x-length//2+2,y+1),(x+length//2-2,y-4)],fill=mid,width=3)
        draw.line([(x-4,y-1),(x+10,y-4)],fill=light,width=1)
        draw.line([(x-8,y+1),(x-15,y-7)],fill=dark,width=3)
        draw.line([(x+9,y-2),(x+16,y+5)],fill=dark,width=3)


def stones(draw: ImageDraw.ImageDraw):
    palette=["#343b33","#4f584b","#6e7661","#909779","#b2b594"]
    for x,y,rng in clustered_points(41,14,52,29):
        rx,ry=rng.randrange(4,10),rng.randrange(3,7)
        draw.polygon([(x-rx,y),(x-rx//2,y-ry),(x+rx//3,y-ry-1),(x+rx,y-1),(x+rx-2,y+ry),(x-rx+2,y+ry)],fill=palette[0])
        draw.polygon([(x-rx+2,y-1),(x-rx//3,y-ry+1),(x+rx//3,y-ry),(x+rx-2,y),(x+rx-3,y+ry-2),(x-rx+3,y+ry-2)],fill=rng.choice(palette[1:4]))
        draw.line([(x-rx//3,y-ry+1),(x+rx//3,y-ry)],fill=palette[4],width=1)


def moss(draw: ImageDraw.ImageDraw):
    colors=["#263a1a","#3d5922","#58722c","#789044","#9baa5a"]
    draw.polygon([(7,50),(19,31),(39,27),(54,18),(73,25),(92,22),(105,35),(121,48),(111,66),(91,69),(76,78),(58,70),(40,77),(23,65),(10,63)],fill=colors[0])
    draw.polygon([(16,49),(28,35),(45,33),(57,25),(72,31),(89,28),(102,39),(111,50),(101,60),(84,62),(73,70),(57,64),(42,69),(27,58)],fill=colors[1])
    for x,y,rng in clustered_points(47,34,55,32):
        r=rng.randrange(2,6)
        draw.ellipse((x-r,y-r//2,x+r,y+r//2+1),fill=colors[0])
        draw.ellipse((x-r+1,y-r//2,x+r-1,y+r//2),fill=rng.choice(colors[1:4]))
        draw.point((x-r//2,y-r//2),fill=colors[4])


def sawdust(draw: ImageDraw.ImageDraw):
    colors=["#674325","#9a6731","#c18a45","#ddb465","#f0cf82"]
    draw.ellipse((25,30,105,72),fill=colors[0])
    draw.ellipse((31,34,99,68),fill=colors[1])
    for x,y,rng in clustered_points(53,105,50,27):
        color=rng.choice(colors[2:])
        if rng.random()<.65: draw.rectangle((x,y,x+rng.randrange(1,4),y+1),fill=color)
        else: draw.line([(x-2,y+2),(x+2,y-2)],fill=color,width=1)
    draw.arc((46,36,83,66),190,348,fill=colors[4],width=2)


def drag_marks(draw: ImageDraw.ImageDraw):
    dark,soil_mid,edge,chip="#392719","#624426","#8a6639","#c49252"
    for offset in (-10,10):
        points=[]
        for x in range(8,122,6): points.append((x,48+offset+round(math.sin(x*.12)*3)))
        draw.line(points,fill=dark,width=5)
        draw.line([(x,y-1) for x,y in points],fill=soil_mid,width=2)
        for x,y in points[::3]: draw.point((x,y-3),fill=edge)
    for x,y,rng in clustered_points(61,26,55,31):
        draw.line([(x-2,y+1),(x+3,y-1)],fill=rng.choice([edge,chip]),width=1)


DRAWERS=[soil,leaves,short_grass,trampled,ferns,branches,stones,moss,sawdust,drag_marks]


def main():
    atlas=Image.new("RGBA",(CELL_W*COLS,CELL_H*ROWS),(0,0,0,0))
    for index,paint in enumerate(DRAWERS):
        cell=Image.new("RGBA",(CELL_W,CELL_H),(0,0,0,0));paint(ImageDraw.Draw(cell))
        atlas.alpha_composite(cell,((index%COLS)*CELL_W,(index//COLS)*CELL_H))
    OUTPUT.parent.mkdir(parents=True,exist_ok=True)
    atlas.save(OUTPUT,optimize=True)
    print(f"FOREST_FLOOR_ASSET_OK {atlas.width}x{atlas.height} decals={len(DRAWERS)}")


if __name__=="__main__": main()
