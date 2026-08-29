from pathlib import Path
from PIL import Image, ImageDraw
import math

ROOT=Path(__file__).resolve().parents[1]
tree=Image.open(ROOT/"assets/trees/broadleaf-tree-cartoon-v3.png").convert("RGBA")
fx=Image.open(ROOT/"assets/fx/regrowth-cast-atlas-v3.png").convert("RGBA")
ground=Image.open(ROOT/"assets/forest-ground-tile-v1.png").convert("RGB")

panel_w,panel_h=260,300
out=Image.new("RGB",(panel_w*6,panel_h),(47,64,29))
for index,raw in enumerate((0,.18,.36,.56,.76,.96)):
    panel=ground.crop((120,160,120+panel_w,160+panel_h)).copy().convert("RGBA")
    frame=min(5,int(raw*6))
    tile=fx.crop((frame*256,0,(frame+1)*256,256))
    pulse=1+math.sin(raw*math.pi)*.09
    fs=.46*pulse
    tile=tile.resize((round(256*fs),round(256*fs)),Image.Resampling.NEAREST)
    panel.alpha_composite(tile,(panel_w//2-tile.width//2,254-round(248*fs)))
    rise=max(0,min(1,(raw-.12)/.72));ease=rise*rise*(3-2*rise)
    scale=.56+ease*.44+math.sin(rise*math.pi)*.065
    alpha=max(0,min(1,raw/.16))
    grown=tree.resize((round(tree.width*scale),round(tree.height*scale)),Image.Resampling.NEAREST)
    if alpha<1:
        a=grown.getchannel("A").point(lambda value:round(value*alpha));grown.putalpha(a)
    foot_y=252
    panel.alpha_composite(grown,(panel_w//2-grown.width//2,foot_y-round(grown.height*.91)))
    draw=ImageDraw.Draw(panel);draw.text((8,8),f"{raw:.2f}s",fill=(238,231,193,255))
    out.paste(panel.convert("RGB"),(index*panel_w,0))

path=ROOT/"docs/previews/tree-emergence-v1-display-scale.png"
out.save(path)
print(path)
