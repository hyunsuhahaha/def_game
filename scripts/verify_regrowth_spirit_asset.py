"""Verify the authored Regrowth Spirit model and its deterministic GPU atlas."""
from pathlib import Path
import json

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
MODEL = ROOT / "assets/enemies/concepts/regrowth-spirit-model-v1.png"
ATLAS = ROOT / "assets/enemies/arcade/planter-atlas-v1.png"
REPORT = ROOT / "docs/previews/regrowth-spirit-v1-build.json"


def main():
    assert MODEL.exists(), "fixed ImageGen model is missing"
    assert ATLAS.exists(), "runtime planter atlas is missing"
    atlas = Image.open(ATLAS).convert("RGBA")
    assert atlas.size == (960, 320), atlas.size
    pixels = np.asarray(atlas)
    alpha = set(np.unique(pixels[:, :, 3]).tolist())
    assert alpha == {0, 255}, f"non-binary alpha: {alpha}"
    opaque = pixels[pixels[:, :, 3] == 255, :3]
    colors = len({tuple(pixel) for pixel in opaque})
    assert colors >= 100, f"material palette collapsed to {colors} colors"
    frames = [pixels[row * 160:(row + 1) * 160, col * 160:(col + 1) * 160]
              for row in range(2) for col in range(6)]
    assert len({frame.tobytes() for frame in frames[:6]}) == 6, "idle row lost motion"
    assert len({frame.tobytes() for frame in frames[6:]}) >= 3, "casting row is visually static"
    assert len({frame.tobytes() for frame in frames}) >= 9, "atlas has too little pose variation"
    data = json.loads(REPORT.read_text(encoding="utf-8"))
    assert data["frames"] == 12 and data["colors"] == colors
    catalog = (ROOT / "src/forest_arcade_catalog.lua").read_text(encoding="utf-8")
    assert 'planter-atlas-v1.png' in catalog and "Placeholder art" not in catalog
    runtime = (ROOT / "src/clearcut_mode.lua").read_text(encoding="utf-8")
    assert "e.planterCasting" in runtime and 'e.kind == "planter"' in runtime
    print(f"REGROWTH_SPIRIT_ASSET_OK size={atlas.width}x{atlas.height} frames=12 colors={colors} alpha=binary")


if __name__ == "__main__":
    main()
