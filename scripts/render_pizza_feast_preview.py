"""Render the persistent pizza feast visual through the real companion draw path."""
from pathlib import Path
import os
from headless_lua import run
from render_clearcut_synergy_ui import render_ui

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs'/'previews'
CAPTURE=OUT/'pizza-feast-v1-draws.json'
OUT.mkdir(parents=True,exist_ok=True)
os.environ['PIZZA_FEAST_CAPTURE']=str(CAPTURE)
run(ROOT/'scripts'/'capture_pizza_feast.lua')
image=render_ui(CAPTURE,(520,320))
image.save(OUT/'pizza-feast-aura-v1-display-scale.png')
image.resize((1040,640)).save(OUT/'pizza-feast-aura-v1-2x.png')
CAPTURE.unlink()
print('PIZZA_FEAST_PREVIEW_OK window=none actual=520x320 zoom=2x')
