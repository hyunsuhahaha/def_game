"""Verify the oven uses an animated hearth fire and no interior pizza overlay."""
from pathlib import Path
from PIL import Image
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
path = ROOT / "assets/automation/pizza-oven-hearth-fire-atlas-pixel-v2.png"
image = Image.open(path).convert("RGBA")
assert image.size == (128 * 8, 96), f"wrong hearth atlas size: {image.size}"
arr = np.asarray(image)
assert set(np.unique(arr[:, :, 3])).issubset({0, 255}), "hearth fire has soft alpha"

frames = [arr[:, i * 128:(i + 1) * 128] for i in range(8)]
assert len({frame.tobytes() for frame in frames}) == 8, "hearth animation has duplicate frames"
for index, frame in enumerate(frames):
    opaque = frame[:, :, 3] > 0
    assert opaque.sum() > 1800, f"frame {index} is too sparse"
    assert opaque[82:90].sum() > 100, f"frame {index} lost the fixed firebox baseline"
    colors = {tuple(v) for v in frame[:, :, :3][opaque]}
    assert len(colors) >= 7, f"frame {index} lacks stepped fire/log materials"

runtime = (ROOT / "src/pizza_oven.lua").read_text(encoding="utf-8")
assert "pizza-oven-hearth-fire-atlas-pixel-v2.png" in runtime, "new hearth atlas is not connected"
assert "pizza-oven-baking-atlas-pixel-v1.png" not in runtime, "interior pizza overlay is still connected"
assert "bakeVisualState" not in runtime, "interior pizza visual state still exists at runtime"
print("PIZZA_OVEN_HEARTH_ASSETS_OK frames=8 hard_alpha=true baseline=84 interior_pizza=removed")
