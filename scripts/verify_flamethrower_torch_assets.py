"""Static contracts for the optional translucent-red torch comparison."""
from pathlib import Path

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / "assets" / "effects"
stream = Image.open(ASSET / "smoker-flamethrower-torch-atlas-v1.png").convert("RGBA")
impact = Image.open(ASSET / "smoker-flamethrower-torch-impact-atlas-v1.png").convert("RGBA")
stream_gif = Image.open(ASSET / "smoker-flamethrower-torch-v1.gif")
impact_gif = Image.open(ASSET / "smoker-flamethrower-torch-impact-v1.gif")
assert stream.size == (6144, 1536) and stream_gif.n_frames == 8
assert impact.size == (1024, 512) and impact_gif.n_frames == 8
for image in (stream, impact):
    alpha = {value for value, count in enumerate(image.getchannel("A").histogram()) if count}
    assert 0 in alpha and max(alpha) >= 224 and any(0 < value < 220 for value in alpha), "translucent red layers disappeared"
stream_frames = [stream.crop(((i % 4) * 1536, (i // 4) * 768,
    (i % 4 + 1) * 1536, (i // 4 + 1) * 768)) for i in range(8)]
impact_frames = [impact.crop(((i % 4) * 256, (i // 4) * 256,
    (i % 4 + 1) * 256, (i // 4 + 1) * 256)) for i in range(8)]
for frames in (stream_frames, impact_frames):
    for first, second in zip(frames, frames[1:] + frames[:1]):
        assert ImageChops.difference(first, second).getbbox(), "torch animation frame duplicated"
print("FLAMETHROWER_TORCH_ASSETS_OK stream=8 impact=8 alpha=stepped comparison=preserved")
