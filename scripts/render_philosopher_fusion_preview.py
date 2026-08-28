from pathlib import Path
import random
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs'/'previews'/'philosopher-fusions-v1-display-scale.png'

canvas=Image.new('RGBA',(1280,720),(92,132,56,255));draw=ImageDraw.Draw(canvas)
rng=random.Random(8226)
for _ in range(2400):
    x,y=rng.randrange(1280),rng.randrange(720);c=rng.choice(((80,118,48,70),(122,153,70,55),(53,96,42,45)))
    draw.rectangle((x,y,x+rng.choice((1,2,3)),y+rng.choice((1,1,2))),fill=c)
draw.rectangle((639,0,641,720),fill=(31,53,37,150))

def crop(path,box,scale=1):
    im=Image.open(ROOT/path).convert('RGBA').crop(box)
    return im.resize((round(im.width*scale),round(im.height*scale)),Image.Resampling.NEAREST)

def foot(sprite,x,y): canvas.alpha_composite(sprite,(round(x-sprite.width/2),round(y-sprite.height)))

tree=crop('assets/trees/broadleaf-tree-cartoon-v3.png',(0,0,*Image.open(ROOT/'assets/trees/broadleaf-tree-cartoon-v3.png').size),.58)
philosopher=crop('assets/characters/ingame/philosopher-atlas-pixel-v2.png',(0,0,96,192),.61)
pool=crop('assets/fx/philosopher/eternal-return-field-atlas-pixel-v1.png',(384*3,0,384*4,256),1)
follower_atlas=Image.open(ROOT/'assets/fx/philosopher/revival-crowd-atlas-pixel-v1.png').convert('RGBA')
followers=[]
for row in range(3):
    followers.append(follower_atlas.crop((96*3,row*160,96*4,(row+1)*160)).resize((45,75),Image.Resampling.NEAREST))
chorus=crop('assets/fx/philosopher/revival-chorus-atlas-pixel-v1.png',(256*2,0,256*3,256),.34)
impact=crop('assets/fx/philosopher/revival-chorus-atlas-pixel-v1.png',(256*4,0,256*5,256),.68)

# Left: actual runtime-scale persistent field beneath actors.
canvas.alpha_composite(pool,(130,315))
foot(tree,460,485);foot(philosopher,184,470)
draw.rectangle((92,558,548,562),fill=(226,216,154,180))

# Right: crowd sources, travelling packets, and contact at the target.
foot(philosopher,735,475)
for i,(x,y) in enumerate(((780,510),(850,530),(910,500),(800,600),(885,610),(950,575))):foot(followers[i%3],x,y)
for x,y in ((965,450),(1025,420),(1070,500)):canvas.alpha_composite(chorus,(x-chorus.width//2,y-chorus.height//2))
foot(tree,1170,520);canvas.alpha_composite(impact,(1080,320))
draw.rectangle((706,620,1200,624),fill=(225,167,62,190))

OUT.parent.mkdir(parents=True,exist_ok=True);canvas.convert('RGB').save(OUT,quality=94)
print(OUT.relative_to(ROOT))
