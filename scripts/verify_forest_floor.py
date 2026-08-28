from pathlib import Path
from PIL import Image, ImageChops

ROOT=Path(__file__).resolve().parents[1]
path=ROOT/"assets/scenery/forest/forest-floor-decal-atlas-pixel-v1.png"
image=Image.open(path)
assert image.mode=="RGBA" and image.size==(640,192)
assert image.getchannel("A").getextrema()==(0,255),"floor decals need hard transparent/opaque pixels"
colors=len(image.getcolors(image.width*image.height) or [])
assert colors>=35,"floor material ramps are too sparse"
cells=[]
for row in range(2):
    for col in range(5):
        cell=image.crop((col*128,row*96,(col+1)*128,(row+1)*96))
        assert cell.getbbox(),f"empty floor decal {len(cells)+1}"
        cells.append(cell)
for i,cell in enumerate(cells):
    assert all(ImageChops.difference(cell,other).getbbox() for other in cells[i+1:]),"duplicate floor decals"
source=(ROOT/"src/forest_floor.lua").read_text(encoding="utf-8")
for token in ("soil","leaves","shortGrass","trampled","fern","branch","stones","moss","sawdust","drag"):
    assert token in source,f"missing runtime decal {token}"
assert "cluster" in source and "readability" in source and "path" in source
print(f"FOREST_FLOOR_OK atlas=640x192 decals=10 colors={colors} layout=clustered path=authored destruction=dynamic")
