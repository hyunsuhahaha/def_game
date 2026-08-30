"""Render the live tree-fire art at display scale and as an animated GIF."""
from pathlib import Path
import os
import json
from PIL import Image

from headless_lua import run
from render_clearcut_synergy_ui import render_ui

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/previews'
OUT.mkdir(parents=True,exist_ok=True)
capture=OUT/'tree-fire-loop-v2-runtime.json'
os.environ['TREE_FIRE_CAPTURE']=str(capture)
os.environ['TREE_FIRE_CAPTURE_TIME']='1.0'
run(ROOT/'scripts/capture_tree_fire_combustion.lua')
commands=json.loads(capture.read_text(encoding='utf-8'))
# The generic JSON renderer cannot execute the ground-FX shader and would draw
# its cigarette carrier texture as a large capsule.  Remove only that recorded
# smoke command here; the focused Lua verifier still asserts the live shader draw.
commands=[command for command in commands if command.get('shader')!='assets/shaders/cigarette-ground-fx.glsl']
capture.write_text(json.dumps(commands),encoding='utf-8')
runtime=render_ui(capture,(760,430)).convert('RGBA')
capture.unlink()
runtime.save(OUT/'tree-fire-loop-v2-display-scale.png')
crop=(270,150,490,425)
zoom=runtime.crop(crop).resize((660,825),Image.Resampling.NEAREST)
zoom.save(OUT/'tree-fire-loop-v2-3x.png')

# The animated review is assembled from the exact atlas cells consumed by Lua.
# A clean static tree plate keeps every animation frame comparable.
plate=Image.new('RGBA',(760,430),(66,103,38,255))
tree=Image.open(ROOT/'assets/trees/broadleaf-tree-cartoon-v3.png').convert('RGBA')
plate.alpha_composite(tree,(380-tree.width//2,360-round(tree.height*.91)))
atlas=Image.open(ROOT/'assets/fx/tree-fire-loop-atlas-pixel-v2.png').convert('RGBA')
frames=[]
for index in range(16):
    frame=plate.copy()
    fire=atlas.crop((index*320,0,(index+1)*320,320)).resize((128,128),Image.Resampling.NEAREST)
    frame.alpha_composite(fire,(316,251))
    frames.append(frame)
frames[0].save(OUT/'tree-fire-loop-v2-runtime.gif',save_all=True,append_images=frames[1:],duration=72,loop=0,disposal=2)
print('TREE_FIRE_LOOP_V2_PREVIEW_OK window=none actual=760x430 frames=16 gif=runtime')
