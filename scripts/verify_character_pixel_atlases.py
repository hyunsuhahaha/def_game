"""Headless contract checks for the four playable-character pixel atlases."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets" / "characters" / "ingame"
ROLES = ("logger", "smoker", "vegan", "developer")
ATLAS_SIZE = (576, 384)
CELL_SIZE = (96, 192)
FOOTLINE = 190


def frame_box(column: int, row: int) -> tuple[int, int, int, int]:
    width, height = CELL_SIZE
    return column * width, row * height, (column + 1) * width, (row + 1) * height


for role in ROLES:
    version = "v3" if role == "vegan" else "v2"
    path = ASSETS / f"{role}-atlas-pixel-{version}.png"
    image = Image.open(path).convert("RGBA")
    assert image.size == ATLAS_SIZE, (role, image.size)
    assert image.getpixel((0, 0))[3] == 0, f"{role}: background must be transparent"

    opaque_colors: set[tuple[int, int, int]] = set()
    for row in range(2):
        for column in range(6):
            frame = image.crop(frame_box(column, row))
            alpha = frame.getchannel("A")
            bounds = alpha.getbbox()
            assert bounds is not None, f"{role}: empty frame {row}:{column}"
            assert bounds[3] >= FOOTLINE - 5, f"{role}: floating frame {row}:{column} {bounds}"
            assert bounds[2] - bounds[0] >= 15, f"{role}: implausibly narrow frame {row}:{column}"
            assert bounds[3] - bounds[1] >= 50, f"{role}: implausibly short frame {row}:{column}"
            rgba_colors = frame.getcolors(maxcolors=CELL_SIZE[0] * CELL_SIZE[1]) or []
            opaque_colors.update(color[:3] for _, color in rgba_colors if color[3])

    assert 72 <= len(opaque_colors) <= 110, (role, len(opaque_colors))

game_source = (ROOT / "src" / "game.lua").read_text(encoding="utf-8")
for role in ROLES:
    version = "v3" if role == "vegan" else "v2"
    assert f'{role}-atlas-pixel-{version}.png' in game_source, f"{role}: runtime still uses an old atlas"
assert game_source.count("walkFeet={190,190,190,190,190,190}") >= 4
assert game_source.count("actionFeet={190,190,190,190,190,190}") >= 4
print("CHARACTER_PIXEL_ATLASES_OK roles=4 frames=48 cell=96x192 footline=190")
