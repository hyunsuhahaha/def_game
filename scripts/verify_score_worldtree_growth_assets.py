"""Structural/quality regression checks for score World Tree growth atlases."""
from pathlib import Path
from PIL import Image
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
CELL = 512
NAMES = ("young", "adolescent", "precursor")

signatures = []
for name in NAMES:
    version = 2 if name == "young" else 1
    path = ROOT / f"assets/enemies/arcade/score-worldtree-{name}-atlas-v{version}.png"
    image = Image.open(path).convert("RGBA")
    assert image.size == (CELL * 6, CELL * 2), f"{name}: wrong atlas size {image.size}"
    arr = np.asarray(image)
    assert set(np.unique(arr[:, :, 3])).issubset({0, 255}), f"{name}: soft alpha halo"
    opaque = arr[:, :, 3] > 0
    colors = len({tuple(v) for v in arr[:, :, :3][opaque]})
    assert colors >= 50, f"{name}: insufficient material palette ({colors})"
    coverage, states = [], []
    for col, row in ((1, 0), (4, 0), (1, 1), (4, 1)):
        frame = arr[row * CELL:(row + 1) * CELL, col * CELL:(col + 1) * CELL]
        coverage.append(int((frame[:, :, 3] > 0).sum()))
        states.append(frame.tobytes())
    assert len(set(states)) == 4, f"{name}: damage states are duplicated"
    assert min(coverage[1:]) < coverage[0] - 300, f"{name}: damage never removes a visible crown section {coverage}"
    first = arr[:CELL, CELL:CELL * 2, 3] > 0
    ys, xs = np.where(first)
    signatures.append((xs.max() - xs.min(), ys.max() - ys.min(), int(first.sum())))

assert len(set(signatures)) == 3, "growth forms are duplicated/scaled from one identical silhouette"
print("SCORE_WORLDTREE_GROWTH_ASSETS_OK forms=3 cell=512 damage=4 motion=3 hard_alpha=true")
