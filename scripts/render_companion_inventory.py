from pathlib import Path
import os
from headless_lua import run
from render_clearcut_synergy_ui import render_ui
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'docs'/'previews';OUT.mkdir(parents=True,exist_ok=True)
capture=OUT/'companion-inventory-runtime.json';os.environ['COMPANION_INVENTORY_CAPTURE']=str(capture)
run(ROOT/'scripts'/'capture_companion_inventory.lua')
image=render_ui(capture,(1280,720));image.save(OUT/'companion-inventory-runtime-v1.png')
print('COMPANION_INVENTORY_RENDER_OK 1280x720 window=none')
