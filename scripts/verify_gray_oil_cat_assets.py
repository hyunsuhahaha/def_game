from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
atlas = Image.open(root / "assets/characters/companions/gray-oil-cat-atlas-pixel-v1.png").convert("RGBA")
drum = Image.open(root / "assets/characters/companions/oil-drum-pixel-v1.png").convert("RGBA")
assert atlas.size == (768, 384)
assert drum.size == (128, 128)
assert atlas.getbbox() and drum.getbbox()
for row in range(3):
    for frame in range(6):
        assert atlas.crop((frame * 128, row * 128, (frame + 1) * 128, (row + 1) * 128)).getbbox()
print("GRAY_OIL_CAT_ASSETS_OK atlas=768x384 cells=18 drum=128x128")
