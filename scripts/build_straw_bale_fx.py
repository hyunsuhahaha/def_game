"""Build the authored cartoon straw-bale ignition atlas and gameplay preview."""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image


ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/"assets/fx/straw-bale/concepts/straw-bale-cartoon-source-v3.png"
DESTINATION=ROOT/"assets/fx/straw-bale/straw-bale-atlas-pixel-v3.png"
ATLAS_PREVIEW=ROOT/"docs/previews/straw-bale-atlas-v3.png"
RUNTIME_PREVIEW=ROOT/"docs/previews/straw-bale-runtime-v3.png"
GROUND=ROOT/"assets/forest-ground-tile-v1.png"
COLUMNS,ROWS=6,2
SOURCE_CELL=(256,512)
CELL_W,CELL_H=128,224
BASELINE=214


def remove_checker(image:Image.Image)->Image.Image:
    data=np.asarray(image.convert("RGBA")).copy()
    rgb=data[:,:,:3].astype(np.int16)
    neutral=(rgb.max(axis=2)-rgb.min(axis=2)<=18)&(rgb.min(axis=2)>=225)
    data[neutral,3]=0
    for _ in range(2):
        alpha=data[:,:,3];clear=alpha==0;near=np.zeros_like(clear)
        near[1:]|=clear[:-1];near[:-1]|=clear[1:];near[:,1:]|=clear[:,:-1];near[:,:-1]|=clear[:,1:]
        pale=(rgb.max(axis=2)-rgb.min(axis=2)<=24)&(rgb.min(axis=2)>=210)
        data[pale&near,3]=0
    data[:,:,3]=np.where(data[:,:,3]>=96,255,0).astype(np.uint8)
    data[data[:,:,3]==0,:3]=0
    return Image.fromarray(data,"RGBA")


def fit(cell:Image.Image,row:int)->Image.Image:
    box=cell.getchannel("A").getbbox()
    if not box: raise RuntimeError("empty straw-bale source cell")
    cell=cell.crop(box)
    maximum=(120,205) if row==0 else (122,214)
    scale=min(maximum[0]/cell.width,maximum[1]/cell.height)
    size=(round(cell.width*scale),round(cell.height*scale))
    cell=cell.resize(size,Image.Resampling.LANCZOS)
    data=np.asarray(cell).copy();data[:,:,3]=np.where(data[:,:,3]>=92,255,0).astype(np.uint8)
    data[data[:,:,3]==0,:3]=0
    return Image.fromarray(data,"RGBA")


def frame(atlas:Image.Image,row:int,column:int)->Image.Image:
    return atlas.crop((column*CELL_W,row*CELL_H,(column+1)*CELL_W,(row+1)*CELL_H))


def build()->None:
    source=Image.open(SOURCE).convert("RGBA")
    expected=(SOURCE_CELL[0]*COLUMNS,SOURCE_CELL[1]*ROWS)
    if source.size!=expected: raise SystemExit(f"unexpected source size {source.size}; expected {expected}")
    source=remove_checker(source)
    atlas=Image.new("RGBA",(CELL_W*COLUMNS,CELL_H*ROWS),(0,0,0,0))
    for row in range(ROWS):
        for column in range(COLUMNS):
            raw=source.crop((column*256,row*512,(column+1)*256,(row+1)*512))
            sprite=fit(raw,row)
            x=column*CELL_W+(CELL_W-sprite.width)//2
            y=row*CELL_H+BASELINE-sprite.height
            atlas.alpha_composite(sprite,(x,y))
    alpha=atlas.getchannel("A")
    atlas=atlas.quantize(colors=112,method=Image.Quantize.FASTOCTREE,dither=Image.Dither.NONE).convert("RGBA")
    atlas.putalpha(alpha)
    DESTINATION.parent.mkdir(parents=True,exist_ok=True);atlas.save(DESTINATION)
    ATLAS_PREVIEW.parent.mkdir(parents=True,exist_ok=True)
    atlas.resize((atlas.width*2,atlas.height*2),Image.Resampling.NEAREST).save(ATLAS_PREVIEW)

    ground=Image.open(GROUND).convert("RGB").resize((960,440),Image.Resampling.BICUBIC).convert("RGBA")
    # Dry, cigarette-primed, and three loop frames at approximate runtime size.
    placements=((0,0,150,250),(0,3,365,250),(1,0,590,250),(1,2,735,250),(1,4,865,250))
    for row,column,x,y in placements:
        sprite=frame(atlas,row,column).resize((96,168),Image.Resampling.NEAREST)
        ground.alpha_composite(sprite,(x-48,y-160))
    ground.save(RUNTIME_PREVIEW)
    print(f"saved={DESTINATION} size={atlas.size} cell={CELL_W}x{CELL_H}")


if __name__=="__main__": build()
