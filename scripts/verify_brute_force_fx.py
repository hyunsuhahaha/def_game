from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[1]
image=Image.open(root/"assets/fx/brute-force/brute-force-atlas-pixel-v1.png").convert("RGBA")
assert image.size==(768,320);assert set(image.getchannel("A").getdata())<={0,255}
cells=[]
for row in range(2):
    for col in range(6):
        c=image.crop((col*128,row*160,(col+1)*128,(row+1)*160));assert c.getchannel("A").getbbox();cells.append(c.tobytes())
assert len(set(cells))==12
print("brute force atlas ok: 768x320 cells=12 alpha=hard")
