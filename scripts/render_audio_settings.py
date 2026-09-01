"""Render the audio settings screen at production sizes without a game window."""
from pathlib import Path
from headless_lua import run
from render_clearcut_synergy_ui import render_ui

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"docs/previews"
for width,height in ((1280,720),(960,540)):
    run(ROOT/"scripts/capture_audio_settings.lua",f"CAPTURE_W={width};CAPTURE_H={height}")
    suffix="" if width==1280 else f"-{width}"
    target=OUT/f"audio-settings-v1{suffix}.png"
    render_ui(OUT/f"audio-settings-v1{suffix}-draws.json",(width,height)).save(target)
    print(f"AUDIO_SETTINGS_RENDER_OK {target.relative_to(ROOT)} window=none")
