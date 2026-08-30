"""Replay the real mole companion/tree/contact draw paths without a game window."""
from pathlib import Path
import os
from headless_lua import run
from render_clearcut_synergy_ui import render_ui

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/previews'
CAPTURE=OUT/'mole-companion-v1-draws.json'
OUT.mkdir(parents=True,exist_ok=True)
os.environ['MOLE_COMPANION_CAPTURE']=str(CAPTURE)
run(ROOT/'scripts/capture_mole_companion.lua')
image=render_ui(CAPTURE,(520,360))
image.save(OUT/'mole-companion-v1-display-scale.png')
image.crop((100,150,390,330)).resize((870,540)).save(OUT/'mole-companion-v1-3x.png')
CAPTURE.unlink()
print('MOLE_COMPANION_PREVIEW_OK window=none actual=520x360 zoom=3x')
