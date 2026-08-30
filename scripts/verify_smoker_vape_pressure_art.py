"""Visual-data gates for the authored vape charge, pressure and leaf atlases."""
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
charge=Image.open(ROOT/'assets/effects/smoker-vape-charge-fx-v2.png').convert('RGBA')
gust=Image.open(ROOT/'assets/effects/smoker-vape-pressure-fx-v2.png').convert('RGBA')
leaves=Image.open(ROOT/'assets/effects/smoker-vape-leaves-fx-v2.png').convert('RGBA')
assert charge.size==(6144,256) and gust.size==(6144,1152) and leaves.size==(512,64)

def audit(image,cell_w,cell_h,count,min_pixels,min_colors):
    label=f'{cell_w}x{cell_h}'
    signatures=[]
    for frame in range(count):
        cell=image.crop((frame*cell_w,0,(frame+1)*cell_w,cell_h));alpha=cell.getchannel('A')
        bbox=alpha.getbbox();assert bbox,(label,frame)
        pixels=[p for p in cell.get_flattened_data() if p[3]]
        assert len(pixels)>=min_pixels,(label,frame,len(pixels))
        assert len({p[:3] for p in pixels})>=min_colors,(label,frame,len({p[:3] for p in pixels}))
        signatures.append(bytes(alpha.get_flattened_data()))
    assert len(set(signatures))==count,(label,'repeated frames')

audit(charge,256,256,24,160,6)
gust_frames=[]
for frame in range(24):
    x=(frame%8)*768;y=(frame//8)*384
    gust_frames.append(gust.crop((x,y,x+768,y+384)))
gust_strip=Image.new('RGBA',(768*24,384))
for frame,image in enumerate(gust_frames):gust_strip.paste(image,(frame*768,0))
audit(gust_strip,768,384,24,1800,9)
audit(leaves,64,64,8,70,3)
gust_colors={p[:3] for p in gust.get_flattened_data() if p[3]}
for expected in ((45,204,201),(220,255,238),(35,88,42),(180,203,91)):
    assert expected in gust_colors,('missing material ramp',expected)
print('SMOKER_VAPE_PRESSURE_ART_OK charge=24 pressure=24@30fps/768x384 leaves=8 density=3.2px_per_world')
