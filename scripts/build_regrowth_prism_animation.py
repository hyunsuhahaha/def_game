"""Author a seamless 24-frame rotating prism atlas for regeneration totems."""
from pathlib import Path
import math
from PIL import Image,ImageDraw

ROOT=Path(__file__).resolve().parents[1]
CELL,FRAMES=64,24
OUT=ROOT/'assets/enemies/arcade/regrowth-prism-rotation-atlas-v1.png'
GIF=ROOT/'docs/previews/regrowth-prism-v1-motion.gif'
SHEET=ROOT/'docs/previews/regrowth-prism-v1-contact-sheet.png'
PALETTES=[
    ((13,42,35),(26,111,93),(63,202,167),(192,255,222),(240,214,112)),
    ((8,39,44),(11,116,119),(48,220,209),(207,255,248),(124,206,169)),
    ((52,33,10),(133,87,18),(210,168,43),(255,244,145),(165,210,69)),
    ((8,42,55),(9,132,157),(42,220,229),(220,255,250),(255,122,91)),
]

def pixel(draw,x,y,color,size=1):
    draw.rectangle((round(x)-size//2,round(y)-size//2,round(x)+(size-1)//2,round(y)+(size-1)//2),fill=color)

def broken_orbit(draw,cx,cy,rx,ry,phase,color,back=False):
    # Deliberately separated pixel clusters: an authored orbit, not a smooth vector ellipse.
    for step in range(72):
        a=step/72*math.tau
        if ((step+int(phase*11))//9)%2==0 and ((math.sin(a)<0)==back):
            x=cx+math.cos(a)*rx;y=cy+math.sin(a)*ry
            pixel(draw,x,y,color,1 if step%3 else 2)

def make_frame(row,index):
    dark,shadow,mid,light,accent=PALETTES[row]
    frame=Image.new('RGBA',(CELL,CELL));draw=ImageDraw.Draw(frame)
    phase=index/FRAMES*math.tau;cx,cy=32,31
    # Rear orbit is drawn before the solid crystal.
    broken_orbit(draw,cx,cy,25,8,phase,(*shadow,210),True)
    broken_orbit(draw,cx,cy,19,12,-phase*.75,(*accent,190),True)
    facing=math.cos(phase);half=2+round(abs(facing)*12);h=19
    outline=(*dark,255)
    draw.polygon([(cx,cy-h-2),(cx+half+3,cy-1),(cx,cy+h+2),(cx-half-3,cy-1)],fill=outline)
    left,right=(shadow,mid) if facing>=0 else (mid,shadow)
    draw.polygon([(cx,cy-h),(cx-1,cy+1),(cx,cy+h),(cx-half-1,cy-1)],fill=(*left,255))
    draw.polygon([(cx,cy-h),(cx+half+1,cy-1),(cx,cy+h),(cx-1,cy+1)],fill=(*right,255))
    # A highlight travels across the visible facet as the prism turns.
    hx=cx+round(facing*max(1,half*.42))
    draw.line((hx,cy-h+4,hx,cy+3),fill=(*light,255),width=2)
    pixel(draw,hx-1,cy-h+5,(*accent,255),2)
    draw.line((cx,cy+4,cx,cy+h-3),fill=(*mid,255),width=1)
    # Front orbit and opposed beads complete the depth cue.
    broken_orbit(draw,cx,cy,25,8,phase,(*shadow,235),False)
    broken_orbit(draw,cx,cy,19,12,-phase*.75,(*accent,215),False)
    for offset,radius,color in ((0,25,light),(math.pi,19,accent)):
        a=phase+offset;x=cx+math.cos(a)*radius;y=cy+math.sin(a)*(8 if radius==25 else 12)
        pixel(draw,x,y,(*dark,255),5);pixel(draw,x,y,(*color,255),3);pixel(draw,x-1,y-1,(*light,255),1)
    # One tiny detached glint moves on a slower seamless loop.
    a=-phase*.5+row*.7;pixel(draw,cx+math.cos(a)*28,cy-22+math.sin(a)*3,(*light,220),2)
    return frame

def main():
    atlas=Image.new('RGBA',(CELL*FRAMES,CELL*4));rows=[]
    for row in range(4):
        frames=[]
        for index in range(FRAMES):
            frame=make_frame(row,index);frames.append(frame);atlas.paste(frame,(index*CELL,row*CELL),frame)
        rows.append(frames)
    OUT.parent.mkdir(parents=True,exist_ok=True);atlas.save(OUT,optimize=True)
    # Forest row GIF at 4x nearest shows the exact 20 fps runtime cadence.
    gif_frames=[f.resize((CELL*4,CELL*4),Image.Resampling.NEAREST) for f in rows[0]]
    GIF.parent.mkdir(parents=True,exist_ok=True)
    gif_frames[0].save(GIF,save_all=True,append_images=gif_frames[1:],duration=50,loop=0,disposal=2)
    sheet=Image.new('RGBA',(6*CELL*4,4*CELL*4),(46,66,37,255))
    for row in range(4):
        for col,index in enumerate((0,4,8,12,16,20)):
            frame=rows[row][index].resize((CELL*4,CELL*4),Image.Resampling.NEAREST)
            sheet.alpha_composite(frame,(col*CELL*4,row*CELL*4))
    sheet.convert('RGB').save(SHEET,quality=95)
    print('REGROWTH_PRISM_ATLAS_OK',OUT.relative_to(ROOT),atlas.size,'frames=24 rows=4 fps=20')

if __name__=='__main__':main()
