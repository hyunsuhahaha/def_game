from pathlib import Path

from PIL import Image, ImageChops

ROOT=Path(__file__).resolve().parents[1]
names=("giantcedar","ancienthemlock","mossoak")
trees=[]
for name in names:
    path=ROOT/f"assets/trees/{name}-tree-pixel-v1.png"
    image=Image.open(path).convert("RGBA")
    assert image.width>=200 and image.height>=320,(name,image.size)
    assert set(image.getchannel("A").get_flattened_data())<={0,255},name+" soft alpha"
    colors={p for p in image.get_flattened_data() if p[3]}
    assert len(colors)>=18,(name,len(colors))
    trees.append(image)
for index,left in enumerate(trees):
    for right in trees[index+1:]:
        canvas=Image.new("RGBA",(max(left.width,right.width),max(left.height,right.height)))
        a=canvas.copy();a.alpha_composite(left);b=canvas.copy();b.alpha_composite(right)
        assert ImageChops.difference(a,b).getbbox(),"great forest tree silhouettes were duplicated"

floor=Image.open(ROOT/"assets/scenery/biomes/greatforest-floor-decal-atlas-pixel-v1.png").convert("RGBA")
assert floor.size==(640,192) and set(floor.getchannel("A").get_flattened_data())<={0,255}
preview=Image.open(ROOT/"assets/maps/greatforest-preview-v1.png").convert("RGBA")
assert preview.size==(384,216)
maps=(ROOT/"src/clearcut_maps.lua").read_text(encoding="utf-8")
floor_source=(ROOT/"src/forest_floor.lua").read_text(encoding="utf-8")
assert 'world.width,world.height=7200,4600' in maps and 'greatforest={"giantcedar","ancienthemlock","mossoak"}' in maps
for token in ("rootMat","needles","deepMoss","mushrooms","nurseLog","paleSawdust","rootDrag"):
    assert token in floor_source,token
print("GREAT_FOREST_ASSETS_OK trees=3 world=7200x4600 floor=10 preview=384x216 hard_alpha=true")
