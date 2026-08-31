"""Render the score-mode weapon hotbar without opening a game window."""
from pathlib import Path

from headless_lua import run
from render_clearcut_synergy_ui import render_ui

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "previews"
run(ROOT / "scripts" / "capture_score_weapon_slots.lua")
render_ui(OUT / "score-weapon-slots-draws.json", (1280, 720)).save(OUT / "score-weapon-slots-v1.png")
print("SCORE_WEAPON_SLOTS_RENDER_OK 1280x720 window=none")
