from pathlib import Path
from PIL import Image,ImageChops
root=Path(__file__).resolve().parents[1];im=Image.open(root/'assets/fx/philosopher/revival-crowd-atlas-pixel-v1.png').convert('RGBA')
assert im.size==(576,480) and set(im.getchannel('A').getdata())<={0,255}
for row in range(3):
    frames=[im.crop((i*96,row*160,(i+1)*96,(row+1)*160)) for i in range(6)]
    assert all(f.getchannel('A').getbbox() for f in frames)
    assert all(ImageChops.difference(frames[0],f).getbbox() for f in frames[1:])
mode=(root/'src/clearcut_mode.lua').read_text(encoding='utf-8');assert 'RevivalCrowdArt.start' in mode and 'RevivalCrowdArt.queue' in mode
print('REVIVAL_CROWD_OK followers=3 frames=18 depth_queue=true')
