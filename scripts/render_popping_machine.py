from pathlib import Path
from headless_lua import run
from render_clearcut_synergy_ui import render_ui
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'docs/previews'
run(ROOT/'scripts/capture_popping_machine.lua')
image=render_ui(OUT/'popping-machine-runtime-draws.json',(1280,720))
image.save(OUT/'popping-machine-runtime-v2.png')
image.crop((240,330,950,700)).resize((1420,740)).save(OUT/'popping-machine-zoom-v2.png')
print('POPPING_MACHINE_RENDER_OK v2 actual=1280x720 zoom=1420x740 window=none')
