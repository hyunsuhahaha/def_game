"""Guard the smoke detail that survives the real clearcut camera path."""
from pathlib import Path
import math
import re

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
ART = (ROOT / "src/secondhand_smoke_art.lua").read_text(encoding="utf-8")
PREVIEW = (ROOT / "scripts/render_secondhand_smoke_preview.py").read_text(encoding="utf-8")


match = re.search(r'newImage\("([^"]+secondhand-smoke[^"]+\.png)"\)', ART)
assert match, "runtime secondhand-smoke asset path not found"
asset_path = ROOT / match.group(1)
atlas = Image.open(asset_path).convert("RGBA")

cell_match = re.search(r"CELL_W,CELL_H,FRAMES,COLS=(\d+),(\d+),(\d+),(\d+)", ART)
world_match = re.search(r"WORLD_W,WORLD_H=(\d+),(\d+)", ART)
assert cell_match and world_match, "runtime smoke grid contract is not explicit"
cell_w, cell_h, frames, columns = map(int, cell_match.groups())
world_w, world_h = map(int, world_match.groups())
rows = math.ceil(frames / columns)
assert atlas.size == (cell_w * columns, cell_h * rows) and frames == 6

# The enlarged fog bank needs more than the old 3.2 source texels per world
# unit; otherwise camera downsampling exposes broad, low-detail blocks.
assert cell_w / world_w >= 4.8 and cell_h / world_h >= 4.8, (
    f"runtime smoke density is still {cell_w/world_w:.1f} texels/world-unit"
)

# Measure visible alpha structure after the real opening-stage camera zoom.
# This ignores nominal PNG size and catches a huge smooth blob stored in a
# large file. Each frame must retain local wisps at actual screen scale.
camera_zoom = .84
screen_size = (round(world_w * camera_zoom), round(world_h * camera_zoom))
details = []
for index in range(frames):
    left = (index % columns) * cell_w
    top = (index // columns) * cell_h
    alpha = np.asarray(
        atlas.crop((left, top, left + cell_w, top + cell_h))
        .resize(screen_size, Image.Resampling.NEAREST)
        .getchannel("A"),
        dtype=np.float32,
    ) / 255
    detail = (np.abs(np.diff(alpha, axis=1)).mean() + np.abs(np.diff(alpha, axis=0)).mean())
    details.append(float(detail))
assert min(details) >= .0105, f"screen-scale smoke detail too low: {min(details):.4f}"

# A preview called in-game must reproduce the camera transform and the legal
# three-cloud overlap rather than showing a cleaner one-cloud 1.0x mockup.
assert "CAMERA_ZOOM = .84" in PREVIEW and "OVERLAP_CLOUDS = 3" in PREVIEW, (
    "smoke preview does not reproduce the actual camera/overlap path"
)

print(
    f"SECONDHAND_SMOKE_RUNTIME_FIDELITY_OK density={cell_w/world_w:.1f} "
    f"screen={screen_size[0]}x{screen_size[1]} detail={min(details):.4f} overlap=3"
)
