"""Replay the production world draw queue without opening a game window."""
from pathlib import Path
import json
from PIL import Image
from headless_lua import run
from verify_forest_arcade_assets import replay
from render_clearcut_synergy_ui import render_ui

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/previews'
run(ROOT/'scripts/capture_job_master.lua')
paths=[OUT/f'job-master-runtime-{i}.json' for i in range(8)]
# The shared GPU replayer handles sprite shaders and geometry, not text.
for path in paths:
    commands=json.loads(path.read_text(encoding='utf-8'))
    path.write_text(json.dumps([op for op in commands if op['op'] in ('draw','rectangle','ellipse','line')]),encoding='utf-8')
frames,renderer,count=replay(paths,size=(1280,900))
views=[frame.resize((1075,756),Image.Resampling.NEAREST) for frame in frames]
views[2].save(OUT/'job-master-runtime-v1.png')
views[0].save(OUT/'job-master-motion-v1.gif',save_all=True,append_images=views[1:],duration=100,loop=0)
frames[2].crop((240,260,900,690)).resize((1320,860),Image.Resampling.NEAREST).save(OUT/'job-master-pixels-v1.png')
render_ui(OUT/'job-master-research.json',(1280,720)).save(OUT/'job-master-research-v1.png')
for path in (ROOT/'assets/construction').glob('*.png'):
    im=Image.open(path).convert('RGBA')
    assert {value for count,value in im.getchannel('A').getcolors()}=={0,255},path
    # Concrete is one 16-step material ramp, unlike the multi-material mast.
    assert len(im.getcolors(im.width*im.height))>=16,path
sheet=Image.open(ROOT/'assets/construction/concrete-pipe-roll-atlas-v1.png')
assert len({sheet.crop((i*192,0,(i+1)*192,192)).tobytes() for i in range(12)})==12
print('JOB_MASTER_RENDER_OK GPU='+renderer+' actual=.84 enlarged=2x solid-alpha=hard motion=12frames window=none')
