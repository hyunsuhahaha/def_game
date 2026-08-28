from pathlib import Path
from PIL import Image,ImageChops

ROOT=Path(__file__).resolve().parents[1]
names=('beginner','forest','mangrove','madagascar','island')
for name in names:
    p=ROOT/f'assets/enemies/biome-bosses/arcade-v2/{name}-boss-atlas-v2.png';im=Image.open(p).convert('RGBA')
    assert im.size==(2304,768),(name,im.size);assert set(im.getchannel('A').get_flattened_data())<={0,255},name
    frames=[im.crop((i*384,row*384,(i+1)*384,(row+1)*384)) for row in range(2) for i in range(6)]
    assert all(f.getbbox() for f in frames),name
    assert len({f.tobytes() for f in frames[:6]})>=4,(name,'idle frames')
    assert any(ImageChops.difference(frames[i],frames[i+6]).getbbox() for i in range(6)),(name,'action row')
    colors=len({px[:3] for px in im.get_flattened_data() if px[3]});assert 60<=colors<=112,(name,colors)
print('BIOME_BOSS_ASSETS_V2_OK bosses=5 grid=384 atlas=6x2 alpha=hard style=cartoon')
