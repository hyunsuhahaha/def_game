"""Build the genius mole's cinematic brute-force FX atlas and preview."""
from pathlib import Path
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/"assets/fx/brute-force/concepts/brute-force-source-board-v1.png"
DEST=ROOT/"assets/fx/brute-force/brute-force-atlas-pixel-v1.png"
PREVIEW=ROOT/"docs/previews/brute-force-runtime-v1.png"
GROUND=ROOT/"assets/forest-ground-tile-v1.png"
CELL_W,CELL_H=128,160

def clean(image):
    data=np.asarray(image.convert("RGBA")).copy();rgb=data[:,:,:3].astype(np.int16)
    mask=(rgb.min(axis=2)>=225)&(rgb.max(axis=2)-rgb.min(axis=2)<=18);data[mask,3]=0
    data[:,:,3]=np.where(data[:,:,3]>=92,255,0).astype(np.uint8);data[data[:,:,3]==0,:3]=0
    return Image.fromarray(data,"RGBA")

def build():
    source=Image.open(SOURCE).convert("RGBA");assert source.size==(1536,1024),source.size;source=clean(source)
    atlas=Image.new("RGBA",(768,320),(0,0,0,0))
    for row in range(2):
        for col in range(6):
            raw=source.crop((col*256,row*512,(col+1)*256,(row+1)*512));box=raw.getchannel("A").getbbox();assert box,(row,col);raw=raw.crop(box)
            maximum=(122,150) if row==0 else (122,112)
            scale=min(maximum[0]/raw.width,maximum[1]/raw.height)
            raw=raw.resize((round(raw.width*scale),round(raw.height*scale)),Image.Resampling.LANCZOS)
            data=np.asarray(raw).copy();data[:,:,3]=np.where(data[:,:,3]>=88,255,0).astype(np.uint8);data[data[:,:,3]==0,:3]=0;raw=Image.fromarray(data,"RGBA")
            x=col*CELL_W+(CELL_W-raw.width)//2;y=row*CELL_H+150-raw.height
            atlas.alpha_composite(raw,(x,y))
    alpha=atlas.getchannel("A");atlas=atlas.quantize(colors=112,method=Image.Quantize.FASTOCTREE,dither=Image.Dither.NONE).convert("RGBA");atlas.putalpha(alpha)
    DEST.parent.mkdir(parents=True,exist_ok=True);atlas.save(DEST)
    ground=Image.open(GROUND).convert("RGB").resize((960,440),Image.Resampling.BICUBIC).convert("RGBA")
    for i in range(6):
        sprite=atlas.crop((i*128,0,(i+1)*128,160)).resize((96,120),Image.Resampling.NEAREST);ground.alpha_composite(sprite,(65+i*145,230-112))
    for i in range(6):
        sprite=atlas.crop((i*128,160,(i+1)*128,320)).resize((76,95),Image.Resampling.NEAREST);ground.alpha_composite(sprite,(95+i*142,380-90))
    ground.save(PREVIEW);print(f"saved={DEST} size={atlas.size} cells=12")

if __name__=="__main__":build()
