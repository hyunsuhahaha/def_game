"""Extract and bake the approved high-density straw-bale body source."""
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageFilter

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/"assets/fx/straw-bale/concepts/straw-bale-body-source-v4.png"
CUTOUT=ROOT/"assets/fx/straw-bale/concepts/straw-bale-body-cutout-v4.png"
DEST=ROOT/"assets/fx/straw-bale/straw-bale-body-pixel-v4.png"

def main():
    bgr=cv2.imread(str(SOURCE),cv2.IMREAD_COLOR)
    if bgr is None: raise SystemExit(f"missing {SOURCE}")
    h,w=bgr.shape[:2]
    mask=np.zeros((h,w),np.uint8)
    bg=np.zeros((1,65),np.float64);fg=np.zeros((1,65),np.float64)
    cv2.grabCut(bgr,mask,(145,20,w-285,h-45),bg,fg,9,cv2.GC_INIT_WITH_RECT)
    alpha=np.where((mask==cv2.GC_FGD)|(mask==cv2.GC_PR_FGD),255,0).astype(np.uint8)
    # Remove disconnected halo islands while preserving loose straw attached to the bale.
    count,labels,stats,_=cv2.connectedComponentsWithStats(alpha,8)
    if count>1:
        largest=1+np.argmax(stats[1:,cv2.CC_STAT_AREA])
        alpha=np.where(labels==largest,255,0).astype(np.uint8)
    rgba=cv2.cvtColor(bgr,cv2.COLOR_BGR2RGBA);rgba[:,:,3]=alpha
    cut=Image.fromarray(rgba,"RGBA")
    cut.save(CUTOUT)
    box=cut.getchannel("A").getbbox()
    if not box: raise SystemExit("foreground extraction failed")
    cut=cut.crop(box)
    scale=min(304/cut.width,256/cut.height)
    cut=cut.resize((round(cut.width*scale),round(cut.height*scale)),Image.Resampling.LANCZOS)
    a=cut.getchannel("A").point(lambda value:255 if value>=112 else 0)
    rgb=cut.convert("RGB").quantize(colors=144,method=Image.Quantize.FASTOCTREE,dither=Image.Dither.NONE).convert("RGBA")
    rgb.putalpha(a)
    canvas=Image.new("RGBA",(320,288))
    x=(320-rgb.width)//2;y=278-rgb.height
    # Two-native-pixel material-colour outline for readability on bright grass.
    outline=Image.new("RGBA",canvas.size)
    placed=Image.new("L",canvas.size);placed.paste(a,(x,y))
    dilated=placed.filter(ImageFilter.MaxFilter(5))
    outline.putalpha(Image.fromarray(np.maximum(0,np.asarray(dilated,dtype=np.int16)-np.asarray(placed,dtype=np.int16)).astype(np.uint8)))
    outline.paste((48,25,10,255),(0,0,320,288),outline)
    canvas.alpha_composite(outline)
    canvas.alpha_composite(rgb,(x,y))
    canvas.save(DEST)
    print(f"STRAW_BALE_BODY_V4_OK source={w}x{h} sprite={canvas.size} body={rgb.size} colors=144")

if __name__=="__main__": main()
