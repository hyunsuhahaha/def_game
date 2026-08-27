"""Bake the authored charge/torus board into a fixed 6x2 pixel FX atlas."""
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'assets/fx/philosopher/../smoke-ring/smoke-ring-charge-source-v1.png'
OUT=ROOT/'assets/fx/smoke-ring/smoke-ring-charge-atlas-pixel-v1.png'
PREVIEW=ROOT/'docs/previews/smoke-ring-charge-atlas-v1.png'
CELL=192

def key(im):
    im=im.convert('RGBA');p=im.load()
    for y in range(im.height):
        for x in range(im.width):
            r,g,b,a=p[x,y]
            keyed=r>205 and b>175 and g<125 and r-b<100
            if keyed:p[x,y]=(0,0,0,0)
            elif r>150 and g<125 and b<105: p[x,y]=(r,g,b,255) # final ember flecks
            else:
                lum=round(r*.28+g*.55+b*.17);p[x,y]=(min(255,round(lum*1.04)),lum,round(lum*.94),255)
    return im

def main():
    src=key(Image.open(SOURCE));atlas=Image.new('RGBA',(CELL*6,CELL*2))
    for row in range(2):
        for col in range(6):
            part=src.crop((round(col*src.width/6),round(row*src.height/2),round((col+1)*src.width/6),round((row+1)*src.height/2)))
            box=part.getchannel('A').getbbox()
            if not box and row==0 and col==0:
                part=src.crop((round(src.width/6),0,round(src.width/3),round(src.height/2)));box=part.getchannel('A').getbbox()
            assert box;part=part.crop(box)
            target_h=(124 if row==0 and col==0 else 176) if row==0 else 170;scale=min((CELL-12)/part.width,target_h/part.height)
            part=part.resize((round(part.width*scale),round(part.height*scale)),Image.Resampling.NEAREST)
            x=col*CELL+(CELL-part.width)//2;y=row*CELL+(CELL-part.height)//2
            atlas.alpha_composite(part,(x,y))
    alpha=atlas.getchannel('A');rgb=Image.new('RGB',atlas.size);rgb.paste(atlas.convert('RGB'),mask=alpha)
    atlas=rgb.quantize(colors=112,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE).convert('RGBA');atlas.putalpha(alpha.point(lambda v:255 if v else 0))
    OUT.parent.mkdir(parents=True,exist_ok=True);PREVIEW.parent.mkdir(parents=True,exist_ok=True);atlas.save(OUT)
    bg=Image.new('RGB',(1200,430),(86,123,59));shown=atlas.resize((1152,384),Image.Resampling.NEAREST);bg.paste(shown,(24,22),shown);bg.save(PREVIEW)
    print('SMOKE_RING_FX_BUILD_OK cells=12 atlas=1152x384')
if __name__=='__main__':main()
