from pathlib import Path
from PIL import Image, ImageChops

root=Path(__file__).resolve().parents[1]
kinds=("thornHunter","hammerBloom","seedPod","bambooCannon","resinSprayer")
for kind in kinds:
    path=root/"assets/enemies/arcade"/f"{kind}-atlas-v1.png"
    im=Image.open(path).convert("RGBA")
    assert im.size==(960,320), (kind,im.size)
    assert set(im.getchannel("A").getdata()) <= {0,255}, f"{kind}: soft alpha"
    frames=[im.crop(((i%6)*160,(i//6)*160,(i%6+1)*160,(i//6+1)*160)) for i in range(12)]
    assert all(f.getbbox() for f in frames), f"{kind}: blank frame"
    assert any(ImageChops.difference(frames[6],f).getbbox() for f in frames[7:]), f"{kind}: static action row"
fx=Image.open(root/"assets/fx/nature-counterattack-atlas-v1.png")
assert fx.size==(960,320)
code=(root/"src/attack_plants.lua").read_text(encoding="utf-8")
for token in ("thornHunter","hammerBloom","seedPod","bambooCannon","resinSprayer","resinPuddles"):
    assert token in code, token
mode=(root/"src/clearcut_mode.lua").read_text(encoding="utf-8")
for token in ("rootQuake","branchFall","AttackPlants.update","AttackPlants.drawTelegraph"):
    assert token in mode, token
print("ATTACK_PLANTS_OK species=5 action_atlases=12 root_quake=authored branch_fall=authored")
