"""Render the real developer-tools screen at desktop and minimum supported size."""
from pathlib import Path
from headless_lua import run
from render_clearcut_synergy_ui import render_ui

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs'/'previews'
OUT.mkdir(parents=True,exist_ok=True)
for width,height in ((1280,720),(960,540)):
    capture=OUT/f'developer-tools-{width}x{height}-draws.json'
    escaped=str(capture).replace('\\','\\\\').replace('"','\\"')
    prelude=(f'DEVELOPER_TOOLS_WIDTH={width};DEVELOPER_TOOLS_HEIGHT={height};'
             f'DEVELOPER_TOOLS_CAPTURE_PATH="{escaped}"')
    run(ROOT/'scripts'/'capture_developer_tools.lua',prelude)
    render_ui(capture,(width,height)).save(OUT/f'developer-tools-max-all-{width}x{height}.png')
    capture.unlink()
print('DEVELOPER_TOOLS_PREVIEW_OK window=none sizes=1280x720+960x540')
