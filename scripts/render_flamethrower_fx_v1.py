"""Replay the production flamethrower draw path without opening a window."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

from headless_lua import run
from render_clearcut_synergy_ui import render_ui

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "previews"
run(ROOT / "scripts" / "verify_flamethrower_art.lua")
run(ROOT / "scripts" / "capture_flamethrower_fx_v1.lua")
frames = [render_ui(OUT / f"flamethrower-fx-v5-draws-{i}.json", (1280, 720)) for i in range(8)]
torch_frames = [render_ui(OUT / f"flamethrower-torch-v1-draws-{i}.json", (1280, 720)) for i in range(8)]
frames[0].save(
    OUT / "flamethrower-fx-v5-runtime.gif", save_all=True,
    append_images=frames[1:], duration=56, loop=0, optimize=False,
)
sheet = Image.new("RGB", (1280, 720), (8, 14, 12))
for index, source in enumerate((0, 2, 4, 6)):
    frame = frames[source].resize((640, 360), Image.Resampling.NEAREST)
    sheet.paste(frame, ((index % 2) * 640, (index // 2) * 360))
draw = ImageDraw.Draw(sheet)
font = ImageFont.truetype(str(ROOT / "assets" / "font-korean-bold.ttf"), 24)
draw.text((22, 18), "화염방사기 v5 · 8장 독립 연소 · 실제 게임 배율", font=font, fill=(255, 220, 92))
sheet.save(OUT / "flamethrower-fx-v5-runtime-sheet.png")
torch_frames[0].save(
    OUT / "flamethrower-torch-v1-runtime.gif", save_all=True,
    append_images=torch_frames[1:], duration=62, loop=0, optimize=False,
)
comparison = []
for classic, torch in zip(frames, torch_frames):
    canvas = Image.new("RGB", (1280, 720), (8, 14, 12))
    canvas.paste(classic.resize((640, 360), Image.Resampling.NEAREST), (0, 180))
    canvas.paste(torch.resize((640, 360), Image.Resampling.NEAREST), (640, 180))
    labels = ImageDraw.Draw(canvas)
    labels.text((24, 136), "A · 기존 불꽃", font=font, fill=(255, 220, 92))
    labels.text((664, 136), "B · 반투명 적색 토치 + 나무별 타격", font=font, fill=(255, 128, 92))
    comparison.append(canvas)
comparison[0].save(OUT / "flamethrower-ab-comparison-v1.gif", save_all=True,
    append_images=comparison[1:], duration=62, loop=0, optimize=False)
comparison[0].save(OUT / "flamethrower-ab-comparison-v1.png")
print("FLAMETHROWER_FX_COMPARE_RENDER_OK styles=classic+torch frames=8 per_tree_impacts=2 window=none")
