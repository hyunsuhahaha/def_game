from pathlib import Path
from PIL import Image

root=Path(__file__).resolve().parents[1]
folder=root/'assets'/'scenery'/'skyview'
maps=('forest','mangrove','madagascar','island')
for name in maps:
    path=folder/f'{name}-sun-skyview-pixel-v2.png'
    image=Image.open(path).convert('RGB')
    assert image.size==(2172,448),(name,image.size)
    colors=image.getcolors(maxcolors=2_000_000)
    assert colors and 96<=len(colors)<=192,(name,len(colors or []))
    # The sun must remain a readable hot core, not a dim flat sky patch.
    hot=sum(count for count,color in colors if color[0]>=235 and color[1]>=220 and color[2]>=155)
    assert hot>=500,(name,hot)

source=(root/'src'/'skyview.lua').read_text(encoding='utf-8')
for token in ['horizonRatio=.285','setFilter("nearest","nearest")','sun-skyview-pixel-v2.png',
              'world and world.clearcutMap','setScissor']:
    assert token in source,token
print('SKYVIEW_ASSETS_OK maps=4 panorama=2172x448 colors<=192 sun=hot_core regional=true')
