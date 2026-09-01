"""Render the real code-native oil-link draw path without opening a game window."""
from pathlib import Path

from PIL import Image

from headless_lua import run
from render_clearcut_synergy_ui import render_ui

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"docs"/"previews"
CAPTURE=OUT/"oil-fire-links-v1-draws.json"

run(ROOT/"scripts"/"capture_oil_fire_links.lua")
actual=render_ui(CAPTURE,(1280,520))
actual.save(OUT/"oil-fire-links-v1-display-scale.png")
actual.crop((640,90,1280,410)).resize((1920,960),Image.Resampling.NEAREST).save(
    OUT/"oil-fire-links-v1-3x.png")
print("OIL_FIRE_LINK_PREVIEW_OK actual=1280x520 enlarged=1920x960 window=none")
