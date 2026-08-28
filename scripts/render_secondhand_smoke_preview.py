"""Render the reload-smoke atlas at its exact in-game nearest-neighbour scale."""
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs/previews/secondhand-smoke-fusion-pixel-v1.png"


def crop_frame(sheet, cell_w, cell_h, index):
    return sheet.crop((index * cell_w, 0, (index + 1) * cell_w, cell_h))


def main():
    ground = Image.open(ROOT / "assets/forest-ground-tile-v1.png").convert("RGB")
    atlas = Image.open(ROOT / "assets/fx/secondhand-smoke/secondhand-smoke-mist-atlas-pixel-v1.png").convert("RGBA")
    smoker = Image.open(ROOT / "assets/characters/ingame/smoker-atlas-pixel-v2.png").convert("RGBA")

    canvas = Image.new("RGB", (1240, 480), (21, 28, 18))
    tile = ground.crop((160, 220, 880, 620)).resize((720, 400), Image.Resampling.NEAREST)
    canvas.paste(tile, (24, 45))

    body = crop_frame(smoker, 96, 192, 1).resize((59, 117), Image.Resampling.NEAREST)
    smoke = crop_frame(atlas, 1280, 800, 2).resize((640, 400), Image.Resampling.NEAREST)
    smoke.putalpha(smoke.getchannel("A").point(lambda value: round(value * .88)))

    layer = Image.new("RGBA", canvas.size)
    shadow = Image.new("RGBA", canvas.size)
    ImageDraw.Draw(shadow).ellipse((329, 327, 391, 345), fill=(10, 15, 7, 72))
    layer.alpha_composite(shadow)
    layer.alpha_composite(body, (331, 231))
    layer.alpha_composite(smoke, (104, 45))
    canvas = Image.alpha_composite(canvas.convert("RGBA"), layer)

    # Right: the same final-grid frame at 2x, with no smoothing, so individual
    # authored pixels and ordered dithering remain auditable.
    zoom = smoke.resize((440, 275), Image.Resampling.NEAREST)
    panel = Image.new("RGBA", (464, 400), (38, 48, 31, 255))
    panel.alpha_composite(zoom, (12, 62))
    canvas.alpha_composite(panel, (744, 45))

    draw = ImageDraw.Draw(canvas)
    draw.text((24, 18), "IN-GAME 640 x 400", fill=(225, 232, 211, 255))
    draw.text((744, 18), "PIXEL GRID INSPECTION", fill=(225, 232, 211, 255))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(OUT)
    print(f"SECONDHAND_SMOKE_PREVIEW_OK {OUT} {canvas.size}")


if __name__ == "__main__":
    main()
