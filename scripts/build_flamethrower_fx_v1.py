"""Build the smoker's authored flamethrower equipment and eight-frame stream."""
from pathlib import Path
import math
import random

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / "assets" / "effects"
PREVIEW = ROOT / "docs" / "previews"
CELL_W, CELL_H, COLS, FRAMES = 1280, 768, 4, 8
GRID = 2

INK = (49, 21, 22, 255)
COAL = (58, 39, 37, 255)
SMOKE_DARK = (67, 57, 55, 218)
SMOKE = (91, 76, 69, 190)
SMOKE_LIT = (132, 91, 62, 174)
RED = (139, 30, 19, 255)
RED_LIT = (169, 34, 14, 255)
VERMILION = (199, 42, 11, 255)
VERMILION_LIT = (224, 52, 7, 255)
ORANGE = (244, 72, 7, 255)
AMBER = (252, 98, 5, 255)
GOLD = (255, 132, 8, 255)
YELLOW = (255, 205, 42, 255)
CREAM = (255, 239, 142, 255)
PALE = (255, 247, 184, 255)
WHITE = (255, 252, 220, 255)


def snap(value):
    return round(value / GRID) * GRID


def poly(draw, points, fill):
    draw.polygon([(snap(x), snap(y)) for x, y in points], fill=fill)


def stream_profile(frame, width_scale=1.0, length_scale=1.0):
    """One coherent jagged flame mass; later layers shrink inside this profile."""
    rng = random.Random(9173 + frame * 71 + round(width_scale * 100))
    phase = frame * math.tau / FRAMES
    top, bottom = [], []
    samples = 31
    for index in range(samples):
        u = index / (samples - 1)
        x = 58 + 1160 * u * length_scale
        envelope = (34 + 306 * math.sin(u * math.pi) ** .82) * width_scale
        envelope *= .70 + .30 * min(1, u / .14)
        tooth = math.sin(phase * 1.3 + index * 1.81) * (10 + 34 * u)
        tooth += math.sin(phase * .73 - index * 2.43) * (7 + 20 * u)
        tooth += rng.choice((-12, -6, 0, 6, 12)) * u
        center = 384 + math.sin(phase + u * 7.5) * (7 + 18 * u)
        top.append((x, center - envelope - tooth))
        bottom.append((x, center + envelope - math.sin(phase * .91 + index * 1.57) * (12 + 31 * u)))
    return top + list(reversed(bottom))


def detached_tongue(draw, x, y, length, width, angle, colors):
    nx, ny = math.cos(angle), math.sin(angle)
    px, py = -ny, nx
    for inset, color in enumerate(colors):
        scale = 1 - inset * .18
        if scale <= .25:
            break
        l, w = length * scale, width * scale
        ox = x + nx * length * inset * .055
        oy = y + ny * length * inset * .055
        poly(draw, [
            (ox - px * w, oy - py * w),
            (ox + nx * l * .42 - px * w * .70, oy + ny * l * .42 - py * w * .70),
            (ox + nx * l, oy + ny * l),
            (ox + nx * l * .56 + px * w * .58, oy + ny * l * .56 + py * w * .58),
            (ox + px * w, oy + py * w),
        ], color)


