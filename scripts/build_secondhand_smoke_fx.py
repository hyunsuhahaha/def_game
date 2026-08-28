"""Build the smoker fusion's authored-grid mist atlas.

The effect is calculated directly on its final pixel grid. It deliberately
uses stepped colour/alpha ramps and ordered dithering: no blurred circles, no
upscaled low-resolution puffs, and no generated-image source enters runtime.
"""
from pathlib import Path

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
CELL_W, CELL_H, FRAMES = 2048, 1280, 6
ATLAS_COLS, ATLAS_ROWS = 3, 2
OUT = ROOT / "assets/fx/secondhand-smoke/secondhand-smoke-mist-atlas-pixel-v2.png"


def _hash(ix, iy, seed):
    value = np.sin(ix * 127.1 + iy * 311.7 + seed * 74.7) * 43758.5453
    return value - np.floor(value)


def _noise(x, y, scale, seed):
    gx, gy = x * scale, y * scale
    ix, iy = np.floor(gx), np.floor(gy)
    fx, fy = gx - ix, gy - iy
    fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    a = _hash(ix, iy, seed)
    b = _hash(ix + 1, iy, seed)
    c = _hash(ix, iy + 1, seed)
    d = _hash(ix + 1, iy + 1, seed)
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def frame(index):
    yy, xx = np.mgrid[0:CELL_H, 0:CELL_W]
    x = (xx + .5) / CELL_W * 2 - 1
    y = (yy + .5) / CELL_H * 2 - 1
    phase = index / FRAMES

    # Three coherent noise bands drift at different rates. They break the
    # boundary into wisps without making random decorative speckles.
    n1 = _noise(x + phase * .31, y - phase * .12, 2.8, 11)
    n2 = _noise(x - phase * .18, y + phase * .22, 5.4, 23)
    n3 = _noise(x + phase * .09, y + phase * .08, 10.5, 37)
    flow = .52 * n1 + .31 * n2 + .17 * n3

    center = .07 * np.sin(x * 5.2 + phase * np.pi * 2) + .035 * np.sin(x * 11 - phase * 4)
    thickness = .52 + .09 * np.sin(x * 3.1 - phase * 5) + (n1 - .5) * .14
    vertical = 1 - np.abs(y - center) / np.maximum(.24, thickness)
    horizontal = 1 - np.abs(x + .04 * np.sin(y * 8 + phase * 6)) ** 3.2
    envelope = np.clip(vertical, 0, 1) * np.clip(horizontal, 0, 1)

    # Low layered fog with a few curved internal currents. The currents remain
    # translucent; they describe motion rather than becoming white ribbons.
    current_a = np.exp(-((y - center - .12 * np.sin(x * 4.2 + phase * 6.28)) / .10) ** 2)
    current_b = np.exp(-((y - center + .16 * np.sin(x * 3.3 - phase * 5.1)) / .13) ** 2)
    density = envelope * (.16 + .54 * flow + .10 * current_a + .07 * current_b)
    density -= envelope * np.clip((.44 - n2) * .42, 0, .16)

    # Sparse tapered wisps at the perimeter. They are connected to the fog
    # field, not independent round particles.
    edge_wisps = np.clip(envelope * (n3 - .53) * 1.7, 0, .22)
    density = np.clip(density + edge_wisps, 0, 1)

    bayer = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]], dtype=float) / 16
    dither = bayer[yy % 4, xx % 4] - .5
    stepped = np.floor(np.clip(density + dither / 22, 0, 1) * 8) / 8
    alpha_levels = np.array([0, 45, 70, 95, 120, 145, 170, 195, 215], dtype=np.uint8)
    alpha = alpha_levels[np.clip(np.rint(stepped * 8).astype(int), 0, 8)]
    alpha[density < .115] = 0

    shade = np.clip(np.rint((.58 * stepped + .42 * n2) * 6).astype(int), 0, 6)
    palette = np.array([
        [122, 130, 132], [138, 146, 148], [153, 161, 161], [168, 176, 174],
        [184, 191, 187], [203, 208, 201], [222, 225, 216],
    ], dtype=np.uint8)
    rgb = palette[shade]
    rgba = np.dstack((rgb, alpha)).astype(np.uint8)
    rgba[alpha == 0, :3] = 0
    return Image.fromarray(rgba, "RGBA")


def main():
    OUT.parent.mkdir(parents=True, exist_ok=True)
    atlas = Image.new("RGBA", (CELL_W * ATLAS_COLS, CELL_H * ATLAS_ROWS))
    for index in range(FRAMES):
        atlas.alpha_composite(frame(index), ((index % ATLAS_COLS) * CELL_W, (index // ATLAS_COLS) * CELL_H))
    atlas.save(OUT)
    pixels = np.asarray(atlas)
    colors = len(np.unique(pixels.reshape(-1, 4), axis=0))
    alphas = np.unique(pixels[:, :, 3]).tolist()
    assert atlas.size == (6144, 2560)
    assert 18 <= colors <= 80
    assert len(alphas) >= 6 and max(alphas) <= 220
    print(f"SECONDHAND_SMOKE_BUILD_OK size={atlas.width}x{atlas.height} colors={colors} alpha={alphas}")


if __name__ == "__main__":
    main()
