from pathlib import Path
from PIL import Image, ImageDraw
import math

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/fx/attack-plants/attack-plant-projectiles-atlas-v2.png"
CELL, FRAMES, ROWS = 160, 6, 4

RAMPS = {
    "outline": ["#11180e", "#172512", "#213619", "#2e4920"],
    "seed": ["#33220f", "#513516", "#754a1b", "#9c6823", "#c18a31", "#e1b94e", "#f3dc72"],
    "leaf": ["#163416", "#20501e", "#2f7027", "#479535", "#70b947", "#a0d35c"],
    "bamboo": ["#18351c", "#245128", "#337238", "#4d9348", "#72b75d", "#a7d47b", "#d3eaa0"],
    "resin": ["#3a1708", "#672508", "#943a09", "#c4530a", "#e87910", "#f6a626", "#ffd35a", "#fff0a2"],
}

def poly(draw, pts, fill):
    draw.polygon([(int(x), int(y)) for x, y in pts], fill=fill)

def cluster_line(draw, pts, color, width):
    draw.line([(int(x), int(y)) for x, y in pts], fill=color, width=width, joint="curve")

def dither(draw, mask, colors, phase, stride=5):
    px = mask.load()
    for y in range(2, CELL - 2):
        for x in range(2, CELL - 2):
            if px[x, y] and ((x + y * 2 + phase) % stride == 0):
                draw.point((x, y), fill=colors[(x + phase) % len(colors)])

def seed_frame(frame):
    im = Image.new("RGBA", (CELL, CELL)); d = ImageDraw.Draw(im)
    wobble = (frame % 3 - 1) * 2; cy = 80 + wobble
    outline = [(35, cy), (48, cy-20), (91, cy-26), (124, cy-10), (132, cy), (123, cy+12), (88, cy+25), (49, cy+19)]
    poly(d, outline, RAMPS["outline"][0])
    body = [(39, cy), (51, cy-16), (89, cy-21), (119, cy-8), (126, cy), (117, cy+9), (86, cy+20), (52, cy+15)]
    poly(d, body, RAMPS["seed"][2])
    poly(d, [(48,cy-13),(86,cy-18),(113,cy-7),(80,cy-4)], RAMPS["seed"][4])
    poly(d, [(43,cy+3),(84,cy+1),(116,cy+8),(84,cy+17),(52,cy+12)], RAMPS["seed"][1])
    cluster_line(d, [(55,cy-12),(69,cy+11)], RAMPS["seed"][6], 3)
    cluster_line(d, [(76,cy-17),(89,cy+13)], RAMPS["seed"][5], 3)
    cluster_line(d, [(98,cy-13),(106,cy+8)], RAMPS["seed"][6], 2)
    # leafy fins make it read as an explosive pod, not a brown pebble
    poly(d, [(42,cy-8),(24,cy-22),(31,cy-1)], RAMPS["outline"][1]); poly(d, [(40,cy-7),(28,cy-18),(33,cy-2)], RAMPS["leaf"][4])
    poly(d, [(44,cy+7),(27,cy+22),(33,cy+1)], RAMPS["outline"][1]); poly(d, [(42,cy+7),(31,cy+17),(35,cy+2)], RAMPS["leaf"][3])
    # pulsing seam, synchronized to the launch animation
    glow = RAMPS["resin"][5 + (frame % 2)]
    d.rectangle((119,cy-3,132,cy+3), fill=RAMPS["outline"][0]); d.rectangle((121,cy-2,134,cy+2), fill=glow)
    mask=Image.new("1",(CELL,CELL));ImageDraw.Draw(mask).polygon(body,fill=1);dither(d,mask,[RAMPS["seed"][3],RAMPS["seed"][5]],frame,7)
    return im

def bamboo_frame(frame):
    im=Image.new("RGBA",(CELL,CELL));d=ImageDraw.Draw(im);cy=80+(frame%2)
    poly(d,[(18,cy-17),(119,cy-17),(146,cy),(119,cy+17),(18,cy+17),(8,cy)],RAMPS["outline"][0])
    poly(d,[(17,cy-12),(119,cy-12),(139,cy),(118,cy+12),(17,cy+12),(11,cy)],RAMPS["bamboo"][2])
    poly(d,[(18,cy-10),(116,cy-10),(133,cy-1),(24,cy-1)],RAMPS["bamboo"][5])
    poly(d,[(18,cy+2),(119,cy+2),(134,cy+1),(116,cy+10),(18,cy+10)],RAMPS["bamboo"][1])
    for x in (39,66,94,118):
        d.rectangle((x-3,cy-14,x+3,cy+14),fill=RAMPS["outline"][1]);d.rectangle((x-1,cy-11,x+1,cy+11),fill=RAMPS["bamboo"][6])
    # split leaf fletching and compressed-air nose flash
    poly(d,[(17,cy-7),(2,cy-27),(26,cy-12)],RAMPS["outline"][1]);poly(d,[(15,cy-8),(5,cy-23),(22,cy-12)],RAMPS["leaf"][4])
    poly(d,[(17,cy+7),(2,cy+27),(26,cy+12)],RAMPS["outline"][1]);poly(d,[(15,cy+8),(5,cy+23),(22,cy+12)],RAMPS["leaf"][3])
    flare=4+(frame%3)*2;poly(d,[(140,cy),(151,cy-flare),(148,cy),(151,cy+flare)],RAMPS["resin"][6]);d.point((153,cy),fill=RAMPS["resin"][7])
    return im

