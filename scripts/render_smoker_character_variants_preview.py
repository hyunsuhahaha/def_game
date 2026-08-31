"""Render an offscreen native-scale comparison; never opens a LÖVE window."""

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
INGAME = ROOT / "assets/characters/ingame"
OUT = ROOT / "docs/previews/smoker-character-variants-v1-display.png"
AVATARS = (
    ("ORIGINAL / runtime cigarette only", "smoker-atlas-pixel-v3.png", "smoker-score-axe-atlas-pixel-v1.png"),
    ("SCRAPYARD WELDER", "scrapyard-welder-atlas-pixel-v1.png", "scrapyard-welder-score-axe-atlas-pixel-v1.png"),
    ("NIGHT SHOPKEEPER", "night-shopkeeper-atlas-pixel-v1.png", "night-shopkeeper-score-axe-atlas-pixel-v1.png"),
)


def cell(path: str, column: int, row: int = 0) -> Image.Image:
    sheet = Image.open(INGAME / path).convert("RGBA")
    return sheet.crop((column * 96, row * 192, (column + 1) * 96, (row + 1) * 192))


canvas = Image.new("RGBA", (1200, 690), (96, 130, 62, 255))
draw = ImageDraw.Draw(canvas)
for y in range(0, canvas.height, 32):
    draw.line((0, y, canvas.width, y), fill=(89, 119, 57))
for x in range(0, canvas.width, 48):
    draw.line((x, 0, x, canvas.height), fill=(101, 137, 64))
draw.rectangle((0, 0, canvas.width, 58), fill=(22, 27, 22))
draw.text((24, 19), "NEW AVATARS — exact runtime scale 0.61 / nearest", fill=(245, 233, 194))

runtime_scale = .61
for index, (label, body_file, axe_file) in enumerate(AVATARS):
    panel_x = 24 + index * 392
    draw.rounded_rectangle((panel_x, 78, panel_x + 368, 650), 14, fill=(19, 27, 21), outline=(176, 190, 134), width=2)
    draw.text((panel_x + 16, 94), label, fill=(245, 233, 194))
    poses = ((body_file, 0, 0), (body_file, 1, 1), (body_file, 5, 1), (axe_file, 3, 0))
    labels = ("walk", "reload", "flick", "axe contact")
    for pose_index, ((file_name, column, row), pose_label) in enumerate(zip(poses, labels)):
        sprite = cell(file_name, column, row)
        size = (round(sprite.width * runtime_scale), round(sprite.height * runtime_scale))
        sprite = sprite.resize(size, Image.Resampling.NEAREST)
        cx = panel_x + 92 + (pose_index % 2) * 176
        baseline = 326 + (pose_index // 2) * 262
        canvas.alpha_composite(sprite, (cx - sprite.width // 2, baseline - round(190 * runtime_scale)))
        draw.text((cx - 38, baseline + 10), pose_label, fill=(210, 218, 184))

OUT.parent.mkdir(parents=True, exist_ok=True)
canvas.save(OUT)
print(OUT)
