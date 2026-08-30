"""Build the authored continuous tree-root fire loop with pixel sparks."""
from __future__ import annotations

from pathlib import Path
import math

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/fx/tree-fire-loop-atlas-pixel-v2.png"
GIF_OUT = ROOT / "assets/fx/tree-fire-loop-pixel-v2.gif"
FRAMES = 16
DW = DH = 160
SCALE = 2
FW = FH = DW * SCALE

EDGE = (83, 19, 10, 255)
DEEP = (137, 29, 8, 255)
RED = (196, 43, 7, 255)
ORANGE = (239, 68, 6, 255)
AMBER = (255, 128, 11, 255)
GOLD = (255, 194, 35, 255)
HOT = (255, 240, 143, 255)


def flame_shape(cx: float, base_y: float, height: float, width: float,
                phase: float, frame: int, inset: float = 0) -> list[tuple[int, int]]:
    t = frame / FRAMES * math.tau
    left, right = [], []
    for i in range(12):
        q = i / 11
        taper = max(.025, (1 - q) ** .72)
        half = width * taper * (1 - inset)
        sway = math.sin(q * 6.2 + phase + t) * (1.0 + q * 4.8)
        sway += math.sin(q * 12.4 - phase + t * .57) * (.5 + q * 1.8)
        y = base_y - q * height + math.sin(q * 7.1 + phase + t * .43)
        bite = (i % 3 == int(phase * 3) % 3) * (1 + q * 1.4)
        left.append((round(cx + sway - half + bite), round(y)))
        right.append((round(cx + sway + half), round(y + i % 2)))
    return left + list(reversed(right))


def flame(draw: ImageDraw.ImageDraw, cx: float, base_y: float, height: float,
          width: float, phase: float, frame: int) -> None:
    # Each tongue breathes independently by only five percent.
    local_height = height * (1 + math.sin(frame / FRAMES * math.tau + phase) * .05)
    layers = (
        (EDGE, 1.08, 1.12, 0),
        (DEEP, 1.00, 1.00, 0),
        (ORANGE, .84, .72, .03),
        (AMBER, .62, .48, .07),
        (GOLD, .43, .29, .10),
        (HOT, .25, .15, .14),
    )
    for color, hs, ws, inset in layers:
        draw.polygon(flame_shape(cx, base_y - (1 if color != EDGE else 0),
                                 local_height * hs, width * ws, phase + inset * 4,
                                 frame, inset), fill=color)


def spark(draw: ImageDraw.ImageDraw, x: int, y: int, size: int, hot: bool) -> None:
    # Dark rim + orange cross + one hot center pixel reads at game scale.
    draw.rectangle((x - size - 1, y - 1, x + size + 1, y + 1), fill=EDGE)
    draw.rectangle((x - 1, y - size - 1, x + 1, y + size + 1), fill=EDGE)
    draw.rectangle((x - size, y, x + size, y + 1), fill=ORANGE)
    draw.rectangle((x, y - size, x + 1, y + size), fill=AMBER)
    draw.point((x, y), fill=HOT if hot else GOLD)


def make_frame(frame: int) -> Image.Image:
    image = Image.new("RGBA", (DW, DH))
    draw = ImageDraw.Draw(image)
    base_y = 143

    # The established effect remains a root fire: broad base, three main tongues,
    # smaller side licks. It does not climb over the whole tree.
    for cx, h, w, phase in (
        (47, 47, 11, .4), (64, 68, 14, 1.8), (82, 82, 15, 3.1),
        (101, 63, 13, 4.5), (117, 44, 10, 5.6), (92, 39, 8, .9),
    ):
        flame(draw, cx, base_y, h, w, phase, frame)

    # Broken glowing root line prevents a floating campfire silhouette.
    for i in range(12):
        x = 34 + i * 8 + ((frame + i) % 3 - 1)
        y = base_y + (i % 2)
        draw.rectangle((x, y, x + 5, y + 2), fill=DEEP)
        draw.rectangle((x + 1, y, x + 3, y + 1), fill=GOLD if i % 4 == 0 else ORANGE)

    # Twenty-four staggered spark paths travel upward and sideways. Their phase,
    # speed and lateral drift differ so they never fire as a synchronized pulse.
    t = frame / FRAMES
    for i in range(24):
        q = (t * (1.0 + (i % 5) * .17) + i * .137) % 1
        if q > .84:
            continue
        side = -1 if i % 2 else 1
        launch_x = 56 + (i * 17) % 53
        drift = side * (8 + (i % 6) * 4) * q
        flutter = math.sin(q * 9 + i * 1.9) * (2 + q * 4)
        x = round(launch_x + drift + flutter)
        y = round(125 - q * (76 + (i % 4) * 13) + 13 * q * q)
        spark(draw, x, y, 1 + (i % 7 == 0), i % 4 == 0)

    return image.resize((FW, FH), Image.Resampling.NEAREST)


def main() -> None:
    atlas = Image.new("RGBA", (FW * FRAMES, FH))
    frames = []
    for frame in range(FRAMES):
        image = make_frame(frame)
        frames.append(image)
        atlas.alpha_composite(image, (frame * FW, 0))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(OUT)
    frames[0].save(GIF_OUT, save_all=True, append_images=frames[1:], duration=72,
                   loop=0, disposal=2, transparency=0)
    print(f"wrote {OUT.relative_to(ROOT)} {atlas.width}x{atlas.height}")
    print(f"wrote {GIF_OUT.relative_to(ROOT)} {FW}x{FH} frames={FRAMES}")


if __name__ == "__main__":
    main()
