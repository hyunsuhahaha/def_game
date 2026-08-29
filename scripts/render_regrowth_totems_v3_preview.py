"""Offscreen QA at actual runtime scale; never launches the game window."""
from pathlib import Path
import random
from PIL import Image,ImageDraw

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/previews/regrowth-totems-v3-display-scale.png'
canvas=Image.new('RGBA',(1280,720),(82,122,48,255));draw=ImageDraw.Draw(canvas);rng=random.Random(829)
for _ in range(2400):
    x,y=rng.randrange(1280),rng.randrange(720);c=rng.choice(((46,84,36,70),(112,144,62,55),(70,106,43,60)))
    draw.rectangle((x,y,x+rng.choice((1,2)),y+rng.choice((1,1,2))),fill=c)

def cel(path,cell=256,col=2,row=0):
    im=Image.open(ROOT/path).convert('RGBA');return im.crop((col*cell,row*cell,(col+1)*cell,(row+1)*cell))
def scale(im,s):return im.resize((round(im.width*s),round(im.height*s)),Image.Resampling.NEAREST)
def foot(im,x,y):canvas.alpha_composite(im,(round(x-im.width/2),round(y-im.height)))

tree=Image.open(ROOT/'assets/trees/broadleaf-tree-cartoon-v3.png').convert('RGBA')
smoker=Image.open(ROOT/'assets/characters/ingame/smoker-atlas-pixel-v2.png').convert('RGBA').crop((0,0,96,192))
foot(tree,180,570);foot(scale(smoker,.61),370,565)
specs=[('forest',68,182),('mangrove',70,176),('madagascar',72,190),('island',74,190)]
for i,(name,width,body) in enumerate(specs):
    x=535+i*190;im=scale(cel(f'assets/enemies/arcade/planter-{name}-atlas-v3.png'),width/body)
    foot(im,x,565);draw.rectangle((x-width//2,581,x+width//2,584),fill=(210,198,117,180))
# Lower row uses the casting frames, still at identical runtime sizes.
for i,(name,width,body) in enumerate(specs):
    x=535+i*190;im=scale(cel(f'assets/enemies/arcade/planter-{name}-atlas-v3.png',col=2,row=1),width/body)
    foot(im,x,705)
OUT.parent.mkdir(parents=True,exist_ok=True);canvas.convert('RGB').save(OUT,quality=95)
print(OUT.relative_to(ROOT))
