from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/"assets/fx/concepts/tree-damage-source-v1.png"
PREVIEW=ROOT/"docs/previews/tree-destruction-v1-3x.png"
CELL=160
TREE_SPECS={"broadleaf":(154,28),"pine":(174,22),"birch":(160,19),"maple":(171,25)}

def damaged_tree(name,stage):
    im=Image.open(ROOT/"assets/trees"/f"{name}-tree-cartoon-v3.png").convert("RGBA")
    px=im.load(); cy,band=TREE_SPECS[name]
    depth=(5,10,16)[stage-1]; half=(6,10,14)[stage-1]
    heart=(230,166,85,255); heart_hi=(255,211,128,255); dark=(83,43,24,255)
    for y in range(cy-half,cy+half+1):
        row=[x for x in range(max(0,im.width//2-band),min(im.width,im.width//2+band+1)) if px[x,y][3]>0]
        if not row: continue
        edge=max(row); cut=max(0,round(depth*(1-abs(y-cy)/(half+1))))
        for x in range(edge-cut+1,edge+1): px[x,y]=(0,0,0,0)
        boundary=edge-cut
        if cut>0 and boundary>=0:
            px[boundary,y]=dark
            if boundary-1>=0: px[boundary-1,y]=heart
            if cut>5 and boundary-2>=0: px[boundary-2,y]=heart_hi if (y-cy)%4==0 else heart
    # A few restrained chips belong to the cut itself, not a second stump pasted on top.
    for n in range(stage):
        x=im.width//2+band+4+n*4; y=cy-5+n*6
        if 1<=x<im.width-2 and 1<=y<im.height-2:
            for yy in range(y,y+2):
                for xx in range(x,x+3): px[xx,yy]=heart if xx<x+2 else dark
    return im

def main():
    source=Image.open(SOURCE).convert("RGBA")
    sheet=Image.new("RGBA",(CELL*4,CELL))
    for i in range(4):
        item=source.crop((i*source.width//4,0,(i+1)*source.width//4,source.height))
        item.putalpha(item.getchannel("A").point(lambda a:255 if a>=135 else 0))
        item=item.crop(item.getbbox())
        item.thumbnail((142,146),Image.Resampling.LANCZOS)
        rgb=item.convert("RGB").quantize(colors=72,method=Image.Quantize.MEDIANCUT).convert("RGB")
        rgb.putalpha(item.getchannel("A").point(lambda a:255 if a>=90 else 0))
        sheet.alpha_composite(rgb,(i*CELL+(CELL-rgb.width)//2,154-rgb.height))
    # Keep only the useful final burst from the concept sheet at runtime.
    burst=sheet.crop((CELL*3,0,CELL*4,CELL));burst_path=ROOT/"assets/fx/tree-break-burst-v1.png";burst_path.parent.mkdir(parents=True,exist_ok=True);burst.save(burst_path)
    damage_dir=ROOT/"assets/trees/damage";damage_dir.mkdir(parents=True,exist_ok=True)
    for name in TREE_SPECS:
        for stage in range(1,4): damaged_tree(name,stage).save(damage_dir/f"{name}-damage{stage}-v1.png")
    PREVIEW.parent.mkdir(parents=True,exist_ok=True)
    board=Image.new("RGBA",(820,980),(31,46,23,255))
    for row,name in enumerate(TREE_SPECS):
        frames=[Image.open(ROOT/"assets/trees"/f"{name}-tree-cartoon-v3.png").convert("RGBA")]+[damaged_tree(name,s) for s in range(1,4)]
        for col,frame in enumerate(frames):
            frame.thumbnail((180,220),Image.Resampling.NEAREST)
            board.alpha_composite(frame,(col*200+(200-frame.width)//2,row*240+220-frame.height))
    board.save(PREVIEW)

if __name__=="__main__":main()
