"""Bake the authored six-pose bee into a fixed-anchor transparent pixel atlas."""
from pathlib import Path
import numpy as np
from PIL import Image, ImageFilter

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'assets/fx/bees/concepts/bee-flight-source-v1.png'
DEST=ROOT/'assets/fx/bees/bee-flight-cartoon-pixel-v1.png'
PREVIEW=ROOT/'docs/previews/bee-flight-cartoon-pixel-v1.png'
FRAMES,CELL=6,96

def main():
    source=Image.open(SOURCE).convert('RGB')
    if source.width%FRAMES: raise SystemExit(f'bad source width {source.size}')
    sw=source.width//FRAMES
    masks=[]
    cells=[]
    union=[sw,source.height,0,0]
    for i in range(FRAMES):
        cell=source.crop((i*sw,0,(i+1)*sw,source.height))
        arr=np.asarray(cell)
        # Generated backing is exact/near black. Preserve the authored brown-black outline.
        alpha=(arr.max(axis=2)>7).astype(np.uint8)*255
        # Keep the main connected bee and discard isolated background specks.
        import cv2
        count,labels,stats,_=cv2.connectedComponentsWithStats(alpha,8)
        if count<=1: raise SystemExit(f'frame {i} has no bee')
        largest=1+np.argmax(stats[1:,cv2.CC_STAT_AREA])
        alpha=np.where(labels==largest,255,0).astype(np.uint8)
        box=Image.fromarray(alpha).getbbox()
        union=[min(union[0],box[0]),min(union[1],box[1]),max(union[2],box[2]),max(union[3],box[3])]
        cells.append(cell);masks.append(Image.fromarray(alpha,'L'))
    # One union crop and one scale keep body/feet/head anchors stable while wings flap.
    pad=8;box=(max(0,union[0]-pad),max(0,union[1]-pad),min(sw,union[2]+pad),min(source.height,union[3]+pad))
    cw,ch=box[2]-box[0],box[3]-box[1]
    scale=min(88/cw,88/ch)
    size=(round(cw*scale),round(ch*scale))
    atlas=Image.new('RGBA',(CELL*FRAMES,CELL))
    preview=Image.new('RGBA',(CELL*FRAMES,CELL))
    for i,(rgb,alpha) in enumerate(zip(cells,masks)):
        rgba=rgb.convert('RGBA');rgba.putalpha(alpha)
        sprite=rgba.crop(box).resize(size,Image.Resampling.LANCZOS)
        hard=sprite.getchannel('A').point(lambda v:255 if v>=96 else 0)
        quant=sprite.convert('RGB').quantize(colors=96,method=Image.Quantize.FASTOCTREE,dither=Image.Dither.NONE).convert('RGBA')
        quant.putalpha(hard)
        canvas=Image.new('RGBA',(CELL,CELL))
        x=(CELL-size[0])//2;y=(CELL-size[1])//2
        # A one-native-pixel colored outline keeps the tiny bee readable on foliage.
        placed=Image.new('L',(CELL,CELL));placed.paste(hard,(x,y))
        dilated=placed.filter(ImageFilter.MaxFilter(3))
        outline=Image.new('RGBA',(CELL,CELL),(38,23,12,0))
        outline.putalpha(Image.fromarray(np.maximum(0,np.asarray(dilated,dtype=np.int16)-np.asarray(placed,dtype=np.int16)).astype(np.uint8)))
        canvas.alpha_composite(outline);canvas.alpha_composite(quant,(x,y))
        atlas.alpha_composite(canvas,(i*CELL,0));preview.alpha_composite(canvas,(i*CELL,0))
    DEST.parent.mkdir(parents=True,exist_ok=True);atlas.save(DEST)
    PREVIEW.parent.mkdir(parents=True,exist_ok=True);preview.resize((CELL*FRAMES*2,CELL*2),Image.Resampling.NEAREST).save(PREVIEW)
    colors={p[:3] for p in atlas.getdata() if p[3]}
    print(f'BEE_ART_V1_OK source={source.size} atlas={atlas.size} frames={FRAMES} colors={len(colors)}')
if __name__=='__main__':main()
