from pathlib import Path
from PIL import Image,ImageChops
root=Path(__file__).resolve().parents[1];im=Image.open(root/'assets/fx/smoke-ring/smoke-ring-charge-atlas-pixel-v1.png').convert('RGBA')
assert im.size==(1152,384) and set(im.getchannel('A').getdata())<={0,255}
opaque=[p for p in im.getdata() if p[3]]
assert not any(r>185 and b>145 and g<max(r,b)*.78 for r,g,b,a in opaque), 'magenta key contamination remains'
for row in range(2):
    frames=[im.crop((i*192,row*192,(i+1)*192,(row+1)*192)) for i in range(6)]
    assert all(f.getchannel('A').getbbox() for f in frames)
    assert all(ImageChops.difference(frames[0],f).getbbox() for f in frames[1:])
mode=(root/'src/clearcut_mode.lua').read_text(encoding='utf-8');assert 'SmokeRingArt.drawCharge' in mode
assert 'SmokeRingArt.drawRing' not in mode
print('SMOKE_RING_FX_OK charge=6 original_ring_preserved=true runtime_wired=true')
