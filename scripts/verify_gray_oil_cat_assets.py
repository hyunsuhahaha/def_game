from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
atlas = Image.open(root / "assets/characters/companions/gray-oil-cat-atlas-pixel-v1.png").convert("RGBA")
drum = Image.open(root / "assets/characters/companions/oil-drum-pixel-v1.png").convert("RGBA")
spill = Image.open(root / "assets/fx/oil-drum-spill/oil-drum-spill-atlas-pixel-v2.png").convert("RGBA")
assert atlas.size == (768, 384)
assert drum.size == (128, 128)
assert spill.size == (1024, 400)
assert atlas.getbbox() and drum.getbbox() and spill.getbbox()
for row in range(3):
    for frame in range(6):
        assert atlas.crop((frame * 128, row * 128, (frame + 1) * 128, (row + 1) * 128)).getbbox()
for row in range(2):
    for frame in range(4):
        assert spill.crop((frame * 256, row * 200, (frame + 1) * 256, (row + 1) * 200)).getbbox()
print("GRAY_OIL_CAT_ASSETS_OK cat-cells=18 drum=128x128 spill-cells=8")
