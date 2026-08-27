"""Headless contract checks for the authored coin-miner mole atlas."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
ATLAS = ROOT / "assets/characters/ingame/coin-miner-mole-atlas-pixel-v3.png"
GAME = ROOT / "src/game.lua"
MODE = ROOT / "src/clearcut_mode.lua"


def main() -> None:
    image = Image.open(ATLAS).convert("RGBA")
    assert image.size == (1152, 768), image.size
    pixels = list(image.get_flattened_data())
    assert all(pixel[3] in (0, 255) for pixel in pixels)
    colors = {pixel[:3] for pixel in pixels if pixel[3]}
    assert 70 <= len(colors) <= 112, len(colors)

    frames = []
    for row in range(2):
        for column in range(6):
            frame = image.crop((column * 192, row * 384, (column + 1) * 192, (row + 1) * 384))
            box = frame.getchannel("A").getbbox()
            assert box and box[3] >= 378, (row, column, box)
            frames.append(frame)
    assert len({frame.tobytes() for frame in frames[:6]}) == 6
    assert len({frame.tobytes() for frame in frames[6:]}) == 6
    # Final two action cells are both underground and substantially lower than
    # the standing scratch poses. This prevents the rejected hand-thrown tree
    # pose from re-entering the runtime sheet.
    assert frames[10].getchannel("A").getbbox()[1] > frames[6].getchannel("A").getbbox()[1] + 80
    assert frames[11].getchannel("A").getbbox()[1] > frames[6].getchannel("A").getbbox()[1] + 80

    game = GAME.read_text(encoding="utf-8")
    mode = MODE.read_text(encoding="utf-8")
    assert 'miner = {file="coin-miner-mole-atlas-pixel-v3.png"' in game
    assert "walkFeet={380,380,380,380,380,380}" in game
    assert "function ClearcutMode:activateMinerBurrow" in mode
    assert "function ClearcutMode:launchTreeSideways" in mode
    assert "pointSegmentDistanceSquared" in mode
    assert "node.uprooted=true" in mode
    print(f"COIN_MINER_MOLE_VERIFY_OK size={image.size} colors={len(colors)} frames=12")


if __name__ == "__main__":
    main()
