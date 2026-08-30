"""Render the production lobby score-mode entry without opening a window."""
from pathlib import Path
import sys
from headless_lua import run
from render_clearcut_synergy_ui import render_ui

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/previews'
run(ROOT/'scripts/capture_score_attack_lobby.lua')
image=render_ui(OUT/'score-attack-lobby-draws.json',(1280,720))
image.save(OUT/'score-attack-lobby-v1.png')
print('SCORE_ATTACK_LOBBY_RENDER_OK 1280x720 window=none')
