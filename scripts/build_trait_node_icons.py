"""Build readable, material-shaded pixel icons for the active research board."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"assets/ui/trait-node-icons-pixel-v2.png"
CELL=96
NAMES=("ember","filter","wind","ash","clock","warning","pack","map","basket")
INK=(18,20,24,255);DEEP=(48,31,23,255)
FIRE=((95,34,18,255),(163,52,20,255),(226,84,20,255),(255,143,28,255),(255,215,91,255),(255,247,187,255))
METAL=((45,51,54,255),(73,82,83,255),(111,122,117,255),(166,172,153,255),(226,218,169,255),(255,244,199,255))
PAPER=((105,75,48,255),(160,113,62,255),(211,165,92,255),(242,211,143,255),(255,239,194,255))
GREEN=((28,67,48,255),(43,105,66,255),(63,145,81,255),(106,190,99,255),(180,224,132,255))
CYAN=((25,75,86,255),(37,119,132,255),(57,170,177,255),(113,221,215,255),(207,255,235,255))

def rect(d,xy,c):d.rectangle(tuple(int(v) for v in xy),fill=c)
def poly(d,pts,c):d.polygon([(int(x),int(y))for x,y in pts],fill=c)
def line(d,pts,c,w=3):d.line([(int(x),int(y))for x,y in pts],fill=c,width=w,joint="curve")

def ember(d):
    poly(d,[(48,9),(67,34),(65,61),(51,84),(28,69),(25,43)],INK)
    poly(d,[(48,15),(61,38),(58,64),(49,76),(33,65),(32,44)],FIRE[1])
    poly(d,[(49,28),(56,44),(53,63),(46,69),(38,59),(40,42)],FIRE[3])
    poly(d,[(48,39),(52,49),(48,61),(43,55)],FIRE[5])
    rect(d,(35,62,40,66),FIRE[0]);rect(d,(54,30,58,37),FIRE[4])

def cigarette(d):
    poly(d,[(16,56),(21,65),(70,39),(66,30)],INK)
    poly(d,[(22,56),(25,61),(58,43),(55,37)],PAPER[4])
    poly(d,[(58,43),(70,37),(66,31),(55,37)],FIRE[2])
    rect(d,(26,53,46,55),PAPER[2]);rect(d,(31,49,35,51),PAPER[3])
    rect(d,(69,29,74,34),FIRE[4]);rect(d,(73,25,77,28),METAL[2])

def wind(d):
    for y,end,shade in ((29,69,4),(47,78,3),(64,64,2)):
        line(d,[(15,y),(end-12,y),(end,y-7)],CYAN[shade],5)
        rect(d,(20,y-2,36,y),CYAN[max(1,shade-1)])
    poly(d,[(65,22),(83,28),(71,35)],CYAN[4]);poly(d,[(70,55),(85,63),(69,70)],CYAN[3])

def ash(d):
    poly(d,[(25,54),(32,28),(48,17),(64,32),(72,58),(62,78),(33,77)],INK)
    poly(d,[(31,56),(37,33),(49,23),(59,37),(65,59),(57,70),(37,70)],METAL[1])
    for x,y,s in ((38,47,3),(49,36,2),(57,55,3),(43,63,2),(53,66,2)):
        rect(d,(x,y,x+s,y+s),METAL[4])
    line(d,[(31,56),(65,59)],METAL[3],3)

def clock(d):
    d.ellipse((13,13,83,83),fill=INK);d.ellipse((19,19,77,77),fill=METAL[1]);d.ellipse((25,25,71,71),fill=(20,27,28,255))
    for a in range(0,12):
        import math;x=48+math.cos(a*math.pi/6)*19;y=48+math.sin(a*math.pi/6)*19
        rect(d,(x-1,y-1,x+1,y+1),METAL[4])
    line(d,[(48,48),(48,30)],METAL[5],5);line(d,[(48,48),(63,57)],FIRE[4],5)
    rect(d,(44,44,52,52),FIRE[3])

def warning(d):
    poly(d,[(48,9),(88,80),(8,80)],INK);poly(d,[(48,17),(79,74),(17,74)],FIRE[2]);poly(d,[(48,26),(70,68),(26,68)],FIRE[4])
    rect(d,(44,36,52,56),DEEP);rect(d,(44,61,52,68),DEEP);rect(d,(47,38,50,51),FIRE[5])

def pack(d):
    rect(d,(16,12,80,85),INK);rect(d,(22,18,74,79),PAPER[1]);rect(d,(26,22,70,43),PAPER[4]);rect(d,(26,47,70,74),FIRE[1])
    rect(d,(30,50,36,70),FIRE[3]);rect(d,(41,50,47,70),FIRE[2]);rect(d,(52,50,58,70),FIRE[4]);rect(d,(63,50,67,70),FIRE[2])
    rect(d,(30,26,65,30),PAPER[2]);rect(d,(30,34,53,37),PAPER[3])

def map_icon(d):
    poly(d,[(10,22),(35,13),(59,23),(85,13),(85,74),(60,83),(36,73),(10,83)],INK)
    poly(d,[(16,26),(34,20),(34,67),(16,75)],GREEN[2]);poly(d,[(39,20),(56,27),(56,74),(39,67)],GREEN[4]);poly(d,[(61,27),(79,21),(79,69),(61,76)],GREEN[1])
    line(d,[(18,59),(31,48),(44,54),(55,42),(72,34)],FIRE[4],4);rect(d,(68,29,76,37),FIRE[5])

def basket(d):
    poly(d,[(15,37),(81,37),(73,82),(23,82)],INK);poly(d,[(22,43),(74,43),(67,75),(29,75)],PAPER[1])
    for x in (32,47,62):rect(d,(x,45,x+5,73),PAPER[3])
    for y in (50,62):rect(d,(25,y,70,y+4),PAPER[2])
    line(d,[(29,39),(34,18),(62,18),(68,39)],PAPER[4],6);line(d,[(34,21),(61,21)],PAPER[2],3)

DRAW=(ember,cigarette,wind,ash,clock,warning,pack,map_icon,basket)
def main():
    atlas=Image.new("RGBA",(CELL*3,CELL*3))
    for i,fn in enumerate(DRAW):
        frame=Image.new("RGBA",(CELL,CELL));fn(ImageDraw.Draw(frame));atlas.alpha_composite(frame,((i%3)*CELL,(i//3)*CELL))
    OUT.parent.mkdir(parents=True,exist_ok=True);atlas.save(OUT,optimize=True)
    print("wrote",OUT.relative_to(ROOT),atlas.size)
if __name__=="__main__":main()
