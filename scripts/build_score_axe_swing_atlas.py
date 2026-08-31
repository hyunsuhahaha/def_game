"""Build the six-frame score-mode axe swing atlas from its authored key-pose sheet."""

from collections import deque
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/source/characters/smoker-score-axe-keyposes-imagegen-v1.png"
OUTPUT = ROOT / "assets/characters/ingame/smoker-score-axe-atlas-pixel-v1.png"
FRAME_W, FRAME_H = 96, 192
X_RANGES = ((0, 365), (365, 685), (685, 1030), (1030, 1425), (1425, 1740), (1740, 2051))


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

    box = rgba.getbbox()
    if not box:
        raise RuntimeError("key-pose frame contained no foreground")
    return rgba.crop(box)


def main() -> None:
    source = Image.open(SOURCE)
    atlas = Image.new("RGBA", (FRAME_W * len(X_RANGES), FRAME_H))
    for index, (left, right) in enumerate(X_RANGES):
        pose = extract(source.crop((left, 0, right, source.height)))
        scale = min(92 / pose.width, 188 / pose.height)
        size = (max(1, round(pose.width * scale)), max(1, round(pose.height * scale)))
        pose = pose.resize(size, Image.Resampling.LANCZOS)
        x = index * FRAME_W + (FRAME_W - pose.width) // 2
        y = 190 - pose.height
        atlas.alpha_composite(pose, (x, y))
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(OUTPUT, optimize=True)
    print(OUTPUT.relative_to(ROOT))


if __name__ == "__main__":
    main()
