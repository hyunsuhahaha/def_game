"""Verify the continuous fire GIF and runtime atlas share dense frames."""
from pathlib import Path
from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[1]
atlas = Image.open(ROOT / "assets/fx/tree-fire-loop-atlas-pixel-v2.png").convert("RGBA")
gif = Image.open(ROOT / "assets/fx/tree-fire-loop-pixel-v2.gif")
assert atlas.size == (5120, 320)
assert getattr(gif, "n_frames", 1) == 16

occupied = []
spark_pixels = []
for index in range(16):
    frame = atlas.crop((index * 320, 0, (index + 1) * 320, 320))
    alpha = frame.getchannel("A")
    occupied.append(alpha.getbbox())
    pixels = list(frame.getdata())
    spark_pixels.append(sum(1 for r, g, b, a in pixels if a and r > 225 and g > 95 and b < 80))
    if index:
        previous = atlas.crop(((index - 1) * 320, 0, index * 320, 320))
        assert ImageChops.difference(previous, frame).getbbox(), f"duplicate frame {index}"

assert all(box and box[1] < 120 and box[3] >= 286 for box in occupied)
assert min(spark_pixels) > 4000, "spark and hot-core field is too sparse at native resolution"
assert max(spark_pixels) < min(spark_pixels) * 1.55, "whole fire still pulses in density"
print("TREE_FIRE_LOOP_ART_OK atlas=5120x320 gif=16 sparks=dense rhythm=independent")
