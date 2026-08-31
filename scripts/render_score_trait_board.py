"""Render the active score-mode permanent research board offscreen."""
from pathlib import Path
from headless_lua import run
from render_clearcut_synergy_ui import render_ui

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/previews'
run(ROOT/'scripts/capture_score_trait_board.lua')
image=render_ui(OUT/'score-trait-board-draws.json',(1280,720))
image.save(OUT/'score-trait-board-v1.png')
universal_actual=render_ui(OUT/'score-trait-board-universal-draws.json',(1280,720))
universal_actual.save(OUT/'score-trait-board-universal-v2.png')
wide=render_ui(OUT/'score-trait-board-wide-draws.json',(2048,1038))
wide.save(OUT/'score-trait-board-wide-v2.png')
universal=render_ui(OUT/'score-trait-board-universal-wide-draws.json',(2048,1038))
universal.save(OUT/'score-trait-board-universal-wide-v1.png')
print('SCORE_TRAIT_BOARD_RENDER_OK 1280x720+2048x1038 universal=1280x720+2048x1038 window=none')
