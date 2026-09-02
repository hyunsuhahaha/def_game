from pathlib import Path
from headless_lua import run
from render_clearcut_synergy_ui import render_ui

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/previews'
run(ROOT/'scripts/capture_bomb_monkey.lua')
image=render_ui(OUT/'bomb-monkey-runtime-draws.json',(1280,720))
image.save(OUT/'bomb-monkey-runtime-v1.png')
image.crop((270,390,1110,700)).resize((1680,620)).save(OUT/'bomb-monkey-runtime-zoom-v1.png')
print('BOMB_MONKEY_RENDER_OK v1 actual=1280x720 zoom=1680x620 window=none')
