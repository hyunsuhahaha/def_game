"""Build the mole's persistent disturbed-ground trail atlas and preview."""
from pathlib import Path
import math
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/"assets/fx/mole-burrow/concepts/mole-burrow-cutout-source-v1.png"
DEST=ROOT/"assets/fx/mole-burrow/mole-burrow-trail-atlas-pixel-v1.png"
PREVIEW=ROOT/"docs/previews/mole-burrow-trail-runtime-v1.png"
GROUND=ROOT/"assets/forest-ground-tile-v1.png"
COLS,ROWS,SRC,CELL=6,2,(256,512),128

def clean(image):
    data=np.asarray(image.convert("RGBA")).copy();rgb=data[:,:,:3].astype(np.int16)
    mask=(rgb.min(axis=2)>=225)&(rgb.max(axis=2)-rgb.min(axis=2)<=18);data[mask,3]=0
    data[:,:,3]=np.where(data[:,:,3]>=96,255,0).astype(np.uint8);data[data[:,:,3]==0,:3]=0
    return Image.fromarray(data,"RGBA")

def build():
    source=Image.open(SOURCE).convert("RGBA")
    assert source.size==(1536,1024),source.size
    source=clean(source);atlas=Image.new("RGBA",(768,256),(0,0,0,0))
    for row in range(ROWS):
        for col in range(COLS):
            cell=source.crop((col*256,row*512,(col+1)*256,(row+1)*512));box=cell.getchannel("A").getbbox()
            assert box,(row,col);cell=cell.crop(box)
            maximum=(122,92) if row==0 else (118,112)
            scale=min(maximum[0]/cell.width,maximum[1]/cell.height)
            cell=cell.resize((round(cell.width*scale),round(cell.height*scale)),Image.Resampling.LANCZOS)
            data=np.asarray(cell).copy();data[:,:,3]=np.where(data[:,:,3]>=92,255,0).astype(np.uint8);data[data[:,:,3]==0,:3]=0
            cell=Image.fromarray(data,"RGBA")
            x=col*CELL+(CELL-cell.width)//2;y=row*CELL+116-cell.height
            atlas.alpha_composite(cell,(x,y))
    alpha=atlas.getchannel("A");atlas=atlas.quantize(colors=104,method=Image.Quantize.FASTOCTREE,dither=Image.Dither.NONE).convert("RGBA");atlas.putalpha(alpha)
    DEST.parent.mkdir(parents=True,exist_ok=True);atlas.save(DEST)
    ground=Image.open(GROUND).convert("RGB").resize((960,440),Image.Resampling.BICUBIC).convert("RGBA")
    entry=atlas.crop((0,128,128,256)).resize((76,76),Image.Resampling.NEAREST);ground.alpha_composite(entry,(80,192))
    for i in range(18):
        x=150+i*35;y=240+round(math.sin(i*.45)*38)
        sprite=atlas.crop(((i%6)*128,0,(i%6+1)*128,128)).resize((72,72),Image.Resampling.NEAREST)
        angle=-math.degrees(math.atan2(math.cos(i*.45)*17,35))
        sprite=sprite.rotate(angle,resample=Image.Resampling.NEAREST)
        ground.alpha_composite(sprite,(x-36,y-58))
    exit_sprite=atlas.crop((128,128,256,256)).resize((82,82),Image.Resampling.NEAREST);ground.alpha_composite(exit_sprite,(785,185))
    ground.save(PREVIEW);print(f"saved={DEST} size={atlas.size} cells=12")

if __name__=="__main__":build()
