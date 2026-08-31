"""Render the score-mode weapon hotbar without opening a game window."""
from pathlib import Path

from headless_lua import run
from render_clearcut_synergy_ui import render_ui

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "previews"
run(ROOT / "scripts" / "capture_score_weapon_slots.lua")
image = render_ui(OUT / "score-weapon-hotbar-draws.json", (1280, 720))
image.save(OUT / "score-weapon-hotbar-v2.png")
image.crop((500, 620, 780, 720)).resize((840, 300)).save(OUT / "score-weapon-hotbar-v2-3x.png")
print("SCORE_WEAPON_SLOTS_RENDER_OK 1280x720 window=none")
