from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
path = ROOT / "assets/fx/tree-fire-pulse-atlas-pixel-v1.png"
image = Image.open(path).convert("RGBA")
assert image.size == (2304, 160), image.size
assert image.getchannel("A").getextrema() == (0, 255)

occupied = []
colors = set()
tops = []
for frame in range(12):
    cell = image.crop((frame * 192, 0, (frame + 1) * 192, 160))
    alpha = cell.getchannel("A")
    box = alpha.getbbox()
    assert box, f"empty pulse frame {frame}"
    occupied.append(sum(1 for value in alpha.get_flattened_data() if value))
    tops.append(box[1])
    colors.update(pixel[:3] for pixel in cell.get_flattened_data() if pixel[3])

assert max(occupied) > min(occupied) * 2.2, "combustion pulse silhouette barely changes"
assert max(tops) - min(tops) >= 45, "flame does not visibly surge"
assert len(colors) >= 8, f"fire material ramp too shallow: {len(colors)}"
print("TREE_FIRE_PULSE_ART_OK atlas=12x192x160 surge=stepped rupture+embers")
