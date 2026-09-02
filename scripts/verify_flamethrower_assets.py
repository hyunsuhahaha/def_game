"""Static contracts for the authored flamethrower pixel assets."""
from pathlib import Path
from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[1]
stream = Image.open(ROOT / "assets/effects/smoker-flamethrower-stream-atlas-v3.png").convert("RGBA")
equipment = Image.open(ROOT / "assets/effects/smoker-flamethrower-equipment-v1.png").convert("RGBA")
WHITE = (255, 252, 220, 255)
assert stream.size == (5120, 1536)
assert equipment.size == (384, 128)
frames = []
for index in range(8):
    x, y = (index % 4) * 1280, (index // 4) * 768
    frame = stream.crop((x, y, x + 1280, y + 768));frames.append(frame)
    assert frame.getbbox() and frame.getbbox()[2] >= 1230, "stream lost its full-reach silhouette"
    root = frame.crop((44, 344, 238, 424)).getbbox()
    assert root, "hot nozzle core detached from the stream"
    alpha = frame.getchannel("A")
    # Midstream stays pressurized while the nozzle and leading tip taper. This
    # rejects both the former chain of circular fireballs and a flat laser bar.
    mid = alpha.crop((300, 180, 980, 588)).getbbox()
    assert mid and mid[3] - mid[1] >= 250, "stream lost its turbulent body"
    hot = frame.crop((120, 250, 1160, 518))
    white = sum(count for count, pixel in (hot.getcolors(maxcolors=10_000_000) or [])
                if pixel[:3] == WHITE[:3] and pixel[3])
    assert white >= 3000, "stream lost its travelling white-hot ribbons"
for first, second in zip(frames, frames[1:] + frames[:1]):
    assert ImageChops.difference(first, second).getbbox(), "duplicate animation frame"
assert len(stream.getcolors(maxcolors=10_000_000) or []) >= 12
alpha_values = {index for index, count in enumerate(equipment.getchannel("A").histogram()) if count}
assert alpha_values <= {0, 255}, "equipment edge alpha must stay hard"
assert len(equipment.getcolors(maxcolors=10_000_000) or []) >= 24
print("FLAMETHROWER_ASSETS_OK stream=v3:5120x1536 frames=8 equipment=384x128 flow=forward")
