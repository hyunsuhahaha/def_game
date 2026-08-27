from pathlib import Path
from headless_lua import run
from verify_forest_arcade_assets import replay
ROOT=Path(__file__).resolve().parents[1]
run(ROOT/'scripts/capture_bee_art.lua','BEE_CAPTURE=true')
frames,renderer,shaders=replay([ROOT/'docs/previews/bee-runtime-v2-draws.json'],(640,360))
out=ROOT/'docs/previews/bee-runtime-v2.png';frames[0].save(out)
print(f'BEE_RUNTIME_V2_OK renderer={renderer} shaders={shaders} output={out}')
