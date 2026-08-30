"""Build a dense block-pixel fire loop inspired by classic voxel-game fire."""
from __future__ import annotations

from pathlib import Path
import math

from PIL import Image, ImageChops, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/fx/tree-fire-loop-atlas-pixel-v3.png"
GIF_OUT = ROOT / "assets/fx/tree-fire-loop-pixel-v3.gif"
FRAMES = 20
DW = DH = 160
SCALE = 2
FW = FH = DW * SCALE

RIM = (92, 18, 5, 255)
RED = (174, 31, 4, 255)
ORANGE = (245, 58, 2, 255)
TANGERINE = (255, 101, 2, 255)
YELLOW = (255, 178, 4, 255)
LEMON = (255, 226, 35, 255)
WHITE_HOT = (255, 255, 205, 255)


def q(value: float, step: int = 2) -> int:
    """Snap silhouettes to chunky authored pixel steps."""
    return round(value / step) * step


def shifted(points: list[tuple[float, float]], dx: float, dy: float) -> list[tuple[int, int]]:
    return [(q(x + dx), q(y + dy)) for x, y in points]


def outer_mask(frame: int) -> Image.Image:
    mask = Image.new("L", (DW, DH))
    d = ImageDraw.Draw(mask)
    t = frame / FRAMES * math.tau

    base_top = 113 + q(math.sin(t * 2) * 2)
    d.polygon([(20, 145), (24, 130), (34, 118), (48, base_top), (62, 116),
               (76, 110), (91, 114), (106, 109), (124, 118), (138, 132),
               (140, 147)], fill=255)
    d.rectangle((22, 137, 139, 149), fill=255)

    center_dx = q(math.sin(t) * 6)
    center_tip = 35 + q((1 + math.sin(t + .7)) * 4)
    center = [(58, 132), (54, 116), (62, 102), (60, 88), (70, 78),
              (68, 62), (78, 56), (84, center_tip), (94, 46), (103, 34),
              (106, 52), (101, 68), (110, 78), (106, 94), (118, 103),
              (114, 121), (126, 134)]
    d.polygon(shifted(center, center_dx, 0), fill=255)

    left_dx = q(math.sin(t + 2.2) * 5)
    left = [(27, 137), (26, 122), (35, 112), (32, 98), (43, 89),
            (42, 72), (52, 79), (58, 92), (55, 108), (68, 120), (64, 138)]
    d.polygon(shifted(left, left_dx, q(math.sin(t * 1.7) * 2)), fill=255)

    right_dx = q(math.sin(t + 4.1) * 5)
    right = [(98, 139), (98, 124), (108, 114), (104, 100), (116, 91),
             (118, 74), (128, 84), (132, 99), (128, 113), (140, 124),
             (136, 141)]
    d.polygon(shifted(right, right_dx, q(math.sin(t * 1.3 + 1) * 2)), fill=255)

    for i, (cx, top, width) in enumerate(((36, 103, 15), (67, 92, 16), (94, 86, 15), (121, 108, 14))):
        dx = q(math.sin(t * (1.1 + i * .13) + i * 1.8) * 4)
        h = 24 + (i % 2) * 8
        d.polygon([(q(cx - width + dx), 135), (q(cx - width * .7 + dx), top + h),
                   (q(cx - width * .25 + dx), top + 8), (q(cx + dx), top),
                   (q(cx + width * .55 + dx), top + 11), (q(cx + width + dx), 136)], fill=255)

    stage = frame % 5
    bites = [
        [(45 + stage * 2, 88), (59 + stage * 2, 84), (62 + stage * 2, 98), (51 + stage * 2, 105)],
        [(101 - stage * 2, 70), (117 - stage * 2, 66), (114 - stage * 2, 82), (104 - stage * 2, 88)],
        [(73 + (stage % 2) * 4, 111), (88, 104), (92, 119), (78, 125)],
    ]
    for bite in bites:
        d.polygon([(q(x), q(y)) for x, y in bite], fill=0)
    return mask


def erode(mask: Image.Image, size: int, down: int = 0) -> Image.Image:
    result = mask.filter(ImageFilter.MinFilter(size)) if size > 1 else mask.copy()
    if down:
        moved = Image.new("L", mask.size)
        moved.paste(result, (0, down))
        result = ImageChops.multiply(moved, mask)
    return result


def paint_layer(canvas: Image.Image, color: tuple[int, int, int, int], mask: Image.Image) -> None:
    canvas.paste(color, (0, 0, DW, DH), mask)


def spark(draw: ImageDraw.ImageDraw, x: int, y: int, size: int, hot: bool) -> None:
    draw.rectangle((x - size - 1, y - size - 1, x + size + 1, y + size + 1), fill=RIM)
    draw.rectangle((x - size, y - size, x + size, y + size), fill=TANGERINE)
    if hot:
        draw.rectangle((x, y, x + max(1, size - 1), y + max(1, size - 1)), fill=LEMON)


def make_frame(frame: int) -> Image.Image:
    outer = outer_mask(frame)
    image = Image.new("RGBA", (DW, DH))
    paint_layer(image, RIM, outer)
    paint_layer(image, RED, erode(outer, 3, 1))
    paint_layer(image, ORANGE, erode(outer, 5, 3))
    paint_layer(image, TANGERINE, erode(outer, 7, 5))
    paint_layer(image, YELLOW, erode(outer, 11, 10))
    paint_layer(image, LEMON, erode(outer, 15, 15))
    paint_layer(image, WHITE_HOT, erode(outer, 21, 22))

    d = ImageDraw.Draw(image)
    t = frame / FRAMES
    for i in range(8):
        x = 34 + i * 13 + q(math.sin(frame * .61 + i) * 2)
        y = 132 + (i % 3) * 3
        d.rectangle((x, y, x + 7 + i % 2, y + 5), fill=LEMON)
        if i % 2 == 0:
            d.rectangle((x + 2, y + 1, x + 5, y + 4), fill=WHITE_HOT)

    for i in range(22):
        progress = (t * (1.0 + (i % 4) * .16) + i * .149) % 1
        if progress > .78:
            continue
        side = -1 if i % 2 else 1
        x = q(80 + side * (12 + i % 6 * 5) + math.sin(i * 2.1) * 10)
        y = q(112 - progress * (88 + (i % 3) * 13))
        spark(d, x, y, 1 + (i % 9 == 0), i % 3 == 0)

    return image.resize((FW, FH), Image.Resampling.NEAREST)


def main() -> None:
    atlas = Image.new("RGBA", (FW * FRAMES, FH))
    frames = [make_frame(frame) for frame in range(FRAMES)]
    for index, frame in enumerate(frames):
        atlas.alpha_composite(frame, (index * FW, 0))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(OUT)
    frames[0].save(GIF_OUT, save_all=True, append_images=frames[1:], duration=68,
                   loop=0, disposal=2, transparency=0)
    print(f"wrote {OUT.relative_to(ROOT)} {atlas.width}x{atlas.height}")
    print(f"wrote {GIF_OUT.relative_to(ROOT)} {FW}x{FH} frames={FRAMES}")


if __name__ == "__main__":
    main()
