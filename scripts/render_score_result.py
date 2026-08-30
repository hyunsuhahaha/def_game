"""Render the active score-mode result screen offscreen."""
from pathlib import Path
from headless_lua import run
from render_clearcut_synergy_ui import render_ui

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/previews'
run(ROOT/'scripts/capture_score_result.lua')
render_ui(OUT/'score-result-draws.json',(1280,720)).save(OUT/'score-result-v1.png')
render_ui(OUT/'score-result-compact-draws.json',(960,540)).save(OUT/'score-result-compact-v1.png')
print('SCORE_RESULT_RENDER_OK 1280x720+960x540 window=none')
