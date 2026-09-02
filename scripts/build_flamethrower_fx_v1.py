"""Build the smoker's authored flamethrower equipment and eight-frame stream."""
from pathlib import Path
from collections import deque
import math

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / "assets" / "effects"
PREVIEW = ROOT / "docs" / "previews"
CELL_W, CELL_H, COLS, FRAMES = 1536, 768, 4, 8
GRID = 2
SOURCE = ASSET / "smoker-flamethrower-source-screenshot-v1.png"

INK = (49, 21, 22, 255)
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


FIRE_PALETTE = (
    INK, RED, RED_LIT, VERMILION, VERMILION_LIT, ORANGE, AMBER,
    GOLD, YELLOW, CREAM, PALE, WHITE,
)


def quantize_fire(canvas):
    small = canvas.resize((CELL_W // GRID, CELL_H // GRID), Image.Resampling.LANCZOS)
    colors = []
    for r, g, b, a in small.get_flattened_data():
        if a < 96:
            colors.append((0, 0, 0, 0));continue
        nearest = min(FIRE_PALETTE, key=lambda color:
            (r-color[0])**2 + (g-color[1])**2 + (b-color[2])**2)
        colors.append(nearest)
    small.putdata(colors)
    return small.resize((CELL_W, CELL_H), Image.Resampling.NEAREST)


def extract_reference():
    """Remove the screenshot checkerboard without redrawing any flame detail."""
    source = Image.open(SOURCE).convert("RGBA")
    width, height = source.size
    pixels = source.load()
    flame = set()
    for y in range(height):
        for x in range(width):
            r, g, b, _ = pixels[x, y]
            if max(r, g, b) - min(r, g, b) > 30 and r > 150: flame.add((x, y))

    outside, queue = set(), deque()
    for x in range(width):
        for y in (0, height - 1):
            if (x, y) not in flame and (x, y) not in outside:
                outside.add((x, y));queue.append((x, y))
    for y in range(height):
        for x in (0, width - 1):
            if (x, y) not in flame and (x, y) not in outside:
                outside.add((x, y));queue.append((x, y))
    while queue:
        x, y = queue.popleft()
        for nx, ny in ((x+1,y),(x-1,y),(x,y+1),(x,y-1)):
            if 0 <= nx < width and 0 <= ny < height and (nx, ny) not in flame and (nx, ny) not in outside:
                outside.add((nx, ny));queue.append((nx, ny))

    cutout = Image.new("RGBA", source.size)
    result = cutout.load()
    for y in range(height):
        for x in range(width):
            if (x, y) not in outside: result[x, y] = pixels[x, y][:3] + (255,)
    cutout = cutout.crop(cutout.getbbox()).resize((1480, 630), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (CELL_W, CELL_H))
    canvas.alpha_composite(cutout, (28, 69))
    return quantize_fire(canvas)


MASTER = extract_reference()


def column_bounds(image, x):
    alpha = image.getchannel("A")
    ys = [y for sample_x in range(max(0,x-4),min(CELL_W,x+5),GRID)
        for y in range(0,CELL_H,GRID) if alpha.getpixel((sample_x,y))]
    return (min(ys),max(ys)) if ys else (330,438)


LOBE_ZONES = (
    # Each box isolates a real tongue from the reference.  The boxes end inside
    # the body of the flame so their transformed bases remain naturally hidden.
    (472, 92, 704, 336, 0.00),
    (682, 58, 866, 358, 1.45),
    (842, 36, 1068, 414, 2.70),
    (1218, 224, 1454, 488, 4.05),
    (850, 486, 1112, 696, 5.25),
    (1110, 500, 1392, 686, 0.85),
)


def move_reference_lobe(image, box, frame, phase):
    """Grow a differently posed copy of a real reference lobe."""
    left, top, right, bottom = box
    lobe = MASTER.crop(box)
    lobe_alpha = lobe.getchannel("A")
    lobe_mask = Image.new("L", lobe.size)
    source_mask = lobe_alpha.load()
    target_mask = lobe_mask.load()
    for y in range(lobe.height):
        for x in range(lobe.width):
            # An uneven buried join prevents crop-box edges from becoming part
            # of the silhouette when the tongue leans or stretches.
            join = lobe.height * (.66 + .035 * math.sin(x * .055 + phase))
            target_mask[x, y] = source_mask[x, y] if y < join else 0
    lobe.putalpha(lobe_mask)
    angle = math.sin(frame * math.pi / 4 + phase) * 4.5
    sx = 1.0 + math.sin(frame * math.pi / 2 + phase) * .035
    sy = 1.0 + math.sin(frame * math.pi / 4 + phase + .8) * .12
    posed = lobe.resize((snap(lobe.width * sx), snap(lobe.height * sy)), Image.Resampling.NEAREST)
    posed = posed.rotate(angle, resample=Image.Resampling.NEAREST, expand=True)
    dx = snap(math.sin(frame * math.pi / 2 + phase * 1.7) * 9)
    dy = snap(math.sin(frame * math.pi / 4 + phase) * 12)
    paste_x = left + (lobe.width - posed.width) // 2 + dx
    # Anchor the lobe near its buried base; most motion happens at the tip.
    paste_y = top + lobe.height - posed.height + dy
    image.alpha_composite(posed, (paste_x, paste_y))


def cycle_hot_fragments(image, frame):
    """Make real white/yellow reference fragments blink into new paths."""
    fragments = (
        (292, 342, 438, 438, 1),
        (478, 352, 642, 470, -1),
        (662, 344, 828, 480, 1),
        (850, 366, 1038, 496, -1),
        (1050, 390, 1234, 522, 1),
        (1222, 420, 1398, 558, -1),
    )
    for index, (left, top, right, bottom, direction) in enumerate(fragments):
        patch = MASTER.crop((left, top, right, bottom))
        pixels = patch.load()
        mask = Image.new("L", patch.size)
        mask_pixels = mask.load()
        for y in range(patch.height):
            for x in range(patch.width):
                r, g, b, a = pixels[x, y]
                # Preserve only the authored hottest filaments, never inventing
                # a replacement stripe or polygon.
                inset = min(x, y, patch.width - 1 - x, patch.height - 1 - y)
                mask_pixels[x, y] = 255 if inset > 10 and a and r > 250 and g > 195 and b > 90 else 0
        offset = snap(math.sin(frame * math.pi / 2 + index * 1.1) * (8 + index % 3 * 3))
        lift = snap(math.sin(frame * math.pi / 4 + index * .7) * 5)
        image.paste(patch, (left + direction * offset, top + lift), mask)


def make_stream(frame):
    """Animate real reference fragments; no procedural triangle substitutes."""
    image = MASTER.copy()
    for left, top, right, bottom, phase in LOBE_ZONES:
        move_reference_lobe(image, (left, top, right, bottom), frame, phase)
    cycle_hot_fragments(image, frame)

    # Short-lived embers make frame changes readable even around the outer edge.
    draw = ImageDraw.Draw(image)
    for index in range(12):
        x = 420 + ((index * 101 + frame * 83) % 1040)
        side = -1 if (index + frame) % 2 else 1
        top, bottom = column_bounds(MASTER, x)
        y = (top if side < 0 else bottom) + side * (20 + (index * 11 + frame * 7) % 54)
        size = 4 + index % 3 * 2
        draw.rectangle((snap(x),snap(y),snap(x+size*2),snap(y+size)),fill=YELLOW if index%3 else ORANGE)

    # The pressure root is the one invariant: it never detaches from the nozzle.
    image.alpha_composite(MASTER.crop((0, 0, 190, CELL_H)), (0, 0))
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
MASTER.save(ASSET / "smoker-flamethrower-master-pixel-v1.png", optimize=True)
atlas.save(ASSET / "smoker-flamethrower-stream-atlas-v4.png", optimize=True)
frames[0].save(ASSET / "smoker-flamethrower-stream-v4.gif", save_all=True,
    append_images=frames[1:], duration=62, loop=0, disposal=2, optimize=False)
equipment = make_equipment()
equipment.save(ASSET / "smoker-flamethrower-equipment-v1.png", optimize=True)

# Builder-level board: all eight moments above, nearest 2x inspection below.
board = Image.new("RGB", (1280, 720), (27, 48, 31))
for index, frame in enumerate(frames):
    thumb = frame.resize((300, 150), Image.Resampling.NEAREST)
    board.paste(thumb, ((index % 4) * 320 + 10, (index // 4) * 170 + 10), thumb)
zoom = frames[5].crop((32, 180, 672, 564)).resize((1280, 768), Image.Resampling.NEAREST).crop((0, 0, 1280, 300))
board.paste(zoom, (0, 420), zoom)
board.save(PREVIEW / "flamethrower-fx-v4-pixel-board.png")
alpha_check = Image.new("RGB", (1280, 720), (18, 30, 25))
light = Image.new("RGB", (1280, 360), (235, 232, 218))
alpha_check.paste(light, (0, 360))
check = MASTER.resize((960, 480), Image.Resampling.NEAREST)
alpha_check.paste(check, (160, -60), check)
alpha_check.paste(check, (160, 300), check)
alpha_check.save(PREVIEW / "flamethrower-fx-v4-alpha-check.png")
print("FLAMETHROWER_FX_V4_BUILT stream=1536x768x8 atlas=6144x1536 equipment=384x128 grid=2 source=captured")
