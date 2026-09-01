"""Render PC-time lobby states through the production draw path, without a window."""
from pathlib import Path

from PIL import Image,ImageDraw

from headless_lua import run
from render_clearcut_synergy_ui import render_ui

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs'/'previews'
HOURS=(6,12,17,23)
frames=[]
for hour in HOURS:
    run(ROOT/'scripts'/'capture_score_attack_lobby.lua',f'CAPTURE_W=1280;CAPTURE_H=720;LOBBY_HOUR={hour}')
    frame=render_ui(OUT/f'score-attack-lobby-draws-h{hour:02d}.json',(1280,720))
    frames.append(frame)

sheet=Image.new('RGB',(1280,720),(5,12,10))
draw=ImageDraw.Draw(sheet)
for index,(hour,frame) in enumerate(zip(HOURS,frames)):
    x=(index%2)*640;y=(index//2)*360
    sheet.paste(frame.resize((640,360),Image.Resampling.NEAREST),(x,y))
    draw.rectangle((x+8,y+8,x+92,y+34),fill=(5,24,17))
    draw.text((x+16,y+14),f'{hour:02d}:00',fill=(235,225,174))
sheet.save(OUT/'lobby-pc-time-cycle-v1.png')
frames[-1].save(OUT/'lobby-pc-time-night-v1.png')
frames[-1].crop((700,0,1280,360)).resize((1160,720),Image.Resampling.NEAREST).save(OUT/'lobby-pc-time-night-v1-2x.png')
print('LOBBY_TIME_CYCLE_RENDER_OK hours=06,12,17,23 actual=1280x720 enlarged=2x window=none')
