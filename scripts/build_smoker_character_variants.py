"""Bake coherent smoker-compatible character and axe sheets onto the native grid."""

from collections import deque
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/source/characters"
OUTPUT = ROOT / "assets/characters/ingame"
FRAME_W, FRAME_H = 96, 192

CHARACTERS = {
    "scrapyard-welder": (
        SOURCE / "scrapyard-welder-sheet-imagegen-v1.png",
        SOURCE / "scrapyard-welder-axe-sheet-imagegen-v1.png",
    ),
    "night-shopkeeper": (
        SOURCE / "night-shopkeeper-sheet-imagegen-v1.png",
        SOURCE / "night-shopkeeper-axe-sheet-imagegen-v1.png",
    ),
}


def background_candidate(pixel: tuple[int, int, int]) -> bool:
    low, high = min(pixel), max(pixel)
    return low >= 224 and high - low <= 14


def extract(frame: Image.Image) -> Image.Image:
    rgb = frame.convert("RGB")
    width, height = rgb.size
    pixels = rgb.load()
    outside = bytearray(width * height)
    queue: deque[tuple[int, int]] = deque()

    def seed(x: int, y: int) -> None:
        index = y * width + x
        if not outside[index] and background_candidate(pixels[x, y]):
            outside[index] = 1
            queue.append((x, y))

    for x in range(width):
        seed(x, 0)
        seed(x, height - 1)
    for y in range(height):
        seed(0, y)
        seed(width - 1, y)

    while queue:
        x, y = queue.popleft()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < width and 0 <= ny < height:
                index = ny * width + nx
                if not outside[index] and background_candidate(pixels[nx, ny]):
                    outside[index] = 1
                    queue.append((nx, ny))

    rgba = rgb.convert("RGBA")
    data = rgba.load()
    for y in range(height):
        row = y * width
        for x in range(width):
            if outside[row + x]:
                data[x, y] = (0, 0, 0, 0)
    rgba = remove_small_components(rgba)
    box = rgba.getbbox()
    if not box:
        raise RuntimeError("generated frame contained no character pixels")
    return rgba.crop(box)


def remove_small_components(image: Image.Image) -> Image.Image:
    """Discard checker-cleanup crumbs and neighboring-frame slivers."""
    width, height = image.size
    alpha = image.getchannel("A")
    seen = bytearray(width * height)
    components: list[list[tuple[int, int]]] = []
    for y in range(height):
        for x in range(width):
            index = y * width + x
            if seen[index] or alpha.getpixel((x, y)) == 0:
                continue
            seen[index] = 1
            queue = deque([(x, y)])
            component: list[tuple[int, int]] = []
            while queue:
                px, py = queue.popleft()
                component.append((px, py))
                for nx in range(px - 1, px + 2):
                    for ny in range(py - 1, py + 2):
                        if not (0 <= nx < width and 0 <= ny < height):
                            continue
                        neighbor = ny * width + nx
                        if not seen[neighbor] and alpha.getpixel((nx, ny)):
                            seen[neighbor] = 1
                            queue.append((nx, ny))
            components.append(component)
    largest_component = max(components, key=len, default=[])
    keep = set(largest_component)
    result = image.copy()
    pixels = result.load()
    for y in range(height):
        for x in range(width):
            if alpha.getpixel((x, y)) and (x, y) not in keep:
                pixels[x, y] = (0, 0, 0, 0)
    return result


def quantize_rgba(image: Image.Image, colors: int = 110) -> Image.Image:
    alpha = image.getchannel("A").point(lambda value: 255 if value >= 96 else 0)
    flat = Image.new("RGB", image.size, (0, 0, 0))
    flat.paste(image.convert("RGB"), mask=alpha)
    result = flat.quantize(colors=colors, method=Image.Quantize.MEDIANCUT,
                           dither=Image.Dither.NONE).convert("RGBA")
    result.putalpha(alpha)
    return result


def bake(source_path: Path, rows: int, output_path: Path) -> None:
    source = Image.open(source_path)
    atlas = Image.new("RGBA", (FRAME_W * 6, FRAME_H * rows))
    for row in range(rows):
        top = round(source.height * row / rows)
        bottom = round(source.height * (row + 1) / rows)
        for column in range(6):
            left = round(source.width * column / 6)
            right = round(source.width * (column + 1) / 6)
            pose = extract(source.crop((left, top, right, bottom)))
            scale = min(92 / pose.width, 188 / pose.height)
            size = (max(1, round(pose.width * scale)), max(1, round(pose.height * scale)))
            pose = pose.resize(size, Image.Resampling.LANCZOS)
            pose = remove_small_components(pose)
            x = column * FRAME_W + (FRAME_W - pose.width) // 2
            y = row * FRAME_H + 190 - pose.height
            atlas.alpha_composite(pose, (x, y))
    quantize_rgba(atlas).save(output_path, optimize=True)


def remove_baked_cigarettes() -> None:
    source = Image.open(OUTPUT / "smoker-atlas-pixel-v2.png").convert("RGBA")
    result = source.copy()
    pixels = result.load()
    anchors = (
        ((68, 29), 1), ((73, 29), 1), ((68, 42), 1),
        ((74, 29), 1), ((75, 36), 1), ((73, 29), 1),
        ((34, 30), -1), ((34, 30), -1), ((31, 29), -1),
        ((35, 32), -1), ((65, 32), 1), ((66, 31), 1),
    )
    prop_colors = {
        (235, 224, 195), (229, 217, 206), (254, 250, 241),
        (179, 199, 179), (179, 164, 160), (168, 153, 148),
        (156, 146, 144), (180, 163, 152), (95, 92, 95),
        (181, 117, 49), (255, 92, 24), (255, 183, 55),
        (237, 153, 16), (227, 96, 33), (233, 35, 22),
        (245, 211, 116), (245, 229, 213),
    }
    for index, ((anchor_x, anchor_y), facing) in enumerate(anchors):
        cell_x = (index % 6) * FRAME_W
        cell_y = (index // 6) * FRAME_H
        x_start = anchor_x - 14 if facing < 0 else anchor_x
        x_end = anchor_x + 4 if facing < 0 else anchor_x + 14
        for y in range(max(0, anchor_y - 6), min(FRAME_H, anchor_y + 7)):
            for x in range(max(0, x_start), min(FRAME_W, x_end + 1)):
                if pixels[cell_x + x, cell_y + y][:3] in prop_colors:
                    pixels[cell_x + x, cell_y + y] = (0, 0, 0, 0)
    # Release and pre-flick frames contain detached authored cigarette pixels
    # far from the mouth anchor. They are isolated from the hand silhouette.
    for column, box in ((3, (5, 99, 16, 112)), (4, (75, 52, 91, 71))):
        left, top, right, bottom = box
        for y in range(top, bottom):
            for x in range(left, right):
                pixels[column * FRAME_W + x, FRAME_H + y] = (0, 0, 0, 0)
    result.save(OUTPUT / "smoker-atlas-pixel-v3.png", optimize=True)


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    remove_baked_cigarettes()
    for name, (body_source, axe_source) in CHARACTERS.items():
        bake(body_source, 2, OUTPUT / f"{name}-atlas-pixel-v1.png")
        bake(axe_source, 1, OUTPUT / f"{name}-score-axe-atlas-pixel-v1.png")
    print("SMOKER_CHARACTER_VARIANTS_BUILT original-clean + 2 characters x body/axe")


if __name__ == "__main__":
    main()
