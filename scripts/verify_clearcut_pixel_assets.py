"""Verify native-size clear-cut scenery and developer machinery assets."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SPECS = {
    "assets/trees/broadleaf-tree-pixel-v2.png": (193, 208),
    "assets/trees/pine-tree-pixel-v2.png": (151, 226),
    "assets/trees/birch-tree-pixel-v2.png": (144, 216),
    "assets/trees/maple-tree-pixel-v2.png": (151, 226),
    "assets/characters/ingame/developer-bulldozer-pixel-v2.png": (192, 140),
}

for name, expected_size in SPECS.items():
    image = Image.open(ROOT / name).convert("RGBA")
    assert image.size == expected_size, (name, image.size)
    assert image.getchannel("A").getbbox(), f"{name}: empty alpha"
    colors = image.getcolors(maxcolors=image.width * image.height) or []
    opaque = {color[:3] for _, color in colors if color[3]}
    assert 72 <= len(opaque) <= 110, (name, len(opaque))
    assert any(color[3] == 0 for _, color in colors), f"{name}: transparent background missing"

world = (ROOT / "src/world.lua").read_text(encoding="utf-8")
game = (ROOT / "src/game.lua").read_text(encoding="utf-8")
mode = (ROOT / "src/clearcut_mode.lua").read_text(encoding="utf-8")
for name in list(SPECS)[:4]:
    assert Path(name).name in world
assert "developer-bulldozer-pixel-v2.png" in game
for token in ("construction_dash", "construction_blast", "drawDeveloperMachinery"):
    assert token in mode, f"runtime developer FX missing: {token}"
print("CLEARCUT_PIXEL_ASSETS_OK assets=5 native_scale=1 palettes=limited")
