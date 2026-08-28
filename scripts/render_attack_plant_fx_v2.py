from pathlib import Path
from PIL import Image,ImageDraw

ROOT=Path(__file__).resolve().parents[1];atlas=Image.open(ROOT/'assets/fx/attack-plants/attack-plant-projectiles-atlas-v2.png').convert('RGBA')
bg=Image.new('RGB',(1080,360),(61,92,40));d=ImageDraw.Draw(bg)
labels=('폭발 씨앗','대나무 압축탄','송진 덩어리','송진 장판');scales=(.23,.34,.24,.72)
for row,(label,scale) in enumerate(zip(labels,scales)):
 y=28+row*82;d.text((24,y+25),label,fill=(235,220,172))
 for frame in range(6):
  im=atlas.crop((frame*160,row*160,(frame+1)*160,(row+1)*160));size=round(160*scale*.72)
  if row==3: im=im.resize((size,round(size*.72)),Image.Resampling.NEAREST)
  else: im=im.resize((size,size),Image.Resampling.NEAREST)
  bg.paste(im,(190+frame*138+(80-im.width)//2,y+(60-im.height)//2),im)
bg.save(ROOT/'docs/previews/attack-plant-fx-v2-display-scale.png')
bg.resize((2160,720),Image.Resampling.NEAREST).save(ROOT/'docs/previews/attack-plant-fx-v2-2x.png')
print('ATTACK_PLANT_FX_PREVIEW_OK display=1080x360 zoom=.72')
