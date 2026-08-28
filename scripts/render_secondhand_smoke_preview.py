"""Render the reload-smoke atlas at its exact in-game nearest-neighbour scale."""
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs/previews/secondhand-smoke-fusion-pixel-v2.png"


def crop_frame(sheet, cell_w, cell_h, index, columns=6):
    left = (index % columns) * cell_w
    top = (index // columns) * cell_h
    return sheet.crop((left, top, left + cell_w, top + cell_h))


def main():
    ground = Image.open(ROOT / "assets/forest-ground-tile-v1.png").convert("RGB")
    atlas = Image.open(ROOT / "assets/fx/secondhand-smoke/secondhand-smoke-mist-atlas-pixel-v2.png").convert("RGBA")
    smoker = Image.open(ROOT / "assets/characters/ingame/smoker-atlas-pixel-v2.png").convert("RGBA")

    canvas = Image.new("RGB", (1240, 480), (21, 28, 18))
    tile = ground.crop((160, 220, 880, 620)).resize((720, 400), Image.Resampling.NEAREST)
    canvas.paste(tile, (24, 45))

    body = crop_frame(smoker, 96, 192, 1).resize((59, 117), Image.Resampling.NEAREST)
    source_smoke = crop_frame(atlas, 2048, 1280, 2, 3)
    smoke = source_smoke.resize((640, 400), Image.Resampling.NEAREST)
    smoke.putalpha(smoke.getchannel("A").point(lambda value: round(value * .88)))

    layer = Image.new("RGBA", canvas.size)
    shadow = Image.new("RGBA", canvas.size)
    ImageDraw.Draw(shadow).ellipse((329, 327, 391, 345), fill=(10, 15, 7, 72))
    layer.alpha_composite(shadow)
    layer.alpha_composite(body, (331, 231))
    layer.alpha_composite(smoke, (104, 45))
    canvas = Image.alpha_composite(canvas.convert("RGBA"), layer)

    # Right: a literal 1:1 crop from the native 2048x1280 cell. This verifies
    # the added source density instead of enlarging the already scaled game FX.
    left,top=(source_smoke.width-440)//2,(source_smoke.height-275)//2
    zoom = source_smoke.crop((left,top,left+440,top+275))
    zoom.putalpha(zoom.getchannel("A").point(lambda value: round(value * .88)))
    panel = Image.new("RGBA", (464, 400), (38, 48, 31, 255))
    panel.alpha_composite(zoom, (12, 62))
    canvas.alpha_composite(panel, (744, 45))

    draw = ImageDraw.Draw(canvas)
    draw.text((24, 18), "IN-GAME 640 x 400", fill=(225, 232, 211, 255))
    draw.text((744, 18), "NATIVE 1:1 PIXEL CROP", fill=(225, 232, 211, 255))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(OUT)
    print(f"SECONDHAND_SMOKE_PREVIEW_OK {OUT} {canvas.size}")


if __name__ == "__main__":
    main()
