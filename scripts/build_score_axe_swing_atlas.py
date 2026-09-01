"""Build the six-frame score-mode axe swing atlas from its authored key-pose sheet."""

from collections import deque
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/source/characters/smoker-score-axe-keyposes-imagegen-v3.png"
OUTPUT = ROOT / "assets/characters/ingame/smoker-score-axe-atlas-pixel-v4.png"
FRAME_W, FRAME_H = 224, 224
# The generated sixth recovery pose touches the source edge. Reuse the complete
# first guard pose to close the swing loop without shipping a cropped blade.
X_RANGES = ((0, 390), (390, 725), (700, 1160), (1030, 1500), (1430, 1800), (0, 390))


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

    # The longer forward swings overlap neighbouring pose columns in the source
    # sheet. Keep the largest connected subject so an adjacent arm or axe head
    # cannot leak into this frame.
    alpha = rgba.getchannel("A")
    solid = alpha.load()
    seen = bytearray(width * height)
    largest: list[int] = []
    for sy in range(height):
        for sx in range(width):
            start = sy * width + sx
            if seen[start] or solid[sx, sy] == 0:
                continue
            seen[start] = 1
            component: list[int] = []
            pending = deque([(sx, sy)])
            while pending:
                x, y = pending.popleft()
                component.append(y * width + x)
                for ny in range(max(0, y - 1), min(height, y + 2)):
                    for nx in range(max(0, x - 1), min(width, x + 2)):
                        index = ny * width + nx
                        if not seen[index] and solid[nx, ny] > 0:
                            seen[index] = 1
                            pending.append((nx, ny))
            if len(component) > len(largest):
                largest = component
    keep = bytearray(width * height)
    for index in largest:
        keep[index] = 1
    for y in range(height):
        for x in range(width):
            if not keep[y * width + x]:
                data[x, y] = (0, 0, 0, 0)

    box = rgba.getbbox()
    if not box:
        raise RuntimeError("key-pose frame contained no foreground")
    return rgba.crop(box)


def main() -> None:
    source = Image.open(SOURCE)
    poses = [extract(source.crop((left, 0, right, source.height))) for left, right in X_RANGES]
    scale = min(188 / poses[0].width, 188 / poses[0].height)
    atlas = Image.new("RGBA", (FRAME_W * len(X_RANGES), FRAME_H))
    for index, pose in enumerate(poses):
        size = (max(1, round(pose.width * scale)), max(1, round(pose.height * scale)))
        pose = pose.resize(size, Image.Resampling.LANCZOS)
        pose.putalpha(pose.getchannel("A").point(lambda alpha: 255 if alpha >= 128 else 0))
        x = index * FRAME_W + (FRAME_W - pose.width) // 2
        y = 222 - pose.height
        atlas.alpha_composite(pose, (x, y))
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(OUTPUT, optimize=True)
    print(OUTPUT.relative_to(ROOT))


if __name__ == "__main__":
    main()
