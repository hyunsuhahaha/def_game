"""Static contracts for the authored flamethrower pixel assets."""
from pathlib import Path
from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[1]
stream = Image.open(ROOT / "assets/effects/smoker-flamethrower-stream-atlas-v5.png").convert("RGBA")
master = Image.open(ROOT / "assets/effects/smoker-flamethrower-master-pixel-v1.png").convert("RGBA")
motion = Image.open(ROOT / "assets/effects/smoker-flamethrower-stream-v5.gif")
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
core_masks = []
for frame in frames:
    core = Image.new("1", frame.size)
    core.putdata([pixel[:3] == WHITE[:3] and pixel[3] > 0
        for pixel in frame.get_flattened_data()])
    core_masks.append(core)
for index, (first, second) in enumerate(zip(frames, frames[1:] + frames[:1])):
    changed = sum(pixel != (0, 0, 0, 0)
        for pixel in ImageChops.difference(first, second).get_flattened_data())
    assert changed >= 350_000, "animation reused a static silhouette"
    core_changed = sum(ImageChops.difference(
        core_masks[index], core_masks[(index + 1) % 8]).get_flattened_data())
    assert core_changed >= 85_000, "white-hot core did not redraw between moments"
assert len(stream.getcolors(maxcolors=10_000_000) or []) == 13
alpha_values = {index for index, count in enumerate(equipment.getchannel("A").histogram()) if count}
assert alpha_values <= {0, 255}, "equipment edge alpha must stay hard"
assert len(equipment.getcolors(maxcolors=10_000_000) or []) >= 24
print("FLAMETHROWER_ASSETS_OK stream=v5:6144x1536 frames=8 gif=8 silhouettes=independent core=redrawn")
