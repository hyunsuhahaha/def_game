from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
source = Image.open(root / "assets/fx/oil-drum-spill/oil-drum-spill-generated-v1.png").convert("RGBA")
out = root / "docs/previews"
out.mkdir(parents=True, exist_ok=True)
frames = []
for index in range(8):
    x, y = (index % 4) * 543, (index // 4) * 362
    frame = source.crop((x, y, x + 543, y + 362))
    frame.thumbnail((304, 203), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (304, 203), (0, 0, 0, 0))
    canvas.alpha_composite(frame, ((304 - frame.width) // 2, 203 - frame.height))
    frames.append(canvas)
frames[0].save(out / "oil-drum-spill-runtime-v1.gif", save_all=True, append_images=frames[1:],
               duration=120, loop=0, disposal=2, transparency=0)
print("OIL_DRUM_SPILL_PREVIEW_OK frames=8 duration=120ms window=none")
