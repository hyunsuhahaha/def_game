from collections import deque
from pathlib import Path
import math

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
CELL_W, CELL_H, COLS = 128, 96, 4
OUT = ROOT / "assets/trees/stump-atlas-pixel-v1.png"
PREVIEW = ROOT / "docs/previews/stump-atlas-pixel-v1-2x.png"

SPECS = [
    ("broadleaf", "broadleaf-tree-cartoon-v3.png", 44, (47, 28, 18, 255), (151, 91, 45, 255), (185, 122, 63, 255), (91, 50, 28, 255)),
    ("pine", "pine-tree-cartoon-v3.png", 45, (43, 29, 20, 255), (137, 91, 51, 255), (174, 119, 67, 255), (82, 52, 31, 255)),
    ("birch", "birch-tree-cartoon-v3.png", 43, (47, 39, 39, 255), (172, 145, 115, 255), (211, 184, 143, 255), (98, 72, 59, 255)),
    ("maple", "maple-tree-cartoon-v3.png", 46, (66, 31, 20, 255), (168, 79, 39, 255), (207, 116, 57, 255), (105, 48, 27, 255)),
    ("mangrove", "mangrove-tree-pixel-v2.png", 52, (42, 31, 24, 255), (126, 84, 54, 255), (164, 112, 70, 255), (80, 50, 34, 255)),
    ("avicennia", "avicennia-tree-pixel-v1.png", 46, (48, 41, 34, 255), (139, 119, 91, 255), (179, 154, 112, 255), (88, 70, 54, 255)),
    ("nypa", "nypa-tree-pixel-v1.png", 40, (53, 37, 23, 255), (143, 99, 54, 255), (184, 132, 69, 255), (93, 61, 34, 255)),
    ("baobab", "baobab-tree-pixel-v2.png", 57, (61, 38, 25, 255), (164, 104, 60, 255), (207, 144, 78, 255), (102, 60, 35, 255)),
    ("tamarind", "tamarind-tree-pixel-v1.png", 47, (48, 31, 21, 255), (133, 83, 43, 255), (174, 117, 61, 255), (83, 48, 28, 255)),
    ("commiphora", "commiphora-tree-pixel-v1.png", 45, (60, 42, 31, 255), (151, 113, 76, 255), (191, 148, 99, 255), (99, 68, 46, 255)),
    ("palm", "palm-tree-pixel-v2.png", 53, (58, 39, 23, 255), (159, 111, 57, 255), (203, 151, 78, 255), (101, 67, 36, 255)),
    ("seaalmond", "seaalmond-tree-pixel-v1.png", 45, (50, 33, 22, 255), (139, 90, 48, 255), (181, 126, 67, 255), (88, 54, 31, 255)),
    ("pandanus", "pandanus-tree-pixel-v1.png", 48, (53, 38, 25, 255), (145, 101, 57, 255), (188, 139, 75, 255), (93, 62, 35, 255)),
    ("giantcedar", "giantcedar-tree-pixel-v1.png", 58, (40, 27, 21, 255), (119, 76, 40, 255), (181, 125, 65, 255), (72, 45, 29, 255)),
    ("ancienthemlock", "ancienthemlock-tree-pixel-v1.png", 54, (39, 30, 25, 255), (110, 78, 51, 255), (169, 126, 76, 255), (66, 48, 37, 255)),
    ("mossoak", "mossoak-tree-pixel-v1.png", 57, (43, 29, 22, 255), (130, 88, 47, 255), (191, 143, 73, 255), (75, 50, 31, 255)),
]


def rooted_component(image, cut_y, foot_y):
    alpha = image.getchannel("A")
    pixels = alpha.load()
    width = image.width
    seeds = []
    for y in range(max(cut_y, foot_y - 5), foot_y + 1):
        for x in range(width):
            if pixels[x, y] >= 128:
                seeds.append((x, y))
    seen = set(seeds)
    queue = deque(seeds)
    while queue:
        x, y = queue.popleft()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1),
                       (x - 1, y - 1), (x + 1, y - 1), (x - 1, y + 1), (x + 1, y + 1)):
            if 0 <= nx < width and cut_y <= ny <= foot_y and (nx, ny) not in seen and pixels[nx, ny] >= 128:
                seen.add((nx, ny)); queue.append((nx, ny))
    if not seen:
        return image.crop((0, cut_y, width, foot_y + 1))
    x0, x1 = min(x for x, _ in seen), max(x for x, _ in seen)
    layer = Image.new("RGBA", (x1 - x0 + 1, foot_y - cut_y + 1))
    src, dst = image.load(), layer.load()
    for x, y in seen:
        dst[x - x0, y - cut_y] = src[x, y]
    return layer


