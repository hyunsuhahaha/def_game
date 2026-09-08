"""Render the real character selection UI commands without a game window."""
from pathlib import Path
from headless_lua import run
from render_clearcut_synergy_ui import render_ui

ROOT=Path(__file__).resolve().parents[1]
run(ROOT/'scripts/verify_score_character_select.lua')
for w,h in ((960,540),(1280,720)):
    for state in ('false','true'):
        path=ROOT/f'docs/previews/character-select-{w}-{state}.json'
        render_ui(path,(w,h)).save(path.with_suffix('.png'))
print('CHARACTER_SELECT_RENDER_OK locked+unlocked 960x540+1280x720 offscreen window=none')
