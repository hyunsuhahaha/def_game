"""Replay the real world-tree reward card draw calls without opening a game window."""
from pathlib import Path
import json, os

from PIL import Image, ImageDraw, ImageFont

from headless_lua import run

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs/previews"
CAPTURE = OUT / "score-reward-cards-draws.json"
W, H = 1280, 720

_fonts = {}


def font(path, size):
    key = (path, size)
    if key not in _fonts:
        _fonts[key] = ImageFont.truetype(str(ROOT / path), size)
    return _fonts[key]


def rgba(color):
    return tuple(max(0, min(255, round(v * 255))) for v in color)


def wrap(draw, text, face, width):
    lines, line = [], ""
    for ch in text:
        probe = line + ch
        if draw.textlength(probe, font=face) > width and line:
            lines.append(line)
            line = ch
        else:
            line = probe
    if line:
        lines.append(line)
    return lines


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    os.environ["SCORE_REWARD_CARDS_CAPTURE"] = str(CAPTURE)
    run(ROOT / "scripts/capture_score_reward_cards.lua")
    commands = json.loads(CAPTURE.read_text(encoding="utf-8"))
    canvas = Image.new("RGBA", (W, H), (26, 40, 22, 255))
    texts = 0
    for op in commands:
        layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        draw = ImageDraw.Draw(layer)
        color = rgba(op["color"])
        if op["op"] == "rectangle":
            x, y, w, h = op["args"]
            box = (round(x), round(y), round(x + w), round(y + h))
            radius = op.get("radius")
            if op["mode"] == "fill":
                (draw.rounded_rectangle(box, radius=round(radius), fill=color)
                 if radius else draw.rectangle(box, fill=color))
            else:
                (draw.rounded_rectangle(box, radius=round(radius), outline=color, width=2)
                 if radius else draw.rectangle(box, outline=color, width=2))
        elif op["op"] == "text":
            texts += 1
            face = font(op["file"], op["size"])
            x, y, width = op["args"]
            for i, line in enumerate(wrap(draw, op["text"], face, width) if width else [op["text"]]):
                offset = 0
                if op["align"] == "center" and width:
                    offset = (width - draw.textlength(line, font=face)) / 2
                draw.text((x + offset, y + i * (op["size"] + 6)), line, font=face, fill=color)
        else:
            continue
        canvas.alpha_composite(layer)
    canvas.convert("RGB").save(OUT / "score-reward-cards-1280.png")
    CAPTURE.unlink()
    print(f"SCORE_REWARD_CARDS_PREVIEW_OK window=none actual={W}x{H} texts={texts}")


if __name__ == "__main__":
    main()