def make_stream(frame):
    image = Image.new("RGBA", (CELL_W, CELL_H))
    draw = ImageDraw.Draw(image)
    phase = frame * math.tau / FRAMES
    # Smoke sits behind the fire and breaks away at the long end instead of
    # becoming a translucent geometric cone.
    for index in range(9):
        u = .48 + index * .065
        x = 58 + 1160 * u + math.sin(frame * .77 + index * 1.9) * 22
        y = 384 + math.sin(frame * .91 + index * 1.37) * (62 + index * 8)
        radius = 42 + index * 10
        color = (SMOKE_DARK, SMOKE, SMOKE_LIT)[(index + frame) % 3]
        poly(draw, [
            (x - radius, y + radius * .18), (x - radius * .72, y - radius * .55),
            (x - radius * .20, y - radius), (x + radius * .45, y - radius * .72),
            (x + radius, y - radius * .10), (x + radius * .66, y + radius * .72),
            (x, y + radius),
        ], color)

    layers = [
        (1.00, 1.00, INK), (.965, .985, RED), (.915, .965, RED_LIT),
        (.86, .94, VERMILION), (.77, .89, VERMILION_LIT), (.69, .82, ORANGE),
        (.59, .73, AMBER), (.49, .62, GOLD), (.31, .42, YELLOW),
        (.21, .33, CREAM), (.14, .25, PALE), (.085, .17, WHITE),
    ]
    for width_scale, length_scale, color in layers:
        poly(draw, stream_profile(frame, width_scale, length_scale), color)

    # Ordered streamwise texture describes pressure and heat direction. These
    # are clustered streaks on existing flame faces, not random noise sprinkled
    # into transparent space.
    flow_colors = (RED_LIT, VERMILION_LIT, AMBER, GOLD, YELLOW, CREAM)
    for band in range(7):
        color = flow_colors[band % len(flow_colors)]
        for index in range(12):
            u = .10 + index * .068 + (band % 2) * .018
            x = 58 + 1050 * u + math.sin(phase + index * 1.2) * 8
            envelope = (32 + 245 * math.sin(u * math.pi) ** .9)
            lane = (band - 3) / 3
            y = 384 + lane * envelope * .68 + math.sin(phase * .7 + index * 1.43 + band) * 9
            length = 12 + ((index + band * 2) % 5) * 6
            draw.rectangle((snap(x), snap(y), snap(x) + length, snap(y) + (2 if index % 3 else 4)), fill=color)

    # Independent edge tongues and far-end fragments make the animation read
    # as a pressured jet, not one silhouette being scaled or pulsed.
    tongue_colors = (INK, RED, VERMILION, ORANGE, GOLD, YELLOW)
    for index in range(12):
        u = .18 + index * .065
        side = -1 if (index + frame) % 2 else 1
        x = 58 + 1120 * u
        envelope = 54 + 268 * math.sin(u * math.pi) ** .82
        y = 384 + side * envelope + math.sin(phase + index) * 18
        angle = side * (.45 + .18 * math.sin(phase * .8 + index * 1.3))
        detached_tongue(draw, x, y, 58 + index * 5, 16 + (index % 3) * 4, angle, tongue_colors)
    for index in range(13):
        x = 910 + ((index * 79 + frame * 31) % 330)
        y = 384 + math.sin(index * 2.1 + phase) * (120 + (index % 4) * 43)
        size = (4, 6, 8)[index % 3]
        draw.rectangle((snap(x), snap(y), snap(x) + size, snap(y) + size), fill=YELLOW if index % 2 else ORANGE)

    # Stable white-hot nozzle root prevents the stream from floating away from
    # the weapon while every upper tongue continues to move.
    poly(draw, [(48, 360), (122, 350), (214, 366), (230, 384), (214, 402), (122, 418), (48, 408)], INK)
    poly(draw, [(54, 366), (145, 360), (208, 374), (218, 384), (208, 394), (145, 408), (54, 402)], ORANGE)
    poly(draw, [(58, 372), (154, 370), (198, 380), (204, 384), (198, 388), (154, 398), (58, 396)], YELLOW)
    poly(draw, [(58, 378), (171, 378), (190, 384), (171, 390), (58, 390)], WHITE)
    return image


