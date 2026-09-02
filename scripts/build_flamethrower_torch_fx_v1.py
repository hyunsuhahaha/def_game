"""Bake the optional translucent-red torch stream and tree-contact impact."""
from pathlib import Path
import math

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / "assets" / "effects"
PREVIEW = ROOT / "docs" / "previews"
FRAMES = 8
STREAM_SIZE = (1536, 768)
IMPACT_SIZE = (256, 256)
STREAM_SOURCE = ASSET / "smoker-torch-stream-source-chroma-v1.png"
IMPACT_SOURCE = ASSET / "smoker-torch-impact-source-chroma-v1.png"
TORCH_PALETTE = (
    (78, 8, 18, 72), (112, 10, 20, 96), (152, 12, 18, 120),
    (194, 18, 14, 148), (226, 32, 8, 176), (246, 58, 5, 204),
    (255, 96, 7, 224), (255, 146, 16, 236), (255, 205, 46, 244),
    (255, 239, 156, 250), (255, 252, 224, 255),
)
ALPHA_STEPS = tuple(sorted({0, *(color[3] for color in TORCH_PALETTE)}))


def chroma_cutout(path, crop=None):
    source = Image.open(path).convert("RGB")
    if crop:
        source = source.crop(crop)
    out = Image.new("RGBA", source.size)
    pixels, result = source.load(), out.load()
    for y in range(source.height):
        for x in range(source.width):
            r, g, b = pixels[x, y]
            if not (b > 90 and b > r * 1.13 and b > g * 1.13):
                result[x, y] = (r, g, min(b, int(r * .22)), 255)
    return out.crop(out.getbbox())


def pixelize(source, size, padding):
    width, height = size
    target_w, target_h = width - padding * 2, height - padding * 2
    source = source.resize((target_w // 2, target_h // 2), Image.Resampling.LANCZOS)
    data = []
    for r, g, b, a in source.get_flattened_data():
        if a < 80:
            data.append((0, 0, 0, 0));continue
        color = min(TORCH_PALETTE, key=lambda value:
            (r-value[0])**2 + (g-value[1])**2 + (b-value[2])**2)
        data.append(color)
    source.putdata(data)
    source = source.resize((target_w, target_h), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", size)
    canvas.alpha_composite(source, (padding, padding))
    return canvas


def animate(master, frame, root_width=0):
    """Advect scanlines and burn low-alpha edges into new topology."""
    phase = frame * math.tau / FRAMES
    shifted = Image.new("RGBA", master.size)
    for y in range(master.height):
        offset = round(math.sin(y / 31 + phase) * 7 + math.sin(y / 13 - phase * 1.7) * 3)
        row = master.crop((0, y, master.width, y + 1))
        shifted.alpha_composite(row, (offset, y))
    pixels = shifted.load()
    for y in range(0, shifted.height, 2):
        for x in range(0, shifted.width, 2):
            r, g, b, a = pixels[x, y]
            if not a:
                continue
            flutter = math.sin(x / 47 + y / 29 + phase * 2.1) + math.sin(x / 19 - y / 23 - phase)
            if a <= 176:
                a = max(0, min(176, round(a + flutter * 34)))
                if a < 54:
                    a = 0
            a = min(ALPHA_STEPS, key=lambda value: abs(value - a))
            for py in (y, min(y + 1, shifted.height - 1)):
                for px in (x, min(x + 1, shifted.width - 1)):
                    pr, pg, pb, _ = pixels[px, py]
                    pixels[px, py] = (pr, pg, pb, a)
    if root_width:
        shifted.alpha_composite(master.crop((0, 0, root_width, master.height)), (0, 0))
    return shifted


stream_master = pixelize(chroma_cutout(STREAM_SOURCE), STREAM_SIZE, 28)
# Remove most of the generated incoming beam; the runtime stream already reaches
# the tree. The impact begins at its compression point and wraps the trunk.
impact_source = Image.open(IMPACT_SOURCE)
impact_crop = (430, 40, 1220, 1220)
impact_master = pixelize(chroma_cutout(IMPACT_SOURCE, impact_crop), IMPACT_SIZE, 8)
stream_frames = [animate(stream_master, frame, 170) for frame in range(FRAMES)]
impact_frames = [animate(impact_master, frame) for frame in range(FRAMES)]


def save_animation(frames, atlas_path, gif_path, columns):
    cell_w, cell_h = frames[0].size
    rows = math.ceil(len(frames) / columns)
    atlas = Image.new("RGBA", (cell_w * columns, cell_h * rows))
    for index, frame in enumerate(frames):
        atlas.alpha_composite(frame, ((index % columns) * cell_w, (index // columns) * cell_h))
    atlas.save(atlas_path, optimize=True)
    frames[0].save(gif_path, save_all=True, append_images=frames[1:], duration=62,
        loop=0, disposal=2, optimize=False)
    return atlas


ASSET.mkdir(parents=True, exist_ok=True);PREVIEW.mkdir(parents=True, exist_ok=True)
stream_atlas = save_animation(stream_frames,
    ASSET / "smoker-flamethrower-torch-atlas-v1.png",
    ASSET / "smoker-flamethrower-torch-v1.gif", 4)
impact_atlas = save_animation(impact_frames,
    ASSET / "smoker-flamethrower-torch-impact-atlas-v1.png",
    ASSET / "smoker-flamethrower-torch-impact-v1.gif", 4)

board = Image.new("RGB", (1280, 720), (26, 48, 31))
for index, frame in enumerate(stream_frames):
    thumb = frame.resize((300, 150), Image.Resampling.NEAREST)
    board.paste(thumb, ((index % 4) * 320 + 10, (index // 4) * 170 + 8), thumb)
for index, frame in enumerate(impact_frames[:4]):
    zoom = frame.resize((256, 256), Image.Resampling.NEAREST)
    board.paste(zoom, (index * 320 + 32, 430), zoom)
board.save(PREVIEW / "flamethrower-torch-v1-pixel-board.png")
print("FLAMETHROWER_TORCH_V1_BUILT stream=1536x768x8 impact=256x256x8 alpha=stepped")
