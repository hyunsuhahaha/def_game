"""Replay the real world-tree lumber draw calls without opening a game window."""
from pathlib import Path
import json, math, os

from PIL import Image, ImageChops, ImageDraw

from headless_lua import run

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs/previews"
CAPTURE = OUT / "world-tree-lumber-draws.json"
W, H = 400, 420


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
    source = tinted(source, op["color"])
    radius = math.ceil(max(pivot_x, width - pivot_x, pivot_y, height - pivot_y)) + 4
    layer = Image.new("RGBA", (radius * 2, radius * 2))
    layer.alpha_composite(source, (round(radius - pivot_x), round(radius - pivot_y)))
    if angle:
        layer = layer.rotate(-math.degrees(angle), Image.Resampling.BICUBIC, expand=False)
    canvas.alpha_composite(layer, (round(x - radius), round(y - radius)))


def draw_shape(canvas, op):
    # Pillow's ImageDraw overwrites alpha on an RGBA canvas instead of blending,
    # sosemi-transparent shadows came out solid black. Draw onto a scratch layer and
    # composite it instead.
    color = tuple(max(0, min(255, round(v * 255))) for v in op["color"])
    x, y, w, h = op["args"]
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    if op["op"] == "rectangle":
        draw.rectangle((round(x), round(y), round(x + w), round(y + h)), fill=color)
    else:
        draw.ellipse((round(x - w), round(y - h), round(x + w), round(y + h)), fill=color)
    canvas.alpha_composite(layer)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    os.environ["WORLD_TREE_LUMBER_CAPTURE"] = str(CAPTURE)
    run(ROOT / "scripts/capture_world_tree_lumber.lua")
    commands = json.loads(CAPTURE.read_text(encoding="utf-8"))
    canvas = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    sprites = 0
    for op in commands:
        if op["op"] == "draw":
            draw_sprite(canvas, op)
            sprites += 1
        elif op["op"] in {"rectangle", "ellipse"}:
            draw_shape(canvas, op)
    canvas.convert("RGB").save(OUT / "world-tree-lumber-display-scale.png")
    canvas.resize((W * 3, H * 3), Image.Resampling.NEAREST).convert("RGB").save(
        OUT / "world-tree-lumber-3x.png")
    CAPTURE.unlink()
    print(f"WORLD_TREE_LUMBER_PREVIEW_OK window=none actual={W}x{H} zoom=3x lumber={sprites}")


if __name__ == "__main__":
    main()
