"""Offscreen actual-scale QA for the 2.5x Madagascar baobab."""
from pathlib import Path
import random
from PIL import Image,ImageDraw

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/previews/madagascar-baobab-2_5x-display-scale.png'
canvas=Image.new('RGBA',(1280,720),(151,120,55,255));draw=ImageDraw.Draw(canvas);rng=random.Random(82925)
for _ in range(1900):
    x,y=rng.randrange(1280),rng.randrange(720);c=rng.choice(((111,76,42,80),(180,145,65,70),(83,102,48,65)))
    draw.rectangle((x,y,x+rng.choice((1,2,3)),y+rng.choice((1,1,2))),fill=c)

def grounded(image,x,y,scale,foot=.91):
    im=image.resize((round(image.width*scale),round(image.height*scale)),Image.Resampling.NEAREST)
    canvas.alpha_composite(im,(round(x-im.width/2),round(y-im.height*foot)))

baobab=Image.open(ROOT/'assets/trees/baobab-tree-pixel-v2.png').convert('RGBA')
tamarind=Image.open(ROOT/'assets/trees/tamarind-tree-pixel-v1.png').convert('RGBA')
commiphora=Image.open(ROOT/'assets/trees/commiphora-tree-pixel-v1.png').convert('RGBA')
smoker=Image.open(ROOT/'assets/characters/ingame/smoker-atlas-pixel-v2.png').convert('RGBA').crop((0,0,96,192))
grounded(tamarind,250,590,.28*.95);grounded(commiphora,430,590,.28*.92)
grounded(smoker,610,590,.61)
draw.ellipse((751,578,989,604),fill=(35,27,13,78))
grounded(baobab,870,590,.28*2.5)
draw.line((85,590,1180,590),fill=(232,205,118,210),width=3)
OUT.parent.mkdir(parents=True,exist_ok=True);canvas.convert('RGB').save(OUT,quality=95)
print(OUT.relative_to(ROOT))
