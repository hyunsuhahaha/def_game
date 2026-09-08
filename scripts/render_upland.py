"""Render the actual stage-11 draw commands without opening the game window."""
from pathlib import Path
import json
from PIL import Image
from headless_lua import run
from verify_forest_arcade_assets import replay
from render_clearcut_synergy_ui import render_ui

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/previews'
run(ROOT/'scripts/capture_upland.lua')
commands=json.loads((OUT/'upland-stage-11.json').read_text(encoding='utf-8'))
gpu=OUT/'upland-stage-11-gpu.json'
text=OUT/'upland-stage-11-text.json'
gpu.write_text(json.dumps([p for p in commands if p['op'] in ('draw','rectangle','ellipse','line')]),encoding='utf-8')
text.write_text(json.dumps([p for p in commands if p['op']=='text']),encoding='utf-8')
frame,renderer,_=replay([gpu],size=(1280,720))
frame=frame[0].convert('RGBA')
frame.alpha_composite(render_ui(text,(1280,720),background=(0,0,0,0)))
frame.save(OUT/'upland-stage-11-v1.png')
frame.crop((320,180,960,540)).resize((1280,720),Image.Resampling.NEAREST).save(OUT/'upland-stage-11-pixel-v1.png')
print('UPLAND_RENDER_OK stage11 actual-scale and nearest pixel inspection GPU='+renderer)
