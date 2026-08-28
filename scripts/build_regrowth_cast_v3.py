"""Author the sanctum's seed-rise cast as six fixed-grid cartoon pixel cels."""
from pathlib import Path
import math
import random
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/fx/regrowth-cast-atlas-v3.png'


def tone(color,delta,alpha=255):
    return tuple(max(0,min(255,value+delta)) for value in color)+(alpha,)


def segmented_ring(size,rx,ry,angle,phase,bright=False):
    layer=Image.new('RGBA',(size,size),(0,0,0,0));d=ImageDraw.Draw(layer)
    cx=cy=size//2
    for segment in range(14):
        start=segment*360/14+phase
        if segment%4==1: continue
        directional=round(14*math.cos(math.radians(start+8))-segment%3*3)
        dark=tone((50,45,23),directional)
        mid=tone((119,94,35),directional)
        light=tone((198,166,68) if not bright else (184,220,179),directional)
        d.arc((cx-rx,cy-ry,cx+rx,cy+ry),start,start+16,fill=dark,width=7)
        d.arc((cx-rx,cy-ry-2,cx+rx,cy+ry-2),start+1,start+14,fill=mid,width=4)
        d.arc((cx-rx,cy-ry-3,cx+rx,cy+ry-3),start+3,start+9,fill=light,width=2)
    return layer.rotate(angle,resample=Image.Resampling.NEAREST,center=(cx,cy))


def main():
    cell=256;atlas=Image.new('RGBA',(cell*6,cell),(0,0,0,0))
    rise=(0,5,12,22,15,6);opening=(0,.18,.48,1,.7,.25);strength=(.15,.3,.62,1,.7,.28)
    for frame in range(6):
        im=Image.new('RGBA',(cell,cell),(0,0,0,0));d=ImageDraw.Draw(im);rng=random.Random(7300+frame)
        cx,base_y=128,213;cy=base_y-56-rise[frame]
        # Low contained mist uses discrete pixel clusters, never a smooth runtime circle.
        for i in range(22+frame*3):
            a=(i/25)*math.tau+frame*.21;r=30+(i%6)*7
            x=round(cx+math.cos(a)*r);y=round(base_y-10+math.sin(a)*r*.18)
            delta=(i%7)*3-frame*2
            color=tone((82,151,127) if i%3 else (172,210,166),delta,190 if i%3 else 210)
            d.rectangle((x,y,x+rng.choice((2,4,6)),y+rng.choice((1,2,3))),fill=color)
        ring1=segmented_ring(cell,72,25,-13+frame*7,frame*9,strength[frame]>.6)
        ring2=segmented_ring(cell,55,18,19-frame*9,frame*13,frame==3)
        im.alpha_composite(ring1,(0,cy-128));im.alpha_composite(ring2,(0,cy-128+8))
        d=ImageDraw.Draw(im)
        # Pollen rises at the release frame and falls away during recovery.
        count=(4,7,13,24,17,8)[frame]
        for i in range(count):
            angle=rng.uniform(math.pi,math.tau);r=rng.uniform(25,88)*strength[frame]
            x=round(cx+math.cos(angle)*r);y=round(cy+math.sin(angle)*r*.8-rng.uniform(0,18))
            delta=(i%9)*2-frame
            col=tone((222,214,128) if i%3 else (141,202,168),delta)
            d.rectangle((x,y,x+rng.choice((2,3,4)),y+rng.choice((2,3))),fill=col)
        # Thin root-light forks visually connect the cast back to its grounded shrine.
        for side in (-1,1):
            x=cx+side*(18+round(opening[frame]*13))
            d.line([(cx+side*7,base_y-14),(x,base_y-4),(x+side*17,base_y)],fill=(88,131,73,255),width=3)
            d.line([(cx+side*8,base_y-15),(x,base_y-6)],fill=(207,222,143,255),width=1)
        atlas.alpha_composite(im,(frame*cell,0))
    alpha=atlas.getchannel('A')
    quantized=atlas.convert('RGB').quantize(colors=96,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE).convert('RGB')
    atlas=Image.merge('RGBA',(*quantized.split(),alpha))
    atlas.save(OUT,optimize=True)
    print(OUT.relative_to(ROOT))


if __name__=='__main__':main()
