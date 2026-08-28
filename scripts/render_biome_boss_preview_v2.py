from pathlib import Path
from PIL import Image,ImageDraw

ROOT=Path(__file__).resolve().parents[1]
spec={'beginner':('잘린 숲의 감시목',150,334),'forest':('속빈 고목왕',198,364),'mangrove':('뿌리턱 악어왕',220,368),'madagascar':('바오밥 폭군',178,340),'island':('섬등 소라게',196,356)}
out=Image.new('RGB',(1100,360),(61,92,40));d=ImageDraw.Draw(out)
for i,(name,(label,width,bodyWidth)) in enumerate(spec.items()):
 atlas=Image.open(ROOT/f'assets/enemies/biome-bosses/arcade-v2/{name}-boss-atlas-v2.png').convert('RGBA');im=atlas.crop((0,0,384,384));scale=width/bodyWidth*.72
 im=im.resize((round(384*scale),round(384*scale)),Image.Resampling.NEAREST);x=20+i*216+(196-im.width)//2;y=292-im.height;out.paste(im,(x,y),im)
 d.text((20+i*216,310),label,fill=(240,225,170))
out.save(ROOT/'docs/previews/biome-bosses-v2-display-scale.png');out.resize((2200,720),Image.Resampling.NEAREST).save(ROOT/'docs/previews/biome-bosses-v2-2x.png')
print('BIOME_BOSS_PREVIEW_V2_OK bosses=5 zoom=.72')
