from pathlib import Path
from PIL import Image,ImageEnhance,ImageDraw
from headless_lua import run
from render_clearcut_synergy_ui import render_ui

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"docs/previews"
SIZE=(1280,720)

run(ROOT/"scripts/capture_overcrowd_warning.lua")
source=Image.open(OUT/"forest-arcade-v3-camera072.png").convert("RGB")
background=ImageEnhance.Brightness(source.resize(SIZE,Image.Resampling.NEAREST)).enhance(.72).convert("RGBA")
frames=[]
for density in (80,95):
    overlay=render_ui(OUT/f"overcrowd-warning-{density}-draws.json",SIZE,(0,0,0,0))
    frame=background.copy();frame.alpha_composite(overlay)
    frames.append(frame)
board=Image.new("RGBA",(1280,720),(33,40,27,255))
board.alpha_composite(frames[0].resize((640,360),Image.Resampling.NEAREST),(0,0))
board.alpha_composite(frames[1].resize((640,360),Image.Resampling.NEAREST),(640,0))
zoom80=frames[0].crop((0,0,640,240)).resize((640,240),Image.Resampling.NEAREST)
zoom95=frames[1].crop((640,0,1280,240)).resize((640,240),Image.Resampling.NEAREST)
board.alpha_composite(zoom80,(0,420));board.alpha_composite(zoom95,(640,420))
board.save(OUT/"overcrowd-warning-v1-board.png")
print("OVERCROWD_WARNING_PREVIEW_OK 1280x720 threshold=80,95 window=none")
