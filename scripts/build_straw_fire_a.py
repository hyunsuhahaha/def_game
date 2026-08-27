"""Bake selected concept A into a transparent 8-frame runtime fire atlas."""
from pathlib import Path

import numpy as np
from PIL import Image,ImageDraw

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/"assets/fx/straw-bale/concepts/straw-fire-concept-a-sheet-v4.png"
DEST=ROOT/"assets/fx/straw-bale/straw-fire-a-atlas-pixel-v4.png"
PREVIEW=ROOT/"docs/previews/straw-fire-concepts/straw-fire-concept-a-runtime.gif"
CELL_W,CELL_H,FRAMES=256,112,8
PALETTE=np.asarray([(58,12,12),(116,22,15),(190,43,12),(242,91,10),(255,174,25),(255,232,89),(255,252,211)],dtype=np.int32)

def detached(draw,frame):
    # Three looping fragment paths: broad broken tongues, detached for 3–4 frames.
    paths={
        0:[(46,43,8,15,2),(49,27,7,13,2),(53,15,5,9,1)],
        1:[(172,49,9,16,2),(168,32,8,14,2),(164,19,7,11,1),(160,10,5,8,0)],
        2:[(222,38,8,14,2),(226,23,7,12,2),(231,12,5,8,1)],
    }
    starts={0:0,1:2,2:5}
    for key,path in paths.items():
        age=(frame-starts[key])%FRAMES
        if age>=len(path):continue
        x,y,w,h,hot=path[age]
        # Stepped silhouettes keep these readable as torn-off flame tongues,
        # instead of square embers, after the nearest-neighbour game scale.
        outer=[(x+2,y-1),(x+w-2,y+1),(x+w,y+h//3),(x+w-2,y+h),
               (x+1,y+h-2),(x-1,y+h//2)]
        draw.polygon(outer,fill=tuple(PALETTE[0])+(255,))
        inner=[(x+2,y+1),(x+w-3,y+3),(x+w-2,y+h//3),(x+w-3,y+h-2),
               (x+2,y+h-4),(x+1,y+h//2)]
        draw.polygon(inner,fill=tuple(PALETTE[1+hot])+(255,))
        if hot>0 and w>=6:
            draw.polygon([(x+3,y+4),(x+w-4,y+5),(x+w-4,y+h-5),(x+3,y+h-6)],
                         fill=tuple(PALETTE[3+hot])+(255,))
        if age==len(path)-1:
            draw.rectangle((x+w+3,y-3,x+w+4,y-1),fill=tuple(PALETTE[2])+(255,))

def main():
    sheet=Image.open(SOURCE).convert("RGB")
    if sheet.size!=(1536,1024):raise SystemExit(f"unexpected sheet {sheet.size}")
    atlas=Image.new("RGBA",(CELL_W*FRAMES,CELL_H))
    preview=[]
    for frame in range(FRAMES):
        row,col=divmod(frame,2)
        raw=sheet.crop((col*768,row*256,(col+1)*768,(row+1)*256)).crop((10,8,756,248)).resize((CELL_W,82),Image.Resampling.NEAREST)
        data=np.asarray(raw).copy();r,g,b=data[:,:,0],data[:,:,1],data[:,:,2]
        mask=(r>42)&(r>b*1.22)&(r>=g*.70)
        rgb=data.astype(np.int32)
        distance=((rgb[:,:,None,:]-PALETTE[None,None,:,:])**2).sum(axis=3)
        mapped=PALETTE[distance.argmin(axis=2)].astype(np.uint8)
        rgba=np.zeros((82,CELL_W,4),np.uint8);rgba[:,:,:3]=mapped;rgba[:,:,3]=mask.astype(np.uint8)*255
        cell=Image.new("RGBA",(CELL_W,CELL_H));cell.alpha_composite(Image.fromarray(rgba,"RGBA"),(0,24))
        detached(ImageDraw.Draw(cell),frame)
        atlas.alpha_composite(cell,(frame*CELL_W,0));preview.append(cell.resize((512,224),Image.Resampling.NEAREST))
    atlas.save(DEST)
    PREVIEW.parent.mkdir(parents=True,exist_ok=True)
    preview[0].save(PREVIEW,save_all=True,append_images=preview[1:],duration=78,loop=0,disposal=2)
    print(f"STRAW_FIRE_A_V4_OK atlas={atlas.size} frames={FRAMES} detached=3")

if __name__=="__main__":main()
