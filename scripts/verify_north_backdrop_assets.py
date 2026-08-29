from pathlib import Path
from PIL import Image

root=Path(__file__).resolve().parents[1]/"assets/scenery/north_backdrops"
maps=("forest","mangrove","madagascar","island")
for name in maps:
    panorama=Image.open(root/f"{name}-panorama-pixel-v2.png").convert("RGB")
    assert panorama.size==(2172,724),(name,panorama.size)
    colors=panorama.getcolors(maxcolors=1_000_000)
    assert colors and 96<=len(colors)<=192,(name,len(colors or []))
    ridge=Image.open(root/f"{name}-ridge-pixel-v1.png").convert("RGBA")
    assert ridge.size==(2048,256),(name,ridge.size)
    alpha=ridge.getchannel("A");assert alpha.getbbox(),name
    alpha_values={value for _,value in (alpha.getcolors(maxcolors=3) or [])}
    assert alpha_values and alpha_values.issubset({0,255}),f"{name} ridge has soft alpha leakage"
print("NORTH_BACKDROP_ASSETS_OK maps=4 panorama=2172x724/192colors ridge=2048x256/binary-alpha")
