from pathlib import Path
from PIL import Image

root=Path(__file__).resolve().parents[1]
image=Image.open(root/"assets/fx/straw-bale/straw-bale-atlas-pixel-v3.png").convert("RGBA")
assert image.size==(768,448),image.size
assert set(image.getchannel("A").getdata())<={0,255}
cells=[]
for row in range(2):
    for col in range(6):
        cell=image.crop((col*128,row*224,(col+1)*128,(row+1)*224))
        assert cell.getchannel("A").getbbox(),(row,col)
        cells.append(cell.tobytes())
assert len(set(cells))==12
colors={p[:3] for p in image.getdata() if p[3]}
assert 60<=len(colors)<=130,len(colors)
print(f"straw bale atlas ok: size={image.size}, colors={len(colors)}, unique_cells=12")
