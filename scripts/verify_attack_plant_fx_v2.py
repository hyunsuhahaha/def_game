from pathlib import Path
from PIL import Image,ImageChops

ROOT=Path(__file__).resolve().parents[1]
p=ROOT/'assets/fx/attack-plants/attack-plant-projectiles-atlas-v2.png'
im=Image.open(p).convert('RGBA');assert im.size==(960,640)
assert set(im.getchannel('A').get_flattened_data())<={0,255}
for row in range(4):
 frames=[im.crop((i*160,row*160,(i+1)*160,(row+1)*160)) for i in range(6)]
 assert all(f.getbbox() for f in frames),(row,'empty frame')
 assert len({f.tobytes() for f in frames})>=2,(row,'static row')
colors=len({px[:3] for px in im.get_flattened_data() if px[3]});assert colors>=20,colors
code=(ROOT/'src/attack_plants.lua').read_text(encoding='utf-8')
assert 'attack-plant-projectiles-atlas-v2.png' in code
assert 'circle("fill",0,0,8)' not in code and 'ellipse("fill",p.x,p.y' not in code
print('ATTACK_PLANT_FX_V2_OK grid=160 frames=6 rows=4 alpha=hard runtime=atlas colors=',colors)
