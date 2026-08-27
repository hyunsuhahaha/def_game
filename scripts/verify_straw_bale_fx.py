from pathlib import Path
from PIL import Image
import numpy as np

from headless_lua import run
from verify_forest_arcade_assets import replay

root=Path(__file__).resolve().parents[1]
image=Image.open(root/"assets/fx/straw-bale/straw-bale-atlas-pixel-v3.png").convert("RGBA")
assert image.size==(768,448),image.size
assert set(image.getchannel("A").getdata())<={0,255}
cells=[]
for row in range(2):
    for col in range(6):
        cell=image.crop((col*128,row*224,(col+1)*128,(row+1)*224))
        assert cell.getchannel("A").getbbox(),(row,col)
        cells.append(cell.tobytes())
assert len(set(cells))==12
colors={p[:3] for p in image.getdata() if p[3]}
assert 60<=len(colors)<=130,len(colors)
body=Image.open(root/"assets/fx/straw-bale/straw-bale-body-pixel-v4.png").convert("RGBA")
assert body.size==(320,288)
assert set(body.getchannel("A").getdata())<={0,255}
assert body.getchannel("A").getbbox()[2]-body.getchannel("A").getbbox()[0]>280
body_colors={p[:3] for p in body.getdata() if p[3]}
assert 100<=len(body_colors)<=170,len(body_colors)
run(root/"scripts/verify_straw_bale_gameplay.lua","STRAW_CAPTURE=true")
captures=[root/f"docs/previews/straw-bale-v4-{i}-draws.json" for i in range(18)]
frames,renderer,shader_count=replay(captures,(640,360))
assert shader_count==1,"continuous flame shader was not compiled"
assert len({frame.tobytes() for frame in frames})==18,"flame animation stalled"
samples=np.asarray([np.asarray(frame) for frame in frames],dtype=np.int16)
motion=np.abs(np.diff(samples,axis=0)).sum(axis=3)
assert (motion>12).sum()>3500,"flame lacks continuous per-frame motion"
out=root/"docs/previews"
frames[0].save(out/"straw-bale-runtime-v4.gif",save_all=True,append_images=frames[1:],duration=33,loop=0)
board=Image.new("RGB",(960,720))
for slot,index in enumerate((0,3,6,9,12,15)):
    board.paste(frames[index].crop((160,0,480,360)),((slot%3)*320,(slot//3)*360))
board.save(out/"straw-bale-runtime-v4.png")
print(f"straw bale v4 ok: body_scale=.88 radius=107..160 frames=18 shader={shader_count} renderer={renderer}")
