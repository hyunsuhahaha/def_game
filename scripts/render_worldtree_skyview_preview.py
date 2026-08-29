from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
W, H, HORIZON = 1280, 720, 205


def load(path):
    return Image.open(ROOT / path).convert("RGBA")


def cover_width(image, bottom):
    scale = W / image.width
    resized = image.resize((W, round(image.height * scale)), Image.Resampling.NEAREST)
    return resized, (0, round(bottom - resized.height))


canvas = Image.new("RGBA", (W, H), (83, 151, 208, 255))
sky = load("assets/scenery/skyview/sky-clear-pixel-v1.png")
sky_scale = max(W / sky.width, 337 / sky.height)
sky = sky.resize((round(sky.width * sky_scale), round(sky.height * sky_scale)), Image.Resampling.NEAREST)
canvas.alpha_composite(sky, ((W - sky.width) // 2, 0))

for name, bottom in (
    ("horizon-mountains-pixel-v1.png", HORIZON + 7),
    ("horizon-forest-pixel-v1.png", HORIZON + 9),
):
    layer, pos = cover_width(load("assets/scenery/skyview/" + name), bottom)
    canvas.alpha_composite(layer, pos)

# Perspective ground: distant rows are sampled more densely and become broader
# toward the foreground. This is a static verification board, while runtime
# uses the real projected world mesh.
tile = load("assets/forest-ground-tile-v1.png")
ground = Image.new("RGBA", (W, H - HORIZON), (73, 100, 39, 255))
for y in range(ground.height):
    depth = y / max(1, ground.height - 1)
    source_y = int((depth ** 1.65) * tile.height * 2.8) % tile.height
    row = Image.new("RGBA", (tile.width * 6, 1))
    source_row = tile.crop((0, source_y, tile.width, source_y + 1))
    for x in range(0, row.width, tile.width):
        row.alpha_composite(source_row, (x, 0))
    row = row.resize((W, 1), Image.Resampling.NEAREST)
    ground.alpha_composite(row, (0, y))
shade = Image.new("RGBA", ground.size, (28, 43, 19, 34))
ground = Image.alpha_composite(ground, shade)
canvas.alpha_composite(ground, (0, HORIZON))

mist, mist_pos = cover_width(load("assets/scenery/skyview/horizon-mist-pixel-v1.png"), HORIZON + 31)
mist.putalpha(mist.getchannel("A").point(lambda value: round(value * .82)))
canvas.alpha_composite(mist, mist_pos)

draw = ImageDraw.Draw(canvas, "RGBA")
tree_foot = (760, 680)
draw.ellipse((tree_foot[0] - 92, tree_foot[1] - 7, tree_foot[0] + 92, tree_foot[1] + 13), fill=(22, 25, 10, 100))
draw.ellipse((tree_foot[0] - 205, tree_foot[1] - 7, tree_foot[0] - 85, tree_foot[1] + 8), fill=(24, 27, 11, 75))
draw.ellipse((tree_foot[0] + 88, tree_foot[1] - 7, tree_foot[0] + 212, tree_foot[1] + 9), fill=(24, 27, 11, 75))

atlas = load("assets/enemies/arcade/worldtree-siege-atlas-v1.png")
tree = atlas.crop((0, 0, 1024, 1024))
tree_scale = .667
tree = tree.resize((round(tree.width * tree_scale), round(tree.height * tree_scale)), Image.Resampling.NEAREST)
tree_x = round(tree_foot[0] - 512 * tree_scale)
tree_y = round(tree_foot[1] - 992 * tree_scale)
canvas.alpha_composite(tree, (tree_x, tree_y))

# Player at the same camera zoom gives an immediate height comparison.
smoker = load("assets/characters/ingame/smoker-atlas-pixel-v2.png").crop((0, 0, 96, 192))
player_scale = .61 * .52
smoker = smoker.resize((round(96 * player_scale), round(192 * player_scale)), Image.Resampling.NEAREST)
player_foot = (430, 676)
draw = ImageDraw.Draw(canvas, "RGBA")
draw.ellipse((player_foot[0] - 17, player_foot[1] - 5, player_foot[0] + 17, player_foot[1] + 6), fill=(18, 23, 10, 110))
canvas.alpha_composite(smoker, (round(player_foot[0] - smoker.width / 2), round(player_foot[1] - 190 * player_scale)))

path = ROOT / "docs/previews/worldtree-skyview-height-v1.png"
canvas.convert("RGB").save(path)
print(path)
