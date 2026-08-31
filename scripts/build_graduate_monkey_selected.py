"""Turn the user-approved third concept into the canonical body-only atlas.

This is deliberately source-based rather than a fresh reinterpretation: the approved
silhouette, face, fur ramp and proportions remain intact. Equipment is still detached.
"""
from pathlib import Path
from PIL import Image, ImageChops
from collections import deque

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/"docs"/"concepts"/"graduate-monkey-selected-concept-v1.png"
OUT=ROOT/"assets"/"characters"/"companions"
PREVIEW=ROOT/"docs"/"previews"
CELL=128; COLS=6

def isolate(box):
    image=Image.open(SOURCE).convert("RGBA").crop(box)
    pixels=image.load()
    # Remove only bright neutral pixels connected to the crop boundary.  A global
    # white key erased the approved eye glints and teeth as well as the checker.
    def background(x,y):
        r,g,b,_=pixels[x,y]
        return max(r,g,b)-min(r,g,b)<18 and min(r,g,b)>218
    seen=set(); queue=deque()
    for x in range(image.width):
        if background(x,0):queue.append((x,0))
        if background(x,image.height-1):queue.append((x,image.height-1))
    for y in range(image.height):
        if background(0,y):queue.append((0,y))
        if background(image.width-1,y):queue.append((image.width-1,y))
    while queue:
        x,y=queue.popleft()
        if (x,y) in seen or not background(x,y):continue
        seen.add((x,y));pixels[x,y]=(*pixels[x,y][:3],0)
        for nx,ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
            if 0<=nx<image.width and 0<=ny<image.height and (nx,ny) not in seen:queue.append((nx,ny))
    # Crop by the largest connected opaque component (the monkey), not by every
    # remaining pixel. This discards tiny dark generation specks between poses
    # while retaining eye glints and teeth located inside the monkey bounds.
    alpha=image.getchannel("A"); ap=alpha.load(); visited=set(); largest=[]
    for sy in range(image.height):
        for sx in range(image.width):
            if ap[sx,sy]==0 or (sx,sy) in visited:continue
            component=[]; q=deque([(sx,sy)]);visited.add((sx,sy))
            while q:
                x,y=q.popleft();component.append((x,y))
                for nx,ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
                    if 0<=nx<image.width and 0<=ny<image.height and ap[nx,ny]>0 and (nx,ny) not in visited:
                        visited.add((nx,ny));q.append((nx,ny))
            if len(component)>len(largest):largest=component
    xs=[p[0] for p in largest];ys=[p[1] for p in largest]
    bbox=(min(xs),min(ys),max(xs)+1,max(ys)+1)
    return image.crop(bbox)

def fit(sprite,target_h,foot=119,x_shift=0,y_shift=0):
    scale=min(target_h/sprite.height,120/sprite.width)
    width=max(1,round(sprite.width*scale))
    height=max(1,round(sprite.height*scale))
    body=sprite.resize((width,height),Image.Resampling.NEAREST)
    cell=Image.new("RGBA",(CELL,CELL),(0,0,0,0))
    x=(CELL-width)//2+x_shift; y=foot-height+y_shift
    cell.alpha_composite(body,(x,y))
    return cell

def build():
    OUT.mkdir(parents=True,exist_ok=True);PREVIEW.mkdir(parents=True,exist_ok=True)
    # Exact pose crops from the approved board: tilted idle, side scamper, joy.
    idle=isolate((65,105,555,760));side=isolate((560,125,1190,760));joy=isolate((1160,105,1725,760))
    rows=[]
    walk=[]
    for i,(bob,shift) in enumerate(((0,-1),(-2,0),(0,1),(1,0),(-2,-1),(0,1))):
        walk.append(fit(side,103,119,bob and 0 or shift,bob))
    rows.append(walk)
    # Body reactions are authored from the same three approved drawings. Weapon
    # movement remains in the detached prop layer, so no equipment is baked in.
    rows.append([fit(p,104+(i%2),119,0,(-1 if i in(1,2)else 0)) for i,p in enumerate((idle,idle,joy,joy,side,idle))])
    rows.append([fit(p,104,119,0,(-1 if i in(1,2)else 0)) for i,p in enumerate((idle,idle,idle,side,side,idle))])
    rows.append([fit(p,104+(1 if i in(3,4)else 0),119,0,(1 if i in(3,4)else 0)) for i,p in enumerate((side,side,joy,joy,side,idle))])
    atlas=Image.new("RGBA",(CELL*COLS,CELL*4),(0,0,0,0))
    for row,frames in enumerate(rows):
        for col,frame in enumerate(frames):atlas.alpha_composite(frame,(col*CELL,row*CELL))
    atlas.save(OUT/"graduate-monkey-atlas-pixel-v3.png")
    board=Image.new("RGBA",atlas.size,(35,48,27,255));board.alpha_composite(atlas)
    board.resize((atlas.width*2,atlas.height*2),Image.Resampling.NEAREST).save(PREVIEW/"graduate-monkey-v3-approved-body-2x.png")
    print(f"GRADUATE_MONKEY_SELECTED_OK {atlas.width}x{atlas.height} body_only=1 source=approved_draft_3")

if __name__=="__main__":build()
