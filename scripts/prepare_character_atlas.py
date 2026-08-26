"""Remove only edge-connected neutral checkerboard pixels from generated atlases.

The source draft is preserved. This script also prints per-cell alpha bounds so
the runtime can use a stable foot baseline without visually launching LÖVE.
"""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image


def looks_like_checker(pixel: tuple[int, int, int, int]) -> bool:
    red, green, blue, alpha = pixel
    return alpha > 0 and min(red, green, blue) >= 215 and max(red, green, blue) - min(red, green, blue) <= 16


def remove_edge_checker(image: Image.Image) -> int:
    pixels = image.load()
    width, height = image.size
    queue: deque[tuple[int, int]] = deque()
    seen: set[tuple[int, int]] = set()

    for x in range(width):
        queue.append((x, 0))
        queue.append((x, height - 1))
    for y in range(height):
        queue.append((0, y))
        queue.append((width - 1, y))

    while queue:
        x, y = queue.popleft()
        if (x, y) in seen or not looks_like_checker(pixels[x, y]):
            continue
        seen.add((x, y))
        if x > 0:
            queue.append((x - 1, y))
        if x + 1 < width:
            queue.append((x + 1, y))
        if y > 0:
            queue.append((x, y - 1))
        if y + 1 < height:
            queue.append((x, y + 1))

    for x, y in seen:
        red, green, blue, _ = pixels[x, y]
        pixels[x, y] = red, green, blue, 0
    return len(seen)


