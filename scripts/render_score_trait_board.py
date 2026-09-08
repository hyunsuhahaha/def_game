"""Render the active score-mode permanent research board offscreen."""
from pathlib import Path
from headless_lua import run
from render_clearcut_synergy_ui import render_ui

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/previews'
run(ROOT/'scripts/capture_score_trait_board.lua')
image=render_ui(OUT/'score-trait-board-draws.json',(1280,720))
image.save(OUT/'score-trait-board-tabs-v2.png')
zoomout=render_ui(OUT/'score-trait-board-zoomout-draws.json',(1280,720))
zoomout.save(OUT/'score-trait-board-zoomout-v2.png')
wide=render_ui(OUT/'score-trait-board-wide-draws.json',(2048,1038))
wide.save(OUT/'score-trait-board-tabs-wide-v2.png')
flame=render_ui(OUT/'score-trait-board-flame-draws.json',(1280,720))
flame.save(OUT/'score-trait-board-flame-v2.png')
render_ui(OUT/'research-tabs-builder-small.json',(960,540)).save(OUT/'research-tabs-builder-small-v2.png')
render_ui(OUT/'research-tabs-builder.json',(1280,720)).save(OUT/'research-tabs-builder-v2.png')
for name,size in [('mole',(1280,720)),('oil',(1280,720)),('small',(960,540)),('purchase',(1280,720))]:
    render_ui(OUT/f'research-graph-{name}-v2.json',size).save(OUT/f'research-graph-{name}-v2.png')
image.crop((555,315,730,475)).resize((700,640),resample=0).save(OUT/'research-graph-pixel-detail-v2.png')
print('SCORE_TRAIT_BOARD_RENDER_OK 1280x720 default+zoomout+flame-focus, 2048x1038 wide, window=none')
