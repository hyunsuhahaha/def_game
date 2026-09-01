"""Render the production lobby score-mode entry without opening a window."""
from pathlib import Path
import sys
from headless_lua import run
from render_clearcut_synergy_ui import render_ui

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/previews'
for width,height in ((1280,720),(960,540)):
    run(ROOT/'scripts/capture_score_attack_lobby.lua',f'CAPTURE_W={width};CAPTURE_H={height}')
    suffix='' if width==1280 else f'-{width}'
    image=render_ui(OUT/f'score-attack-lobby-draws{suffix}.json',(width,height))
    image.save(OUT/f'score-attack-lobby-v1{suffix}.png')
    print(f'SCORE_ATTACK_LOBBY_RENDER_OK {width}x{height} window=none')
