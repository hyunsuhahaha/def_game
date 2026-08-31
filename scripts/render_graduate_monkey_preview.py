"""Replay the real graduation-companion draw path without a game window."""
from pathlib import Path
import os
from headless_lua import run
from render_clearcut_synergy_ui import render_ui

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/previews'
CAPTURE = OUT / 'graduate-monkey-runtime-draws.json'
OUT.mkdir(parents=True, exist_ok=True)
os.environ['GRADUATE_MONKEY_CAPTURE'] = str(CAPTURE)
run(ROOT / 'scripts/capture_graduate_monkey.lua')
image = render_ui(CAPTURE, (640, 320))
image.save(OUT / 'graduate-monkey-runtime-v1.png')
image.resize((image.width * 2, image.height * 2)).save(OUT / 'graduate-monkey-runtime-v1-2x.png')
print('GRADUATE_MONKEY_RENDER_OK 640x320 window=none')
