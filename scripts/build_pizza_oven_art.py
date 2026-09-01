"""Build the scrap-built brick pizza oven and its baked slice pickups.

The oven reads as a wood-fired dome welded onto a low handcart: the same
scavenged-industrial lineage as the oil drum and the puffed-rice cannon, not a
clean Neapolitan storefront. Six frames ramp the fire from cold to roaring so the
runtime can show how many trees are burning inside the collection radius. A
separate fixed-grid overlay shows the pizza itself changing from pale dough to a
bubbling, browned pie, so heat progress is readable independently of fire size.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import math

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "automation"
OUT.mkdir(parents=True, exist_ok=True)
FX_OUT = ROOT / "assets" / "fx"
FX_OUT.mkdir(parents=True, exist_ok=True)

INK = (22, 18, 16, 255)
BRICK = [(58, 26, 18, 255), (82, 36, 23, 255), (108, 47, 28, 255), (134, 60, 34, 255),
         (159, 76, 42, 255), (183, 95, 54, 255), (205, 118, 70, 255), (224, 145, 92, 255)]
MORTAR = [(64, 56, 48, 255), (92, 82, 70, 255), (122, 111, 95, 255), (152, 141, 122, 255)]
IRON = [(26, 27, 26, 255), (37, 39, 37, 255), (50, 53, 49, 255), (64, 68, 62, 255),
        (80, 84, 75, 255), (98, 102, 89, 255), (118, 120, 102, 255), (140, 140, 116, 255),
        (164, 160, 130, 255), (188, 180, 144, 255)]
FIRE = [(96, 22, 10, 255), (168, 42, 13, 255), (232, 84, 20, 255), (255, 152, 40, 255),
        (255, 214, 108, 255), (255, 246, 196, 255)]
SOOT = [(18, 16, 15, 255), (32, 29, 27, 255), (48, 44, 40, 255)]
BRASS = [(74, 51, 20, 255), (116, 80, 28, 255), (166, 116, 39, 255), (216, 163, 61, 255), (247, 210, 113, 255)]
CRUST = [(96, 60, 24, 255), (140, 90, 36, 255), (183, 126, 54, 255), (216, 163, 88, 255), (240, 202, 138, 255)]
CHEESE = [(176, 122, 34, 255), (214, 163, 52, 255), (240, 200, 88, 255), (253, 231, 150, 255)]
BAKED_CHEESE = [(253, 231, 150, 255), (250, 221, 126, 255), (242, 201, 87, 255),
                 (231, 178, 61, 255), (214, 151, 44, 255), (188, 119, 31, 255)]
BAKED_CRUST = [(240, 202, 138, 255), (228, 184, 112, 255), (211, 158, 82, 255),
                (191, 132, 59, 255), (164, 102, 41, 255), (132, 73, 27, 255)]
SAUCE = [(96, 22, 18, 255), (146, 34, 24, 255), (192, 50, 32, 255), (224, 78, 48, 255)]
BASIL = [(28, 62, 26, 255), (46, 96, 38, 255), (72, 134, 54, 255)]
AURA = [(198, 125, 0, 125), (245, 171, 8, 170), (255, 205, 30, 210),
        (255, 231, 72, 235), (255, 250, 177, 245)]


def rect(d, b, c):
    d.rectangle(tuple(map(int, b)), fill=c)


def poly(d, p, c):
    d.polygon(tuple((int(x), int(y)) for x, y in p), fill=c)


def brick_dome(d, heat):
    """Half-dome of stacked brick with curvature shading and mortar joints."""
    cx, base, rx, ry = 128, 132, 74, 82
    # Dark outline pass first so every brick sits inside a readable silhouette.
    # Half-dome only: a full ellipse would paint a black crescent over the cart
    # deck below the brick, which reads as a hole rather than an outline.
    d.pieslice((cx - rx - 4, base - ry - 4, cx + rx + 4, base + ry + 4), 180, 360, fill=INK)
    rect(d, (cx - rx - 4, base - 2, cx + rx + 4, base + 2), INK)
    for y in range(base - ry, base + 1):
        t = (base - y) / ry
        half = rx * math.sqrt(max(0.0, 1.0 - t * t))
        for x in range(int(cx - half), int(cx + half) + 1):
            u = (x - cx) / max(1.0, half)
            # Light from upper-left: curvature across x, plus vertical falloff.
            shade = 1.0 - abs(u + 0.34) * 0.62 - (1.0 - t) * 0.30
            row = int(y // 9)
            stagger = 13 if row % 2 else 0
            joint = (x + stagger) % 26 < 2 or y % 9 < 1
            if joint:
                tone = MORTAR[max(0, min(3, int(1 + shade * 2.2)))]
            else:
                tone = BRICK[max(0, min(7, int(1 + shade * 7.4)))]
            d.point((x, y), fill=tone)
    # Soot halo above the mouth: the oven has been run hard.
    for i in range(46):
        a = math.pi + i / 46 * math.pi
        sx, sy = cx + math.cos(a) * 40, base - 34 + math.sin(a) * 22
        d.point((int(sx), int(sy)), fill=SOOT[1 + i % 2])


def arch_mouth(d, heat):
    cx, base = 128, 130
    # Iron-framed arch opening. Deliberately small: the brick mass is the read,
    # and a mouth wide enough to swallow the dome turns the whole sprite into a
    # black hole at game scale.
    d.pieslice((cx - 32, base - 50, cx + 32, base + 16), 180, 360, fill=INK)
    rect(d, (cx - 32, base - 17, cx + 32, base), INK)
    d.pieslice((cx - 26, base - 43, cx + 26, base + 11), 180, 360, fill=SOOT[0])
    rect(d, (cx - 26, base - 16, cx + 26, base - 2), SOOT[0])
    # Brass arch trim so the opening has an edge instead of dissolving into brick.
    d.arc((cx - 32, base - 50, cx + 32, base + 16), 180, 360, fill=BRASS[1], width=2)
    # Fire bed inside. Height and colour ride the heat value.
    if heat > 0:
        bed = int(4 + heat * 20)
        for i in range(26):
            u = i / 25
            fx = cx - 22 + u * 44
            wob = math.sin(u * 7.4 + heat * 5.1) * 0.5 + 0.5
            h = bed * (0.42 + wob * 0.58) * (1.0 - abs(u - 0.5) * 0.8)
            if h < 1:
                continue
            for yy in range(int(h)):
                v = yy / max(1.0, h)
                idx = 1 + int(v * 3.6 + heat * 1.2)
                d.point((int(fx), int(base - 4 - yy)), fill=FIRE[max(0, min(5, idx))])
        # Split logs sitting in the embers.
        for lx, ly in ((cx - 19, base - 8), (cx + 3, base - 6)):
            rect(d, (lx, ly, lx + 16, ly + 4), (58, 34, 18, 255))
            rect(d, (lx + 2, ly + 1, lx + 14, ly + 2), FIRE[max(0, min(5, 1 + int(heat * 3)))])
        # Warm spill onto the hearth lip.
        glow = FIRE[max(0, min(5, 1 + int(heat * 4)))]
        for yy in range(3):
            rect(d, (cx - 22 + yy * 4, base + 1 + yy, cx + 22 - yy * 4, base + 1 + yy), glow)


def chimney(d, heat):
    # Riveted stovepipe, offset right so the dome silhouette stays legible.
    rect(d, (172, 18, 202, 78), INK)
    for x in range(175, 200):
        u = (x - 175) / 24
        shade = max(1, min(9, int(2 + (1 - abs(0.38 - u) * 1.9) * 7)))
        rect(d, (x, 21, x, 75), IRON[shade])
    for yy in (30, 48, 66):
        rect(d, (173, yy, 201, yy + 4), INK)
        rect(d, (175, yy + 1, 199, yy + 2), IRON[6])
    rect(d, (168, 12, 206, 22), INK)
    rect(d, (171, 14, 203, 19), IRON[7])
    if heat > 0.25:
        # The pipe itself glows near the base once the fire is really going.
        g = FIRE[max(0, min(5, 1 + int(heat * 3)))]
        for yy in range(70, 76):
            rect(d, (176, yy, 198, yy), g)


def cart(d):
    # Low welded handcart carrying the dome, with a hearth lip and two wheels.
    poly(d, ((44, 132), (212, 132), (220, 146), (208, 156), (52, 156), (40, 146)), INK)
    poly(d, ((50, 134), (206, 134), (212, 145), (202, 151), (57, 151), (47, 145)), IRON[3])
    for x in range(54, 202, 6):
        rect(d, (x, 136, x + 2, 149), IRON[4 if (x // 6) % 2 else 2])
    rect(d, (44, 128, 212, 134), INK)
    rect(d, (48, 129, 208, 132), IRON[6])
    for cx0 in (76, 180):
        d.ellipse((cx0 - 20, 150, cx0 + 20, 188), fill=INK)
        d.ellipse((cx0 - 14, 156, cx0 + 14, 182), fill=IRON[3])
        d.ellipse((cx0 - 7, 163, cx0 + 7, 177), fill=IRON[1])
        d.ellipse((cx0 - 3, 167, cx0 + 3, 173), fill=BRASS[3])
        for a in range(0, 360, 45):
            r = math.radians(a)
            d.point((int(cx0 + math.cos(r) * 10), int(169 + math.sin(r) * 7)), fill=IRON[7])
    # Firewood bundle strapped under the deck: says what fuels this thing.
    for i, wx in enumerate((96, 112, 128, 144)):
        rect(d, (wx, 158 + (i % 2) * 3, wx + 13, 166 + (i % 2) * 3), (52, 30, 16, 255))
        rect(d, (wx + 1, 159 + (i % 2) * 3, wx + 12, 161 + (i % 2) * 3), (96, 58, 30, 255))


def rack(d):
    # Iron cooling rack across the dome top. The runtime stacks baked slices here,
    # so the sprite has to give them something to physically sit on.
    rect(d, (66, 40, 190, 48), INK)
    rect(d, (69, 42, 187, 46), IRON[5])
    for x in range(74, 186, 11):
        rect(d, (x, 42, x + 2, 46), IRON[8])
    for lx in (72, 182):
        rect(d, (lx, 46, lx + 4, 62), INK)
        rect(d, (lx + 1, 47, lx + 3, 61), IRON[4])


def peel(d):
    # Long-handled pizza peel leaning against the left flank.
    d.line((14, 178, 46, 104), fill=INK, width=9)
    d.line((15, 176, 45, 106), fill=(74, 46, 24, 255), width=4)
    poly(d, ((30, 110), (66, 86), (76, 100), (40, 124)), INK)
    poly(d, ((35, 110), (64, 91), (70, 100), (41, 119)), IRON[7])
    poly(d, ((39, 109), (60, 95), (64, 100), (43, 114)), IRON[5])


def oven_frame(state):
    """state 0..5 -> cold oven through a roaring hearth."""
    heat = state / 5.0
    im = Image.new("RGBA", (256, 192))
    d = ImageDraw.Draw(im)
    cart(d)
    brick_dome(d, heat)
    chimney(d, heat)
    arch_mouth(d, heat)
    rack(d)
    peel(d)
    if heat > 0.55:
        # Sparks lifting out of the chimney once it is truly hot.
        for i in range(9):
            a = i * 1.7 + heat * 4.0
            sx = 187 + math.sin(a) * 7
            sy = 12 - (i * 1.4) % 12
            if sy < 0:
                continue
            d.point((int(sx), int(sy)), fill=FIRE[4 if i % 2 else 3])
    return im


def slice_frame(index):
    """One baked wedge, four rotations so a stack does not look cloned."""
    im = Image.new("RGBA", (96, 96))
    d = ImageDraw.Draw(im)
    layer = Image.new("RGBA", (96, 96))
    ld = ImageDraw.Draw(layer)
    tip, half = (48, 16), 26
    base_y = 76
    ld.polygon(((tip[0], tip[1] - 3), (48 - half - 3, base_y + 3), (48 + half + 3, base_y + 3)), fill=INK)
    ld.polygon((tip, (48 - half, base_y), (48 + half, base_y)), fill=CRUST[2])
    # Cheese field with baked shading toward the crust edge.
    for y in range(tip[1] + 4, base_y - 4):
        t = (y - tip[1]) / (base_y - tip[1])
        w = int(half * t) - 4
        if w <= 0:
            continue
        for x in range(48 - w, 48 + w):
            u = abs(x - 48) / max(1.0, w)
            idx = 3 - int(u * 1.7 + (1 - t) * 1.1)
            ld.point((x, y), fill=CHEESE[max(0, min(3, idx))])
    # Crust rim at the wide end, then toppings.
    ld.polygon(((48 - half, base_y), (48 + half, base_y), (48 + half - 4, base_y - 9), (48 - half + 4, base_y - 9)),
               fill=CRUST[1])
    for x in range(48 - half + 4, 48 + half - 3, 5):
        ld.rectangle((x, base_y - 8, x + 2, base_y - 5), fill=CRUST[4])
    for sx, sy, r in ((44, 44, 5), (56, 58, 6), (40, 62, 4)):
        ld.ellipse((sx - r, sy - r, sx + r, sy + r), fill=SAUCE[1])
        ld.ellipse((sx - r + 1, sy - r + 1, sx + r - 2, sy + r - 2), fill=SAUCE[3])
    for bx, by in ((54, 40), (42, 54)):
        ld.polygon(((bx, by - 4), (bx + 5, by), (bx, by + 4), (bx - 5, by)), fill=BASIL[1])
        ld.point((bx, by), fill=BASIL[2])
    layer = layer.rotate(index * 14 - 21, resample=Image.NEAREST, center=(48, 48))
    im.alpha_composite(layer)
    # Heat wisps so a fresh slice reads as just out of the oven.
    for i in range(3):
        wx = 34 + i * 14
        for k in range(3):
            d.point((wx + (k % 2), 12 - k * 3 - i), fill=(255, 236, 196, 190 - k * 50))
    return im


def baking_pizza_frame(stage):
    """Six authored doneness stages, viewed in perspective inside the mouth."""
    im = Image.new("RGBA", (128, 96))
    d = ImageDraw.Draw(im)
    cx, cy, rx, ry = 64, 64, 32, 15

    # The stone deck and peel edge make the pie read as an object being cooked,
    # rather than another flame blob painted into the oven opening.
    d.ellipse((cx-rx-7, cy+6, cx+rx+7, cy+18), fill=(10, 9, 8, 185))
    rect(d, (cx-rx-9, cy+9, cx+rx+9, cy+13), INK)
    rect(d, (cx-rx-6, cy+9, cx+rx+6, cy+10), IRON[7])

    # Dark contact edge, then a thick crust whose tone progresses with doneness.
    d.ellipse((cx-rx-3, cy-ry-3, cx+rx+3, cy+ry+3), fill=INK)
    d.ellipse((cx-rx, cy-ry, cx+rx, cy+ry), fill=BAKED_CRUST[stage])
    d.ellipse((cx-rx+5, cy-ry+4, cx+rx-5, cy+ry-5), fill=SAUCE[max(1, 3 - stage // 2)])

    # Cheese starts pale and flat, then saturates, blisters and browns toward the
    # rim. Stepped bands preserve the texture at the actual ~45 px display size.
    cheese_index = stage
    d.ellipse((cx-rx+8, cy-ry+5, cx+rx-8, cy+ry-6), fill=BAKED_CHEESE[cheese_index])
    d.arc((cx-rx+10, cy-ry+7, cx+rx-10, cy+ry-7), 195, 338,
          fill=BAKED_CHEESE[max(0, cheese_index-1)], width=2)
    for x in range(cx-rx+8, cx+rx-7, 4):
        edge = abs(x-cx)/max(1, rx-8)
        y = int(cy + (1-edge*edge)*4 - 2)
        tone = BAKED_CHEESE[min(5, cheese_index+1)] if ((x//4)+stage)%3 else BAKED_CHEESE[cheese_index]
        d.point((x, y), fill=tone)

    toppings = ((50, 59, 4), (69, 57, 4), (78, 66, 3), (57, 69, 3))
    for index, (tx, ty, radius) in enumerate(toppings):
        squash = max(2, radius-1)
        d.ellipse((tx-radius, ty-squash, tx+radius, ty+squash), fill=SAUCE[max(1, 3-stage//3)])
        if stage >= 2:
            d.point((tx-1, ty-1), fill=(242, 108, 61, 255))
    for bx, by in ((61, 57), (73, 69)):
        poly(d, ((bx, by-3), (bx+4, by), (bx, by+3), (bx-4, by)), BASIL[1])
        d.point((bx, by), fill=BASIL[2])

    # Real cheese bubbles appear only once the pie is cooking in earnest. Their
    # highlights and brown pin-pricks are staged, not random noise.
    bubble_sets = (((45, 65, 2),), ((45, 65, 2), (66, 63, 3)),
                   ((45, 65, 2), (66, 63, 3), (75, 58, 2), (56, 56, 2)))
    if stage >= 2:
        bubbles = bubble_sets[min(2, stage-2)]
        for i, (bx, by, radius) in enumerate(bubbles):
            d.ellipse((bx-radius, by-max(1, radius-1), bx+radius, by+max(1, radius-1)),
                      fill=BAKED_CHEESE[max(0, cheese_index-1)])
            d.point((bx-1, by-1), fill=(255, 247, 202, 255))
            if stage >= 4 and i % 2 == 0:
                d.point((bx+1, by), fill=CRUST[1])

    # A browned crescent and cheese oil glints make the final two stages pop.
    if stage >= 4:
        d.arc((cx-rx+2, cy-ry+2, cx+rx-2, cy+ry-2), 16, 164,
              fill=CRUST[1 if stage == 4 else 0], width=2)
        for gx, gy in ((48, 58), (63, 69), (80, 64)):
            rect(d, (gx, gy, gx+2, gy+1), FIRE[4 if stage == 4 else 5])
    return im


def baking_wisp_frame(index):
    """Three crisp heat-wisp frames, drawn only while the oven is receiving heat."""
    im = Image.new("RGBA", (128, 96))
    d = ImageDraw.Draw(im)
    shifts = ((0, 2, -1), (2, -1, 1), (-1, 1, 2))[index]
    for strand, base_x in enumerate((49, 64, 79)):
        shift = shifts[strand]
        points = ((base_x, 54), (base_x+shift, 49), (base_x-shift, 44),
                  (base_x+shift, 39), (base_x, 34))
        colors = ((255, 226, 157, 205), (255, 241, 196, 180),
                  (255, 250, 224, 145), (255, 255, 238, 105))
        for p in range(len(points)-1):
            x0, y0 = points[p]
            x1, y1 = points[p+1]
            d.line((x0, y0, x1, y1), fill=colors[p], width=2 if p < 2 else 1)
            d.point((x0+1, y0), fill=colors[min(3, p+1)])
    # A couple of rising cheese-oil sparks keep the loop visibly alive.
    for sx, sy in (((43, 47), (86, 41)), ((42, 42), (87, 48)), ((45, 38), (84, 45)))[index]:
        rect(d, (sx, sy, sx+2, sy+3), FIRE[4])
        d.point((sx+1, sy-2), fill=FIRE[5])
    return im


def feast_aura_frame(index, front=False):
    """Restrained six-frame yellow power aura, split around the actor depth."""
    im = Image.new("RGBA", (192, 192))
    d = ImageDraw.Draw(im)
    sway = (-3, 1, 3, 0, -2, 2)[index]
    lift = (0, -2, 1, -1, 2, 0)[index]

    if not front:
        # A broken, asymmetric flame silhouette leaves the character readable.
        outer = ((47, 159), (44+sway, 134), (52, 117), (48-sway, 96),
                 (64, 106), (61+sway, 72), (75, 87), (84-sway, 43+lift),
                 (97, 70), (109+sway, 36-lift), (116, 78), (133-sway, 58),
                 (130, 98), (148+sway, 87), (140, 122), (150, 140), (145, 159))
        poly(d, outer, AURA[0])
        mid = ((56, 159), (54, 132), (66+sway, 116), (63, 91),
               (80-sway, 105), (87, 64+lift), (98, 91), (111+sway, 57),
               (116, 103), (135-sway, 88), (128, 122), (140, 139), (136, 159))
        poly(d, mid, AURA[1])
        inner = ((68, 159), (65+sway, 137), (78, 120), (78-sway, 97),
                 (92, 113), (100+sway, 77+lift), (108, 117), (125-sway, 105),
                 (119, 133), (130, 145), (126, 159))
        poly(d, inner, AURA[2])
        # Pixel cuts keep the contour crisp instead of reading as one flat blob.
        for x, y, w, h in ((46+sway, 111, 9, 12), (62-sway, 79, 8, 14),
                           (132+sway, 95, 10, 15), (137-sway, 128, 9, 10)):
            rect(d, (x, y, x+w, y+h), (0, 0, 0, 0))
        # Sparse energy dashes rise at different speeds in each real frame.
        motes = (
            ((38, 125), (153, 111), (72, 51)), ((42, 101), (149, 137), (121, 48)),
            ((37, 143), (155, 88), (69, 67)), ((43, 116), (151, 103), (126, 53)),
            ((39, 91), (154, 128), (74, 45)), ((44, 137), (148, 96), (120, 61)),
        )[index]
        for j, (x, y) in enumerate(motes):
            color = AURA[3+j % 2]
            rect(d, (x, y, x+3+(j % 2)*2, y+8-(j % 2)*2), color)
            if j == 2:
                rect(d, (x+2, y-4, x+4, y-2), AURA[4])
    else:
        # A low front rim grounds the aura without washing over the face or prop.
        left = 57 + sway
        right = 137 + sway
        poly(d, ((left, 158), (left+7, 145), (left+14, 153), (left+22, 139),
                 (left+31, 154), (96, 147+lift), (right-30, 155), (right-21, 140),
                 (right-13, 152), (right-6, 144), (right, 158)), AURA[2])
        poly(d, ((left+9, 159), (left+18, 151), (left+26, 158), (96, 153+lift),
                 (right-25, 158), (right-17, 150), (right-8, 159)), AURA[4])
        sparks = (
            ((62, 131), (130, 120)), ((67, 119), (137, 137)), ((58, 140), (128, 126)),
            ((66, 128), (140, 111)), ((55, 122), (132, 142)), ((64, 138), (138, 125)),
        )[index]
        for j, (x, y) in enumerate(sparks):
            rect(d, (x+sway, y, x+sway+3, y+6), AURA[3+j])
    return im


def build():
    oven = Image.new("RGBA", (256 * 6, 192))
    for state in range(6):
        oven.alpha_composite(oven_frame(state), (state * 256, 0))
    oven.save(OUT / "pizza-oven-atlas-pixel-v1.png")

    slices = Image.new("RGBA", (96 * 4, 96))
    for index in range(4):
        slices.alpha_composite(slice_frame(index), (index * 96, 0))
    slices.save(OUT / "pizza-slice-atlas-pixel-v1.png")

    baking = Image.new("RGBA", (128 * 6, 96 * 2))
    for stage in range(6):
        baking.alpha_composite(baking_pizza_frame(stage), (stage * 128, 0))
    for index in range(3):
        baking.alpha_composite(baking_wisp_frame(index), (index * 128, 96))
    baking.save(OUT / "pizza-oven-baking-atlas-pixel-v1.png")

    aura = Image.new("RGBA", (192 * 6, 192 * 2))
    for index in range(6):
        aura.alpha_composite(feast_aura_frame(index, False), (index * 192, 0))
        aura.alpha_composite(feast_aura_frame(index, True), (index * 192, 192))
    aura.save(FX_OUT / "companion-feast-aura-atlas-pixel-v1.png")
    print("pizza-oven-atlas-pixel-v1.png 1536x192, pizza-slice-atlas-pixel-v1.png 384x96, "
          "pizza-oven-baking-atlas-pixel-v1.png 768x192, "
          "companion-feast-aura-atlas-pixel-v1.png 1152x384")


if __name__ == "__main__":
    build()
