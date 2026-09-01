"""Render the real pizza-oven queue at actual display scale and 3x pixel zoom."""
from pathlib import Path
import os
from headless_lua import run
from render_clearcut_synergy_ui import render_ui

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs'/'previews'
CAPTURE=OUT/'pizza-oven-hearth-fire-v2-draws.json'
OUT.mkdir(parents=True,exist_ok=True)
os.environ['PIZZA_OVEN_BAKING_CAPTURE']=str(CAPTURE)
run(ROOT/'scripts'/'capture_pizza_oven_baking.lua')
image=render_ui(CAPTURE,(760,360))
image.save(OUT/'pizza-oven-hearth-fire-v2-display-scale.png')
image.resize((2280,1080),resample=0).save(OUT/'pizza-oven-hearth-fire-v2-3x.png')
CAPTURE.unlink()
print('PIZZA_OVEN_HEARTH_PREVIEW_OK window=none actual=760x360 zoom=3x no_interior_pizza=true')