def resin_blob_frame(frame):
    im=Image.new("RGBA",(CELL,CELL));d=ImageDraw.Draw(im); pulse=(frame%3)-1
    outline=[(80,24-pulse),(106,34),(126,58),(122,92),(101,124),(70,135),(41,117),(27,88),(34,54),(55,33)]
    poly(d,outline,RAMPS["outline"][0]);inner=[(80,30-pulse),(102,39),(119,61),(115,90),(96,117),(70,128),(47,112),(34,86),(40,58),(58,40)]
    poly(d,inner,RAMPS["resin"][2]);poly(d,[(56,43),(84,34),(108,52),(105,76),(77,69),(49,76)],RAMPS["resin"][5]);poly(d,[(45,83),(76,74),(111,83),(96,113),(69,123),(49,106)],RAMPS["resin"][1])
    poly(d,[(60,47),(78,39),(91,43),(78,54),(64,60)],RAMPS["resin"][7]);poly(d,[(101,92),(110,79),(112,94),(99,108)],RAMPS["resin"][4])
    for n in range(5):
        a=n*1.256+frame*.28;r=54+n%2*8;x=80+math.cos(a)*r;y=82+math.sin(a)*r*.78;d.rectangle((int(x)-2,int(y)-2,int(x)+2,int(y)+2),fill=RAMPS["resin"][5])
    mask=Image.new("1",(CELL,CELL));ImageDraw.Draw(mask).polygon(inner,fill=1);dither(d,mask,[RAMPS["resin"][3],RAMPS["resin"][6]],frame,6)
    return im

def puddle_frame(frame):
    im=Image.new("RGBA",(CELL,CELL));d=ImageDraw.Draw(im);cy=89
    outer=[(16,cy),(28,65),(55,57),(75,43),(103,54),(137,61),(148,82),(141,106),(111,116),(83,111),(56,121),(28,108)]
    poly(d,outer,RAMPS["outline"][0]);inner=[(21,cy),(32,69),(57,63),(76,49),(101,59),(132,66),(142,83),(136,101),(109,110),(82,105),(56,115),(33,103)]
    poly(d,inner,RAMPS["resin"][1]);poly(d,[(28,82),(57,67),(78,55),(101,63),(126,69),(135,83),(111,84),(89,76),(65,85),(42,91)],RAMPS["resin"][4]);poly(d,[(34,96),(58,88),(84,81),(108,89),(133,91),(128,103),(104,107),(82,101),(55,111)],RAMPS["resin"][2])
    # animated bubbles and bark fragments make the hazard feel viscous
    for n in range(8):
        a=n*2.19; x=80+math.cos(a)*48; y=86+math.sin(a)*20
        rr=3+((n+frame)%3);d.rectangle((int(x-rr),int(y-rr),int(x+rr),int(y+rr)),fill=RAMPS["outline"][1]);d.rectangle((int(x-rr+2),int(y-rr+1),int(x+rr-1),int(y+rr-1)),fill=RAMPS["resin"][5]);d.point((int(x-rr+2),int(y-rr+1)),fill=RAMPS["resin"][7])
    for x,y,a in [(45,75,-.3),(94,98,.2),(119,76,-.5)]:
        poly(d,[(x-8,y-3),(x+5,y-6),(x+9,y+2),(x-4,y+5)],RAMPS["seed"][1]);cluster_line(d,[(x-4,y-2),(x+5,y+1)],RAMPS["seed"][5],2)
    return im

def main():
    atlas=Image.new("RGBA",(CELL*FRAMES,CELL*ROWS))
    makers=(seed_frame,bamboo_frame,resin_blob_frame,puddle_frame)
    for row,maker in enumerate(makers):
        for frame in range(FRAMES): atlas.alpha_composite(maker(frame),(frame*CELL,row*CELL))
    OUT.parent.mkdir(parents=True,exist_ok=True);atlas.save(OUT,optimize=True)
    print(f"WROTE {OUT.relative_to(ROOT)} {atlas.size[0]}x{atlas.size[1]}")

if __name__ == "__main__": main()
