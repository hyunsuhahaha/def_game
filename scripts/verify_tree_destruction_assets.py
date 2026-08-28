from pathlib import Path
from PIL import Image, ImageChops

root=Path(__file__).resolve().parents[1]
atlas=Image.open(root/"assets/fx/tree-damage-atlas-v1.png").convert("RGBA")
assert atlas.size==(640,160)
assert set(atlas.getchannel("A").getdata())<={0,255}
frames=[atlas.crop((i*160,0,(i+1)*160,160)) for i in range(4)]
assert all(frame.getbbox() for frame in frames)
assert all(ImageChops.difference(frames[i],frames[i+1]).getbbox() for i in range(3))
world=(root/"src/world.lua").read_text(encoding="utf-8")
for token in ("tree-damage-atlas-v1.png","damageStage","fallProfile","treeBreakFx"):
    assert token in world,token
preview=Image.open(root/"docs/previews/tree-destruction-v1-display-scale.png")
assert preview.size==(560,190)
print("TREE_DESTRUCTION_ASSET_OK frames=4 alpha=binary runtime=connected")
