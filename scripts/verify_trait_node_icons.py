from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[1]
im=Image.open(root/"assets/ui/trait-node-icons-pixel-v2.png").convert("RGBA")
assert im.size==(288,288),im.size
assert set(im.getchannel("A").get_flattened_data())<={0,255}
frames=[]
for y in range(3):
    for x in range(3):
        f=im.crop((x*96,y*96,(x+1)*96,(y+1)*96));assert f.getbbox();frames.append(f.tobytes())
assert len(set(frames))==9
assert len(set(im.get_flattened_data()))>=24
print("TRAIT_NODE_ICONS_OK 9 icons",len(set(im.get_flattened_data())),"colors")
