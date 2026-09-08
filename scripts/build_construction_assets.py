"""Bake crane steel and concrete pipe animation on their native pixel grids."""
from pathlib import Path
import math
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/construction'

def ramp(dark,light):
    return [tuple(round(a+(b-a)*i/15) for a,b in zip(dark,light))+(255,) for i in range(16)]

GOLD=ramp((74,43,22),(255,220,111))
STEEL=ramp((29,40,47),(186,202,204))
CONCRETE=ramp((47,53,51),(222,222,204))
GLASS=ramp((19,52,62),(157,207,199))

def beam(im,a,b,width=7,colors=GOLD):
    d=ImageDraw.Draw(im)
    d.line([a,b],fill=colors[0],width=width+4)
    d.line([a,b],fill=colors[6],width=width)
    d.line([(a[0]-1,a[1]-1),(b[0]-1,b[1]-1)],fill=colors[13],width=max(1,width//3))

def plate(im,box,colors):
    d=ImageDraw.Draw(im);x0,y0,x1,y1=box
    for y in range(y0,y1+1):
        i=round(12-(y-y0)/max(1,y1-y0)*8)
        d.line([(x0,y),(x1,y)],fill=colors[i])
        if y%4==0:d.line([(x0+2,y),(x1-2,y)],fill=colors[min(15,i+1)])
    d.rectangle(box,outline=colors[0],width=2)
    d.line([(x0+2,y0+2),(x1-2,y0+2)],fill=colors[15],width=2)

def tower():
    im=Image.new('RGBA',(256,576));d=ImageDraw.Draw(im)
    for box in [(18,527,103,558),(153,527,238,558)]:plate(im,box,CONCRETE)
    for x in [65,191]:beam(im,(128,476),(x,535),14,STEEL)
    for y in range(115,501,55):
        beam(im,(92,y),(164,y+55),6);beam(im,(164,y),(92,y+55),6)
        beam(im,(91,y),(165,y),8)
    beam(im,(88,105),(88,528),12);beam(im,(168,105),(168,528),12)
    plate(im,(105,120,110,524),STEEL);plate(im,(128,120,133,524),STEEL)
    for y in range(125,520,15):beam(im,(108,y),(130,y),2,STEEL)
    plate(im,(65,84,190,119),STEEL)
    plate(im,(126,125,223,204),GOLD)
    plate(im,(136,135,214,174),GLASS)
    d.polygon([(140,139),(178,139),(140,165)],fill=GLASS[13])
    d.line([(177,137),(177,174)],fill=GOLD[2],width=4)
    plate(im,(141,181,212,195),STEEL)
    for x in range(145,210,9):d.line([(x,182),(x,193)],fill=STEEL[1],width=2)
    beam(im,(86,90),(126,18),6);beam(im,(170,90),(126,18),6)
    for y in range(126,513,55):
        for x in [88,168]:
            d.ellipse((x-4,y-4,x+4,y+4),fill=STEEL[2]);d.point((x-1,y-2),fill=STEEL[15])
    return im

def boom():
    im=Image.new('RGBA',(768,96))
    for x in range(12,735,48):
        beam(im,(x,29),(x+48,65),4);beam(im,(x,65),(x+48,29),4)
    beam(im,(4,26),(758,26),9);beam(im,(4,67),(758,67),9)
    for x in range(6,758,48):beam(im,(x,28),(x,66),4)
    plate(im,(10,34,102,59),CONCRETE)
    plate(im,(666,65,716,85),STEEL)
    return im

def pipe(frame):
    im=Image.new('RGBA',(192,192));d=ImageDraw.Draw(im)
    # Cylindrical side: quantized light follows curvature, with sparse aggregate
    # seams in material coordinates instead of unstructured texture noise.
    for y in range(20,170):
        yy=(y-95)/75
        span=math.sqrt(max(0,1-yy*yy))
        shade=max(1,min(15,round(5+8*span-3*yy)))
        d.line([(90,y),(140+round(35*span),y)],fill=CONCRETE[shade])
    d.ellipse((18,20,162,170),fill=CONCRETE[2])
    for inset in range(3,18):
        d.arc((18+inset,20+inset,162-inset,170-inset),130,310,fill=CONCRETE[min(15,7+inset//2)],width=2)
        d.arc((18+inset,20+inset,162-inset,170-inset),310,490,fill=CONCRETE[4+inset//4],width=2)
    d.ellipse((48,50,132,140),fill=CONCRETE[0])
    d.arc((49,51,131,139),0,180,fill=CONCRETE[11],width=4)
    d.arc((51,53,129,137),180,355,fill=CONCRETE[3],width=6)
    angle=frame*math.pi*2/12
    for i in range(8):
        a=angle+i*math.pi/4;x=90+math.cos(a)*57;y=95+math.sin(a)*59
        d.line([(round(x),round(y)),(round(x+math.cos(a)*7),round(y+math.sin(a)*7))],fill=STEEL[3],width=3)
        d.point((round(x)-1,round(y)-1),fill=CONCRETE[15])
    for i in range(36):
        a=angle+i*2.399;r=53+(i%4)*4
        x,y=round(90+math.cos(a)*r),round(95+math.sin(a)*r)
        d.rectangle((x,y,x+1,y+1),fill=CONCRETE[5+i%5])
    return im

def build():
    OUT.mkdir(parents=True,exist_ok=True)
    tower().save(OUT/'tower-crane-pixel-v1.png')
    boom().save(OUT/'tower-jib-pixel-v1.png')
    sheet=Image.new('RGBA',(192*12,192))
    for i in range(12):sheet.paste(pipe(i),(i*192,0))
    sheet.save(OUT/'concrete-pipe-roll-atlas-v1.png')
    print('CONSTRUCTION_ASSETS_OK native mast=256x576 jib=768x96 pipe=12x192x192')

if __name__=='__main__':build()
