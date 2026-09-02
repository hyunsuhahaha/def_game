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


def ellipse(draw, cx, cy, rx, ry, fill):
    draw.ellipse((snap(cx-rx), snap(cy-ry), snap(cx+rx), snap(cy+ry)), fill=fill)


def make_stream(frame):
    """Eight authored frames of a pressured flame jet whose detail travels forward."""
    image = Image.new("RGBA", (CELL_W, CELL_H))
    draw = ImageDraw.Draw(image)
    phase = frame * math.tau / FRAMES
    rng = random.Random(4417 + frame * 97)
    xs = list(range(48, 1249, 40))

    def envelope(x):
        if x < 180:
            return 24 + (x - 48) * .62
        if x > 1080:
            return max(18, 154 - (x - 1080) * .74)
        return 150 + 18 * math.sin(x / 117 - phase * 1.3)

    def flame_band(scale, color, inset=0, phase_shift=0):
        upper, lower = [], []
        for index, x in enumerate(xs):
            flow = x / 92 - phase * 2.35 + phase_shift
            center = 384 + math.sin(flow * .43) * (8 + scale * 9)
            chop = math.sin(flow) * 17 + math.sin(flow * 2.17 + index * .31) * 8
            width = max(8, envelope(x) * scale - inset + chop * scale)
            upper.append((x, center - width))
            lower.append((x, center + width))
        poly(draw, upper + list(reversed(lower)), color)

    # A dark authored edge, then asymmetric hot layers. Unlike the old chain of
    # circles, every ridge is a streamwise tongue and its phase advances right.
    flame_band(1.08, INK, phase_shift=.15)
    flame_band(1.00, RED, phase_shift=.15)
    flame_band(.91, VERMILION, phase_shift=.55)
    flame_band(.76, ORANGE, phase_shift=1.05)
    flame_band(.58, GOLD, phase_shift=1.55)
    flame_band(.39, YELLOW, phase_shift=2.0)

    # White-hot ribbons break apart toward the head instead of forming repeated
    # circular cores. Their x positions advance each animation frame.
    travel = frame * 92
    for index in range(8):
        x = 160 + ((index * 173 + travel) % 930)
        length = 112 + (index % 3) * 42
        y = 384 + math.sin(x / 105 - phase * 2.2 + index) * (30 + index % 2 * 22)
        height = 18 + (index % 3) * 7
        color = (CREAM, PALE, WHITE)[index % 3]
        poly(draw, [(x, y-height), (x+length*.72, y-height*.65),
                    (x+length, y), (x+length*.66, y+height*.62), (x, y+height)], color)

    # Long edge tongues and detached embers visibly advect toward the target.
    for index in range(12):
        x = 210 + ((index * 137 + travel * 1.25) % 1000)
        side = -1 if (index + frame) % 2 else 1
        y = 384 + side * (envelope(x) + 18 + (index % 3) * 12)
        length = 34 + (index % 4) * 18
        poly(draw, [(x-22, y-side*5), (x+8, y-side*20),
                    (x+length, y), (x+2, y+side*13)], (VERMILION, ORANGE, GOLD)[index%3])
    for index in range(16):
        x = 510 + ((index * 79 + travel * 1.7) % 750)
        side = -1 if (index + frame) % 2 else 1
        y = 384 + side * (190 + (index % 4) * 18)
        size = (4, 6, 10)[index % 3]
        draw.rectangle((snap(x), snap(y), snap(x+size*2), snap(y+size)),
                       fill=(ORANGE, GOLD, YELLOW)[index % 3])

    # Small smoke scraps only appear at the cooling leading edge.
    for index in range(5):
        x = 1040 + ((index * 61 + travel) % 190)
        y = 384 + (-1 if index % 2 else 1) * (174 + (index % 3) * 24)
        ellipse(draw, x, y, 16 + index % 2 * 7, 10 + index % 3 * 4,
                (SMOKE_DARK, SMOKE, SMOKE_LIT)[(index+frame)%3])

    # Stable white-hot nozzle root prevents the rolling column from floating.
    poly(draw, [(48,360),(118,348),(222,364),(250,384),(222,404),(118,420),(48,408)], INK)
    poly(draw, [(54,366),(150,358),(226,372),(240,384),(226,396),(150,410),(54,402)], ORANGE)
    poly(draw, [(58,372),(168,368),(218,378),(230,384),(218,390),(168,400),(58,396)], YELLOW)
    poly(draw, [(58,378),(186,376),(210,384),(186,392),(58,390)], WHITE)
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
atlas.save(ASSET / "smoker-flamethrower-stream-atlas-v3.png", optimize=True)
equipment = make_equipment()
equipment.save(ASSET / "smoker-flamethrower-equipment-v1.png", optimize=True)

# Builder-level board: actual-ish scale above, nearest 2x material inspection below.
board = Image.new("RGB", (1280, 720), (27, 48, 31))
for index, frame in enumerate(frames[:4]):
    thumb = frame.resize((600, 360), Image.Resampling.NEAREST)
    board.paste(thumb, ((index % 2) * 640 + 20, (index // 2) * 180 - 78), thumb)
zoom = frames[5].crop((32, 180, 672, 564)).resize((1280, 768), Image.Resampling.NEAREST).crop((0, 0, 1280, 300))
board.paste(zoom, (0, 420), zoom)
board.save(PREVIEW / "flamethrower-fx-v3-pixel-board.png")
print("FLAMETHROWER_FX_V3_BUILT stream=1280x768x8 atlas=5120x1536 equipment=384x128 grid=2 flow=forward")
