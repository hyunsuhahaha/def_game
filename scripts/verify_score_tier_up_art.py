from pathlib import Path
from PIL import Image

root=Path(__file__).resolve().parents[1]
path=root/"assets/fx/score-tier-up-atlas-pixel-v1.png"
im=Image.open(path).convert("RGBA")
assert im.size==(9216,384),im.size
colors=set(im.get_flattened_data());assert len(colors)>=12,len(colors)
alpha={p[3] for p in colors};assert alpha<={0,255},alpha
boxes=[]
for i in range(12):
    f=im.crop((i*768,0,(i+1)*768,384));box=f.getbbox();assert box, i;boxes.append(box)
assert len(set(boxes))>=6,boxes
print("SCORE_TIER_UP_ART_OK",len(colors),"colors",len(set(boxes)),"silhouettes")
