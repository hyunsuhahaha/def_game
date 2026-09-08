"""Actual full-map camera and rolling demolition, recorded without a game window."""
from pathlib import Path
import json
from PIL import Image
from headless_lua import run
from verify_forest_arcade_assets import replay
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/previews'
run(ROOT/'scripts/capture_crane_overview.lua')
paths=[OUT/f'crane-overview-{i}.json' for i in range(28)]
for path in paths:
    commands=json.loads(path.read_text(encoding='utf-8'))
    path.write_text(json.dumps([op for op in commands if op['op'] in ('draw','rectangle','ellipse','line')]),encoding='utf-8')
frames,renderer,_=replay(paths,size=(1280,720))
frames[10].save(OUT/'crane-overview-v1.png')
frames[0].save(OUT/'crane-demolition-v1.gif',save_all=True,append_images=frames[1:],duration=80,loop=0)
frames[10].resize((2560,1440),Image.Resampling.NEAREST).save(OUT/'crane-overview-pixels-v1.png')
print('CRANE_OVERVIEW_RENDER_OK actual-camera 1280x720 2x-pixels rolling-demolition 28frames GPU='+renderer)
