from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/"assets/fx/concepts/tree-damage-source-v1.png"
OUT=ROOT/"assets/fx/tree-damage-atlas-v1.png"
PREVIEW=ROOT/"docs/previews/tree-destruction-v1-3x.png"
CELL=160

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
    OUT.parent.mkdir(parents=True,exist_ok=True);sheet.save(OUT)
    PREVIEW.parent.mkdir(parents=True,exist_ok=True)
    sheet.resize((sheet.width*3,sheet.height*3),Image.Resampling.NEAREST).save(PREVIEW)

if __name__=="__main__":main()
