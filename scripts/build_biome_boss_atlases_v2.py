"""Build coherent 6x2 cartoon boss atlases from the locked v2 cutouts."""
from pathlib import Path
from PIL import Image
import math

ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/'assets/enemies/biome-bosses/concepts/cartoon-v2'
OUT=ROOT/'assets/enemies/biome-bosses/arcade-v2'
CELL,FOOT=384,370
SPECS={
 'beginner':dict(width=150,maxw=334,maxh=344),
 'forest':dict(width=198,maxw=364,maxh=360),
 'mangrove':dict(width=220,maxw=368,maxh=330),
 'madagascar':dict(width=178,maxw=340,maxh=350),
 'island':dict(width=196,maxw=356,maxh=344),
}

def locked_model(name,spec):
 im=Image.open(SRC/f'{name}-source-v2.png').convert('RGBA');box=im.getchannel('A').getbbox();im=im.crop(box)
 scale=min(spec['maxw']/im.width,spec['maxh']/im.height)
 im=im.resize((round(im.width*scale),round(im.height*scale)),Image.Resampling.LANCZOS)
 # Hard pixel edge and a limited authored palette; no smooth alpha survives.
 a=im.getchannel('A').point(lambda v:255 if v>=150 else 0)
 rgb=im.convert('RGB').quantize(colors=96,method=Image.Quantize.FASTOCTREE).convert('RGB')
 im=rgb.convert('RGBA');im.putalpha(a)
 canvas=Image.new('RGBA',(CELL,CELL));canvas.alpha_composite(im,((CELL-im.width)//2,FOOT-im.height))
 return canvas

def transform(base,frame,action,name):
 # One locked model, animated on the same baseline. Horizontal band offsets
 # articulate foliage/tail/arms without inventing new independent drawings.
 out=Image.new('RGBA',(CELL,CELL));phase=frame/6*math.tau
 amp=(2 if not action else (5 if name in ('mangrove','madagascar','island') else 4))
 for y in range(0,CELL,4):
  weight=max(0,(FOOT-y)/FOOT)
  dx=round(math.sin(phase+y*.018)*amp*weight)
  if action: dx+=round(math.sin(phase)*3*(1-weight))
  band=base.crop((0,y,CELL,min(CELL,y+4)))
  out.alpha_composite(band,(dx,y))
 if action:
  seq=[(0,0,1,1),(-2,1,1.02,.98),(-5,2,1.05,.95),(5,-3,.97,1.04),(3,-1,.99,1.01),(0,0,1,1)][frame]
 else: seq=[(0,0,1,1),(0,-1,1.005,.995),(1,-2,1.01,.99),(0,-1,1.005,.995),(-1,0,1,1),(0,1,.995,1.005)][frame]
 ox,oy,sx,sy=seq
 if sx!=1 or sy!=1:
  box=out.getchannel('A').getbbox()
  if box:
   crop=out.crop(box);nw,nh=round(crop.width*sx),round(crop.height*sy);crop=crop.resize((nw,nh),Image.Resampling.NEAREST)
   out=Image.new('RGBA',(CELL,CELL));out.alpha_composite(crop,(CELL//2-nw//2,FOOT-nh+oy))
 else:
  shifted=Image.new('RGBA',(CELL,CELL));shifted.alpha_composite(out,(ox,oy));out=shifted
 return out

def main():
 OUT.mkdir(parents=True,exist_ok=True)
 for name,spec in SPECS.items():
  base=locked_model(name,spec);atlas=Image.new('RGBA',(CELL*6,CELL*2))
  for row in range(2):
   for frame in range(6): atlas.alpha_composite(transform(base,frame,row==1,name),(frame*CELL,row*CELL))
  path=OUT/f'{name}-boss-atlas-v2.png';atlas.save(path,optimize=True)
  colors=len({p[:3] for p in atlas.getdata() if p[3]})
  print('WROTE',path.relative_to(ROOT),atlas.size,'colors',colors,'worldWidth',spec['width'])

if __name__=='__main__':main()
