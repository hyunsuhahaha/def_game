from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
specs={
 'assets/automation/popping-machine-atlas-pixel-v1.png':(1536,192,24),
 'assets/projectiles/puffed-rice-atlas-pixel-v1.png':(512,128,6),
 'assets/fx/puffed-rice-impact-atlas-pixel-v1.png':(1152,192,10),
}
for name,(w,h,min_colors)in specs.items():
 im=Image.open(ROOT/name).convert('RGBA');assert im.size==(w,h),(name,im.size)
 pixels=im.get_flattened_data();colors={p for p in pixels if p[3]};assert len(colors)>=min_colors,(name,len(colors))
 assert all(p[3]in(0,255)for p in pixels),name+' has soft solid-sprite alpha'
print('POPPING_MACHINE_ASSETS_OK machine=6 projectile=4 impact=6 alpha=hard')
