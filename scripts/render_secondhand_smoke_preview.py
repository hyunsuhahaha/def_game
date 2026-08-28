"""Render the reload-smoke atlas at its exact in-game nearest-neighbour scale."""
from pathlib import Path
import math

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs/previews/secondhand-smoke-fusion-pixel-v2.png"
MOTION_OUT = ROOT / "docs/previews/secondhand-smoke-crossfade-v2.gif"


def crop_frame(sheet, cell_w, cell_h, index, columns=6):
    left = (index % columns) * cell_w
    top = (index // columns) * cell_h
    return sheet.crop((left, top, left + cell_w, top + cell_h))


def weighted(image, value):
    result = image.copy()
    result.putalpha(result.getchannel("A").point(lambda alpha: round(alpha * .88 * value)))
    return result


def main():
    ground = Image.open(ROOT / "assets/forest-ground-tile-v1.png").convert("RGB")
    atlas = Image.open(ROOT / "assets/fx/secondhand-smoke/secondhand-smoke-mist-atlas-pixel-v2.png").convert("RGBA")
    smoker = Image.open(ROOT / "assets/characters/ingame/smoker-atlas-pixel-v2.png").convert("RGBA")

    canvas = Image.new("RGB", (1240, 480), (21, 28, 18))
    tile = ground.crop((160, 220, 880, 620)).resize((720, 400), Image.Resampling.NEAREST)
    canvas.paste(tile, (24, 45))

    body = crop_frame(smoker, 96, 192, 1).resize((59, 117), Image.Resampling.NEAREST)
    source_smoke = crop_frame(atlas, 2048, 1280, 2, 3)
    smoke = source_smoke.resize((640, 400), Image.Resampling.NEAREST)
    smoke.putalpha(smoke.getchannel("A").point(lambda value: round(value * .88)))

    layer = Image.new("RGBA", canvas.size)
    shadow = Image.new("RGBA", canvas.size)
    ImageDraw.Draw(shadow).ellipse((329, 327, 391, 345), fill=(10, 15, 7, 72))
    layer.alpha_composite(shadow)
    layer.alpha_composite(body, (331, 231))
    layer.alpha_composite(smoke, (104, 45))
    canvas = Image.alpha_composite(canvas.convert("RGBA"), layer)

    # Right: a literal 1:1 crop from the native 2048x1280 cell. This verifies
    # the added source density instead of enlarging the already scaled game FX.
    left,top=(source_smoke.width-440)//2,(source_smoke.height-275)//2
    zoom = source_smoke.crop((left,top,left+440,top+275))
    zoom.putalpha(zoom.getchannel("A").point(lambda value: round(value * .88)))
    panel = Image.new("RGBA", (464, 400), (38, 48, 31, 255))
    panel.alpha_composite(zoom, (12, 62))
    canvas.alpha_composite(panel, (744, 45))

    draw = ImageDraw.Draw(canvas)
    draw.text((24, 18), "IN-GAME 640 x 400", fill=(225, 232, 211, 255))
    draw.text((744, 18), "NATIVE 1:1 PIXEL CROP", fill=(225, 232, 211, 255))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(OUT)

    runtime_frames = [crop_frame(atlas, 2048, 1280, index, 3).resize((640, 400), Image.Resampling.NEAREST) for index in range(6)]
    scene = tile.convert("RGBA")
    shadow_scene = Image.new("RGBA", scene.size)
    ImageDraw.Draw(shadow_scene).ellipse((305, 282, 367, 300), fill=(10, 15, 7, 72))
    motion=[]
    motion_count=42
    for index in range(motion_count):
        # One exact six-frame cycle, including the frame 6 -> frame 1 blend at
        # the GIF loop boundary. 42 frames at 41 ms matches runtime's 3.5 fps.
        phase=(index/motion_count)*6
        whole=math.floor(phase)
        blend=phase-whole
        blend=blend*blend*(3-2*blend)
        current_weight=(1-blend)**.62
        next_weight=blend**.62
        frame=scene.copy()
        frame.alpha_composite(shadow_scene)
        frame.alpha_composite(body,(307,186))
        frame.alpha_composite(weighted(runtime_frames[whole%6],current_weight),(40,0))
        if next_weight>.001:
            frame.alpha_composite(weighted(runtime_frames[(whole+1)%6],next_weight),(40,0))
        motion.append(frame.convert("P",palette=Image.Palette.ADAPTIVE,colors=255))
    motion[0].save(MOTION_OUT,save_all=True,append_images=motion[1:],duration=41,loop=0,disposal=2,optimize=False)
    print(f"SECONDHAND_SMOKE_PREVIEW_OK {OUT} {canvas.size} motion={MOTION_OUT.name} frames={len(motion)}")


if __name__ == "__main__":
    main()
