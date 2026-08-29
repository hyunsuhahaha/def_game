"""Bake four open-core regeneration pedestals from the approved v4 concept board."""
from pathlib import Path
import json

import numpy as np
from PIL import Image, ImageEnhance


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/enemies/concepts/regrowth-prism-pedestals-concept-v4-cutout.png"
CELL, FOOT = 256, 248
SPECS = {
    "forest": (0, 0, 68, 206, 0.46, 0.29),
    "mangrove": (1, 0, 70, 210, 0.48, 0.31),
    "madagascar": (0, 1, 72, 212, 0.49, 0.30),
    "island": (1, 1, 74, 214, 0.48, 0.30),
}


def alpha_bbox(image):
    a=np.asarray(image.getchannel("A"));ys,xs=np.nonzero(a>=40)
    return int(xs.min()),int(ys.min()),int(xs.max()+1),int(ys.max()+1)


def open_core(quadrant, keep_floor, keep_side):
    """Remove the generated static crystal/rings but retain the regional base."""
    image=quadrant.copy();alpha=np.asarray(image.getchannel("A")).copy()
    x0,y0,x1,y1=alpha_bbox(image);w,h=x1-x0,y1-y0;cx=(x0+x1)/2
    yy,xx=np.mgrid[0:image.height,0:image.width]
    floor=y0+h*keep_floor
    side=abs(xx-cx)>=w*keep_side
    # Below the platform line remains intact. Above it, retain only the broad
    # outside supports. This removes the old fixed crystal, orbit and shards.
    keep=(yy>=floor)|((yy>=y0+h*.29)&side)
    alpha=np.where(keep,alpha,0)
    alpha=np.where(alpha>=112,255,0).astype(np.uint8)
    image.putalpha(Image.fromarray(alpha,"L"))
    return image.crop(alpha_bbox(image))


def pixel_finish(image, body_width):
    # Fit to the authored body width first, then keep hard source pixels and a
    # controlled regional palette. No blur or post-scale smoothing is used.
    scale=body_width/image.width
    image=image.resize((body_width,round(image.height*scale)),Image.Resampling.NEAREST)
    rgb=ImageEnhance.Contrast(image.convert("RGB")).enhance(1.06)
    pal=rgb.quantize(colors=96,method=Image.Quantize.FASTOCTREE,dither=Image.Dither.NONE).convert("RGB")
    pal.putalpha(image.getchannel("A"))
    return pal


def casting_variant(image):
    # Casting changes only the pedestal's light response. Geometry stays
    # bit-identical so the large separate prism is the sole moving silhouette.
    rgba=np.asarray(image).copy();mask=rgba[:,:,3]>0
    rgb=rgba[:,:,:3].astype(np.int16)
    luminous=(rgb[:,:,1]>rgb[:,:,0]*1.04)&(rgb[:,:,1]>rgb[:,:,2]*.82)&mask
    rgb[luminous]=np.minimum(255,rgb[luminous]+np.array([12,24,20]))
    rgba[:,:,:3]=rgb.astype(np.uint8)
    return Image.fromarray(rgba,"RGBA")


def main():
    source=Image.open(SOURCE).convert("RGBA")
    qw,qh=source.width//2,source.height//2
    report={};contact=Image.new("RGBA",(4*320,2*320),(43,64,36,255))
    for column,(name,(qx,qy,world_width,body_width,keep_floor,keep_side)) in enumerate(SPECS.items()):
        quadrant=source.crop((qx*qw,qy*qh,(qx+1)*qw,(qy+1)*qh))
        idle=pixel_finish(open_core(quadrant,keep_floor,keep_side),body_width)
        casting=casting_variant(idle)
        atlas=Image.new("RGBA",(CELL*6,CELL*2))
        px=(CELL-idle.width)//2;py=FOOT-idle.height
        for frame in range(6):
            atlas.alpha_composite(idle,(frame*CELL+px,py))
            atlas.alpha_composite(casting,(frame*CELL+px,CELL+py))
        out=ROOT/f"assets/enemies/arcade/planter-{name}-atlas-v4.png"
        out.parent.mkdir(parents=True,exist_ok=True);atlas.save(out,optimize=True)
        for row,cel in enumerate((idle,casting)):
            scale=min(300/cel.width,300/cel.height)
            show=cel.resize((round(cel.width*scale),round(cel.height*scale)),Image.Resampling.NEAREST)
            contact.alpha_composite(show,(column*320+(320-show.width)//2,row*320+315-show.height))
        report[name]={"file":str(out.relative_to(ROOT)),"source":str(SOURCE.relative_to(ROOT)),
            "worldWidth":world_width,"cell":CELL,"foot":FOOT,"bodyWidth":body_width,
            "height":idle.height,"frames":12,"stableBody":True,"openCore":True}
    preview=ROOT/"docs/previews/regrowth-totems-v4-contact-sheet.png"
    preview.parent.mkdir(parents=True,exist_ok=True);contact.convert("RGB").save(preview,quality=95)
    (ROOT/"docs/previews/regrowth-totems-v4-build.json").write_text(
        json.dumps(report,ensure_ascii=False,indent=2),encoding="utf-8")
    print("REGROWTH_TOTEMS_V4_OK",json.dumps(report,ensure_ascii=False))


if __name__=="__main__":main()
