"""Build the authored 12-frame tree-fire combustion pulse atlas."""
from __future__ import annotations

from pathlib import Path
import math
import random

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/fx/tree-fire-pulse-atlas-pixel-v1.png"
FW, FH, FRAMES = 192, 160, 12

OUTLINE = (92, 25, 13, 255)
DEEP = (151, 37, 13, 255)
ORANGE = (235, 72, 13, 255)
AMBER = (255, 137, 22, 255)
GOLD = (255, 202, 54, 255)
HOT = (255, 244, 166, 255)
SMOKE = ((86, 70, 56, 154), (116, 91, 66, 128), (151, 113, 72, 92))


def rect(d: ImageDraw.ImageDraw, x: float, y: float, w: float, h: float, c) -> None:
    x, y, w, h = round(x), round(y), max(1, round(w)), max(1, round(h))
    d.rectangle((x, y, x + w - 1, y + h - 1), fill=c)


def ember(d: ImageDraw.ImageDraw, x: float, y: float, size: int, heat: int = 0) -> None:
    colors = (OUTLINE, ORANGE, AMBER, GOLD, HOT)
    size = max(2, size)
    rect(d, x - size, y - size // 2, size * 2, size + 1, colors[min(2 + heat, 4)])
    rect(d, x - size // 2, y - size, size, size * 2, colors[min(1 + heat, 4)])
    rect(d, x - size // 3, y - size // 3, max(2, size // 2), max(2, size // 2), HOT)


def tongue(d: ImageDraw.ImageDraw, base_x: float, base_y: float, height: float,
           width: float, phase: float, progress: float) -> None:
    steps = max(4, int(height / 5))
    for step in range(steps):
        q = step / max(1, steps - 1)
        sway = math.sin(q * 8.4 + phase + progress * math.pi * 2) * (2 + q * 8)
        taper = max(.10, 1 - q ** 1.22)
        half = max(2, int(width * taper))
        x = base_x + sway
        y = base_y - q * height
        # Dark outer bark-facing edge, orange body and a stepped hot core.
        rect(d, x - half - 2, y - 4, half * 2 + 4, 7, OUTLINE)
        rect(d, x - half, y - 5, half * 2, 7, DEEP if q > .82 else ORANGE)
        if q < .78:
            inner = max(2, int(half * (.54 - q * .18)))
            rect(d, x - inner, y - 4, inner * 2, 6, AMBER if q > .45 else GOLD)
        if q < .38 and half >= 5:
            rect(d, x - max(1, half // 4), y - 3, max(2, half // 2), 4, HOT)


def make_frame(frame: int) -> Image.Image:
    image = Image.new("RGBA", (FW, FH))
    d = ImageDraw.Draw(image)
    rng = random.Random(43120 + frame)
    t = frame / FRAMES
    pulse = math.sin(min(1, frame / 7) * math.pi)
    base_y = 145

    # A brief root-line rupture leads the beat without becoming a flat circle.
    rupture = math.sin(min(1, frame / 5) * math.pi)
    for side in (-1, 1):
        for i in range(5):
            length = (12 + i * 8) * rupture
            x = 96 + side * length
            y = base_y - 4 - (i % 2) * 3
            rect(d, x - (3 if side < 0 else 0), y, 5 + i % 2, 3, OUTLINE)
            rect(d, x - (2 if side < 0 else 0), y - 2, 4, 3, AMBER if i < 3 else ORANGE)

    # Three coherent tongues surge and collapse on different beats.
    heights = (58 + pulse * 34, 74 + pulse * 48, 48 + pulse * 27)
    for i, (offset, width, phase) in enumerate(((-28, 14, .4), (0, 17, 2.0), (29, 13, 3.7))):
        local = max(.22, pulse * (1 - i * .06) + .18)
        tongue(d, 96 + offset, base_y, heights[i] * local, width, phase, t)

    # Detached fire fragments make the flame break apart instead of reading as one tentacle.
    for i in range(9):
        launch = (frame + i * 3) % FRAMES
        q = launch / (FRAMES - 1)
        side = -1 if i % 2 else 1
        x = 96 + side * (18 + i * 5) * q + math.sin(i * 1.7) * 5
        y = base_y - 28 - (34 + i * 4) * q + 18 * q * q
        if q < .82:
            ember(d, x, y, 2 + (i % 3), 1 if i % 4 == 0 else 0)

    # Sparse stepped smoke pixels live behind the hot silhouette.
    for i in range(4):
        q = ((frame + i * 2) % FRAMES) / (FRAMES - 1)
        x = 96 + math.sin(i * 2.3 + t * 4) * (11 + q * 17)
        y = 102 - q * 52
        c = SMOKE[(i + frame) % len(SMOKE)]
        rect(d, x - 5, y - 3, 11 + i * 2, 5, c)
        rect(d, x - 2, y - 6, 7 + i, 4, c)

    # Tiny hot chips at the base keep the contact point alive at actual display scale.
    for i in range(7):
        x = 67 + i * 10 + rng.randint(-2, 2)
        y = 139 + rng.randint(-2, 2)
        rect(d, x, y, 3 + i % 2, 2 + (i + 1) % 2, GOLD if i % 3 == 0 else ORANGE)
    return image


def main() -> None:
    atlas = Image.new("RGBA", (FW * FRAMES, FH))
    for frame in range(FRAMES):
        atlas.alpha_composite(make_frame(frame), (frame * FW, 0))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(OUT)
    print(f"wrote {OUT.relative_to(ROOT)} {atlas.width}x{atlas.height}")


if __name__ == "__main__":
    main()