def make_equipment():
    image = Image.new("RGBA", (384, 128))
    draw = ImageDraw.Draw(image)
    metal = (
        (30, 32, 33, 255), (42, 47, 47, 255), (57, 64, 63, 255), (76, 83, 80, 255),
        (98, 105, 99, 255), (124, 130, 119, 255), (157, 160, 139, 255), (197, 193, 157, 255),
    )
    tank = (
        (57, 20, 23, 255), (76, 25, 23, 255), (98, 30, 22, 255), (124, 37, 21, 255),
        (153, 47, 20, 255), (184, 62, 21, 255), (216, 84, 25, 255), (241, 126, 40, 255),
    )
    # Backpack fuel cylinder.
    draw.rounded_rectangle((18, 28, 110, 112), radius=20, fill=INK)
    draw.rounded_rectangle((24, 32, 102, 106), radius=17, fill=tank[1])
    for x, color in ((28,tank[2]),(34,tank[3]),(42,tank[4]),(54,tank[5]),(70,tank[4]),(84,tank[3]),(94,tank[2])):
        draw.rectangle((x, 34, x + 7, 103), fill=color)
    draw.rectangle((31, 38, 94, 48), fill=tank[6]);draw.rectangle((28, 86, 98, 100), fill=tank[0])
    draw.rectangle((39, 52, 47, 84), fill=tank[7]);draw.rectangle((48, 52, 52, 84), fill=tank[6])
    draw.rectangle((84, 50, 96, 87), fill=tank[2])
    # Ordered orange-steel dithering follows the cylinder curvature.
    for y in range(54, 84, 6):
        for x in range(56 + (y // 6) % 2 * 2, 82, 6):
            draw.rectangle((x, y, x + 2, y + 2), fill=tank[5 if x < 70 else 3])
    for x,y in ((30,43),(97,43),(30,94),(97,94)):
        draw.rectangle((x-2,y-2,x+2,y+2),fill=metal[6]);draw.point((x,y),fill=metal[7])
    draw.rectangle((53, 20, 78, 31), fill=metal[0]);draw.rectangle((57, 16, 74, 24), fill=metal[5])
    draw.rectangle((60,17,70,19),fill=metal[7]);draw.rectangle((62,24,68,29),fill=metal[2])
    # Pressure gauge with a readable hot-zone needle.
    draw.ellipse((88,18,114,44),fill=INK);draw.ellipse((92,22,110,40),fill=metal[6])
    draw.ellipse((96,26,106,36),fill=(220,211,169,255));draw.line((101,31,107,26),fill=RED_LIT,width=2)
    # Ribbed hose into the hand grip.
    for index in range(10):
        x = 96 + index * 11; y = 90 - round(math.sin(index / 9 * math.pi) * 24)
        draw.rectangle((x, y, x + 13, y + 10), fill=metal[1 + index % 2])
        draw.rectangle((x + 3, y + 2, x + 10, y + 4), fill=metal[6])
        draw.rectangle((x + 5, y + 6, x + 12, y + 8), fill=metal[3])
    draw.rectangle((190, 59, 250, 94), fill=INK);draw.rectangle((198, 65, 244, 86), fill=metal[2])
    draw.rectangle((201,67,240,71),fill=metal[5]);draw.rectangle((205,78,242,84),fill=metal[1])
    draw.rectangle((213, 84, 230, 111), fill=INK);draw.rectangle((217, 87, 226, 105), fill=metal[4])
    for y in range(89,104,4):draw.rectangle((218,y,225,y+1),fill=metal[1 if y%8 else 6])
    # Long, unmistakable nozzle with stepped metal ramps and a hot muzzle.
    poly(draw, [(239, 62), (346, 50), (370, 60), (370, 82), (346, 91), (239, 84)], INK)
    poly(draw, [(246, 66), (344, 57), (362, 64), (362, 78), (344, 84), (246, 80)], metal[2])
    draw.rectangle((255, 67, 335, 70), fill=metal[7]);draw.rectangle((255,71,338,74),fill=metal[5])
    draw.rectangle((268, 75, 346, 81), fill=metal[0])
    for x in range(264,340,12):
        draw.rectangle((x,63,x+4,66),fill=metal[6]);draw.rectangle((x+5,76,x+9,79),fill=metal[3])
    draw.rectangle((302, 58, 314, 83), fill=metal[1]);draw.rectangle((305,59,311,82),fill=metal[6])
    # Heat-stained collar separates steel, hot metal and the self-lit muzzle.
    draw.rectangle((330,57,348,85),fill=(67,35,42,255));draw.rectangle((334,60,350,82),fill=(116,47,38,255))
    draw.rectangle((340,61,354,81),fill=(177,62,29,255));draw.rectangle((344, 58, 371, 84), fill=INK)
    draw.rectangle((350, 62, 377, 80), fill=VERMILION);draw.rectangle((357, 65, 381, 77), fill=GOLD)
    draw.rectangle((365, 68, 383, 74), fill=WHITE)
    return image


ASSET.mkdir(parents=True, exist_ok=True)
PREVIEW.mkdir(parents=True, exist_ok=True)
atlas = Image.new("RGBA", (CELL_W * COLS, CELL_H * 2))
frames = []
for frame in range(FRAMES):
    cell = make_stream(frame)
    frames.append(cell)
    atlas.alpha_composite(cell, ((frame % COLS) * CELL_W, (frame // COLS) * CELL_H))
atlas.save(ASSET / "smoker-flamethrower-stream-atlas-v1.png", optimize=True)
equipment = make_equipment()
equipment.save(ASSET / "smoker-flamethrower-equipment-v1.png", optimize=True)

# Builder-level board: actual-ish scale above, nearest 2x material inspection below.
board = Image.new("RGB", (1280, 720), (27, 48, 31))
for index, frame in enumerate(frames[:4]):
    thumb = frame.resize((600, 360), Image.Resampling.NEAREST)
    board.paste(thumb, ((index % 2) * 640 + 20, (index // 2) * 180 - 78), thumb)
zoom = frames[5].crop((32, 180, 672, 564)).resize((1280, 768), Image.Resampling.NEAREST).crop((0, 0, 1280, 300))
board.paste(zoom, (0, 420), zoom)
board.save(PREVIEW / "flamethrower-fx-v1-pixel-board.png")
print("FLAMETHROWER_FX_V1_BUILT stream=1280x768x8 atlas=5120x1536 equipment=384x128 grid=2")
