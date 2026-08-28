"""Offscreen actual-scale and 3x pixel QA for the regeneration sanctum."""
from pathlib import Path
import random
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/previews/regrowth-sanctum-v2-display-scale.png'

canvas=Image.new('RGBA',(1280,720),(88,127,51,255));draw=ImageDraw.Draw(canvas);rng=random.Random(20826)
for _ in range(2200):
    x,y=rng.randrange(1280),rng.randrange(720)
    c=rng.choice(((55,95,41,70),(124,151,69,55),(75,111,42,55)))
    draw.rectangle((x,y,x+rng.choice((1,2,3)),y+rng.choice((1,1,2))),fill=c)
draw.rectangle((780,0,784,720),fill=(31,53,37,170))

def frame(path,cell,col,row=0):
    image=Image.open(ROOT/path).convert('RGBA')
    return image.crop((col*cell,row*cell,(col+1)*cell,(row+1)*cell))

def scaled(image,scale):
    return image.resize((round(image.width*scale),round(image.height*scale)),Image.Resampling.NEAREST)

def foot(image,x,y):canvas.alpha_composite(image,(round(x-image.width/2),round(y-image.height)))

tree=Image.open(ROOT/'assets/trees/broadleaf-tree-cartoon-v3.png').convert('RGBA')
smoker=frame('assets/characters/ingame/smoker-atlas-pixel-v2.png',96,0)
sanctum=frame('assets/enemies/arcade/planter-atlas-v2.png',256,3)
cast=frame('assets/fx/regrowth-cast-atlas-v3.png',256,3)

# Actual runtime sizes: tree scale 1, smoker .61, sanctum 90/233, cast .55.
foot(tree,250,585);foot(tree,700,555);foot(scaled(smoker,.61),420,560)
foot(scaled(sanctum,90/233),590,555);foot(scaled(cast,.55),590,562)
draw.rectangle((95,620,735,624),fill=(220,212,144,180))

# Enlarged nearest-neighbor inspection, preserving the exact runtime cel pixels.
close=scaled(sanctum,1.75);foot(close,1025,635)
cast_close=scaled(cast,1.1);foot(cast_close,1025,642)
draw.rectangle((830,667,1218,671),fill=(185,217,174,185))

OUT.parent.mkdir(parents=True,exist_ok=True);canvas.convert('RGB').save(OUT,quality=95)
print(OUT.relative_to(ROOT))
