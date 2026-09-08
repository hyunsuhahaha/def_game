"""Bake a horizontal 3D cylinder onto the game's tilted ground; never rotate a billboard."""
from pathlib import Path
import math
from PIL import Image, ImageDraw
from build_construction_assets import CONCRETE
OUT=Path(__file__).resolve().parents[1]/'assets/construction'
W,H=640,544
def pipe(direction,frame,half):
    a=direction*math.tau/16;nx,ny=math.cos(a),math.sin(a)
    ux,uy=-ny,nx
    def point(s,t,r=50):
        return (round(320+ux*s+nx*r*math.cos(t)),round(300+.76*(uy*s+ny*r*math.cos(t))-50-r*math.sin(t)))
    im=Image.new('RGBA',(W,H));d=ImageDraw.Draw(im)
    faces=[]
    for i in range(48):
        t=i*math.tau/48;t2=(i+1)*math.tau/48
        # Front-facing surface in the fixed elevated camera.
        if ny*math.cos((t+t2)/2)*.76+math.sin((t+t2)/2)<=0:continue
        shade=max(2,min(15,round(8+5*math.sin(t)-2*nx*math.cos(t))))
        for j in range(24):
            s=-half+j*half/12;s2=s+half/12
            mark=(i-frame*6)%48
            material=shade-2 if (mark in (4,5,24) and j%5<3) or j in (7,16) else shade
            poly=[point(s,t),point(s2,t),point(s2,t2),point(s,t2)]
            faces.append((sum(p[1] for p in poly)/4,poly,CONCRETE[max(1,material)]))
    for _,poly,color in sorted(faces):d.polygon(poly,fill=color)
    # Aggregate pits are attached to the rotating material coordinates, with
    # small lit lips and dark cavities instead of stationary screen-space noise.
    for j in range(54):
        s=-half+6+(j*37)%(int(half*2)-12)
        for k in range(8):
            t=k*math.tau/8+j*.73+frame*math.tau/8
            if ny*math.cos(t)*.76+math.sin(t)<.2:continue
            x,y=point(s,t,50.3)
            d.line((x,y,x+2+j%3,y),fill=CONCRETE[5+j%3])
            d.point((x,y-1),fill=CONCRETE[14])
    # Only the near end is visible, with a deep inner wall, not two flat circles.
    end=half if uy>=0 else -half
    outer=[point(end,i*math.tau/64)for i in range(64)]
    inner=[point(end,i*math.tau/64,33)for i in range(64)]
    if abs(uy)>.06:
        d.polygon(outer,fill=CONCRETE[10],outline=CONCRETE[2])
        d.polygon(inner,fill=CONCRETE[0])
        for i in range(64):
            t=i*math.tau/64;t2=(i+1)*math.tau/64
            d.polygon([point(end,t),point(end,t2),point(end,t2,36),point(end,t,36)],fill=CONCRETE[12 if math.sin(t)>0 else 5])
    return im
for tier in range(3):
    sheet=Image.new('RGBA',(W*8,H*16))
    for direction in range(16):
        for frame in range(8):sheet.paste(pipe(direction,frame,150+tier*50),(frame*W,direction*H))
    sheet.save(OUT/f'grounded-concrete-pipe-{tier+1}-atlas-v3.png')
# Authored spreading dust lobes, stepped alpha and ballistic grit in eight frames.
sheet=Image.new('RGBA',(192*8,128))
for f in range(8):
    im=Image.new('RGBA',(192,128));d=ImageDraw.Draw(im);u=f/7
    for i in range(9):
        x=96+(i-4)*(8+u*10);y=101-(1-abs(i-4)/6)*u*48
        radius=(8+u*15)*(1-abs(i-4)*.08)
        for layer,color in enumerate(((77,64,45),(116,99,70),(153,134,96))):
            r=radius-layer*3
            poly=[(round(x+math.cos(k*math.tau/9)*r),round(y+math.sin(k*math.tau/9)*r*.65-layer*2)) for k in range(9)]
            d.polygon(poly,fill=color+(round((1-u)*160)//16*16,))
    for i in range(12):
        x=96+math.cos(i*2.4)*u*88;y=106-math.sin(u*math.pi)*(12+i%4*8)
        d.rectangle((int(x),int(y),int(x)+2,int(y)+2),fill=(115,103,76,round((1-u)*255)))
    sheet.paste(im,(f*192,0))
sheet.save(OUT/'concrete-contact-dust-atlas-v1.png')
print('GROUNDED_PIPE_ASSETS_OK 16 directions, 8 roll frames, 3 lengths, contact dust')
