"""Focused asset checks for the interchangeable score-attack avatars."""

from pathlib import Path

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[1]
INGAME = ROOT / "assets/characters/ingame"
BODY_FILES = (
    "smoker-atlas-pixel-v3.png",
    "scrapyard-welder-atlas-pixel-v1.png",
    "night-shopkeeper-atlas-pixel-v1.png",
)
AXE_FILES = (
    "smoker-score-axe-atlas-pixel-v1.png",
    "scrapyard-welder-score-axe-atlas-pixel-v1.png",
    "night-shopkeeper-score-axe-atlas-pixel-v1.png",
)


def frames(image: Image.Image, rows: int) -> list[Image.Image]:
    return [
        image.crop((column * 96, row * 192, (column + 1) * 96, (row + 1) * 192))
        for row in range(rows)
        for column in range(6)
    ]


bodies = [Image.open(INGAME / name).convert("RGBA") for name in BODY_FILES]
axes = [Image.open(INGAME / name).convert("RGBA") for name in AXE_FILES]

for image in bodies:
    assert image.size == (576, 384), image.size
    assert set(image.getchannel("A").getdata()) <= {0, 255}
    cells = frames(image, 2)
    assert all(cell.getbbox() for cell in cells)
    assert all(cell.getbbox()[3] >= 188 for cell in cells), "body pose lost the shared foot baseline"
    assert all(ImageChops.difference(cells[i], cells[i + 1]).getbbox() for i in range(11))

for index, image in enumerate(axes):
    assert image.size == (576, 192), image.size
    if index:
        assert set(image.getchannel("A").getdata()) <= {0, 255}
    cells = frames(image, 1)
    assert all(cell.getbbox() for cell in cells)
    assert all(cell.getbbox()[3] >= 188 for cell in cells), "axe pose lost the shared foot baseline"
    assert all(ImageChops.difference(cells[i], cells[i + 1]).getbbox() for i in range(5))

# These are new silhouettes, not recolors of the archived smoker or each other.
assert ImageChops.difference(bodies[0], bodies[1]).getbbox()
assert ImageChops.difference(bodies[0], bodies[2]).getbbox()
assert ImageChops.difference(bodies[1], bodies[2]).getbbox()

# The two detached authored cigarettes in the old body sheet must stay empty;
# the live cigarette equipment renderer owns those pixels now.
clean = bodies[0]
anchors = (
    ((68, 29), 1), ((73, 29), 1), ((68, 42), 1),
    ((74, 29), 1), ((75, 36), 1), ((73, 29), 1),
    ((34, 30), -1), ((34, 30), -1), ((31, 29), -1),
    ((35, 32), -1), ((65, 32), 1), ((66, 31), 1),
)
cigarette_colors = {
    (235, 224, 195), (229, 217, 206), (254, 250, 241),
    (181, 117, 49), (255, 92, 24), (255, 183, 55),
    (237, 153, 16), (233, 35, 22), (245, 211, 116),
}
for index, ((anchor_x, anchor_y), facing) in enumerate(anchors):
    cell_x, cell_y = (index % 6) * 96, (index // 6) * 192
    x_start = anchor_x - 14 if facing < 0 else anchor_x
    x_end = anchor_x + 4 if facing < 0 else anchor_x + 14
    for y in range(anchor_y - 6, anchor_y + 7):
        for x in range(x_start, x_end + 1):
            assert clean.getpixel((cell_x + x, cell_y + y))[:3] not in cigarette_colors
for column, box in ((3, (5, 99, 16, 112)), (4, (75, 52, 91, 71))):
    left, top, right, bottom = box
    assert not clean.crop((column * 96 + left, 192 + top,
                           column * 96 + right, 192 + bottom)).getbbox()

print("SMOKER_CHARACTER_VARIANTS_ASSETS_OK body=3x12 axe=3x6 clean-runtime-cigarette")
