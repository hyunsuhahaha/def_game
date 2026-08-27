"""Deterministic cartoon-pixel digits and bitcoin wallet for brute-force FX."""
from pathlib import Path
import math
from PIL import Image,ImageDraw,ImageFilter

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"assets/fx/brute-force"
DIGITS=OUT/"brute-force-digits-cartoon-pixel-v2.png"
WALLET=OUT/"bitcoin-wallet-cartoon-pixel-v1.png"
PREVIEW=ROOT/"docs/previews/brute-force-runtime-v3.png"
GROUND=ROOT/"assets/forest-ground-tile-v1.png"
PATTERNS={
"0":["11111","10001","10011","10101","11001","10001","11111"],"1":["00100","01100","00100","00100","00100","00100","01110"],
"2":["11110","00001","00001","11110","10000","10000","11111"],"3":["11110","00001","00001","01110","00001","00001","11110"],
"4":["10010","10010","10010","11111","00010","00010","00010"],"5":["11111","10000","10000","11110","00001","00001","11110"],
"6":["01111","10000","10000","11110","10001","10001","01110"],"7":["11111","00001","00010","00100","01000","01000","01000"],
"8":["01110","10001","10001","01110","10001","10001","01110"],"9":["01110","10001","10001","01111","00001","00001","11110"]}

def glyph(value,palette):
    logical=Image.new("L",(8,10),0);d=ImageDraw.Draw(logical)
    for y,row in enumerate(PATTERNS[value]):
        for x,on in enumerate(row):
            if on=="1":d.rectangle((x+1,y+1,x+1,y+1),fill=255)
    mask=logical.resize((32,40),Image.Resampling.NEAREST)
    out=Image.new("RGBA",(32,40),(0,0,0,0))
    shadow=Image.new("L",mask.size,0);shadow.paste(mask,(3,4));outline=mask.filter(ImageFilter.MaxFilter(5))
    out.paste((8,20,13,220),(0,0,32,40),shadow);out.paste(palette[0],(0,0,32,40),outline);out.paste(palette[1],(0,0,32,40),mask)
    px=out.load()
    for y,row in enumerate(PATTERNS[value]):
        for x,on in enumerate(row):
            if on=="1":
                ox,oy=(x+1)*4,(y+1)*4
                for yy in range(oy,min(oy+1,40)):
                    for xx in range(ox,min(ox+3,32)):px[xx,yy]=palette[2]
    return out

def wallet_frame(state):
    small=Image.new("RGBA",(40,40),(0,0,0,0));d=ImageDraw.Draw(small)
    d.ellipse((7,3,33,29),fill=(57,31,7,255),outline=(24,17,8,255),width=2);d.ellipse((9,5,31,27),fill=(235,128,14,255),outline=(255,211,65,255),width=2)
    # Pixel B with two bitcoin strokes.
    for x,y in ((17,9),(17,10),(17,11),(17,12),(17,13),(17,14),(17,15),(17,16),(17,17),(17,18),(18,8),(18,19),(19,8),(19,19),(20,9),(20,13),(20,18),(21,10),(21,11),(21,12),(21,14),(21,15),(21,16),(21,17),(16,8),(16,19)):
        d.point((x,y),fill=(47,26,6,255))
    d.line((18,7,18,20),fill=(255,221,94,255));d.line((20,7,20,20),fill=(255,221,94,255))
    # Hardware-wallet lock body.
    d.rectangle((11,21,29,35),fill=(8,35,18,255),outline=(4,15,9,255),width=2);d.rectangle((13,23,27,33),fill=(38,196,70,255),outline=(111,255,116,255))
    if state<2:
        d.line((15,22,15,16,25,16,25,22),fill=(11,40,20,255),width=4);d.line((16,21,16,17,24,17,24,21),fill=(100,255,120,255),width=1)
    else:
        d.line((15,22,15,16,24,13,28,17),fill=(11,40,20,255),width=4);d.line((16,21,16,17,24,14,27,17),fill=(100,255,120,255))
    d.rectangle((19,26,21,30),fill=(238,185,33,255));d.point((20,25),fill=(255,239,105,255))
    if state==1:
        for line in [((5,16),(12,19)),((34,15),(28,20)),((8,31),(3,35)),((32,30),(37,34))]:d.line(line,fill=(84,255,102,255),width=2)
    if state==2:
        for i in range(10):
            a=i/10*math.tau;x1,y1=20+math.cos(a)*18,20+math.sin(a)*15;x2,y2=20+math.cos(a)*21,20+math.sin(a)*18;d.line((x1,y1,x2,y2),fill=(i%2*171+84,255 if i%2==0 else 180,58,255),width=1)
    return small.resize((80,80),Image.Resampling.NEAREST)

def build():
    OUT.mkdir(parents=True,exist_ok=True);sheet=Image.new("RGBA",(320,80),(0,0,0,0))
    palettes=[((4,39,18,255),(37,209,72,255),(192,255,183,255)),((57,31,5,255),(238,139,19,255),(255,236,113,255))]
    for row,palette in enumerate(palettes):
        for i in range(10):sheet.alpha_composite(glyph(str(i),palette),(i*32,row*40))
    sheet.save(DIGITS);wallet=Image.new("RGBA",(240,80),(0,0,0,0))
    for i in range(3):wallet.alpha_composite(wallet_frame(i),(i*80,0))
    wallet.save(WALLET)
    ground=Image.open(GROUND).convert("RGB").resize((960,440),Image.Resampling.BICUBIC).convert("RGBA")
    mole_sheet=Image.open(ROOT/"assets/characters/ingame/coin-miner-mole-atlas-pixel-v3.png").convert("RGBA")
    mole=mole_sheet.crop((0,0,192,384)).resize((96,192),Image.Resampling.NEAREST);ground.alpha_composite(mole,(210,155))
    wallet_x,wallet_y=500,190;ground.alpha_composite(wallet_frame(1),(wallet_x,wallet_y))
    beam=ImageDraw.Draw(ground);start=(302,258);target=(wallet_x+38,wallet_y+48)
    beam.line((start,target),fill=(7,44,16,210),width=9);beam.line((start,target),fill=(55,239,77,245),width=3)
    for i in range(18):
        p=(i+1)/19;x=start[0]+(target[0]-start[0])*p;y=start[1]+(target[1]-start[1])*p+math.sin(i*2.1)*5
        sprite=glyph(str((i*7+3)%10),palettes[i%2]).resize((23,29),Image.Resampling.NEAREST);ground.alpha_composite(sprite,(round(x-12),round(y-15)))
    for i in range(18):
        a=i/18*math.tau
        for step,opacity in ((85,70),(125,150),(175,255)):
            sprite=glyph(str((i*9+1)%10),palettes[i%2]).resize((27,34),Image.Resampling.NEAREST);sprite.putalpha(sprite.getchannel("A").point(lambda v:v*opacity//255))
            x=target[0]+math.cos(a)*step;y=target[1]+math.sin(a)*step*.62;ground.alpha_composite(sprite,(round(x-14),round(y-17)))
    PREVIEW.parent.mkdir(parents=True,exist_ok=True);ground.save(PREVIEW);print(DIGITS);print(WALLET);print(PREVIEW)

if __name__=="__main__":build()
