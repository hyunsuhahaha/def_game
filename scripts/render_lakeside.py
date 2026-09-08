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
names=[f'lakeside-stage-{tier}' for tier in range(1,6)]+['lakeside-tutorial']
for name in names:
    commands=json.loads((OUT/f'{name}.json').read_text(encoding='utf-8'))
    gpu=OUT/f'{name}-gpu.json'
    text=OUT/f'{name}-text.json'
    gpu.write_text(json.dumps([p for p in commands if p['op'] in ('draw','rectangle','ellipse','line')]),encoding='utf-8')
    text.write_text(json.dumps([p for p in commands if p['op']=='text']),encoding='utf-8')
    paths.append(gpu);texts.append(text)
frames,renderer,_=replay(paths,size=(1280,720))
for name,frame,text in zip(names,frames,texts):
    frame=frame.convert('RGBA')
    frame.alpha_composite(render_ui(text,(1280,720),background=(0,0,0,0)))
    frame.save(OUT/f'{name}-v2.png')
    if name=='lakeside-tutorial':
        frame.crop((320,200,960,520)).resize((1280,640),Image.Resampling.NEAREST).save(OUT/'lakeside-pixel-inspection-v2.png')
print('LAKESIDE_RENDER_OK five stages, one-target tutorial and nearest pixel inspection GPU='+renderer)
