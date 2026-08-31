from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
source_path = root / "assets/fx/oil-drum-spill/oil-drum-spill-generated-v2-source.png"
out_path = root / "assets/fx/oil-drum-spill/oil-drum-spill-atlas-pixel-v2.png"
source = Image.open(source_path).convert("RGBA")
assert source.size == (1536, 1024)

cell_w, cell_h = 384, 512
out_w, out_h = 256, 200
atlas = Image.new("RGBA", (out_w * 4, out_h * 2))
for index in range(8):
    x, y = (index % 4) * cell_w, (index // 4) * cell_h
    # All frames share one crop so the source and ground anchors never jump.
    frame = source.crop((x, y + 180, x + cell_w, y + 480))
    pixels = frame.load()
    for py in range(frame.height):
        for px in range(frame.width):
            r, g, b, _ = pixels[px, py]
            neutral = max(r, g, b) - min(r, g, b) <= 10
            pixels[px, py] = (r, g, b, 0 if neutral and min(r, g, b) >= 188 else 255)
    frame = frame.resize((out_w, out_h), Image.Resampling.NEAREST)
    atlas.alpha_composite(frame, ((index % 4) * out_w, (index // 4) * out_h))

atlas.save(out_path)
print("OIL_DRUM_SPILL_V2_OK atlas=1024x400 cell=256x200 frames=8 source=oil-only")
