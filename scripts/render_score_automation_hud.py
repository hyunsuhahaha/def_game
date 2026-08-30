"""Render the score-mode automation procurement rail without opening a window."""
from pathlib import Path
from headless_lua import run
from render_clearcut_synergy_ui import render_ui
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'docs/previews'
run(ROOT/'scripts/capture_score_automation_hud.lua')
image=render_ui(OUT/'score-automation-hud-draws.json',(1280,720))
image.save(OUT/'score-automation-hud-v1.png')
print('SCORE_AUTOMATION_HUD_RENDER_OK 1280x720 window=none')
