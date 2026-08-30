"""Build the smoker butt landing/ignition impact atlas on a fixed pixel grid."""
from __future__ import annotations

from pathlib import Path
import math
import random

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/fx/cigarette-impact-atlas-pixel-v1.png"
FRAME = 160
FRAMES = 10

HOT = [(255, 246, 177, 255), (255, 206, 69, 255), (255, 125, 24, 255), (178, 45, 16, 255)]
ASH = [(163, 126, 78, 225), (145, 110, 70, 218), (124, 95, 62, 225),
       (107, 83, 58, 230), (88, 72, 57, 225), (73, 62, 51, 220), (57, 51, 45, 205)]
FLAME = [(255, 246, 174, 255), (255, 189, 51, 255), (244, 86, 19, 255), (139, 33, 18, 255)]
LEAF = [(129, 137, 48, 235), (83, 105, 38, 235), (172, 151, 54, 230)]


def px_rect(draw: ImageDraw.ImageDraw, x: float, y: float, w: int, h: int, color):
    x, y = int(round(x)), int(round(y))
    draw.rectangle((x, y, x + w - 1, y + h - 1), fill=color)


def cluster(draw: ImageDraw.ImageDraw, x: float, y: float, size: int, ramp, shade: int = 0):
    """A stepped, outlined pixel cluster rather than a smooth runtime primitive."""
    x, y = int(round(x)), int(round(y))
    dark = ramp[min(len(ramp) - 1, shade + 2)]
    mid = ramp[min(len(ramp) - 1, shade + 1)]
    light = ramp[min(len(ramp) - 1, shade)]
    draw.polygon([(x-size, y), (x-size//2, y-size), (x+size//2, y-size),
                  (x+size, y), (x+size//2, y+size), (x-size//2, y+size)], fill=dark)
    px_rect(draw, x-size//2, y-size//2, max(2, size), max(2, size), mid)
    px_rect(draw, x-size//3, y-size//2, max(2, size//2), max(2, size//3), light)


def landing_frame(frame: int) -> Image.Image:
    im = Image.new("RGBA", (FRAME, FRAME))
    d = ImageDraw.Draw(im)
    t = frame / (FRAMES - 1)
    cx, cy = 80, 104
    rng = random.Random(8100 + frame)

    # Contact flash peaks immediately and collapses into the glowing butt tip.
    if frame <= 3:
        flash = [22, 30, 21, 12][frame]
        for arm in range(8):
            a = arm * math.pi / 4
            length = flash * (0.76 if arm % 2 else 1)
            steps = max(2, int(length / 4))
            for step in range(steps):
                q = step / steps
                color = HOT[0 if q < .28 else 1 if q < .62 else 2]
                px_rect(d, cx + math.cos(a)*length*q, cy + math.sin(a)*length*q*.58,
                        5 if step < 2 else 3, 4 if step < 2 else 3, color)
        cluster(d, cx, cy, max(4, 11-frame*2), HOT)

    # Authored ballistic flecks: upward first, then gravity and fading.
    for i in range(11):
        a = -math.pi + i * math.pi / 10
        speed = 27 + (i % 4) * 6
        q = min(1, t * 1.28)
        x = cx + math.cos(a) * speed * q
        y = cy - abs(math.sin(a)) * speed * q + 35*q*q
        if q < .86 or i % 3:
            size = max(2, 5 - frame // 3 - i % 2)
            cluster(d, x, y, size, HOT, 1 if frame > 5 else 0)

    # Low ash/dirt chips spread on the floor and break the perfect radial shape.
    for i in range(9):
        side = -1 if i % 2 == 0 else 1
        reach = 12 + i * 4.2
        x = cx + side * reach * min(1, t*1.6) + rng.randint(-2, 2)
        y = cy + 7 + (i % 3)*3 + rng.randint(-1, 1)
        if frame < 8 or i % 2:
            px_rect(d, x, y, 5 + i % 3, 3 + (i+1) % 2, ASH[(i+frame) % len(ASH)])
    return im


def ignition_frame(frame: int) -> Image.Image:
    im = Image.new("RGBA", (FRAME, FRAME))
    d = ImageDraw.Draw(im)
    t = frame / (FRAMES - 1)
    cx, base = 80, 127

    # A sharp bark-contact star makes the exact ignition frame legible.
    if frame <= 3:
        radius = [13, 33, 25, 13][frame]
        for arm in range(12):
            a = arm * math.pi / 6
            for step in range(2, max(3, radius // 3)):
                q = step / max(3, radius // 3)
                px_rect(d, cx + math.cos(a)*radius*q, base-8 + math.sin(a)*radius*q*.62,
                        4 if q < .45 else 3, 4 if q < .45 else 3,
                        HOT[0 if q < .25 else 1 if q < .62 else 2])

    # Three changing tongues rise from separate roots; this reads as catching fire,
    # not as a single soft cone or a runtime ellipse.
    grow = min(1, t * 1.9)
    fade = min(1, (1-t) * 2.6)
    for tongue, (offset, height, phase) in enumerate(((-20, 64, .2), (1, 91, 1.7), (22, 53, 3.1))):
        h = height * grow
        segments = max(1, int(h / 7))
        for s in range(segments):
            q = s / max(1, segments-1)
            sway = math.sin(q*7 + phase + frame*.9) * (3 + q*7)
            width = max(3, int((10 + tongue*2) * (1-q*.74) * fade))
            x, y = cx + offset + sway, base - q*h
            color = FLAME[0 if q < .23 else 1 if q < .56 else 2 if q < .84 else 3]
            px_rect(d, x-width, y-5, width*2, 7, color)
            if width > 5:
                px_rect(d, x-width//2, y-4, width, 4, FLAME[max(0, (0 if q < .45 else 1))])

    # Detached embers and a few leaf chips communicate force through the canopy.
    for i in range(12):
        q = min(1, t * (1.25 + (i % 3)*.08))
        a = -2.83 + i * .51
        x = cx + math.cos(a)*(27+i*2)*q
        y = base-13 - abs(math.sin(a))*(50+i*2)*q + 20*q*q
        if frame < 8 or i % 4:
            cluster(d, x, y, max(2, 5-frame//4), HOT, 1)
    for i in range(5):
        q = min(1, max(0, t-.12)*1.4)
        side = -1 if i % 2 else 1
        x = cx + side*(24+i*9)*q
        y = base-35-i*7*q+17*q*q
        px_rect(d, x, y, 7, 4, LEAF[i % len(LEAF)])
        px_rect(d, x+2, y-2, 3, 2, LEAF[(i+1) % len(LEAF)])
    return im


def main() -> None:
    atlas = Image.new("RGBA", (FRAME * FRAMES, FRAME * 2))
    for i in range(FRAMES):
        atlas.alpha_composite(landing_frame(i), (i * FRAME, 0))
        atlas.alpha_composite(ignition_frame(i), (i * FRAME, FRAME))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(OUT)
    print(f"wrote {OUT.relative_to(ROOT)} {atlas.width}x{atlas.height}")


if __name__ == "__main__":
    main()
