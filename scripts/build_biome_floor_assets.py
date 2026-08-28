"""Build four biome-specific native-pixel ground-decal atlases."""
from pathlib import Path
import math
import random

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets/scenery/biomes"
PREVIEW = ROOT / "docs/previews/biome-floor-atlases-v1-2x.png"
CW, CH, COLS = 128, 96, 5


def points(seed, count, rx=54, ry=31):
    rng = random.Random(seed)
    for _ in range(count):
        a, r = rng.random() * math.tau, math.sqrt(rng.random())
        yield round(64 + math.cos(a) * rx * r), round(49 + math.sin(a) * ry * r), rng


def patch(draw, colors, seed, wet=False):
    outline, mid, warm, light = colors
    outer=[(7,52),(16,35),(34,29),(48,19),(69,24),(86,19),(104,31),(121,47),(113,65),(94,69),(79,77),(59,70),(42,77),(24,66),(10,63)]
    inner=[(17,50),(28,38),(45,34),(58,27),(74,31),(91,27),(106,40),(112,51),(100,61),(83,63),(70,69),(54,64),(39,69),(25,59)]
    draw.polygon(outer,fill=outline);draw.polygon(inner,fill=mid)
    for x,y,rng in points(seed,58,56,33):
        color=rng.choice([mid,warm,warm,light]);w=rng.choice([1,2,3])
        draw.rectangle((x,y,x+w,y+rng.choice([1,1,2])),fill=color)
    if wet:
        draw.line([(24,43),(39,40),(55,42)],fill=light,width=1)
        draw.line([(69,58),(87,55),(102,56)],fill=light,width=1)


