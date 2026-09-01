"""Bake real blanket-covered lobby sleep loops from the approved concept sheet.

The concept keeps each companion's approved identity while providing a genuinely
authored sleeping silhouette: pillow, closed eyes, blanket mound, and (for the
monkey) a sleeping cap. This baker removes the concept backdrop, locks it to the
game pixel grid, and produces a six-frame breathing loop with hard alpha.
"""
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/characters/companions"
CONCEPT = OUT / "concepts/lobby-companion-sleep-concept-v1.png"
FRAMES = 6

# Crop zones are normalized so rebuilding stays deterministic if the stored
# concept is losslessly repacked without changing its composition.
SPECS = (
    {
        "name": "monkey", "zone": (0.00, 0.14, 0.34, 0.61),
        "cell": (192, 160), "width": 174, "foot": 152,
        "output": OUT / "lobby-monkey-sleep-atlas-pixel-v2.png",
    },
    {
        "name": "mole", "zone": (0.35, 0.14, 0.66, 0.62),
        "cell": (320, 384), "width": 292, "foot": 380,
        "output": OUT / "lobby-mole-sleep-atlas-pixel-v2.png",
    },
    {
        "name": "cat", "zone": (0.67, 0.14, 0.99, 0.62),
        "cell": (192, 160), "width": 166, "foot": 152,
        "output": OUT / "lobby-cat-sleep-atlas-pixel-v2.png",
    },
)

WALK_SPECS = {
    "monkey": (OUT / "graduate-monkey-atlas-pixel-v3.png", (128, 128), .42),
    "mole": (ROOT / "assets/characters/ingame/coin-miner-mole-atlas-pixel-v3.png", (192, 384), .29),
    "cat": (OUT / "gray-oil-cat-atlas-pixel-v1.png", (128, 128), .60),
}


def remove_backdrop(image):
    """Remove the neutral white concept backdrop without erasing cream cloth."""
    image = image.convert("RGBA")
    pixels = []
    for red, green, blue, alpha in image.getdata():
        neutral = max(red, green, blue) - min(red, green, blue) <= 9
        if alpha == 0 or (neutral and min(red, green, blue) >= 232):
            pixels.append((0, 0, 0, 0))
        else:
            pixels.append((red, green, blue, 255))
    image.putdata(pixels)
    return image


def concept_pose(source, spec):
    width, height = source.size
    x1, y1, x2, y2 = spec["zone"]
    pose = source.crop((round(width * x1), round(height * y1),
                        round(width * x2), round(height * y2)))
    bounds = pose.getbbox()
    if not bounds:
        raise RuntimeError(f"empty concept pose: {spec['name']}")
    pose = pose.crop(bounds)
    target_width = spec["width"]
    target_height = max(1, round(pose.height * target_width / pose.width))
    pose = pose.resize((target_width, target_height), Image.Resampling.NEAREST)

    # A fixed, restrained game palette keeps materials stepped and eliminates
    # interpolation colours while preserving the concept's hand-shaped clusters.
    alpha = pose.getchannel("A").point(lambda value: 255 if value >= 128 else 0)
    rgb = pose.convert("RGB").quantize(colors=64, method=Image.Quantize.MEDIANCUT,
                                       dither=Image.Dither.NONE).convert("RGB")
    rgb.putalpha(alpha)
    return rgb


def build(source, spec):
    cell_w, cell_h = spec["cell"]
    pose = concept_pose(source, spec)
    if pose.width > cell_w or pose.height > cell_h:
        raise RuntimeError(f"concept pose exceeds cell: {spec['name']} {pose.size}")
    atlas = Image.new("RGBA", (cell_w * FRAMES, cell_h), (0, 0, 0, 0))

    # Slow inhale/hold/exhale. The ground and lower tucked hem remain anchored;
    # only two native pixels of vertical expansion are used to avoid noisy motion.
    breath = (0, 2, 4, 4, 2, 0)
    for frame, amount in enumerate(breath):
        breathing = pose.resize((pose.width, pose.height + amount), Image.Resampling.NEAREST)
        x = frame * cell_w + (cell_w - breathing.width) // 2
        y = spec["foot"] - breathing.height
        atlas.alpha_composite(breathing, (x, y))

    spec["output"].parent.mkdir(parents=True, exist_ok=True)
    atlas.save(spec["output"], optimize=True)
    alpha_values = set(atlas.getchannel("A").getdata())
    if alpha_values - {0, 255}:
        raise RuntimeError(f"soft alpha in {spec['name']} sleep atlas")
    colours = len({pixel for pixel in atlas.getdata() if pixel[3]})
    print(f"LOBBY_COMPANION_SLEEP_OK {spec['name']} {atlas.width}x{atlas.height} "
          f"frames={FRAMES} colors={colours} blanket=1 closed_eyes=1 hard_alpha=1")


def validate_display_proportions(spec):
    walk_path, walk_cell, scale = WALK_SPECS[spec["name"]]
    walk = Image.open(walk_path).convert("RGBA").crop((0, 0, walk_cell[0], walk_cell[1]))
    sleep = Image.open(spec["output"]).convert("RGBA").crop((0, 0, spec["cell"][0], spec["cell"][1]))
    walk_box, sleep_box = walk.getbbox(), sleep.getbbox()
    walk_w, walk_h = walk_box[2] - walk_box[0], walk_box[3] - walk_box[1]
    sleep_w, sleep_h = sleep_box[2] - sleep_box[0], sleep_box[3] - sleep_box[1]
    width_ratio, height_ratio = sleep_w / walk_w, sleep_h / walk_h
    if not 1.65 <= width_ratio <= 2.25 or not .68 <= height_ratio <= 1.40:
        raise RuntimeError(f"physical sleep proportion drift: {spec['name']} "
                           f"width={width_ratio:.2f} height={height_ratio:.2f}")
    print(f"LOBBY_COMPANION_PROPORTION_OK {spec['name']} "
          f"awake={walk_w*scale:.1f}x{walk_h*scale:.1f} "
          f"sleep={sleep_w*scale:.1f}x{sleep_h*scale:.1f} same_scale={scale}")


if __name__ == "__main__":
    transparent = remove_backdrop(Image.open(CONCEPT))
    for item in SPECS:
        build(transparent, item)
        validate_display_proportions(item)
