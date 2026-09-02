"""Static contracts for the authored flamethrower pixel assets."""
from pathlib import Path
from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[1]
stream = Image.open(ROOT / "assets/effects/smoker-flamethrower-stream-atlas-v4.png").convert("RGBA")
master = Image.open(ROOT / "assets/effects/smoker-flamethrower-master-pixel-v1.png").convert("RGBA")
motion = Image.open(ROOT / "assets/effects/smoker-flamethrower-stream-v4.gif")
equipment = Image.open(ROOT / "assets/effects/smoker-flamethrower-equipment-v1.png").convert("RGBA")
WHITE = (255, 252, 220, 255)
assert stream.size == (6144, 1536)
assert master.size == (1536, 768) and motion.size == master.size and motion.n_frames == 8
assert equipment.size == (384, 128)
assert {index for index, count in enumerate(master.getchannel("A").histogram()) if count} <= {0, 255}
frames = []
for index in range(8):
    x, y = (index % 4) * 1536, (index // 4) * 768
    frame = stream.crop((x, y, x + 1536, y + 768));frames.append(frame)
    assert frame.getbbox() and frame.getbbox()[2] >= 1500, "stream lost its full-reach silhouette"
    root = frame.crop((20, 300, 340, 520)).getbbox()
    assert root, "hot nozzle core detached from the stream"
    alpha = frame.getchannel("A")
    mid = alpha.crop((480, 40, 1320, 730)).getbbox()
    assert mid and mid[3] - mid[1] >= 540, "stream lost its large turbulent body"
    hot = frame.crop((260, 180, 1460, 700))
    white = sum(count for count, pixel in (hot.getcolors(maxcolors=10_000_000) or [])
                if pixel[:3] == WHITE[:3] and pixel[3])
    assert white >= 3000, "stream lost its travelling white-hot ribbons"
for first, second in zip(frames, frames[1:] + frames[:1]):
    changed = sum(pixel != (0, 0, 0, 0)
        for pixel in ImageChops.difference(first, second).get_flattened_data())
    assert changed >= 70_000, "animation is a static source with token wobble"
master_alpha = list(master.getchannel("A").get_flattened_data())
for frame in frames:
    frame_alpha = list(frame.getchannel("A").get_flattened_data())
    intersection = sum(bool(a and b) for a, b in zip(master_alpha, frame_alpha))
    union = sum(bool(a or b) for a, b in zip(master_alpha, frame_alpha))
    assert intersection / union >= .97, "animation discarded the captured reference silhouette"
assert len(stream.getcolors(maxcolors=10_000_000) or []) == 12
alpha_values = {index for index, count in enumerate(equipment.getchannel("A").histogram()) if count}
assert alpha_values <= {0, 255}, "equipment edge alpha must stay hard"
assert len(equipment.getcolors(maxcolors=10_000_000) or []) >= 24
print("FLAMETHROWER_ASSETS_OK stream=v4:6144x1536 frames=8 gif=8 master=transparent source=captured")
