from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
asset_dir = root / "assets/fx/oil-drum-spill"
preview_dir = root / "docs/previews"
preview_dir.mkdir(parents=True, exist_ok=True)
CELL_W, CELL_H = 256, 200


def split_frames(path, remove_light_background):
    source = Image.open(path).convert("RGBA")
    frames = []
    for index in range(8):
        left, right = round((index % 4) * source.width / 4), round((index % 4 + 1) * source.width / 4)
        top, bottom = round((index // 4) * source.height / 2), round((index // 4 + 1) * source.height / 2)
        frame = source.crop((left, top, right, bottom)).resize((444, 444), Image.Resampling.NEAREST)
        if remove_light_background:
            pixels = frame.load()
            for y in range(frame.height):
                for x in range(frame.width):
                    r, g, b, _ = pixels[x, y]
                    neutral = max(r, g, b) - min(r, g, b) <= 12
                    pixels[x, y] = (r, g, b, 0 if neutral and min(r, g, b) >= 205 else 255)
        frames.append(frame)
    return frames


def bake(source_name, output_name, preview_name, remove_light_background):
    frames = split_frames(asset_dir / source_name, remove_light_background)
    boxes = [frame.getbbox() for frame in frames]
    union = (
        min(box[0] for box in boxes), min(box[1] for box in boxes),
        max(box[2] for box in boxes), max(box[3] for box in boxes),
    )
    width, height = union[2] - union[0], union[3] - union[1]
    scale = min(230 / width, 174 / height)
    size = (max(1, round(width * scale)), max(1, round(height * scale)))
    atlas = Image.new("RGBA", (CELL_W * 4, CELL_H * 2))
    runtime = []
    for index, frame in enumerate(frames):
        normalized = frame.crop(union).resize(size, Image.Resampling.NEAREST)
        cell = Image.new("RGBA", (CELL_W, CELL_H))
        cell.alpha_composite(normalized, ((CELL_W - size[0]) // 2, 185 - size[1]))
        atlas.alpha_composite(cell, ((index % 4) * CELL_W, (index // 4) * CELL_H))
        runtime.append(cell)
    atlas.save(asset_dir / output_name)
    runtime[0].save(preview_dir / preview_name, save_all=True, append_images=runtime[1:],
                    duration=120, loop=0, disposal=2, transparency=0)


def extract_fire_overlay(source_name, output_name, preview_name):
    """Strip the baked oil floor from the flame sheet.

    Runtime composes these flame-only cells over a separately scaled puddle,
    so larger oil-radius upgrades never require a new combined animation.
    """
    atlas = Image.open(asset_dir / source_name).convert("RGBA")
    pixels = atlas.load()
    for y in range(atlas.height):
        for x in range(atlas.width):
            r, g, b, a = pixels[x, y]
            hot_core = r >= 205 and g >= 105
            hot_edge = r >= 110 and r >= g * 1.08 and b <= 125
            pixels[x, y] = (r, g, b, a if hot_core or hot_edge else 0)
    atlas.save(asset_dir / output_name)
    frames = []
    for index in range(8):
        x, y = (index % 4) * CELL_W, (index // 4) * CELL_H
        frames.append(atlas.crop((x, y, x + CELL_W, y + CELL_H)))
    frames[0].save(preview_dir / preview_name, save_all=True, append_images=frames[1:],
                   duration=120, loop=0, disposal=2, transparency=0)


bake("oil-puddle-generated-v1-source.png", "oil-puddle-atlas-pixel-v1.png",
     "oil-puddle-runtime-v1.gif", True)
bake("burning-oil-generated-v1-source.png", "burning-oil-atlas-pixel-v1.png",
     "burning-oil-runtime-v1.gif", False)
extract_fire_overlay("burning-oil-atlas-pixel-v1.png", "oil-fire-overlay-atlas-pixel-v1.png",
                     "oil-fire-overlay-runtime-v1.gif")
print("OIL_PUDDLE_FIRE_OK ground=1024x400 overlay=1024x400 cell=256x200 frames=8 previews=3")
