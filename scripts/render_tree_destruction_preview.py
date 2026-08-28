from pathlib import Path
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
TREE=Image.open(ROOT/"assets/trees/broadleaf-tree-cartoon-v3.png").convert("RGBA")
ATLAS=Image.open(ROOT/"assets/fx/tree-damage-atlas-v1.png").convert("RGBA")

def scaled(im,s): return im.resize((round(im.width*s),round(im.height*s)),Image.Resampling.NEAREST)

canvas=Image.new("RGBA",(560,190),(91,117,48,255));d=ImageDraw.Draw(canvas)
for i in range(4):
    cx=70+i*140; tree=scaled(TREE,.28); base=155
    d.ellipse((cx-30,base-5,cx+30,base+5),fill=(35,44,18,90))
    canvas.alpha_composite(tree,(cx-tree.width//2,base-round(tree.height*.91)))
    if i:
        decal=scaled(ATLAS.crop((i*160-160,0,i*160,160)),.18)
        canvas.alpha_composite(decal,(cx-decal.width//2,base-round(154*.22)))
    d.text((cx-26,168),f"stage {i}",fill=(240,232,196,255))
out=ROOT/"docs/previews/tree-destruction-v1-display-scale.png";out.parent.mkdir(parents=True,exist_ok=True);canvas.save(out)
