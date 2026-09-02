from pathlib import Path
from PIL import Image,ImageDraw
from headless_lua import run
from render_clearcut_synergy_ui import render_ui

ROOT=Path(__file__).resolve().parents[1]
PREVIEWS=ROOT/'docs'/'previews'
run(ROOT/'scripts'/'capture_score_melee_toggle.lua')
states=[]
for name in ('on','off'):
    full=render_ui(PREVIEWS/f'score-melee-toggle-{name}-v1-draws.json',(1280,720),(20,29,25,255))
    states.append(full.crop((10,648,92,714)))
board=Image.new('RGB',(640,360),(16,22,19));draw=ImageDraw.Draw(board)
draw.text((28,22),'MELEE TOGGLE / ACTUAL SCALE',fill=(220,228,214))
for i,(name,image) in enumerate(zip(('ON','OFF'),states)):
    x=42+i*300;board.paste(image,(x,62));draw.text((x,136),name,fill=(238,190,92))
    zoom=image.resize((image.width*3,image.height*3),Image.Resampling.NEAREST)
    board.paste(zoom,(x,168))
board.save(PREVIEWS/'score-melee-toggle-v1.png')
print('SCORE_MELEE_TOGGLE_PREVIEW_OK actual+3x window=none')
