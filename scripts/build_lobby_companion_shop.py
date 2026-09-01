"""Bake the clickable lobby pet shop and three purchased playground props."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"assets/ui"

INK=(25,24,19,255);WOOD_D=(62,43,27,255);WOOD=(104,70,38,255);WOOD_L=(158,111,57,255)
TEAL_D=(19,62,52,255);TEAL=(37,116,91,255);TEAL_L=(88,167,119,255)
CREAM=(231,215,157,255);AMBER=(230,143,45,255);RED=(151,57,42,255)

def rect(d,box,color): d.rectangle(tuple(round(v) for v in box),fill=color)
def ramp(dark,light,steps=16):
    return [tuple(round(dark[c]+(light[c]-dark[c])*i/(steps-1)) for c in range(3))+(255,)
            for i in range(steps)]

WOOD_RAMP=ramp((47,31,22),(190,137,73))
TEAL_RAMP=ramp((13,48,43),(103,184,132))
CREAM_RAMP=ramp((121,105,72),(244,229,171))
AMBER_RAMP=ramp((102,52,26),(250,178,61))
RED_RAMP=ramp((75,31,31),(197,76,53))

def build_shop(name,w,h):
    im=Image.new("RGBA",(w,h),(0,0,0,0));d=ImageDraw.Draw(im)
    sx,sy=w/192,h/144
    def R(x0,y0,x1,y1,c): rect(d,(x0*sx,y0*sy,x1*sx,y1*sy),c)
    # Deep stump-and-timber silhouette first.
    R(16,129,178,139,INK);R(25,47,169,132,INK);R(40,24,154,51,INK)
    d.polygon([(round(30*sx),round(48*sy)),(round(55*sx),round(15*sy)),
               (round(145*sx),round(15*sy)),(round(174*sx),round(48*sy))],fill=INK)
    d.polygon([(round(36*sx),round(45*sy)),(round(59*sx),round(20*sy)),
               (round(141*sx),round(20*sy)),(round(166*sx),round(45*sy))],fill=WOOD_D)
    # Roof shingles: stepped, directional highlights rather than noise.
    for row,(y,color) in enumerate(((24,WOOD),(31,WOOD_L),(38,WOOD))):
        for col in range(8):
            x=43+col*15+(row%2)*7
            R(x,y,x+13,y+7,color);R(x,y+6,x+13,y+8,WOOD_D)
    R(48,50,153,128,WOOD);R(55,57,146,123,WOOD_L)
    for x in range(58,145,12): R(x,59,x+2,121,WOOD)
    # Counter and dark interior.
    R(61,69,140,109,INK);R(66,74,135,103,TEAL_D)
    R(55,104,146,113,WOOD_D);R(58,101,143,108,CREAM)
    # Teal awning with alternating cloth folds.
    R(55,53,146,70,INK)
    for i in range(7):
        x=59+i*12;R(x,56,x+11,67,TEAL if i%2==0 else CREAM)
        R(x,66,x+11,70,TEAL_D if i%2==0 else WOOD_L)
    # Paw sign: readable at final scale.
    R(74,29,126,51,TEAL_D);R(78,32,122,48,TEAL)
    cx,cy=100*sx,41*sy
    d.ellipse((round(cx-6*sx),round(cy-3*sy),round(cx+6*sx),round(cy+6*sy)),fill=CREAM)
    for ox,oy in ((-9,-6),(-3,-9),(4,-9),(10,-5)):
        d.ellipse((round(cx+(ox-2)*sx),round(cy+(oy-2)*sy),round(cx+(ox+2)*sx),round(cy+(oy+2)*sy)),fill=CREAM)
    # Visible stock and warm lantern.
    for x,c in ((75,AMBER),(89,RED),(119,TEAL_L)):
        d.ellipse((round((x-4)*sx),round(83*sy),round((x+4)*sx),round(91*sy)),fill=c)
    R(151,67,164,92,WOOD_D);R(154,70,161,86,AMBER);R(155,72,160,84,CREAM)
    # Material highlights/dither only at plank lower edges.
    for y in (118,124):
        for x in range(58,145,4):
            if (x//4+y//2)%2==0:R(x,y,x+1,y+1,WOOD_D)
    # Authored material ramps: roof follows the shingle slope, planks follow the
    # grain, cloth follows each fold, and the lamp/stock follow curved highlights.
    # Every shade belongs to a surface transition; these are not random palette noise.
    for i,color in enumerate(WOOD_RAMP):
        R(48+i*6,42-(i%3),51+i*6,43-(i%3),color)
        R(59+(i%8)*10,116+(i//8)*5,61+(i%8)*10,117+(i//8)*5,color)
    for i,color in enumerate(TEAL_RAMP):
        R(68+(i%8)*8,76+(i//8)*19,70+(i%8)*8,79+(i//8)*19,color)
        R(59+(i%7)*12,56+(i//7)*5,61+(i%7)*12,58+(i//7)*5,color)
    for i,color in enumerate(CREAM_RAMP):
        R(60+i*5,102,63+i*5,103,color)
    for i,color in enumerate(AMBER_RAMP):
        R(155+(i%3),72+(i//3)*2,156+(i%3),73+(i//3)*2,color)
    for i,color in enumerate(RED_RAMP):
        R(84+(i%4),82+(i//4)*2,85+(i%4),83+(i//4)*2,color)
    OUT.mkdir(parents=True,exist_ok=True);im.save(OUT/name,optimize=True)
    print(f"LOBBY_SHOP_OK {name} {w}x{h}")

def build_playgrounds_v2():
    cell_w,cell_h=160,128
    im=Image.new("RGBA",(cell_w*4,cell_h),(0,0,0,0));d=ImageDraw.Draw(im)
    # 1. Ball court: a broad turf patch and fence at a scale shared with companions.
    ox=0;rect(d,(ox+10,112,ox+150,121),INK);rect(d,(ox+15,105,ox+145,116),TEAL_D)
    for x in range(20,146,16):
        rect(d,(ox+x,82,ox+x+5,111),INK);rect(d,(ox+x+1,84,ox+x+3,108),WOOD_L)
    for x,y,c in ((49,103,AMBER),(80,96,RED),(113,104,TEAL_L)):
        d.ellipse((ox+x-10,y-10,ox+x+10,y+10),fill=INK);d.ellipse((ox+x-7,y-7,ox+x+7,y+7),fill=c)
        rect(d,(ox+x-4,y-6,ox+x+1,y-3),CREAM)
    for i,color in enumerate(TEAL_RAMP):rect(d,(ox+18+i*7,108+(i%2),ox+22+i*7,109+(i%2)),color)

    # 2. Sand burrow: deeper box, shaped tunnel and authored granular highlights.
    ox=cell_w;rect(d,(ox+10,111,ox+150,122),INK);rect(d,(ox+15,102,ox+145,116),WOOD_D)
    d.polygon([(ox+20,103),(ox+43,68),(ox+116,68),(ox+140,103)],fill=INK)
    d.polygon([(ox+26,102),(ox+47,74),(ox+112,74),(ox+134,102)],fill=(196,150,83,255))
    d.ellipse((ox+61,65,ox+101,112),fill=INK);d.ellipse((ox+68,73,ox+94,112),fill=(55,42,31,255))
    for i,color in enumerate(AMBER_RAMP):rect(d,(ox+29+i*6,88+(i%4),ox+32+i*6,90+(i%4)),color)
    for x,y in ((32,100),(49,91),(116,93),(129,104),(42,108),(111,109)):rect(d,(ox+x,y,ox+x+4,y+2),CREAM)

    # 3. Cat tower: tall enough for a full-size cat to climb, perch and jump.
    ox=cell_w*2
    rect(d,(ox+28,113,ox+133,122),INK);rect(d,(ox+34,108,ox+127,116),WOOD_D)
    for x0,y0,x1,y1 in ((48,38,59,111),(105,23,116,111)):
        rect(d,(ox+x0-3,y0-3,ox+x1+3,y1+3),INK);rect(d,(ox+x0,y0,ox+x1,y1),WOOD)
        for y in range(y0+3,y1-2,6):rect(d,(ox+x0+2,y,ox+x1-2,y+2),CREAM_RAMP[(y-y0)//6%16])
    for x0,y0,x1,y1 in ((29,88,83,98),(75,61,132,71),(88,22,137,33)):
        rect(d,(ox+x0-4,y0-4,ox+x1+4,y1+4),INK);rect(d,(ox+x0,y0,ox+x1,y1),TEAL)
        rect(d,(ox+x0+3,y0+2,ox+x1-3,y0+4),TEAL_L)
    rect(d,(ox+67,72,ox+102,103),INK);rect(d,(ox+72,76,ox+98,100),WOOD_L)
    d.ellipse((ox+78,79,ox+93,96),fill=TEAL_D)
    for i,color in enumerate(WOOD_RAMP):rect(d,(ox+74+i%8*3,99+i//8*3,ox+76+i%8*3,100+i//8*3),color)

    # 4. Swing frame. Ropes and seat are a synchronized overlay atlas below.
    ox=cell_w*3
    d.line((ox+28,116,ox+53,24),fill=INK,width=10);d.line((ox+132,116,ox+107,24),fill=INK,width=10)
    d.line((ox+30,115,ox+54,25),fill=WOOD,width=5);d.line((ox+130,115,ox+106,25),fill=WOOD,width=5)
    rect(d,(ox+42,18,ox+118,30),INK);rect(d,(ox+47,21,ox+113,27),WOOD_L)
    rect(d,(ox+20,113,ox+140,122),INK);rect(d,(ox+26,110,ox+134,116),WOOD_D)
    for i,color in enumerate(WOOD_RAMP):rect(d,(ox+49+i*4,22+(i%2),ox+52+i*4,24+(i%2)),color)
    im.save(OUT/"lobby-playgrounds-pixel-v2.png",optimize=True)

    angles=(-.36,-.24,0,.24,.36,.24,0,-.24)
    motion=Image.new("RGBA",(cell_w*len(angles),cell_h),(0,0,0,0))
    md=ImageDraw.Draw(motion)
    import math
    for frame,angle in enumerate(angles):
        ox=frame*cell_w;px,py=80,27;length=58
        sx=round(px+math.sin(angle)*length);sy=round(py+math.cos(angle)*length)
        for side in (-13,13):
            md.line((ox+px+side,py,ox+sx+side,sy),fill=INK,width=5)
            md.line((ox+px+side,py,ox+sx+side,sy),fill=CREAM_RAMP[10+frame%6],width=2)
            for i,color in enumerate(CREAM_RAMP):
                u=(i+.5)/16
                rx=round(px+side+(sx-px)*u);ry=round(py+(sy-py)*u)
                rect(md,(ox+rx,ry,ox+rx+1,ry+1),color)
        rect(md,(ox+sx-23,sy-3,ox+sx+23,sy+7),INK)
        rect(md,(ox+sx-19,sy-1,ox+sx+19,sy+4),WOOD)
        rect(md,(ox+sx-16,sy,ox+sx+16,sy+1),WOOD_RAMP[12])
        for i,color in enumerate(WOOD_RAMP):rect(md,(ox+sx-18+i*2,sy+2,ox+sx-17+i*2,sy+3),color)
        for i,color in enumerate(RED_RAMP):rect(md,(ox+sx-16+i*2,sy-1,ox+sx-15+i*2,sy),color)
        for i,color in enumerate(AMBER_RAMP):
            bx=sx-22 if i<8 else sx+20;by=sy-2+(i%8)
            rect(md,(ox+bx,by,ox+bx+1,by+1),color)
        for i,color in enumerate(TEAL_RAMP):
            rect(md,(ox+sx-8+i,sy+5,ox+sx-8+i,sy+5),color)
    motion.save(OUT/"lobby-swing-motion-pixel-v1.png",optimize=True)
    print("LOBBY_PLAYGROUNDS_OK lobby-playgrounds-pixel-v2.png cells=4 160x128 swing_frames=8")

if __name__=="__main__":
    build_shop("lobby-companion-shop-pixel-v1.png",192,144)
    build_shop("lobby-companion-shop-small-pixel-v1.png",144,108)
    build_playgrounds_v2()
