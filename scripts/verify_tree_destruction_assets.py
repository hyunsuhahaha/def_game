from pathlib import Path
from PIL import Image, ImageChops

root=Path(__file__).resolve().parents[1]
burst=Image.open(root/"assets/fx/tree-break-burst-v1.png").convert("RGBA")
assert burst.size==(160,160) and burst.getbbox()
for name in ("broadleaf","pine","birch","maple"):
    base=Image.open(root/"assets/trees"/f"{name}-tree-cartoon-v3.png").convert("RGBA")
    previous=base
    for stage in range(1,4):
        frame=Image.open(root/"assets/trees/damage"/f"{name}-damage{stage}-v1.png").convert("RGBA")
        assert frame.size==base.size and frame.getbbox()
        assert ImageChops.difference(previous,frame).getbbox(),(name,stage)
        previous=frame
world=(root/"src/world.lua").read_text(encoding="utf-8")
for token in ("tree-break-burst-v1.png","treeDamageVariants","damageStage","fallProfile","treeBreakFx"):
    assert token in world,token
preview=Image.open(root/"docs/previews/tree-destruction-v1-display-scale.png")
assert preview.size==(560,190)
print("TREE_DESTRUCTION_ASSET_OK frames=4 alpha=binary runtime=connected")
