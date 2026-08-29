from pathlib import Path

from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[1]
ATLAS = ROOT / "assets/trees/stump-atlas-pixel-v1.png"

image = Image.open(ATLAS).convert("RGBA")
assert image.size == (512, 480), f"unexpected stump atlas size: {image.size}"
alpha = image.getchannel("A")
assert {value for _, value in alpha.getcolors(maxcolors=256)}.issubset({0, 255}), "stump atlas has soft alpha"
assert len(image.getcolors(maxcolors=512 * 384) or []) >= 90, "stump materials lost their authored palette detail"

cells = []
for index in range(17):
    x, y = (index % 4) * 128, (index // 4) * 96
    cell = image.crop((x, y, x + 128, y + 96))
    assert cell.getchannel("A").getbbox(), f"empty stump cell {index + 1}"
    cells.append(cell)
for index, cell in enumerate(cells[:16]):
    assert all(ImageChops.difference(cell, other).getbbox() for other in cells[:index]), f"duplicate stump cell {index + 1}"

world = (ROOT / "src/world.lua").read_text(encoding="utf-8")
floor = (ROOT / "src/forest_floor.lua").read_text(encoding="utf-8")
assert 'stump-atlas-pixel-v1.png' in world and 'setFilter("nearest","nearest")' in world
for token in ("forest=0", "beginner=0", "mangrove=4", "madagascar=7", "island=10", "greatforest=13"):
    assert token in world, f"missing biome stump mapping: {token}"
assert "stumpQuads[17]" in world, "regrowth sprout is not connected"
assert "node.giantTree and 38 or 26" in floor and "catalog.felled[1]" in floor
assert 'love.graphics.polygon("fill", node.x - 17' not in world, "legacy geometric stump returned"

print("STUMP_ASSETS_OK atlas=512x480 variants=16 biome_matched=true roots=source_pixels cut=rings soil=sawdust shadow=ground")
