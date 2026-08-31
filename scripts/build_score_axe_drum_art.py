"""Build the damage-state oil drum and its short axe-contact pixel FX."""
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
COMPANIONS = ROOT / "assets" / "characters" / "companions"
FX = ROOT / "assets" / "fx"

CELL = 128
DRUM_STATES = 3

INK = (24, 28, 27, 255)
METAL = [
    (43, 50, 49, 255), (51, 60, 58, 255), (61, 72, 69, 255),
    (74, 86, 82, 255), (88, 101, 96, 255), (106, 119, 112, 255),
    (127, 139, 130, 255), (150, 161, 149, 255),
]
RUST = [(83, 48, 31, 255), (119, 65, 38, 255), (157, 88, 45, 255), (198, 125, 57, 255)]
GOLD = [(91, 55, 18, 255), (151, 96, 28, 255), (219, 158, 52, 255), (255, 214, 96, 255)]


def rect(draw, box, fill):
    draw.rectangle(tuple(int(v) for v in box), fill=fill)


def barrel_bounds(y, state):
    if y < 27 or y > 111:
        return None
    if y < 34:
        half = 28 + (y - 27) // 2
    elif y > 102:
        half = 33 - (y - 102) // 2
    else:
        half = 34
    left, right = 64 - half, 64 + half
    if state >= 1 and 39 <= y <= 62:
        right -= max(0, 8 - abs(50 - y) // 2)
    if state >= 2 and 73 <= y <= 101:
        left += max(0, 6 - abs(87 - y) // 3)
        right -= 2 if y > 91 else 0
    return left, right


def draw_drum_state(atlas, state):
    frame = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    px = frame.load()
    # Curved steel body. Every texel belongs to a material/light band; the
    # ordered dither describes curvature rather than adding random noise.
    for y in range(27, 112):
        bounds = barrel_bounds(y, state)
        if not bounds:
            continue
        left, right = bounds
        for x in range(left, right + 1):
            edge = min(x - left, right - x)
            if edge < 3:
                color = INK
            else:
                u = (x - left) / max(1, right - left)
                light = 1.0 - abs(u - 0.43) * 1.65
                vertical = 0.08 if 35 < y < 64 else (-0.08 if y > 90 else 0)
                level = max(0, min(7, int((light + vertical) * 7)))
                if ((x + y * 2) % 5 == 0) and 3 < edge < 12:
                    level = max(0, level - 1)
                color = METAL[level]
            px[x, y] = color

    d = ImageDraw.Draw(frame)
    # Rolled rims and reinforcing bands use separate stepped ramps.
    for y, top in ((26, True), (62, False), (101, False)):
        bounds = barrel_bounds(max(27, y), state) or (34, 94)
        left, right = bounds
        rect(d, (left - 2, y, right + 2, y + 3), INK)
        rect(d, (left, y + 1, right, y + 1), METAL[7] if top else METAL[5])
        rect(d, (left + 3, y + 2, right - 3, y + 2), METAL[2])
    rect(d, (39, 21, 88, 25), INK)
    rect(d, (43, 19, 84, 21), METAL[6])
    rect(d, (48, 18, 78, 19), METAL[3])
    rect(d, (38, 110, 89, 113), INK)
    rect(d, (43, 109, 84, 110), METAL[3])

    # Oil label: small enough to read at runtime, but with metal inset depth.
    rect(d, (51, 69, 76, 93), INK)
    rect(d, (54, 71, 73, 90), GOLD[1])
    rect(d, (57, 74, 70, 87), GOLD[2])
    rect(d, (60, 76, 68, 85), GOLD[3])
    rect(d, (63, 78, 65, 83), (117, 68, 18, 255))

    # Purposeful rust at water traps and rim seams.
    chips = ((38, 37, 0), (85, 43, 1), (43, 59, 2), (82, 98, 0), (47, 105, 1), (88, 67, 0))
    for x, y, ramp in chips:
        rect(d, (x, y, x + 3, y + 2), RUST[ramp])
        rect(d, (x + 1, y, x + 2, y), RUST[min(3, ramp + 2)])

    # Dents are part of the steel surface, not a generic flash overlay.
    if state >= 1:
        d.line(((83, 40), (77, 47), (81, 53), (74, 60)), fill=INK, width=2)
        d.line(((82, 41), (77, 47), (80, 52)), fill=METAL[6], width=1)
        rect(d, (73, 58, 78, 61), RUST[1])
    if state >= 2:
        d.line(((42, 74), (49, 80), (44, 88), (51, 96)), fill=INK, width=2)
        d.line(((44, 75), (49, 80), (45, 87)), fill=METAL[6], width=1)
        rect(d, (48, 94, 54, 98), RUST[2])
        rect(d, (87, 103, 90, 108), RUST[3])

    atlas.alpha_composite(frame, (state * CELL, 0))


def build_drum():
    atlas = Image.new("RGBA", (CELL * DRUM_STATES, CELL), (0, 0, 0, 0))
    for state in range(DRUM_STATES):
        draw_drum_state(atlas, state)
    path = COMPANIONS / "oil-drum-damage-atlas-pixel-v2.png"
    atlas.save(path)
    return path


def polygon(draw, points, fill):
    draw.polygon(tuple((int(x), int(y)) for x, y in points), fill=fill)


def build_hit_fx():
    cell_w, cell_h, frames = 192, 160, 6
    atlas = Image.new("RGBA", (cell_w * frames, cell_h), (0, 0, 0, 0))
    hot = [(112, 49, 18, 255), (221, 100, 29, 255), (255, 181, 55, 255), (255, 235, 145, 255), (255, 253, 225, 255)]
    steel = [INK, METAL[2], METAL[5], METAL[7]]
    for frame_index in range(frames):
        frame = Image.new("RGBA", (cell_w, cell_h), (0, 0, 0, 0))
        d = ImageDraw.Draw(frame)
        p = frame_index / (frames - 1)
        cx, cy = 91, 84
        if frame_index <= 3:
            size = (8, 15, 20, 14)[frame_index]
            polygon(d, ((cx - size, cy), (cx, cy - size // 2), (cx + size, cy), (cx, cy + size // 2)), hot[1])
            inner = max(3, size - 6)
            polygon(d, ((cx - inner, cy), (cx, cy - inner // 2), (cx + inner, cy), (cx, cy + inner // 2)), hot[4])
            rect(d, (cx - max(2, inner // 2), cy - 2, cx + inner, cy + 2), hot[3])

        travel = (0, 10, 24, 39, 53, 67)[frame_index]
        rays = ((1.0, -0.62, 0), (1.0, -0.18, 1), (1.0, 0.26, 2), (.74, .66, 1), (.35, -.9, 2))
        for index, (dx, dy, variant) in enumerate(rays):
            start = 10 + variant * 3
            length = max(0, travel - start)
            if length <= 0:
                continue
            x = cx + dx * (start + length * .65)
            y = cy + dy * (start + length * .65)
            w = max(2, 7 - frame_index)
            polygon(d, ((x - w, y), (x, y - w // 2 - 1), (x + w + length * .18, y + dy * 2), (x, y + w // 2 + 1)), hot[3 - min(2, frame_index // 2)])
            rect(d, (x, y - 1, x + max(2, length * .12), y + 1), hot[4])

        # Metal flakes tumble farther than the hot sparks and keep the impact
        # readable after the white contact core is gone.
        for index, (dx, dy) in enumerate(((1, -.46), (.82, .5), (.48, -.82))):
            dist = travel * (0.55 + index * .11)
            x, y = cx + dx * dist, cy + dy * dist + p * p * 18
            s = max(2, 5 - frame_index // 2)
            polygon(d, ((x - s, y), (x, y - s), (x + s + 1, y), (x, y + s)), steel[(index + frame_index) % len(steel)])
            if frame_index < 4:
                rect(d, (x, y - s, x + 1, y - s + 1), steel[3])
        atlas.alpha_composite(frame, (frame_index * cell_w, 0))
    path = FX / "oil-drum-axe-hit-atlas-pixel-v1.png"
    atlas.save(path)
    return path


def main():
    COMPANIONS.mkdir(parents=True, exist_ok=True)
    FX.mkdir(parents=True, exist_ok=True)
    drum = build_drum()
    hit = build_hit_fx()
    print(f"SCORE_AXE_DRUM_ART_OK drum={drum.name} 384x128 states=3 hit={hit.name} 1152x160 frames=6")


if __name__ == "__main__":
    main()
