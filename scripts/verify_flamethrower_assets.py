"""Static contracts for the authored flamethrower pixel assets."""
from pathlib import Path
from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[1]
stream = Image.open(ROOT / "assets/effects/smoker-flamethrower-stream-atlas-v1.png").convert("RGBA")
equipment = Image.open(ROOT / "assets/effects/smoker-flamethrower-equipment-v1.png").convert("RGBA")
assert stream.size == (5120, 1536)
assert equipment.size == (384, 128)
frames = []
for index in range(8):
    x, y = (index % 4) * 1280, (index // 4) * 768
    frame = stream.crop((x, y, x + 1280, y + 768));frames.append(frame)
    assert frame.getbbox() and frame.getbbox()[2] >= 1230, "stream lost its cannon-length silhouette"
    root = frame.crop((44, 344, 238, 424)).getbbox()
    assert root, "hot nozzle core detached from the stream"
for first, second in zip(frames, frames[1:] + frames[:1]):
    assert ImageChops.difference(first, second).getbbox(), "duplicate animation frame"
assert len(stream.getcolors(maxcolors=10_000_000) or []) >= 16
alpha_values = {index for index, count in enumerate(equipment.getchannel("A").histogram()) if count}
assert alpha_values <= {0, 255}, "equipment edge alpha must stay hard"
assert len(equipment.getcolors(maxcolors=10_000_000) or []) >= 24
print("FLAMETHROWER_ASSETS_OK stream=5120x1536 frames=8 equipment=384x128 coherent=true")
