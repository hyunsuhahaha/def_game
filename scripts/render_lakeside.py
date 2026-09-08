"""Actual game-command renders, not concept composites; no game window."""
from pathlib import Path
import json
from PIL import Image
from headless_lua import run
from verify_forest_arcade_assets import replay
from render_clearcut_synergy_ui import render_ui
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/previews'
run(ROOT/'scripts/capture_lakeside.lua')
paths=[]
texts=[]
for tier in range(1,6):
    commands=json.loads((OUT/f'lakeside-stage-{tier}.json').read_text(encoding='utf-8'))
    gpu=OUT/f'lakeside-stage-{tier}-gpu.json'
    text=OUT/f'lakeside-stage-{tier}-text.json'
    gpu.write_text(json.dumps([p for p in commands if p['op'] in ('draw','rectangle','ellipse','line')]),encoding='utf-8')
    text.write_text(json.dumps([p for p in commands if p['op']=='text']),encoding='utf-8')
    paths.append(gpu);texts.append(text)
frames,renderer,_=replay(paths,size=(1280,720))
for tier,(frame,text) in enumerate(zip(frames,texts),1):
    frame=frame.convert('RGBA')
    frame.alpha_composite(render_ui(text,(1280,720),background=(0,0,0,0)))
    frame.save(OUT/f'lakeside-stage-{tier}-v1.png')
    if tier==3:
        frame.crop((920,180,1240,500)).resize((640,640),Image.Resampling.NEAREST).save(OUT/'lakeside-pixel-inspection-v1.png')
print('LAKESIDE_RENDER_OK five actual-scale frames and nearest pixel inspection GPU='+renderer)
