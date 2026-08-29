"""Render the separated prism over each totem at its actual runtime scale."""
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs/previews/regrowth-prism-v1-runtime-scale.png"
PRISM = Image.open(ROOT / "assets/enemies/arcade/regrowth-prism-rotation-atlas-v1.png").convert("RGBA")
REGIONS = [
    ("1-1 TEMPERATE", "planter-forest-atlas-v4.png", 68, 206, 0, 42, 43),
    ("2-1 MANGROVE", "planter-mangrove-atlas-v4.png", 70, 210, 1, 42, 43),
    ("3-1 MADAGASCAR", "planter-madagascar-atlas-v4.png", 72, 212, 2, 44, 44),
    ("4-1 ISLAND", "planter-island-atlas-v4.png", 74, 214, 3, 44, 43),
]


def nearest(image, size):
    return image.resize(size, Image.Resampling.NEAREST)


def main():
    canvas = Image.new("RGBA", (1280, 620), (74, 105, 52, 255))
    draw = ImageDraw.Draw(canvas)
    for i, (label, filename, width, body_width, row, prism_width, prism_y) in enumerate(REGIONS):
        left = 25 + i * 315
        draw.rectangle((left, 35, left + 290, 585), fill=(46, 72, 39, 255), outline=(131, 157, 79, 255), width=2)
        draw.text((left + 14, 48), label, fill=(238, 226, 158, 255))
        body_atlas = Image.open(ROOT / "assets/enemies/arcade" / filename).convert("RGBA")
        body = body_atlas.crop((0, 0, 256, 256))
        scale = width / body_width
        body = nearest(body, (round(256 * scale), round(256 * scale)))
        foot = round(248 * scale)
        # Four separate actual-size snapshots. Runtime draws exactly one phase;
        # separating them prevents a QA contact sheet from resembling ghosting.
        for column, phase in enumerate((0, 6, 12, 18)):
            foot_y = 330 + (column % 2) * 170
            x = left + 78 + (column // 2) * 140
            canvas.alpha_composite(body, (round(x - body.width / 2), foot_y - foot))
            prism = PRISM.crop((phase * 64, row * 64, (phase + 1) * 64, (row + 1) * 64))
            prism = nearest(prism, (prism_width, prism_width))
            canvas.alpha_composite(prism, (round(x - prism.width / 2), round(foot_y - prism_y - prism.height / 2)))
            draw.line((x - 52, foot_y, x + 52, foot_y), fill=(191, 151, 70, 150), width=1)
            draw.text((x - 18, foot_y + 18), f"F{phase + 1:02}", fill=(168, 190, 139, 255))
        draw.text((left + 14, 552), f"BODY LOCKED / PRISM 24F / {prism_width}px", fill=(205, 216, 173, 255))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(OUT, quality=95)
    print("REGROWTH_PRISM_RUNTIME_PREVIEW_OK", OUT.relative_to(ROOT))


if __name__ == "__main__":
    main()
