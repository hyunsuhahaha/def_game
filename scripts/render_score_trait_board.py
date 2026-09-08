"""Render the active score-mode permanent research board offscreen."""
from pathlib import Path
from headless_lua import run
from render_clearcut_synergy_ui import render_ui

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/previews'
run(ROOT/'scripts/capture_score_trait_board.lua')
image=render_ui(OUT/'score-trait-board-draws.json',(1280,720))
image.save(OUT/'score-trait-board-tabs-v1.png')
zoomout=render_ui(OUT/'score-trait-board-zoomout-draws.json',(1280,720))
zoomout.save(OUT/'score-trait-board-zoomout-v1.png')
wide=render_ui(OUT/'score-trait-board-wide-draws.json',(2048,1038))
wide.save(OUT/'score-trait-board-tabs-wide-v1.png')
render_ui(OUT/'research-tabs-builder-small.json',(960,540)).save(OUT/'research-tabs-builder-small-v1.png')
render_ui(OUT/'research-tabs-builder.json',(1280,720)).save(OUT/'research-tabs-builder-v1.png')
print('SCORE_TRAIT_BOARD_RENDER_OK 1280x720 default+zoomout, 2048x1038 wide, window=none')
