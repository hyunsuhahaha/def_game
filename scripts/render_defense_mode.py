from pathlib import Path
from PIL import Image
from headless_lua import run
from render_clearcut_synergy_ui import render_ui

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/previews'
run(ROOT/'scripts/capture_defense_mode.lua')
image=render_ui(OUT/'defense-mode-v1-draws.json',(1280,720))
image.save(OUT/'defense-mode-v1.png')
image.resize((2560,1440),Image.Resampling.NEAREST).save(OUT/'defense-mode-v1-2x.png')
print('DEFENSE_MODE_RENDER_OK display=1280x720 enlarged=2560x1440 window=none')
