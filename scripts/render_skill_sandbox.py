"""Render the real practice panel draw path without opening a game window."""
from pathlib import Path
from headless_lua import run
from render_clearcut_synergy_ui import render_ui

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/previews'
run(ROOT/'scripts/verify_skill_sandbox.lua')
run(ROOT/'scripts/capture_skill_sandbox.lua')
render_ui(OUT/'skill-sandbox-v2-draws.json',(1280,720)).save(OUT/'skill-sandbox-v2.png')
print('SKILL_SANDBOX_RENDER_OK window=none')
