from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
CASES = (
    ("assets/fx/philosopher/eternal-return-field-atlas-pixel-v1.png", 384, 256, 6),
    ("assets/fx/philosopher/revival-chorus-atlas-pixel-v1.png", 256, 256, 6),
)

for rel, cell_w, cell_h, frames in CASES:
    path = ROOT / rel
    image = Image.open(path).convert("RGBA")
    assert image.size == (cell_w * frames, cell_h), (rel, image.size)
    colors = set()
    for frame in range(frames):
        crop = image.crop((frame * cell_w, 0, (frame + 1) * cell_w, cell_h))
        alpha = crop.getchannel("A")
        assert alpha.getbbox(), f"empty frame {frame}: {rel}"
        bbox = alpha.getbbox()
        assert bbox[0] > 0 and bbox[1] > 0 and bbox[2] < cell_w and bbox[3] < cell_h, f"clipped frame {frame}: {rel}"
        colors.update(pixel for pixel in crop.get_flattened_data() if pixel[3])
    assert len(colors) >= 24, f"insufficient material ramp: {rel} ({len(colors)})"
    assert any(0 < color[3] < 255 for color in colors), f"no translucent pixels: {rel}"
    print(f"PHILOSOPHER_FUSION_ASSET_OK {rel} colors={len(colors)}")
