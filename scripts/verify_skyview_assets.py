from pathlib import Path
from PIL import Image

root=Path(__file__).resolve().parents[1]
folder=root/'assets'/'scenery'/'skyview'
expected={
    'sky-clear-pixel-v1.png':(1536,384),
    'horizon-mountains-pixel-v1.png':(1536,160),
    'horizon-forest-pixel-v1.png':(1536,120),
    'horizon-mist-pixel-v1.png':(1536,96),
}
for name,size in expected.items():
    image=Image.open(folder/name).convert('RGBA')
    assert image.size==size,(name,image.size)
    colors=image.getcolors(maxcolors=2_000_000)
    minimum={'sky-clear-pixel-v1.png':20,'horizon-mountains-pixel-v1.png':12,
             'horizon-forest-pixel-v1.png':8,'horizon-mist-pixel-v1.png':5}[name]
    assert colors and len(colors)>=minimum,(name,len(colors or []),minimum)
    if name!='sky-clear-pixel-v1.png':
        alpha=image.getchannel('A').getextrema()
        assert alpha[0]==0 and alpha[1]>0,(name,alpha)

source=(root/'src'/'skyview.lua').read_text(encoding='utf-8')
for token in ['horizonRatio=.285','setFilter("nearest","nearest")','mountains','forest','mist']:
    assert token in source,token
print('SKYVIEW_ASSETS_OK layers=4 sky=1536x384 horizon=mountain+forest+mist')
