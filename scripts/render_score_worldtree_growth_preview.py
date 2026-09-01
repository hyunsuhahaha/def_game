"""Render score World Tree growth forms at their real 1x game display sizes."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
BACKGROUND = ROOT / "assets/forest-ground-tile-v1.png"
OUT = ROOT / "docs/previews/score-worldtree-growth-v2-display-scale.png"
ZOOM = ROOT / "docs/previews/score-worldtree-growth-v2-pixel-zoom.png"
CELL, FOOT = 512, 492

FORMS = (
    ("TIER 1", "young", 176, 316, 1.20, 170),
    ("TIER 4", "adolescent", 258, 348, 1.08, 430),
    ("TIER 7", "precursor", 400, 430, .98, 760),
    ("TIER 9", "precursor", 400, 430, 1.28, 1080),
)


def frame(name):
    version = 2 if name == "young" else 1
    atlas = Image.open(ROOT / f"assets/enemies/arcade/score-worldtree-{name}-atlas-v{version}.png").convert("RGBA")
    return atlas.crop((CELL, 0, CELL * 2, CELL))  # undamaged, neutral leaf phase


def main():
    tile = Image.open(BACKGROUND).convert("RGB")
    bg = Image.new("RGB", (1280, 720))
    for y in range(0, bg.height, tile.height):
        for x in range(0, bg.width, tile.width):
            bg.paste(tile, (x, y))
    # A light dusk wash keeps the authored pixels readable without changing them.
    wash = Image.new("RGBA", bg.size, (18, 24, 12, 30))
    board = Image.alpha_composite(bg.convert("RGBA"), wash)
    ground = 625
    draw = ImageDraw.Draw(board)
    font = ImageFont.load_default()
    for label, name, width, body_width, art_scale, x in FORMS:
        sprite = frame(name)
        scale = width / body_width * art_scale
        size = (max(1, round(CELL * scale)), max(1, round(CELL * scale)))
        sprite = sprite.resize(size, Image.Resampling.NEAREST)
        px = round(x - CELL * .5 * scale)
        py = round(ground - FOOT * scale)
        board.alpha_composite(sprite, (px, py))
        radius = {"TIER 1": 100, "TIER 4": 138, "TIER 7": 200, "TIER 9": 275}[label]
        draw.ellipse((x-radius, ground-9, x+radius, ground+9), outline=(226, 183, 79, 190), width=2)
        draw.rectangle((x-34, 654, x+34, 675), fill=(15, 20, 11, 220), outline=(174, 143, 64, 220))
        draw.text((x-26, 660), label, fill=(246, 238, 195, 255), font=font)
    draw.rectangle((18, 18, 608, 63), fill=(12, 17, 9, 220), outline=(155, 135, 69, 220), width=2)
    draw.text((32, 30), "SCORE WORLD TREE 1-9 / ACTUAL 1X DISPLAY + COLLISION FOOTPRINT", fill=(245, 236, 188, 255), font=font)
    board.convert("RGB").save(OUT, optimize=True)

    # Native nearest-neighbour crop proves the leaf/bark clusters at 4x.
    source = frame("precursor").crop((64, 42, 448, 474))
    source.resize((source.width * 4, source.height * 4), Image.Resampling.NEAREST).save(ZOOM, optimize=True)
    print("SCORE_WORLDTREE_GROWTH_PREVIEW_OK actual=1280x720 zoom=4x")


if __name__ == "__main__":
    main()
