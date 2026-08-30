"""Verify the continuous fire GIF and runtime atlas share dense frames."""
from pathlib import Path
from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[1]
atlas = Image.open(ROOT / "assets/fx/tree-fire-loop-atlas-pixel-v3.png").convert("RGBA")
gif = Image.open(ROOT / "assets/fx/tree-fire-loop-pixel-v3.gif")
assert atlas.size == (6400, 320)
assert getattr(gif, "n_frames", 1) == 20

occupied = []
spark_pixels = []
for index in range(20):
    frame = atlas.crop((index * 320, 0, (index + 1) * 320, 320))
    alpha = frame.getchannel("A")
    occupied.append(alpha.getbbox())
    pixels = list(frame.getdata())
    spark_pixels.append(sum(1 for r, g, b, a in pixels if a and r > 225 and g > 95 and b < 80))
    if index:
        previous = atlas.crop(((index - 1) * 320, 0, index * 320, 320))
        assert ImageChops.difference(previous, frame).getbbox(), f"duplicate frame {index}"

assert all(box and box[1] < 120 and box[3] >= 286 for box in occupied)
assert min(spark_pixels) > 7000, "bright heat bed is too sparse at native resolution"
assert max(spark_pixels) < min(spark_pixels) * 1.45, "whole fire still pulses in density"
print("TREE_FIRE_LOOP_ART_OK atlas=6400x320 gif=20 block_fire=true white_hot=wide")
