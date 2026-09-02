"""Render the second-run score tutorial from recorded LÖVE draw commands."""
from pathlib import Path
from headless_lua import run
from render_clearcut_synergy_ui import render_ui

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/previews'
run(ROOT/'scripts/capture_score_tutorial.lua')
for step in range(1,4):
    render_ui(OUT/f'score-tutorial-step{step}-draws.json',(1280,720)).save(OUT/f'score-tutorial-step{step}.png')
render_ui(OUT/'score-tutorial-step1-960-draws.json',(960,540)).save(OUT/'score-tutorial-step1-960.png')
print('SCORE_TUTORIAL_RENDER_OK steps=3 size=1280x720 compact=960x540 window=none')
