"""Verify the authored mystical Regrowth Sanctum and its deterministic atlases."""
from pathlib import Path
import json

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
MODEL = ROOT / "assets/enemies/concepts/regrowth-sanctum-model-v2.png"
ATLAS = ROOT / "assets/enemies/arcade/planter-forest-atlas-v3.png"
REPORT = ROOT / "docs/previews/regrowth-totems-v3-build.json"
CAST_FX = ROOT / "assets/fx/regrowth-cast-atlas-v3.png"


def main():
    assert MODEL.exists(), "fixed ImageGen model is missing"
    assert ATLAS.exists(), "runtime planter atlas is missing"
    atlas = Image.open(ATLAS).convert("RGBA")
    assert atlas.size == (1536, 512), atlas.size
    pixels = np.asarray(atlas)
    alpha = set(np.unique(pixels[:, :, 3]).tolist())
    assert alpha == {0, 255}, f"non-binary alpha: {alpha}"
    opaque = pixels[pixels[:, :, 3] == 255, :3]
    colors = len({tuple(pixel) for pixel in opaque})
    assert colors >= 100, f"material palette collapsed to {colors} colors"
    frames = [pixels[row * 256:(row + 1) * 256, col * 256:(col + 1) * 256]
              for row in range(2) for col in range(6)]
    assert len({frame.tobytes() for frame in frames[:6]}) == 6, "idle row lost motion"
    assert len({frame.tobytes() for frame in frames[6:]}) >= 3, "casting row is visually static"
    assert len({frame.tobytes() for frame in frames}) >= 9, "atlas has too little pose variation"
    data = json.loads(REPORT.read_text(encoding="utf-8"))
    assert data["forest"]["frames"] == 12 and data["forest"]["worldWidth"] == 68
    for name,width in {"forest":68,"mangrove":70,"madagascar":72,"island":74}.items():
        path=ROOT/data[name]["file"]
        assert path.exists() and Image.open(path).size==(1536,512)
        assert data[name]["worldWidth"]==width and data[name]["bodyWidth"]<=190
    catalog = (ROOT / "src/forest_arcade_catalog.lua").read_text(encoding="utf-8")
    assert 'planter-forest-atlas-v3.png' in catalog and 'planter-island-atlas-v3.png' in catalog and 'cell=256' in catalog and "Placeholder art" not in catalog
    runtime = (ROOT / "src/clearcut_mode.lua").read_text(encoding="utf-8")
    assert "e.planterCasting" in runtime and 'e.kind == "planter"' in runtime
    cast = np.asarray(Image.open(CAST_FX).convert("RGBA"))
    assert cast.shape == (256, 1536, 4)
    assert set(np.unique(cast[:, :, 3]).tolist()) == {0, 190, 210, 255}
    cast_colors = len({tuple(pixel[:3]) for pixel in cast.reshape(-1, 4) if pixel[3]})
    assert 72 <= cast_colors <= 128
    assert len({cast[:, i*256:(i+1)*256].tobytes() for i in range(6)}) == 6
    cast_runtime = (ROOT / "src/regrowth_cast_art.lua").read_text(encoding="utf-8")
    assert "regrowth-cast-atlas-v3.png" in cast_runtime and "love.graphics.circle" not in cast_runtime
    planter_block = runtime[runtime.index('e.kind == "planter"'):runtime.index("ForestArt.drawHealth")]
    assert "RegrowthCastArt.draw(e)" in planter_block and "love.graphics.polygon" not in planter_block
    print(f"REGROWTH_SANCTUM_ASSET_OK body={atlas.width}x{atlas.height}/12 cast=1536x256/6 colors={cast_colors} structure=true mystical=true")


if __name__ == "__main__":
    main()
