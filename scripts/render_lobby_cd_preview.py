"""Render all lobby CDs at actual scale and 4x nearest-neighbour scale."""
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / "assets/ui/lobby-cd-tracks-half-pixel-v2.png"
OUT_DISPLAY = ROOT / "docs/previews/lobby-cd-v2-display-scale.png"
OUT_ZOOM = ROOT / "docs/previews/lobby-cd-v2-4x.png"
FRAMES, TRACKS, CELL_W, CELL_H = 32, 8, 160, 84
LABELS = ("FOREST DAY", "RIVER LINE", "OWL SHIFT", "SAWMILL RUN",
          "RAIN SHACK", "LAST LIGHT", "DREAM PARADE", "WAKING ROOT")
GRASS, PANEL, LINE = (54, 82, 43), (5, 18, 13), (87, 184, 128)
ACCENT = (242, 158, 46)


def tile(atlas, track, frame):
    return atlas.crop((frame * CELL_W, track * CELL_H,
                       (frame + 1) * CELL_W, (track + 1) * CELL_H))


def main():
    atlas = Image.open(ASSET).convert("RGBA")
    display = Image.new("RGB", (720, 18 + TRACKS * 84), GRASS)
    draw = ImageDraw.Draw(display)
    for track in range(TRACKS):
        y = 12 + track * 84
        draw.rectangle((12, y + 48, 707, y + 81), fill=PANEL, outline=LINE, width=2)
        draw.rectangle((12, y + 48, 16, y + 81), fill=ACCENT)
        draw.text((190, y + 58), LABELS[track], fill=(172, 203, 169))
        for column, frame in enumerate((0, 8, 16, 24)):
            image = tile(atlas, track, frame)
            x = 32 + column * 155
            display.paste(image, (x, y - 32), image)
    OUT_DISPLAY.parent.mkdir(parents=True, exist_ok=True)
    display.save(OUT_DISPLAY)

    columns = 4
    rows = (TRACKS + columns - 1) // columns
    zoom = Image.new("RGB", (CELL_W * 4 * columns + 40, CELL_H * 4 * rows + 24), PANEL)
    for track in range(TRACKS):
        image = Image.new("RGB", (CELL_W, CELL_H), PANEL)
        frame = tile(atlas, track, (5 + track * 7) % FRAMES)
        image.paste(frame, (0, 0), frame)
        column, row = track % columns, track // columns
        zoom.paste(image.resize((CELL_W * 4, CELL_H * 4), Image.Resampling.NEAREST),
                   (8 + column * (CELL_W * 4 + 8), 8 + row * (CELL_H * 4 + 8)))
    zoom.save(OUT_ZOOM)
    print(f"LOBBY_CD_PREVIEW_OK {OUT_DISPLAY.relative_to(ROOT)} {OUT_ZOOM.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
