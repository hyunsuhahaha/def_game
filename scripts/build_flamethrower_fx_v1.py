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
    """Eight authored frames of a rolling, constant-width fire column."""
    image = Image.new("RGBA", (CELL_W, CELL_H))
    draw = ImageDraw.Draw(image)
    phase = frame * math.tau / FRAMES
    rng = random.Random(4417 + frame * 97)
    centers = (145, 320, 500, 680, 860, 1042, 1140)

    # Sparse exhaust sits behind the orange mass; it must never become the
    # silhouette. The column itself is built from overlapping round billows.
    for index in range(7):
        x = 690 + index * 82 + math.sin(phase + index) * 16
        y = 384 + (-1 if index % 2 else 1) * (205 + (index % 3) * 18)
        radius = 22 + (index % 3) * 8
        ellipse(draw, x, y, radius, radius*.72, (SMOKE_DARK, SMOKE, SMOKE_LIT)[(index+frame)%3])

    lobes = []
    for index, cx in enumerate(centers):
        pulse = math.sin(phase + index * 1.31)
        cy = 384 + pulse * (16 if index else 5)
        rx = (150 if index < 6 else 118) + math.cos(phase*.8 + index)*12
        ry = (216 if index in (1,2,3,4,5) else 174) + pulse*14
        lobes.append((cx, cy, rx, ry))

    # Dark outline and twelve stepped heat bands keep each cloud readable while
    # overlaps weld them into a single pressured blast.
    bands = (
        (1.00, INK), (.965, RED), (.91, RED_LIT), (.855, VERMILION),
        (.79, VERMILION_LIT), (.72, ORANGE), (.64, AMBER), (.55, GOLD),
        (.44, YELLOW), (.34, CREAM), (.25, PALE), (.16, WHITE),
    )
    for scale, color in bands:
        for index, (cx, cy, rx, ry) in enumerate(reversed(lobes)):
            real_index = len(lobes)-1-index
            # Hot cores roll around each other instead of sharing one centered
            # gradient, producing the reference's circular cannon rhythm.
            drift_x = (1-scale)*rx*.36*math.cos(phase*1.2+real_index*1.4)
            drift_y = (1-scale)*ry*.30*math.sin(phase+real_index*1.7)
            ellipse(draw, cx+drift_x, cy+drift_y, rx*scale, ry*scale, color)

    # Crescent/spiral cuts describe rotation on the flame surface. All strokes
    # are hard pixel steps; no blur, translucent glow, or procedural noise.
    for index, (cx, cy, rx, ry) in enumerate(lobes[1:6], 1):
        flip = -1 if (index+frame)%2 else 1
        box = (snap(cx-rx*.58), snap(cy-ry*.57), snap(cx+rx*.58), snap(cy+ry*.57))
        start = int(30 + (frame*19 + index*47)%120)
        draw.arc(box, start=start, end=start+215, fill=VERMILION_LIT, width=18)
        inner = (snap(cx-rx*.40), snap(cy-ry*.39), snap(cx+rx*.40), snap(cy+ry*.39))
        draw.arc(inner, start=start+35*flip, end=start+35*flip+175, fill=YELLOW, width=14)
        ellipse(draw, cx+flip*rx*.25, cy-ry*.18, 17, 11, CREAM)

    # Streamwise hot seams and edge tongues add dense, intentional pixel
    # texture without breaking the round-lobe silhouette.
    for index in range(34):
        x = 92 + index*32 + math.sin(phase*1.7+index)*8
        lane = ((index*5+frame)%7)-3
        y = 384 + lane*39 + math.sin(index*1.9+phase)*11
        length = 10 + (index%5)*5
        color = (RED_LIT, ORANGE, GOLD, YELLOW, CREAM)[index%5]
        draw.rectangle((snap(x), snap(y), snap(x+length), snap(y+4+(index%2)*2)), fill=color)
    for index in range(16):
        x = 180 + ((index*71 + frame*29)%1030)
        side = -1 if (index+frame)%2 else 1
        y = 384 + side*(185 + (index%4)*17)
        tip = 22 + (index%4)*10
        poly(draw, [(x-20,y-side*5),(x+10,y-side*18),(x+tip,y+side*7),(x-8,y+side*18)],
             (RED, VERMILION, ORANGE, GOLD)[index%4])
    for index in range(12):
        x = 930 + ((index*61 + frame*37)%300); y = 384 + math.sin(index*2.2+phase)*(214+(index%3)*18)
        size = (4,6,8)[index%3]
        draw.rectangle((snap(x),snap(y),snap(x+size),snap(y+size)),fill=YELLOW if index%2 else ORANGE)

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
atlas.save(ASSET / "smoker-flamethrower-stream-atlas-v2.png", optimize=True)
equipment = make_equipment()
equipment.save(ASSET / "smoker-flamethrower-equipment-v1.png", optimize=True)

# Builder-level board: actual-ish scale above, nearest 2x material inspection below.
board = Image.new("RGB", (1280, 720), (27, 48, 31))
for index, frame in enumerate(frames[:4]):
    thumb = frame.resize((600, 360), Image.Resampling.NEAREST)
    board.paste(thumb, ((index % 2) * 640 + 20, (index // 2) * 180 - 78), thumb)
zoom = frames[5].crop((32, 180, 672, 564)).resize((1280, 768), Image.Resampling.NEAREST).crop((0, 0, 1280, 300))
board.paste(zoom, (0, 420), zoom)
board.save(PREVIEW / "flamethrower-fx-v2-pixel-board.png")
print("FLAMETHROWER_FX_V2_BUILT stream=1280x768x8 atlas=5120x1536 equipment=384x128 grid=2 rolling=column")