def beginner_cells():
    def meadow(d): patch(d,("#40562a","#61743a","#7f8e48","#a5ad65"),101)
    def clover(d):
        for x,y,r in points(102,25):
            dark,mid,hi="#29451f","#52753a","#82a052"
            for dx,dy in ((-3,-1),(3,-1),(0,3)):
                d.ellipse((x+dx-3,y+dy-2,x+dx+3,y+dy+2),fill=dark);d.rectangle((x+dx-1,y+dy-1,x+dx+2,y+dy+1),fill=mid)
            d.point((x-1,y-2),fill=hi)
    def trimmed(d):
        for x,y,r in points(103,34):
            h=r.randrange(5,12);d.line((x,y+5,x-2,y-h),fill="#29451e",width=2);d.line((x+2,y+5,x+3,y-h+2),fill="#5f813e",width=2);d.point((x+3,y-h+2),fill="#9caf68")
    def flowers(d):
        for x,y,r in points(104,22):
            d.line((x,y+6,x,y),fill="#426830",width=2);petal=r.choice(["#e8dfb2","#d8d0a0","#e5c95e"])
            for dx,dy in ((-3,0),(3,0),(0,-3),(0,3)): d.rectangle((x+dx-1,y+dy-1,x+dx+1,y+dy+1),fill="#746d42");d.point((x+dx,y+dy),fill=petal)
            d.rectangle((x-1,y-1,x+1,y+1),fill="#b57a2d")
    def bracken(d):
        for x,y,r in points(105,8,48,24):
            d.line((x,y+11,x,y-15),fill="#284522",width=2)
            for yy in range(y-10,y+8,4):
                width=4+(yy-(y-10))//3;d.line((x,yy,x-width,yy-3),fill="#66854a",width=2);d.line((x,yy-1,x+width,yy-4),fill="#66854a",width=2)
                d.point((x-width,yy-3),fill="#a0ad6a")
    def cones(d):
        for x,y,r in points(106,17):
            d.polygon(((x,y-6),(x+5,y-2),(x+4,y+6),(x-4,y+6),(x-5,y-2)),fill="#3d291b")
            d.rectangle((x-3,y-2,x+3,y+4),fill="#79502a");d.line((x-3,y,x+3,y+3),fill="#b47c40",width=1)
    def chalk_stones(d):
        for x,y,r in points(107,13):
            rx,ry=r.randrange(5,10),r.randrange(3,6);d.polygon(((x-rx,y),(x-rx//2,y-ry),(x+rx//2,y-ry-1),(x+rx,y),(x+rx-2,y+ry),(x-rx+2,y+ry)),fill="#5c6257")
            d.polygon(((x-rx+2,y-1),(x-rx//3,y-ry+1),(x+rx//2,y-ry),(x+rx-3,y+1)),fill="#a4a58a");d.line((x-rx//3,y-ry+1,x+rx//3,y-ry),fill="#d3cfaa")
    def chips(d):
        for x,y,r in points(108,82):
            c=r.choice(["#734a26","#9d6933","#c18b4a","#d9ad68"]);d.line((x-2,y+1,x+r.randrange(2,6),y-1),fill=c,width=r.choice([1,2]))
    def sawdust(d): patch(d,("#70502d","#aa7a3c","#d0a053","#ead080"),109)
    def ruts(d):
        for off in (-10,10):
            p=[(x,49+off+round(math.sin(x*.11)*2)) for x in range(7,123,5)];d.line(p,fill="#46502a",width=5);d.line([(x,y-1) for x,y in p],fill="#8d8248",width=2)
        for x,y,r in points(110,20): d.line((x-3,y+1,x+3,y-1),fill="#b3a566")
    return [meadow,clover,trimmed,flowers,bracken,cones,chalk_stones,chips,sawdust,ruts]


def mangrove_cells():
    def mud(d): patch(d,("#263a31","#3e5544","#61705a","#9a9b76"),201,True)
    def puddle(d):
        d.polygon(((8,50),(20,35),(43,29),(65,34),(85,25),(108,36),(121,50),(108,65),(83,68),(62,74),(38,67),(17,63)),fill="#183f42")
        d.polygon(((18,49),(33,38),(52,35),(68,40),(86,32),(107,42),(109,53),(94,60),(71,64),(49,61),(28,58)),fill="#276063")
        d.line((28,45,49,42,67,44),fill="#70a7a0",width=2);d.line((73,56,91,53,103,55),fill="#9bc0ae")
    def roots(d):
        for x,y,r in points(203,24):
            h=r.randrange(8,22);d.polygon(((x-2,y+5),(x-1,y-h),(x+1,y-h-3),(x+3,y+5)),fill="#263027");d.line((x,y+3,x,y-h+1),fill="#7b7658",width=2);d.point((x,y-h+1),fill="#b1a27a")
    def wax_leaves(d):
        for x,y,r in points(204,42):
            angle=r.choice([-1,1]);d.polygon(((x-7,y+2),(x-2,y-4),(x+7,y-2),(x+3,y+3)),fill="#173629");d.polygon(((x-5,y+1),(x-1,y-3),(x+5,y-2),(x+2,y+2)),fill=r.choice(["#416648","#597855","#806b3b"]));d.line((x-4,y,x+4,y-1),fill="#9a9a68")
    def sedge(d):
        for x,y,r in points(205,17):
            for dx in (-5,-2,1,4):
                h=r.randrange(10,24);d.line((x+dx,y+7,x+dx+r.choice([-3,-1,1,3]),y-h),fill="#173e32",width=2);d.point((x+dx,y-h),fill="#7e9b66")
    def fern(d):
        for x,y,r in points(206,7,48,24):
            d.line((x,y+10,x,y-20),fill="#17372c",width=2)
            for step in range(4,25,5):
                yy=y+8-step;wide=10-step//4;d.line((x,yy,x-wide,yy-4),fill="#47745b",width=3);d.line((x,yy-1,x+wide,yy-5),fill="#47745b",width=3);d.point((x-wide,yy-4),fill="#82a477")
    def shells(d):
        for x,y,r in points(207,19):
            d.ellipse((x-5,y-3,x+5,y+4),fill="#45473e");d.arc((x-4,y-3,x+4,y+3),190,355,fill="#d3c9a5",width=3);d.line((x,y-1,x+3,y+2),fill="#8e876f")
    def burrows(d):
        for x,y,r in points(208,15):
            d.ellipse((x-6,y-3,x+6,y+4),fill="#1b2b27");d.ellipse((x-3,y-1,x+3,y+2),fill="#101c1a")
            for a in range(0,360,60):
                px=x+round(math.cos(math.radians(a))*9);py=y+round(math.sin(math.radians(a))*5);d.rectangle((px,py,px+2,py+1),fill="#70806a")
    def wet_chips(d):
        for x,y,r in points(209,75): d.line((x-3,y+1,x+r.randrange(2,7),y-1),fill=r.choice(["#3d3024","#66503a","#8e7550","#b49a6b"]),width=r.choice([1,2]))
    def groove(d):
        for off in (-8,8):
            p=[(x,49+off+round(math.sin(x*.14)*3)) for x in range(6,123,5)];d.line(p,fill="#192d28",width=7);d.line([(x,y-2) for x,y in p],fill="#536b58",width=2)
        d.line((22,47,46,44),fill="#9ba184");d.line((76,56,101,53),fill="#87977d")
    return [mud,puddle,roots,wax_leaves,sedge,fern,shells,burrows,wet_chips,groove]


def madagascar_cells():
    def laterite(d): patch(d,("#5d2c1f","#8c3f28","#b15d34","#d58a4d"),301)
    def cracked(d):
        patch(d,("#68412a","#9a6337","#bd8348","#dda968"),302)
        for x,y,r in points(303,13,48,25): d.line((x-7,y,x,y+2,x+5,y-4),fill="#563321",width=2);d.line((x,y+2,x+2,y+8),fill="#563321")
    def dry_grass(d):
        for x,y,r in points(304,18):
            for dx in (-5,-2,1,4):
                h=r.randrange(10,24);d.line((x+dx,y+7,x+dx+r.choice([-5,-2,2,5]),y-h),fill="#584326",width=2);d.point((x+dx,y-h),fill=r.choice(["#ad8a4e","#cfaa63"]))
    def thorn(d):
        for x,y,r in points(305,7,46,23):
            d.line((x-18,y+7,x+17,y-7),fill="#4a2e22",width=4);d.line((x-15,y+5,x+14,y-8),fill="#96704a",width=2)
            for s in (-10,0,9): d.line((x+s,y-round(s*.4),x+s+r.choice([-4,4]),y-round(s*.4)-7),fill="#d0a36d",width=2)
    def baobab_litter(d):
        for x,y,r in points(306,34):
            if r.random()<.25: d.ellipse((x-4,y-8,x+4,y+8),fill="#533022");d.rectangle((x-2,y-5,x+2,y+5),fill="#9c5a34")
            else: d.polygon(((x-6,y),(x-1,y-4),(x+6,y-1),(x+2,y+4)),fill="#4d3d26");d.polygon(((x-4,y),(x-1,y-3),(x+4,y-1),(x+1,y+2)),fill="#8c7336")
    def pods(d):
        for x,y,r in points(307,20):
            d.arc((x-9,y-5,x+9,y+6),5,175,fill="#3e251c",width=5);d.arc((x-8,y-5,x+8,y+5),8,172,fill="#9b5e30",width=2);d.point((x,y-4),fill="#d39a58")
    def limestone(d):
        for x,y,r in points(308,14):
            rx,ry=r.randrange(4,10),r.randrange(3,7);d.polygon(((x-rx,y),(x-rx//2,y-ry),(x+rx//3,y-ry-1),(x+rx,y),(x+rx-2,y+ry),(x-rx+2,y+ry)),fill="#5d5549");d.polygon(((x-rx+2,y-1),(x-rx//3,y-ry+1),(x+rx//2,y-ry),(x+rx-3,y+1)),fill="#b7aa8c");d.line((x-rx//3,y-ry+1,x+rx//3,y-ry),fill="#e0cfaa")
    def rosette(d):
        for x,y,r in points(309,12):
            for a in range(0,360,45):
                dx,dy=round(math.cos(math.radians(a))*8),round(math.sin(math.radians(a))*5);d.polygon(((x,y),(x+dx,y+dy),(x+dx//2+1,y+dy//2+2)),fill="#34452c")
            d.rectangle((x-2,y-1,x+2,y+2),fill="#7a7c45")
    def sawdust(d): patch(d,("#754122","#aa6330","#d18b45","#efc675"),310)
    def groove(d):
        for off in (-9,9):
            p=[(x,49+off+round(math.sin(x*.1)*2)) for x in range(6,123,5)];d.line(p,fill="#552719",width=6);d.line([(x,y-1) for x,y in p],fill="#ad5b32",width=2)
        for x,y,r in points(311,17): d.rectangle((x,y,x+3,y+1),fill="#d08649")
    return [laterite,cracked,dry_grass,thorn,baobab_litter,pods,limestone,rosette,sawdust,groove]


def island_cells():
    def sand(d): patch(d,("#8f7548","#c2a866","#dfc780","#f1dea4"),401)
    def coral(d):
        for x,y,r in points(402,26):
            c=r.choice(["#8b6b58","#c18e78","#dda996","#e7cfad"]);d.line((x,y+4,x,y-5),fill="#5f5145",width=4);d.line((x,y+2,x-5,y-2),fill="#5f5145",width=3);d.line((x,y,x+5,y-4),fill="#5f5145",width=3);d.line((x,y+3,x,y-5),fill=c,width=2);d.point((x-5,y-2),fill=c);d.point((x+5,y-4),fill=c)
    def shells(d):
        for x,y,r in points(403,23):
            if r.random()<.45:
                d.polygon(((x-6,y+3),(x,y-5),(x+6,y+3)),fill="#66584a");d.polygon(((x-4,y+2),(x,y-3),(x+4,y+2)),fill="#ead7aa");d.line((x,y-3,x,y+2),fill="#b7896e")
            else:
                d.arc((x-5,y-4,x+6,y+5),20,325,fill="#d4a58b",width=3);d.point((x+4,y+2),fill="#665246")
    def beach_grass(d):
        for x,y,r in points(404,16):
            for dx in (-5,-2,1,4):
                h=r.randrange(9,21);d.line((x+dx,y+6,x+dx+r.choice([-4,-2,2,4]),y-h),fill="#355431",width=2);d.point((x+dx,y-h),fill="#9aa55d")
    def vine(d):
        for x,y,r in points(405,7,48,25):
            d.arc((x-20,y-8,x+22,y+10),185,350,fill="#24513c",width=3)
            for dx in (-13,-3,8,17): d.ellipse((x+dx-4,y-2+(dx%3),x+dx+4,y+4+(dx%3)),fill="#1d3c31");d.rectangle((x+dx-2,y-1+(dx%3),x+dx+2,y+2+(dx%3)),fill="#528153")
    def frond(d):
        for x,y,r in points(406,5,42,21):
            d.line((x-18,y+8,x+19,y-8),fill="#493522",width=3)
            for step in range(-13,17,5):
                yy=y+round(-step*.42);d.line((x+step,yy,x+step-5,yy-8),fill="#376342",width=3);d.line((x+step+2,yy,x+step+8,yy+5),fill="#254a36",width=3);d.point((x+step-5,yy-8),fill="#78945b")
    def husk(d):
        for x,y,r in points(407,14):
            d.ellipse((x-7,y-5,x+7,y+6),fill="#49301f");d.polygon(((x-5,y-3),(x+3,y-4),(x+6,y+3),(x-2,y+5)),fill="#8e6033");d.line((x-3,y-2,x+4,y+2),fill="#c29455");d.rectangle((x+3,y-1,x+5,y+1),fill="#2a2119")
    def volcanic(d):
        for x,y,r in points(408,16):
            rx,ry=r.randrange(4,9),r.randrange(3,6);d.polygon(((x-rx,y),(x-rx//2,y-ry),(x+rx//2,y-ry),(x+rx,y),(x+rx-2,y+ry),(x-rx+2,y+ry)),fill="#242c2c");d.polygon(((x-rx+2,y-1),(x-rx//3,y-ry+1),(x+rx//2,y-ry),(x+rx-3,y+1)),fill="#56615a");d.point((x-rx//3,y-ry+1),fill="#98a18d")
    def fibre(d):
        for x,y,r in points(409,88):
            d.line((x-3,y+1,x+r.randrange(2,7),y-1),fill=r.choice(["#78512b","#aa7940","#c99b58","#e1c17b"]),width=1)
    def sand_drag(d):
        for off in (-9,9):
            p=[(x,49+off+round(math.sin(x*.13)*2)) for x in range(6,123,5)];d.line(p,fill="#8e754a",width=5);d.line([(x,y-2) for x,y in p],fill="#e2ca86",width=2)
        for x,y,r in points(410,20): d.point((x,y),fill="#f2dfa6")
    return [sand,coral,shells,beach_grass,vine,frond,husk,volcanic,fibre,sand_drag]


BIOMES={"beginner":beginner_cells,"mangrove":mangrove_cells,"madagascar":madagascar_cells,"island":island_cells}


def main():
    OUT_DIR.mkdir(parents=True,exist_ok=True)
    board=Image.new("RGBA",(CW*COLS*2,CH*2*len(BIOMES)*2),(30,45,27,255))
    for row,(name,factory) in enumerate(BIOMES.items()):
        atlas=Image.new("RGBA",(CW*COLS,CH*2))
        for index,paint in enumerate(factory()):
            cell=Image.new("RGBA",(CW,CH));paint(ImageDraw.Draw(cell));atlas.alpha_composite(cell,((index%COLS)*CW,(index//COLS)*CH))
        atlas.save(OUT_DIR/f"{name}-floor-decal-atlas-pixel-v1.png",optimize=True)
        board.alpha_composite(atlas.resize((atlas.width*2,atlas.height*2),Image.Resampling.NEAREST),(0,row*CH*4))
    PREVIEW.parent.mkdir(parents=True,exist_ok=True);board.save(PREVIEW)
    print("BIOME_FLOOR_ASSETS_OK biomes=4 decals=40 atlas=640x192")


if __name__=="__main__": main()
