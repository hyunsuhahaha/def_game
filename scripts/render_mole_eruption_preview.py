"""Replay the real Lua eruption draw calls without opening a game window."""
from pathlib import Path
import json, math, os

from PIL import Image, ImageChops, ImageDraw

from headless_lua import run


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs/previews"
CAPTURE = OUT / "mole-eruption-v1-draws.json"


def tinted(image, color):
    rgba = tuple(max(0, min(255, round(value * 255))) for value in color)
    return ImageChops.multiply(image, Image.new("RGBA", image.size, rgba))


def draw_sprite(canvas, op):
    qx, qy, w, h, _, _ = op["quad"]
    source = Image.open(ROOT / op["file"]).convert("RGBA").crop((qx, qy, qx + w, qy + h))
    x, y, angle, sx, sy, ox, oy = (op["args"] + [0, 1, 1, 0, 0])[:7]
    width, height = max(1, round(w * abs(sx))), max(1, round(h * abs(sy)))
    source = source.resize((width, height), Image.Resampling.NEAREST)
    pivot_x, pivot_y = ox * abs(sx), oy * abs(sy)
    if sx < 0:
        source = source.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        pivot_x = width - pivot_x
    if sy < 0:
        source = source.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
        pivot_y = height - pivot_y
    source = tinted(source, op["color"])
    radius = math.ceil(max(pivot_x, width - pivot_x, pivot_y, height - pivot_y)) + 3
    layer = Image.new("RGBA", (radius * 2, radius * 2))
    layer.alpha_composite(source, (round(radius - pivot_x), round(radius - pivot_y)))
    if angle:
        layer = layer.rotate(-math.degrees(angle), Image.Resampling.NEAREST, expand=False)
    canvas.alpha_composite(layer, (round(x - radius), round(y - radius)))


def draw_shape(canvas, op):
    draw = ImageDraw.Draw(canvas, "RGBA")
    color = tuple(round(value * 255) for value in op["color"])
    x, y, w, h = op["args"]
    box = (round(x), round(y), round(x + w), round(y + h))
    if op["op"] == "rectangle":
        draw.rectangle(box, fill=color)
    elif op["op"] == "ellipse":
        draw.ellipse((round(x - w), round(y - h), round(x + w), round(y + h)), fill=color)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    os.environ["MOLE_ERUPTION_CAPTURE"] = str(CAPTURE)
    run(ROOT / "scripts/capture_mole_eruption.lua")
    commands = json.loads(CAPTURE.read_text(encoding="utf-8"))
    canvas = Image.new("RGBA", (400, 300), (0, 0, 0, 255))
    for op in commands:
        if op["op"] == "draw":
            assert op["filter"] == "nearest"
            draw_sprite(canvas, op)
        elif op["op"] in {"rectangle", "ellipse"}:
            draw_shape(canvas, op)
    actual = OUT / "mole-eruption-v1-display-scale.png"
    zoom = OUT / "mole-eruption-v1-3x.png"
    canvas.convert("RGB").save(actual)
    canvas.resize((1200, 900), Image.Resampling.NEAREST).convert("RGB").save(zoom)
    CAPTURE.unlink()
    print(f"MOLE_ERUPTION_PREVIEW_OK window=none actual=400x300 zoom=3x draws={len(commands)}")


if __name__ == "__main__":
    main()
