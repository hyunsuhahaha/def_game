"""Render natural lobby distribution and a window-to-fullscreen transition offscreen."""
from pathlib import Path

from headless_lua import run
from render_clearcut_synergy_ui import render_ui


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "previews"


def render(width, height, seconds, name, resize_from=None):
    prefix = (
        f"CAPTURE_W={width};CAPTURE_H={height};LOBBY_HOUR=18;"
        f"LOBBY_NATURAL_LAYOUT=true;LOBBY_PREVIEW_TIME={seconds};"
    )
    suffix = ""
    if resize_from:
        prefix += f"LOBBY_RESIZE_FROM_W={resize_from[0]};LOBBY_RESIZE_FROM_H={resize_from[1]};"
        suffix = "-resized"
    run(ROOT / "scripts" / "capture_lobby_companions.lua", prefix)
    source = OUT / f"lobby-companions-draws-{width}-h18{suffix}.json"
    target = OUT / name
    render_ui(source, (width, height)).save(target)
    return target


if __name__ == "__main__":
    made = (
        render(960, 540, 12, "lobby-companions-v4-natural-960.png"),
        render(1920, 1080, 12, "lobby-companions-v4-natural-1920.png"),
        render(2560, 1440, 12, "lobby-companions-v4-resize-960-to-2560.png", (960, 540)),
    )
    print("LOBBY_COMPANION_DISTRIBUTION_PREVIEW_OK " + " ".join(str(path.relative_to(ROOT)) for path in made) + " window=none")
