from pathlib import Path
from PIL import Image
import numpy as np

root=Path(__file__).resolve().parents[1]
path=root/"assets/fx/worldtree/worldtree-telegraphs-atlas-v1.png"
im=Image.open(path).convert("RGBA")
assert im.size==(2304,1536),im.size
a=np.asarray(im)
assert a[...,3].max()==255 and np.count_nonzero(a[...,3])>45000
opaque=a[a[...,3]>0]
assert np.mean(opaque[:,0])>np.mean(opaque[:,1])*2.2,"warning is not clearly red"
for row in range(4):
    frames=[]
    for frame in range(6):
        cell=a[row*384:(row+1)*384,frame*384:(frame+1)*384]
        assert np.count_nonzero(cell[...,3])>1200,(row,frame)
        frames.append(cell.tobytes())
    assert len(set(frames))==6,"warning animation frames are static"
source=(root/"src/worldtree_attack_art.lua").read_text(encoding="utf-8")
assert "worldtree-telegraphs-atlas-v1.png" in source
assert "warningCapsule" in source and "warningCircle" in source
print("WORLDTREE_TELEGRAPHS_OK atlas=2304x1536 rows=4 frames=6 red=true exact_circle_capsule=true")
