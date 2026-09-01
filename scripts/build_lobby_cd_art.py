"""Bake the compact, track-specific half CDs used by the lobby audio bar.

Each size is authored at its final pixel grid. The three atlas rows are the
forest, river, and night records; columns are a quiet moving reflection.
"""
import math
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
FRAMES = 32
TRACKS = 3
SIZES = (
    ("lobby-cd-tracks-half-pixel-v2.png", 76, 2),
    ("lobby-cd-tracks-half-small-pixel-v2.png", 52, 2),
)

OUTLINE = (7, 17, 15)
BAYER = ((0, 2), (3, 1))
SHEEN_ARC = 28.0

PALETTES = (
    {  # FOREST DAY: resin green, bark label, young-leaf marks
        "dark": (18, 38, 30), "mid": (30, 58, 44), "rim": (48, 81, 58),
        "label": (83, 72, 38), "hub": (20, 43, 32),
        "hub_ring": (154, 183, 132),
        "sheen": ((211, 169, 76), (128, 174, 105), (91, 158, 126)),
    },
    {  # RIVER LINE: deep water, blue label, ripple marks
        "dark": (12, 34, 43), "mid": (20, 55, 67), "rim": (29, 77, 83),
        "label": (31, 78, 94), "hub": (12, 38, 47),
        "hub_ring": (133, 188, 186),
        "sheen": ((103, 175, 186), (124, 168, 202), (170, 201, 194)),
    },
    {  # OWL SHIFT: muted night violet, moon label, amber owl eyes
        "dark": (24, 27, 43), "mid": (39, 40, 62), "rim": (59, 53, 77),
        "label": (57, 51, 78), "hub": (26, 29, 45),
        "hub_ring": (166, 167, 190),
        "sheen": ((128, 139, 184), (162, 145, 188), (185, 183, 204)),
    },
)


def mix(a, b, amount):
    return tuple(round(a[i] + (b[i] - a[i]) * amount) for i in range(3))


def motif(track, dx, dy, radius, base):
    """Small fixed-grid label motifs, kept above the bar's clipping line."""
    scale = max(1, radius // 38)
    if track == 0:
        stem_x = round(radius * .03)
        if abs(dx - stem_x) <= scale and -radius * .30 <= dy <= -radius * .08:
            return (54, 75, 37)
        for ox, oy, side in ((-7, -18, -1), (7, -15, 1), (-5, -9, -1)):
            ox, oy = ox * scale, oy * scale
            if ((dx - ox) / (5 * scale)) ** 2 + ((dy - oy) / (3 * scale)) ** 2 <= 1:
                return (146, 165, 73) if side < 0 else (105, 143, 62)
    elif track == 1:
        for index, oy in enumerate((-19, -13, -7)):
            yy = oy * scale
            span = (12 - index * 2) * scale
            if abs(dy - yy) < scale and abs(dx + (index - 1) * 2 * scale) < span:
                if not (-2 * scale < dx < 2 * scale):
                    return (104, 170, 178) if index != 1 else (73, 143, 160)
    else:
        moon_x, moon_y = -7 * scale, -17 * scale
        moon = (dx - moon_x) ** 2 + (dy - moon_y) ** 2 <= (6 * scale) ** 2
        cut = (dx - moon_x - 3 * scale) ** 2 + (dy - moon_y + scale) ** 2 <= (5 * scale) ** 2
        if moon and not cut:
            return (197, 190, 150)
        if abs(dy + 8 * scale) < 2 * scale and any(
                abs(dx - eye * 5 * scale) < 2 * scale for eye in (-1, 1)):
            return (205, 143, 56)
    return base


def build_size(filename, radius, groove):
    cell_w, cell_h = radius * 2 + 8, radius + 8
    cx, cy = cell_w / 2 - .5, float(radius + 4)
    hub = max(12, round(radius * .34))
    hole = max(5, round(radius * .13))
    atlas = Image.new("RGBA", (cell_w * FRAMES, cell_h * TRACKS), (0, 0, 0, 0))

    for track, palette in enumerate(PALETTES):
        plan = []
        for y in range(cell_h):
            for x in range(cell_w):
                dx, dy = x - cx, y - cy
                r = math.hypot(dx, dy)
                if r <= hole or r > radius + 2:
                    continue
                if r > radius:
                    plan.append((x, y, None, OUTLINE))
                    continue
                angle = math.degrees(math.atan2(dy, dx)) % 360
                if r <= hub:
                    edge = hub - max(2, radius // 25)
                    base = palette["hub_ring"] if r > edge else palette["label"]
                    if r <= edge:
                        base = motif(track, dx, dy, radius, base)
                    plan.append((x, y, None, base))
                    continue
                ring = palette["mid"] if int(r / groove) % 2 else palette["dark"]
                rim_amount = max(0, min(1, (r - radius * .63) / (radius * .37)))
                base = mix(ring, palette["rim"], .20 * (1 - rim_amount))
                base = mix(base, palette["dark"], rim_amount * .42)
                dither = (BAYER[y % 2][x % 2] + .5) / 4 - .5
                plan.append((x, y, (angle, r, dither), base))

        for frame in range(FRAMES):
            rotation = frame * 360 / FRAMES
            tile = Image.new("RGBA", (cell_w, cell_h), (0, 0, 0, 0))
            pixels = tile.load()
            for x, y, geometry, base in plan:
                if geometry is None:
                    pixels[x, y] = base + (255,)
                    continue
                angle, r, dither = geometry
                distance = abs(((angle - rotation + 180) % 360) - 180)
                if distance >= SHEEN_ARC or r < hub + 3:
                    pixels[x, y] = base + (255,)
                    continue
                strength = (1 - distance / SHEEN_ARC) ** 1.4
                band = int((r / groove + distance / 7) % len(palette["sheen"]))
                level = max(0, min(3, int(strength * 3 + dither + .5)))
                pixels[x, y] = mix(base, palette["sheen"][band], level / 3 * .44) + (255,)
            atlas.alpha_composite(tile, (frame * cell_w, track * cell_h))

    output = ROOT / "assets" / "ui" / filename
    output.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(output, optimize=True)
    colours = len({pixel for pixel in atlas.getdata() if pixel[3]})
    print(f"LOBBY_CD_ATLAS_OK {output.relative_to(ROOT)} tracks={TRACKS} "
          f"frames={FRAMES} cell={cell_w}x{cell_h} radius={radius} colors={colours}")


if __name__ == "__main__":
    for spec in SIZES:
        build_size(*spec)
