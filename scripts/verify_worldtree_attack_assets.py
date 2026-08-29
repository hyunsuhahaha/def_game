from pathlib import Path
from PIL import Image

root=Path(__file__).resolve().parents[1]
path=root/"assets/fx/worldtree/worldtree-attacks-atlas-v1.png"
image=Image.open(path).convert("RGBA")
assert image.size==(1536,1280),image.size
colors=image.getcolors(maxcolors=1_000_000)
assert colors and len(colors)>=24,len(colors or [])
alpha=image.getchannel("A")
for row in range(5):
    for frame in range(6):
        cell=alpha.crop((frame*256,row*256,(frame+1)*256,(row+1)*256))
        assert cell.getbbox(),f"empty row={row} frame={frame}"
print(f"WORLDTREE_ATTACK_ASSETS_OK size=1536x1280 colors={len(colors)} cells=30")
