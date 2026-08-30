"""Render the live tree-fire art at display scale and 3x nearest zoom."""
from pathlib import Path
import os

from headless_lua import run
from render_clearcut_synergy_ui import render_ui

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/previews'
CAPTURE=OUT/'tree-fire-combustion-v1-draws.json'
OUT.mkdir(parents=True,exist_ok=True)
os.environ['TREE_FIRE_CAPTURE']=str(CAPTURE)
run(ROOT/'scripts/capture_tree_fire_combustion.lua')
image=render_ui(CAPTURE,(760,430))
image.save(OUT/'tree-fire-combustion-v1-display-scale.png')
image.crop((55,185,705,420)).resize((1950,705),resample=0).save(OUT/'tree-fire-combustion-v1-3x.png')
CAPTURE.unlink()
print('TREE_FIRE_COMBUSTION_PREVIEW_OK window=none actual=760x430 zoom=3x')
