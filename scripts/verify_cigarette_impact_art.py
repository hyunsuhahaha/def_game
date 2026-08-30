from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
path = ROOT / "assets/fx/cigarette-impact-atlas-pixel-v1.png"
image = Image.open(path).convert("RGBA")
assert image.size == (1600, 320), image.size
assert image.getchannel("A").getextrema() == (0, 255)

for row, name in enumerate(("landing", "ignition")):
    occupied = []
    colors = set()
    for frame in range(10):
        cell = image.crop((frame*160, row*160, (frame+1)*160, (row+1)*160))
        alpha = cell.getchannel("A")
        assert alpha.getbbox(), f"{name} frame {frame} is empty"
        occupied.append(sum(1 for value in alpha.get_flattened_data() if value))
        colors.update(pixel[:3] for pixel in cell.get_flattened_data() if pixel[3])
    assert max(occupied) > min(occupied) * 1.6, f"{name} silhouette is static"
    assert len(colors) >= 10, f"{name} material ramp too shallow: {len(colors)}"

print("CIGARETTE_IMPACT_ART_OK atlas=10x2 frame=160px landing+ignition")
