"""Build the scrap-built brick pizza oven and its baked slice pickups.

The oven reads as a wood-fired dome welded onto a low handcart: the same
scavenged-industrial lineage as the oil drum and the puffed-rice cannon, not a
clean Neapolitan storefront. Six frames ramp the fire from cold to roaring so the
runtime can show how many trees are burning inside the collection radius.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import math

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "automation"
OUT.mkdir(parents=True, exist_ok=True)

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
SAUCE = [(96, 22, 18, 255), (146, 34, 24, 255), (192, 50, 32, 255), (224, 78, 48, 255)]
BASIL = [(28, 62, 26, 255), (46, 96, 38, 255), (72, 134, 54, 255)]


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


def build():
    oven = Image.new("RGBA", (256 * 6, 192))
    for state in range(6):
        oven.alpha_composite(oven_frame(state), (state * 256, 0))
    oven.save(OUT / "pizza-oven-atlas-pixel-v1.png")

    slices = Image.new("RGBA", (96 * 4, 96))
    for index in range(4):
        slices.alpha_composite(slice_frame(index), (index * 96, 0))
    slices.save(OUT / "pizza-slice-atlas-pixel-v1.png")
    print("pizza-oven-atlas-pixel-v1.png 1536x192, pizza-slice-atlas-pixel-v1.png 384x96")


if __name__ == "__main__":
    build()
