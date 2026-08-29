"""Verify the seamless high-cadence regeneration-prism overlay."""
from pathlib import Path

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
ATLAS = ROOT / "assets/enemies/arcade/regrowth-prism-rotation-atlas-v1.png"
GIF = ROOT / "docs/previews/regrowth-prism-v1-motion.gif"


def main():
    assert ATLAS.exists(), "regrowth prism atlas is missing"
    atlas = np.asarray(Image.open(ATLAS).convert("RGBA"))
    assert atlas.shape == (256, 1536, 4), atlas.shape
    assert set(np.unique(atlas[:, :, 3])).issuperset({0, 255})
    for row in range(4):
        frames = [atlas[row * 64:(row + 1) * 64, i * 64:(i + 1) * 64]
                  for i in range(24)]
        assert len({frame.tobytes() for frame in frames}) == 24, f"row {row} lost rotation phases"
        counts = [int(np.count_nonzero(frame[:, :, 3])) for frame in frames]
        assert min(counts) > 150 and max(counts) < 950, f"row {row} silhouette is malformed"

    gif = Image.open(GIF)
    assert getattr(gif, "n_frames", 0) == 24
    assert gif.info.get("duration") == 50, gif.info.get("duration")

    catalog = (ROOT / "src/forest_arcade_catalog.lua").read_text(encoding="utf-8")
    art = (ROOT / "src/forest_arcade_art.lua").read_text(encoding="utf-8")
    for row in range(4):
        assert f"prism=true,prismRow={row}" in catalog
    assert catalog.count("motion=0") >= 5
    assert "regrowth-prism-rotation-atlas-v1.png" in art
    assert "e.planterCasting and 24 or 20" in art
    assert "frame=e.planterCasting and 7 or 1" in art
    assert "math.floor(clock*fps" in art
    assert "prismWidth=42" in catalog and "prismWidth=44" in catalog
    runtime_gif=Image.open(ROOT / "docs/previews/regrowth-totems-v4-runtime-motion.gif")
    assert runtime_gif.n_frames==24 and runtime_gif.info.get("duration")==50
    print("REGROWTH_PRISM_ANIMATION_OK frames=24 rows=4 idle=20fps casting=24fps body=stable")


if __name__ == "__main__":
    main()
