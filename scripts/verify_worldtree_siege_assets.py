from pathlib import Path
from PIL import Image
import numpy as np

ROOT=Path(__file__).resolve().parents[1]
atlas=Image.open(ROOT/'assets/enemies/arcade/worldtree-siege-atlas-v1.png').convert('RGBA')
debris=Image.open(ROOT/'assets/fx/worldtree-siege-debris-atlas-v1.png').convert('RGBA')
assert atlas.size==(6144,2048)
assert debris.size==(768,96)
assert set(np.unique(np.asarray(atlas)[:,:,3]))=={0,255}
assert set(np.unique(np.asarray(debris)[:,:,3]))=={0,255}
counts=[]
for stage in range(4):
    i=stage*3+1;x=(i%6)*1024;y=(i//6)*1024
    frame=np.asarray(atlas.crop((x,y,x+1024,y+1024)))
    counts.append(int((frame[:,:,3]>0).sum()))
    colors=len({tuple(v) for v in frame[:,:,:3][frame[:,:,3]>0]})
    assert 55<=colors<=128,(stage,colors)
assert counts[0]>counts[1]>counts[2]>counts[3],counts
assert (ROOT/'assets/enemies/arcade/worldtree-atlas-v3.png').exists(),"old worldtree was deleted"
assert (ROOT/'assets/concepts/unused/worldtree/worldtree-siege-rejected-v2.png').exists(),"rejected concept was deleted"
print('WORLDTREE_SIEGE_ASSETS_OK atlas=6144x2048 debris=8 states=4 alpha=hard foliage='+','.join(map(str,counts)))
