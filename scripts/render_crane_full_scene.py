"""Full Game:draw regression, real perspective maths, companions and HUD on."""
from pathlib import Path
import json
from headless_lua import run
from verify_forest_arcade_assets import replay
from render_clearcut_synergy_ui import render_ui
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/previews'
run(ROOT/'scripts/capture_crane_full_scene.lua')
paths=[];texts=[]
for i in range(16):
    commands=json.loads((OUT/f'crane-full-scene-{i}.json').read_text(encoding='utf-8'))
    gpu=OUT/f'crane-full-scene-gpu-{i}.json'
    gpu.write_text(json.dumps([op for op in commands if op['op'] in ('draw','rectangle','ellipse','line')]),encoding='utf-8')
    text=OUT/f'crane-full-scene-text-{i}.json'
    text.write_text(json.dumps([op for op in commands if op['op']=='text']),encoding='utf-8')
    paths.append(gpu);texts.append(text)
frames,renderer,_=replay(paths,size=(1280,720))
results=[]
for frame,text in zip(frames,texts):
    result=frame.convert('RGBA')
    result.alpha_composite(render_ui(text,(1280,720),background=(0,0,0,0)))
    results.append(result)
results[6].save(OUT/'crane-full-scene-v2.png')
results[0].save(OUT/'crane-full-scene-v2.gif',save_all=True,append_images=results[1:],duration=80,loop=0)
print('CRANE_FULL_RENDER_OK Game.draw perspective+clipping+HUD flame+companions+facilities GPU='+renderer)