def remove_edge_smooth_background(image: Image.Image, threshold: int = 18) -> int:
    """Flood through smooth background without crossing detailed sprite outlines."""
    array = np.asarray(image).copy()
    rgb = array[:, :, :3].astype(np.int16)
    gradient = np.zeros(rgb.shape[:2], dtype=np.int16)
    gradient[:, 1:] = np.maximum(gradient[:, 1:], np.max(np.abs(rgb[:, 1:] - rgb[:, :-1]), axis=2))
    gradient[:, :-1] = np.maximum(gradient[:, :-1], np.max(np.abs(rgb[:, 1:] - rgb[:, :-1]), axis=2))
    gradient[1:, :] = np.maximum(gradient[1:, :], np.max(np.abs(rgb[1:, :] - rgb[:-1, :]), axis=2))
    gradient[:-1, :] = np.maximum(gradient[:-1, :], np.max(np.abs(rgb[1:, :] - rgb[:-1, :]), axis=2))
    eligible = gradient <= threshold
    height, width = eligible.shape
    background = np.zeros_like(eligible)

    for row in range(2):
        for column in range(6):
            x0, y0 = column * (width // 6), row * (height // 2)
            x1, y1 = (column + 1) * (width // 6), (row + 1) * (height // 2)
            queue: deque[tuple[int, int]] = deque()
            for x in range(x0, x1):
                queue.append((x, y0)); queue.append((x, y1 - 1))
            for y in range(y0, y1):
                queue.append((x0, y)); queue.append((x1 - 1, y))
            while queue:
                x, y = queue.popleft()
                if x < x0 or x >= x1 or y < y0 or y >= y1 or background[y, x] or not eligible[y, x]:
                    continue
                background[y, x] = True
                queue.append((x - 1, y)); queue.append((x + 1, y))
                queue.append((x, y - 1)); queue.append((x, y + 1))

    array[background, 3] = 0
    image.paste(Image.fromarray(array, "RGBA"))
    return int(background.sum())


def remove_chroma_green(image: Image.Image) -> int:
    array = np.asarray(image).copy()
    red, green, blue = array[:, :, 0], array[:, :, 1], array[:, :, 2]
    chroma = (green >= 100) & (green.astype(np.int16) - red.astype(np.int16) >= 35) & (green.astype(np.int16) - blue.astype(np.int16) >= 35)
    array[chroma, :3] = 0
    array[chroma, 3] = 0
    image.paste(Image.fromarray(array, "RGBA"))
    return int(chroma.sum())


def repack_connected_sprites(image: Image.Image) -> int:
    """Center the twelve largest disconnected sprites into strict 256x512 cells."""
    array = np.asarray(image).copy()
    foreground = array[:, :, 3] > 0
    height, width = foreground.shape
    seen = np.zeros_like(foreground)
    components: list[list[tuple[int, int]]] = []
    for y in range(height):
        for x in range(width):
            if not foreground[y, x] or seen[y, x]:
                continue
            stack, points = [(x, y)], []
            seen[y, x] = True
            while stack:
                px, py = stack.pop()
                points.append((px, py))
                for nx, ny in ((px - 1, py), (px + 1, py), (px, py - 1), (px, py + 1)):
                    if 0 <= nx < width and 0 <= ny < height and foreground[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        stack.append((nx, ny))
            if len(points) >= 10_000:
                components.append(points)

    slots: dict[int, list[tuple[int, int]]] = {}
    for points in components:
        cx = sum(point[0] for point in points) / len(points)
        cy = sum(point[1] for point in points) / len(points)
        column = max(0, min(5, int(cx // 256)))
        row = max(0, min(1, int(cy // 512)))
        slot = row * 6 + column
        if slot not in slots or len(points) > len(slots[slot]):
            slots[slot] = points

    output = Image.new("RGBA", image.size, (0, 0, 0, 0))
    for slot in range(12):
        points = slots.get(slot)
        if not points:
            continue
        xs, ys = [point[0] for point in points], [point[1] for point in points]
        left, top, right, bottom = min(xs), min(ys), max(xs) + 1, max(ys) + 1
        mask = Image.new("L", (right - left, bottom - top), 0)
        mask_pixels = mask.load()
        for x, y in points:
            mask_pixels[x - left, y - top] = int(array[y, x, 3])
        sprite = image.crop((left, top, right, bottom))
        sprite.putalpha(mask)
        scale = min(1.0, 244 / sprite.width, 500 / sprite.height)
        if scale < 1:
            sprite = sprite.resize((round(sprite.width * scale), round(sprite.height * scale)), Image.Resampling.NEAREST)
        column, row = slot % 6, slot // 6
        x = column * 256 + (256 - sprite.width) // 2
        y = row * 512 + 506 - sprite.height
        output.alpha_composite(sprite, (x, y))
    image.paste(output)
    return len(slots)


def alpha_bounds(image: Image.Image, columns: int = 6, rows: int = 2) -> list[tuple[int, int, int, int] | None]:
    cell_width, cell_height = image.width // columns, image.height // rows
    alpha = image.getchannel("A")
    bounds = []
    for row in range(rows):
        for column in range(columns):
            crop = alpha.crop((column * cell_width, row * cell_height, (column + 1) * cell_width, (row + 1) * cell_height))
            bounds.append(crop.getbbox())
    return bounds


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("--clean-checker", action="store_true")
    parser.add_argument("--clean-smooth", action="store_true")
    parser.add_argument("--clean-green", action="store_true")
    parser.add_argument("--repack", action="store_true")
    args = parser.parse_args()

    image = Image.open(args.source).convert("RGBA")
    if image.size != (1536, 1024):
        raise SystemExit(f"unexpected atlas size: {image.size}")
    removed = remove_edge_checker(image) if args.clean_checker else 0
    if args.clean_smooth:
        removed += remove_edge_smooth_background(image)
    if args.clean_green:
        removed += remove_chroma_green(image)
    if args.repack:
        removed += repack_connected_sprites(image)
    args.destination.parent.mkdir(parents=True, exist_ok=True)
    image.save(args.destination)
    print(f"saved={args.destination} removed={removed}")
    for index, bounds in enumerate(alpha_bounds(image), start=1):
        print(f"cell={index:02d} bounds={bounds}")


if __name__ == "__main__":
    main()
