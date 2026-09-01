from pathlib import Path
from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[1]
drum = Image.open(ROOT / "assets/characters/companions/oil-drum-damage-atlas-pixel-v2.png").convert("RGBA")
hit = Image.open(ROOT / "assets/fx/oil-drum-axe-hit-atlas-pixel-v1.png").convert("RGBA")
axe = Image.open(ROOT / "assets/characters/ingame/smoker-score-axe-atlas-pixel-v4.png").convert("RGBA")
previous_axe = Image.open(ROOT / "assets/characters/ingame/smoker-score-axe-atlas-pixel-v2.png").convert("RGBA")
assert drum.size == (384, 128)
assert hit.size == (1152, 160)
assert axe.size == (1344, 224)
assert set(drum.getchannel("A").getdata()) <= {0, 255}
assert set(hit.getchannel("A").getdata()) <= {0, 255}
assert set(axe.getchannel("A").getdata()) <= {0, 255}
def silhouette_widths(image):
    cell_width = image.width // 6
    return [image.crop((index * cell_width, 0, (index + 1) * cell_width, image.height)).getbbox()[2]
            - image.crop((index * cell_width, 0, (index + 1) * cell_width, image.height)).getbbox()[0]
            for index in range(6)]

assert sum(silhouette_widths(axe)) > sum(silhouette_widths(previous_axe)) * 1.05
drum_frames = [drum.crop((i * 128, 0, (i + 1) * 128, 128)) for i in range(3)]
hit_frames = [hit.crop((i * 192, 0, (i + 1) * 192, 160)) for i in range(6)]
axe_frames = [axe.crop((i * 224, 0, (i + 1) * 224, 224)) for i in range(6)]
assert all(frame.getbbox() for frame in drum_frames + hit_frames)
assert all(frame.getbbox() for frame in axe_frames)
assert all(ImageChops.difference(drum_frames[i], drum_frames[i + 1]).getbbox() for i in range(2))
assert all(ImageChops.difference(hit_frames[i], hit_frames[i + 1]).getbbox() for i in range(5))
assert all(ImageChops.difference(axe_frames[i], axe_frames[i + 1]).getbbox() for i in range(5))
assert all(frame.getbbox()[3] >= 220 for frame in axe_frames), "axe poses lost the shared foot baseline"
print("SCORE_AXE_DRUM_ASSETS_OK axe=1344x224/6 fixed-body-scale poses drum=384x128/3 hit=1152x160/6")