def stump_cell(spec):
    name, filename, height, outline, sapwood, highlight, ring = spec
    source = Image.open(ROOT / "assets/trees" / filename).convert("RGBA")
    bbox = source.getchannel("A").getbbox()
    foot = bbox[3] - 1
    root = rooted_component(source, max(bbox[1], foot - height), foot)
    max_w, max_h = 112, 66
    scale = min(1, max_w / root.width, max_h / root.height)
    if scale < 1:
        root = root.resize((max(1, round(root.width * scale)), max(1, round(root.height * scale))), Image.Resampling.NEAREST)
    # Remove low branch fragments that happen to cross the crop line. The
    # upper third must read as one severed trunk, widening into roots below.
    root_pixels = root.load();top_zone=max(8,min(18,root.height//3));center=root.width//2
    for y in range(top_zone):
        half=round(root.width*(.22+.13*y/max(1,top_zone-1)))
        for x in range(root.width):
            if abs(x-center)>half: root_pixels[x,y]=(0,0,0,0)
    cell = Image.new("RGBA", (CELL_W, CELL_H))
    baseline = 86
    px = (CELL_W - root.width) // 2
    py = baseline - root.height
    cell.alpha_composite(root, (px, py))

    # The cut follows the source trunk width, then adds a restrained uneven
    # bark rim and muted annual rings instead of the old bright orange oval.
    alpha = root.getchannel("A")
    scan_y = min(3, root.height - 1)
    xs = [x for x in range(root.width) if alpha.getpixel((x, scan_y)) >= 128]
    trunk_w = max(22, min(54, (max(xs) - min(xs) + 1) if xs else root.width // 3))
    cx, top_y = CELL_W // 2, py + 2
    rx, ry = trunk_w // 2 + 3, max(5, trunk_w // 7)
    draw = ImageDraw.Draw(cell)
    draw.rectangle((cx-rx+3, top_y+ry-1, cx+rx-3, top_y+ry+2), fill=outline)
    draw.ellipse((cx-rx, top_y-ry, cx+rx, top_y+ry), fill=outline)
    draw.ellipse((cx-rx+3, top_y-ry+2, cx+rx-3, top_y+ry-2), fill=sapwood)
    draw.arc((cx-rx+5, top_y-ry+3, cx+rx-5, top_y+ry-3), 196, 344, fill=highlight, width=2)
    draw.ellipse((cx-rx//2, top_y-max(2, ry//2), cx+rx//2, top_y+max(2, ry//2)), outline=ring, width=2)
    draw.arc((cx-rx//3, top_y-2, cx+rx//3, top_y+3), 12, 190, fill=outline, width=1)
    # Chips/notches break the perfect manufactured ellipse.
    for dx, dy in ((-rx+2, -1), (rx-5, 1), (-rx//2, -ry+1)):
        draw.rectangle((cx+dx, top_y+dy, cx+dx+2, top_y+dy+1), fill=outline)
    return name, cell


def sprout_cell():
    cell = Image.new("RGBA", (CELL_W, CELL_H)); draw = ImageDraw.Draw(cell)
    dark, stem, leaf, light = (32, 66, 31, 255), (65, 117, 48, 255), (87, 145, 55, 255), (137, 181, 76, 255)
    draw.rectangle((62, 47, 65, 73), fill=dark);draw.rectangle((63, 47, 64, 72), fill=stem)
    draw.polygon(((63, 56),(49, 48),(45, 51),(51, 61),(62, 62)),fill=dark)
    draw.polygon(((61, 57),(50, 50),(48, 52),(52, 58),(61, 60)),fill=leaf)
    draw.line((51,52,59,58),fill=light,width=1)
    draw.polygon(((65, 52),(77, 42),(82, 45),(78, 56),(66, 59)),fill=dark)
    draw.polygon(((67, 53),(77, 45),(79, 46),(76, 53),(67, 57)),fill=leaf)
    draw.line((68,55,76,47),fill=light,width=1)
    return cell


def main():
    rows = math.ceil((len(SPECS)+1)/COLS)
    sheet = Image.new("RGBA", (CELL_W * COLS, CELL_H * rows))
    cells = []
    for index, spec in enumerate(SPECS):
        name, cell = stump_cell(spec); cells.append((name, cell))
        sheet.alpha_composite(cell, ((index % COLS) * CELL_W, (index // COLS) * CELL_H))
    sprout_index=len(SPECS)
    sheet.alpha_composite(sprout_cell(), ((sprout_index % COLS) * CELL_W, (sprout_index // COLS) * CELL_H))
    OUT.parent.mkdir(parents=True, exist_ok=True); sheet.save(OUT)

    board = Image.new("RGBA", (CELL_W * COLS * 2, CELL_H * rows * 2), (33, 49, 25, 255))
    board.alpha_composite(sheet.resize(board.size, Image.Resampling.NEAREST))
    PREVIEW.parent.mkdir(parents=True, exist_ok=True); board.save(PREVIEW)
    print(f"STUMP_ASSET_OK {sheet.width}x{sheet.height} variants={len(SPECS)} sprout=1")


if __name__ == "__main__":
    main()
