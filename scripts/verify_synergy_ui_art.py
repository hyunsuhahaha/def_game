"""Static quality gates for the authored synergy emblem/chrome atlases."""
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
emblems=Image.open(ROOT/'assets/ui/synergy-emblems-pixel-v1.png').convert('RGBA')
chrome=Image.open(ROOT/'assets/ui/synergy-chrome-pixel-v1.png').convert('RGBA')
assert emblems.size==(448,64),emblems.size
assert chrome.size==(256,64),chrome.size
assert set(emblems.getchannel('A').get_flattened_data()) <= {0,255}
assert set(chrome.getchannel('A').get_flattened_data()) <= {0,180,245,255}

signatures=[]
for i in range(7):
    cell=emblems.crop((i*64,0,(i+1)*64,64))
    alpha=cell.getchannel('A');box=alpha.getbbox();assert box
    assert box[0]>=2 and box[1]>=2 and box[2]<=62 and box[3]<=62,(i,box)
    opaque=sum(1 for value in alpha.get_flattened_data() if value)
    colors=len({pixel[:3] for pixel in cell.get_flattened_data() if pixel[3]})
    assert opaque>=850,(i,opaque)
    assert colors>=12,(i,colors)
    signatures.append(bytes(channel for pixel in cell.get_flattened_data() for channel in pixel))
assert len(set(signatures))==7

for i in range(4):
    cell=chrome.crop((i*64,0,(i+1)*64,64))
    assert cell.getchannel('A').getbbox(),i

print('SYNERGY_UI_ART_OK emblems=7 cell=64 colors>=12 silhouettes=distinct chrome=4')
