"""Replay the production smoker evolution draw path into an offscreen sheet/GIF."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
from headless_lua import run
from render_clearcut_synergy_ui import render_ui

ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'docs/previews'
run(ROOT/'scripts/verify_smoker_weapon_evolutions.lua')
run(ROOT/'scripts/capture_smoker_weapon_evolutions.lua')
frames=[render_ui(OUT/f'smoker-weapon-evolutions-draws-{i}.json',(640,360)) for i in range(6)]
choice=render_ui(OUT/'smoker-weapon-evolution-choice-draws.json',(1280,720));choice.save(OUT/'smoker-weapon-evolution-choice-v1.png')
frames[0].save(OUT/'smoker-weapon-evolutions-v1.gif',save_all=True,append_images=frames[1:],duration=110,loop=0)
sheet=Image.new('RGB',(1280,1080),(9,14,13));draw=ImageDraw.Draw(sheet)
for i,frame in enumerate(frames):sheet.paste(frame,((i%2)*640,(i//2)*360))
font=ImageFont.truetype(str(ROOT/'assets/font-korean-regular.ttf'),21)
draw.text((22,20),'전자담배 — 관통 증기 연사',font=font,fill=(126,245,229))
draw.text((692,20),'폭죽 발사기 — 곡사 로켓 / 다색 폭발',font=font,fill=(255,190,82))
sheet.save(OUT/'smoker-weapon-evolutions-v1.png')
print('SMOKER_WEAPON_EVOLUTION_RENDER_OK renderer=Pillow-command-replay window=none')
