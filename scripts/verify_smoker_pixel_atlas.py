from pathlib import Path

import numpy as np
from PIL import Image


path = Path("assets/characters/ingame/smoker-atlas-pixel-v2.png")
image = Image.open(path).convert("RGBA")
assert image.size == (576, 384), f"unexpected atlas size: {image.size}"
array = np.asarray(image)
assert int(array[0, 0, 3]) == 0, "atlas background is not transparent"

bounds = []
for row in range(2):
    for column in range(6):
        alpha = image.getchannel("A").crop((column * 96, row * 192, (column + 1) * 96, (row + 1) * 192))
        box = alpha.getbbox()
        assert box is not None, f"empty frame: {row},{column}"
        assert box[3] == 190, f"unstable footline in frame {row},{column}: {box}"
        bounds.append(box)

opaque = array[:, :, 3] > 0
colors = np.unique(array[opaque, :3], axis=0)
assert 72 <= len(colors) <= 110, f"shared palette detail is out of range: {len(colors)}"

# The walking row always contains a bright cigarette/ember cluster near the head.
for column in range(6):
    frame = array[:96, column * 96:(column + 1) * 96]
    ember = (frame[:, :, 0] > 210) & (frame[:, :, 1] > 70) & (frame[:, :, 2] < 100) & (frame[:, :, 3] > 0)
    assert int(ember.sum()) >= 2, f"walk frame {column} lost its mouth cigarette"

game_source = Path("src/game.lua").read_text(encoding="utf-8")
assert 'file="smoker-atlas-pixel-v2.png"' in game_source, "new smoker atlas is not loaded in game"
assert "walkFeet={190,190,190,190,190,190}" in game_source, "smoker foot anchors are not locked"

print(f"SMOKER_PIXEL_ATLAS_OK frames=12 colors={len(colors)} footline=190")
