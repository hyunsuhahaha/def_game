"""Render all production lobby CD variants without opening a game window."""
from pathlib import Path

from PIL import Image, ImageDraw

from headless_lua import run
from render_clearcut_synergy_ui import render_ui


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs/previews"
LABELS = ("FOREST DAY / LOOP 07", "RIVER LINE / LOOP 03", "OWL SHIFT / LOOP 11",
          "SAWMILL RUN / LOOP 16", "RAIN SHACK / LOOP 05", "LAST LIGHT / LOOP 09",
          "DREAM PARADE / LOOP 13")


def render_set(width, height, suffix):
    frames = []
    for track in range(1, len(LABELS) + 1):
        run(ROOT / "scripts/capture_score_attack_lobby.lua",
            f"CAPTURE_W={width};CAPTURE_H={height};LOBBY_HOUR=12;"
            f"LOBBY_TRACK={track};LOBBY_CD_ANGLE=.19")
        size_suffix = "" if width == 1280 else f"-{width}"
        draws = OUT / f"score-attack-lobby-draws{size_suffix}-h12-track{track}.json"
        frame = render_ui(draws, (width, height))
        frames.append(frame)
    board = Image.new("RGB", (width, height * len(LABELS)), (5, 18, 13))
    draw = ImageDraw.Draw(board)
    for index, frame in enumerate(frames):
        board.paste(frame, (0, index * height))
        draw.rectangle((8, index * height + 8, 230, index * height + 32), fill=(5, 18, 13))
        draw.text((16, index * height + 14), LABELS[index], fill=(194, 220, 185))
    target = OUT / f"lobby-cd-v2-production-{suffix}.png"
    board.save(target)
    return target


def main():
    wide = render_set(1280, 720, "tracks")
    compact = render_set(960, 540, "compact")
    print(f"LOBBY_CD_PRODUCTION_PREVIEW_OK {wide.relative_to(ROOT)} "
          f"{compact.relative_to(ROOT)} window=none")


if __name__ == "__main__":
    main()
