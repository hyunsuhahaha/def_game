from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[1]
image=Image.open(root/"assets/fx/mole-burrow/mole-burrow-trail-atlas-pixel-v1.png").convert("RGBA")
assert image.size==(768,256)
assert set(image.getchannel("A").getdata())<={0,255}
cells=[]
for row in range(2):
    for col in range(6):
        cell=image.crop((col*128,row*128,(col+1)*128,(row+1)*128));assert cell.getchannel("A").getbbox();cells.append(cell.tobytes())
assert len(set(cells))==12
print("mole burrow trail atlas ok: 768x256 cells=12 alpha=hard")
