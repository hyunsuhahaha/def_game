"""Build localised cartoon-pixel claw gouges, never a ranged beam."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"assets/fx/mole-claw/mole-claw-swipe-cartoon-pixel-v1.png"
PREVIEW=ROOT/"docs/previews/mole-claw-upgrades-v1.png"
CW,CH,FRAMES,TIERS=192,128,5,3

PALETTES=[((45,49,52,255),(224,229,230,255),(255,255,255,255)),
          ((38,43,47,255),(237,241,241,255),(255,255,255,255)),
          ((30,35,40,255),(247,249,249,255),(255,255,255,255))]

def pixel_curve(draw,points,width,color):
    draw.line(points,fill=color,width=width,joint="curve")

def bezier(p0,p1,p2,p3,amount):
    points=[]
    steps=max(2,round(22*amount))
    for i in range(steps+1):
        t=amount*i/steps; u=1-t
        x=round(u**3*p0[0]+3*u*u*t*p1[0]+3*u*t*t*p2[0]+t**3*p3[0])
        y=round(u**3*p0[1]+3*u*u*t*p1[1]+3*u*t*t*p2[1]+t**3*p3[1])
        if not points or points[-1]!=(x,y): points.append((x,y))
    return points

def make_atlas():
    atlas=Image.new("RGBA",(CW*FRAMES,CH*TIERS))
    for tier in range(TIERS):
        dark,mid,core=PALETTES[tier]
        claw_count=4
        for frame in range(FRAMES):
            cell=Image.new("RGBA",(CW,CH)); d=ImageDraw.Draw(cell)
            reveal=(frame+1)/FRAMES
            for n in range(claw_count):
                # Authored along +X. Runtime rotation can therefore use the exact
                # mole->target angle without a mysterious extra offset.
                off=-18+n*12
                p0=(35,82+off)
                p1=(58,48+off)
                p2=(112+tier*2,38+off)
                p3=(158+tier*6,58+off)
                pts=bezier(p0,p1,p2,p3,reveal)
                pixel_curve(d,pts,4,dark)
                pixel_curve(d,pts,2,mid)
                if tier>=1: pixel_curve(d,[(x+1,y-1) for x,y in pts],1,core)
                if frame>=3 and tier>=1:
                    ex,ey=pts[-1]
                    d.rectangle((ex+5,ey-2,ex+7,ey),fill=mid)
                    if tier==2: d.rectangle((ex+9,ey-7,ex+10,ey-6),fill=core)
            atlas.alpha_composite(cell,(frame*CW,tier*CH))
    return atlas

def make_preview(atlas):
    canvas=Image.new("RGB",(1120,520),(86,125,61)); d=ImageDraw.Draw(canvas)
    for x in range(0,1120,16):
        for y in range(0,520,16):
            q=3 if (x//16+y//16)%2 else -3
            d.rectangle((x,y,x+15,y+15),fill=(86+q,125+q,61+q))
    labels=["LV 1", "LV 3", "LV 5"]
    for tier in range(3):
        cell=atlas.crop((4*CW,tier*CH,5*CW,(tier+1)*CH)).resize((320,213),Image.Resampling.NEAREST)
        x=25+tier*365; y=158
        canvas.paste(cell,(x,y),cell)
        d.rectangle((x+12,88,x+118,122),fill=(19,29,20)); d.text((x+28,96),labels[tier],fill=(245,231,180))
    return canvas

def main():
    OUT.parent.mkdir(parents=True,exist_ok=True); PREVIEW.parent.mkdir(parents=True,exist_ok=True)
    atlas=make_atlas(); atlas.save(OUT); make_preview(atlas).save(PREVIEW)
    assert atlas.size==(960,384)
    print(f"MOLE_CLAW_FX_BUILD_OK atlas={atlas.size} tiers=3 frames=5")

if __name__=="__main__": main()
