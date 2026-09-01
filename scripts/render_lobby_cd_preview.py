"""Render all three lobby CDs at actual scale and 4x nearest-neighbour scale."""
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / "assets/ui/lobby-cd-tracks-half-pixel-v2.png"
OUT_DISPLAY = ROOT / "docs/previews/lobby-cd-v2-display-scale.png"
OUT_ZOOM = ROOT / "docs/previews/lobby-cd-v2-4x.png"
FRAMES, TRACKS, CELL_W, CELL_H = 32, 3, 160, 84
LABELS = ("FOREST DAY", "RIVER LINE", "OWL SHIFT")
GRASS, PANEL, LINE = (54, 82, 43), (5, 18, 13), (87, 184, 128)
ACCENT = (242, 158, 46)


def tile(atlas, track, frame):
    return atlas.crop((frame * CELL_W, track * CELL_H,
                       (frame + 1) * CELL_W, (track + 1) * CELL_H))


def main():
    atlas = Image.open(ASSET).convert("RGBA")
    display = Image.new("RGB", (720, 270), GRASS)
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

    zoom = Image.new("RGB", (CELL_W * 4 * TRACKS + 32, CELL_H * 4 + 16), PANEL)
    for track in range(TRACKS):
        image = Image.new("RGB", (CELL_W, CELL_H), PANEL)
        frame = tile(atlas, track, 5 + track * 7)
        image.paste(frame, (0, 0), frame)
        zoom.paste(image.resize((CELL_W * 4, CELL_H * 4), Image.Resampling.NEAREST),
                   (8 + track * (CELL_W * 4 + 8), 8))
    zoom.save(OUT_ZOOM)
    print(f"LOBBY_CD_PREVIEW_OK {OUT_DISPLAY.relative_to(ROOT)} {OUT_ZOOM.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
