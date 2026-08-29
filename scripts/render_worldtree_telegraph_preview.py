from pathlib import Path
from PIL import Image
import math

root=Path(__file__).resolve().parents[1]
base=Image.open(root/"docs/previews/forest-arcade-v3-camera072.png").convert("RGBA")
atlas=Image.open(root/"assets/fx/worldtree/worldtree-telegraphs-atlas-v1.png").convert("RGBA")
C=384;zoom=.72;frame=5

def cell(row): return atlas.crop((frame*C,row*C,(frame+1)*C,(row+1)*C))
def paste_scaled(canvas,sprite,x,y,sx,sy,ox,oy,angle=0):
    scaled=sprite.resize((max(1,round(C*sx)),max(1,round(C*sy))),Image.Resampling.NEAREST)
    anchor=(ox*sx,oy*sy)
    if angle:
        pad=Image.new("RGBA",(scaled.width*2,scaled.height*2))
        pad.alpha_composite(scaled,(scaled.width//2,scaled.height//2))
        rotated=pad.rotate(-math.degrees(angle),resample=Image.Resampling.NEAREST,expand=False)
        canvas.alpha_composite(rotated,(round(x-rotated.width/2),round(y-rotated.height/2)))
    else:
        canvas.alpha_composite(scaled,(round(x-anchor[0]),round(y-anchor[1])))

# 420-radius slam at the world-tree roots, 62-radius burst near the player.
paste_scaled(base,cell(2),270,390,420/138*zoom,420/138*zoom,192,192)
paste_scaled(base,cell(0),690,470,62/123*zoom,62/123*zoom,192,238)

# Exact swept-capsule vine: strip plus two authored endpoint discs.
x1,y1,x2,y2=470,365,710,455;dx,dy=x2-x1,y2-y1;length=math.hypot(dx,dy);angle=math.atan2(dy,dx)
paste_scaled(base,cell(1),(x1+x2)/2,(y1+y2)/2,length/340,64*2/72*zoom,192,192,angle)
cap=cell(0);cap_scale=64/123*zoom
paste_scaled(base,cap,x1,y1,cap_scale,cap_scale,192,238)
paste_scaled(base,cap,x2,y2,cap_scale,cap_scale,192,238)

out=root/"docs/previews/worldtree-telegraphs-v1-display-scale.png"
base.save(out);print(out)
