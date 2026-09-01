"""Render unlocked lobby animal life, interaction stories, and sleep detail."""
from pathlib import Path

from PIL import Image, ImageDraw

from headless_lua import run
from render_clearcut_synergy_ui import render_ui


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs/previews"


def render_lobby(width, height, hour, name):
    run(ROOT / "scripts/capture_lobby_companions.lua",
        f"CAPTURE_W={width};CAPTURE_H={height};LOBBY_HOUR={hour}")
    source = OUT / f"lobby-companions-draws-{width}-h{hour:02d}.json"
    image = render_ui(source, (width, height))
    target = OUT / name
    image.save(target)
    return target


def sleep_board():
    specs = (
        ("MONKEY", ROOT / "assets/characters/companions/lobby-monkey-sleep-atlas-pixel-v1.png", 128, 128),
        ("MOLE", ROOT / "assets/characters/companions/lobby-mole-sleep-atlas-pixel-v1.png", 192, 384),
        ("CAT", ROOT / "assets/characters/companions/lobby-cat-sleep-atlas-pixel-v1.png", 128, 128),
    )
    tiles = []
    for label, path, cell_w, cell_h in specs:
        atlas = Image.open(path).convert("RGBA")
        frame = atlas.crop((2 * cell_w, 0, 3 * cell_w, cell_h))
        bounds = frame.getbbox()
        frame = frame.crop(bounds) if bounds else frame
        tiles.append((label, frame))
    board = Image.new("RGB", (1660, 650), (7, 20, 15))
    draw = ImageDraw.Draw(board)
    x = 24
    for label, tile in tiles:
        zoom = tile.resize((tile.width * 3, tile.height * 3), Image.Resampling.NEAREST)
        y = 610 - zoom.height
        board.paste(zoom, (x, y), zoom)
        draw.text((x, 625), label, fill=(177, 204, 170))
        x += zoom.width + 42
    target = OUT / "lobby-companions-v1-sleep-3x.png"
    board.save(target)
    return target


def life_gif():
    frames = []
    for index in range(16):
        preview_time = index / 8
        run(ROOT / "scripts/capture_lobby_companions.lua",
            f"CAPTURE_W=1280;CAPTURE_H=720;LOBBY_HOUR=17;"
            f"LOBBY_PREVIEW_TIME={preview_time};LOBBY_PREVIEW_FRAME={index}")
        source = OUT / f"lobby-companions-draws-1280-h17-f{index:02d}.json"
        full = render_ui(source, (1280, 720))
        frames.append(full.crop((420, 420, 1210, 680)))
    target = OUT / "lobby-companions-v1-life.gif"
    frames[0].save(target, save_all=True, append_images=frames[1:], duration=125,
                   loop=0, disposal=2, optimize=False)
    return target


def interaction_frame(kind, preview_time, frame_index=None):
    suffix = f";LOBBY_PREVIEW_FRAME={frame_index}" if frame_index is not None else ""
    run(ROOT / "scripts/capture_lobby_companions.lua",
        f'CAPTURE_W=1280;CAPTURE_H=720;LOBBY_HOUR=17;LOBBY_INTERACTION_KIND="{kind}";'
        f"LOBBY_PREVIEW_TIME={preview_time}{suffix}")
    frame_suffix = f"-f{frame_index:02d}" if frame_index is not None else ""
    source = OUT / f"lobby-companions-draws-1280-h17-{kind}{frame_suffix}.json"
    return render_ui(source, (1280, 720))


def interaction_board():
    scenes = (
        ("CAT WAND CHASE", "cat_wand", .65),
        ("BANANA TOSS", "banana_toss", .55),
        ("MOLE PEEKABOO", "mole_peek", 0),
        ("CHASE TRAIN", "chase_train", .85),
    )
    board = Image.new("RGB", (1560, 570), (6, 18, 13))
    draw = ImageDraw.Draw(board)
    for index, (label, kind, moment) in enumerate(scenes):
        full = interaction_frame(kind, moment)
        crop = full.crop((420, 410, 1200, 665))
        x = (index % 2) * 780
        y = (index // 2) * 285
        board.paste(crop, (x, y + 24))
        draw.text((x + 14, y + 6), label, fill=(190, 218, 170))
    target = OUT / "lobby-companions-v2-interactions.png"
    board.save(target)
    return target


def cat_wand_gif():
    frames = []
    for index in range(32):
        full = interaction_frame("cat_wand", index / 8, index)
        frames.append(full.crop((420, 405, 1200, 670)))
    target = OUT / "lobby-companions-v2-cat-wand.gif"
    frames[0].save(target, save_all=True, append_images=frames[1:], duration=125,
                   loop=0, disposal=2, optimize=False)
    return target


def main():
    day = render_lobby(1280, 720, 12, "lobby-companions-v1-production-day.png")
    night = render_lobby(960, 540, 23, "lobby-companions-v1-production-night-compact.png")
    zoom = sleep_board()
    motion = life_gif()
    interactions = interaction_board()
    wand = cat_wand_gif()
    print(f"LOBBY_COMPANIONS_PREVIEW_OK {day.relative_to(ROOT)} {night.relative_to(ROOT)} "
          f"{zoom.relative_to(ROOT)} {motion.relative_to(ROOT)} "
          f"{interactions.relative_to(ROOT)} {wand.relative_to(ROOT)} window=none")


if __name__ == "__main__":
    main()
