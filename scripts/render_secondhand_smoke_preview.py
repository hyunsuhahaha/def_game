"""Render the smoke through the same camera scale and overlap used in game."""
from pathlib import Path
import json
import math
import os

from PIL import Image, ImageChops, ImageDraw

from headless_lua import run


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs/previews/secondhand-smoke-runtime-v3.png"
PIXEL_OUT = ROOT / "docs/previews/secondhand-smoke-runtime-v3-3x.png"
MOTION_OUT = ROOT / "docs/previews/secondhand-smoke-runtime-v3.gif"
SINGLE_CAPTURE = OUT.parent / "secondhand-smoke-single-v3-draws.json"
OVERLAP_CAPTURE = OUT.parent / "secondhand-smoke-overlap-v3-draws.json"

CELL_W, CELL_H, COLUMNS = 3072, 1920, 2
WORLD_W, WORLD_H = 640, 400
CAMERA_ZOOM = .84
OVERLAP_CLOUDS = 3
SCREEN_W, SCREEN_H = round(WORLD_W * CAMERA_ZOOM), round(WORLD_H * CAMERA_ZOOM)


def crop_frame(sheet, index):
    left = (index % COLUMNS) * CELL_W
    top = (index // COLUMNS) * CELL_H
    return sheet.crop((left, top, left + CELL_W, top + CELL_H))


def weighted(image, value):
    result = image.copy()
    result.putalpha(result.getchannel("A").point(lambda alpha: round(alpha * .88 * value)))
    return result


def blend_frame(runtime_frames, age, life=3.2):
    phase = age * 3.5
    whole = math.floor(phase)
    blend = phase - whole
    blend = blend * blend * (3 - 2 * blend)
    fade = min(1, age * 7, (1 - min(1, age / life)) * 3.2)
    layer = Image.new("RGBA", (SCREEN_W, SCREEN_H))
    layer.alpha_composite(weighted(runtime_frames[whole % 6], fade * (1 - blend) ** .62))
    if blend > .001:
        layer.alpha_composite(weighted(runtime_frames[(whole + 1) % 6], fade * blend ** .62))
    return layer


def scene_background(ground, width=760, height=540):
    crop = ground.crop((80, 120, 1040, 800)).resize((width, height), Image.Resampling.NEAREST)
    return crop.convert("RGBA")


def add_character(scene, smoker, center_x, center_y):
    body = smoker.crop((96, 0, 192, 192)).resize((59, 117), Image.Resampling.NEAREST)
    shadow = Image.new("RGBA", scene.size)
    ImageDraw.Draw(shadow).ellipse((center_x - 31, center_y - 8, center_x + 31, center_y + 10), fill=(10, 15, 7, 72))
    scene.alpha_composite(shadow)
    scene.alpha_composite(body, (center_x - 29, center_y - 109))


def add_cloud(scene, runtime_frames, center_x, center_y, age):
    smoke = blend_frame(runtime_frames, age)
    scene.alpha_composite(smoke, (round(center_x - SCREEN_W / 2), round(center_y - SCREEN_H / 2)))


def replay_runtime_draws(scene, commands, center_x, center_y):
    for op in commands:
        assert op["op"] == "draw" and op["filter"] == "nearest"
        qx, qy, width, height, _, _ = op["quad"]
        source = Image.open(ROOT / op["file"]).convert("RGBA").crop((qx, qy, qx + width, qy + height))
        x, y, _, sx, sy, ox, oy = op["args"]
        draw_w = round(width * abs(sx) * CAMERA_ZOOM)
        draw_h = round(height * abs(sy) * CAMERA_ZOOM)
        source = source.resize((draw_w, draw_h), Image.Resampling.NEAREST)
        tint = tuple(round(value * 255) for value in op["color"])
        source = ImageChops.multiply(source, Image.new("RGBA", source.size, tint))
        left = round(center_x + x * CAMERA_ZOOM - ox * abs(sx) * CAMERA_ZOOM)
        top = round(center_y + y * CAMERA_ZOOM - oy * abs(sy) * CAMERA_ZOOM)
        scene.alpha_composite(source, (left, top))


def main():
    ground = Image.open(ROOT / "assets/forest-ground-tile-v1.png").convert("RGB")
    atlas = Image.open(ROOT / "assets/fx/secondhand-smoke/secondhand-smoke-mist-atlas-pixel-v3.png").convert("RGBA")
    smoker = Image.open(ROOT / "assets/characters/ingame/smoker-atlas-pixel-v2.png").convert("RGBA")
    runtime_frames = [
        crop_frame(atlas, index).resize((SCREEN_W, SCREEN_H), Image.Resampling.NEAREST)
        for index in range(6)
    ]

    os.environ["SECONDHAND_SINGLE_CAPTURE"] = str(SINGLE_CAPTURE)
    os.environ["SECONDHAND_OVERLAP_CAPTURE"] = str(OVERLAP_CAPTURE)
    run(ROOT / "scripts/capture_secondhand_smoke_runtime.lua")
    single_commands = json.loads(SINGLE_CAPTURE.read_text(encoding="utf-8"))
    overlap_commands = json.loads(OVERLAP_CAPTURE.read_text(encoding="utf-8"))

    single = scene_background(ground)
    add_character(single, smoker, 380, 310)
    replay_runtime_draws(single, single_commands, 380, 310)

    overlap = scene_background(ground)
    add_character(overlap, smoker, 380, 310)
    replay_runtime_draws(overlap, overlap_commands, 380, 310)

    canvas = Image.new("RGBA", (1560, 590), (19, 25, 16, 255))
    canvas.alpha_composite(single, (20, 38))
    canvas.alpha_composite(overlap, (800, 38))
    labels = ImageDraw.Draw(canvas)
    labels.text((20, 14), "RUNTIME CAMERA 0.84x / ONE CLOUD", fill=(225, 232, 211, 255))
    labels.text((800, 14), "RUNTIME CAMERA 0.84x / MAX THREE-CLOUD OVERLAP", fill=(225, 232, 211, 255))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(OUT)

    # Enlarged nearest-neighbour crop of the actual camera result, not the
    # source atlas. This exposes what one screen pixel contains in game.
    single.crop((165, 105, 595, 430)).resize((1290, 975), Image.Resampling.NEAREST).convert("RGB").save(PIXEL_OUT)

    motion = []
    frame_count = 48
    emissions = (0, .95, 1.90)
    for frame_index in range(frame_count):
        now = frame_index / 12
        frame = scene_background(ground, 960, 540)
        add_character(frame, smoker, 480, 310)
        for emitted_at in emissions:
            age = now - emitted_at
            if 0 <= age < 3.2:
                drift = round((64 + age * 7) * CAMERA_ZOOM)
                rise = round((-17 - age * 2.5) * CAMERA_ZOOM)
                add_cloud(frame, runtime_frames, 480 + drift, 310 + rise, age)
        motion.append(frame.convert("P", palette=Image.Palette.ADAPTIVE, colors=255))
    motion[0].save(
        MOTION_OUT, save_all=True, append_images=motion[1:], duration=83,
        loop=0, disposal=2, optimize=False,
    )
    SINGLE_CAPTURE.unlink()
    OVERLAP_CAPTURE.unlink()
    print(
        f"SECONDHAND_SMOKE_PREVIEW_OK camera={CAMERA_ZOOM} screen={SCREEN_W}x{SCREEN_H} "
        f"overlap={OVERLAP_CLOUDS} motion={len(motion)} window=none"
    )


if __name__ == "__main__":
    main()
