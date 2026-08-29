from pathlib import Path
from PIL import Image

root=Path(__file__).resolve().parents[1]
path=root/"assets/fx/worldtree/worldtree-attacks-atlas-v2.png"
image=Image.open(path).convert("RGBA")
assert image.size==(2304,1920),image.size
colors=image.getcolors(maxcolors=1_000_000)
assert colors and len(colors)>=40,len(colors or [])
alpha=image.getchannel("A")
for row in range(5):
    for frame in range(6):
        cell=alpha.crop((frame*384,row*384,(frame+1)*384,(row+1)*384))
        assert cell.getbbox(),f"empty row={row} frame={frame}"
emergence=Image.open(root/"assets/fx/worldtree/worldtree-emergence-atlas-v2.png").convert("RGBA")
assert emergence.size==(3072,384),emergence.size
assert emergence.getchannel("A").getbbox(),"empty emergence atlas"
assert image.getpixel((0,0))[3]==0 and emergence.getpixel((0,0))[3]==0,"opaque canvas leaked into FX"
print(f"WORLDTREE_ATTACK_ASSETS_OK attack=2304x1920 emergence=3072x384 colors={len(colors)} cells=30 transparent=true")
