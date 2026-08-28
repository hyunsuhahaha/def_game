from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
BIOMES = ("forest", "beginner", "mangrove", "madagascar", "island")


def main():
    signatures = {}
    for biome in BIOMES:
        path = ROOT / "assets" / "scenery" / "canopy" / f"{biome}-foreground-canopy-atlas-pixel-v1.png"
        assert path.exists(), path
        image = Image.open(path).convert("RGBA")
        assert image.size == (1024, 256), (biome, image.size)
        assert set(image.getchannel("A").get_flattened_data()) <= {0, 255}
        colors = {pixel for pixel in image.get_flattened_data() if pixel[3]}
        assert len(colors) >= 12, (biome, len(colors))
        regions = ((0, 0, 320, 256), (320, 0, 640, 256), (640, 0, 768, 256),
                   (768, 0, 896, 256), (896, 0, 1024, 256))
        cells = [image.crop(region) for region in regions]
        assert all(cell.getbbox() for cell in cells), f"empty canopy component: {biome}"
        signatures[biome] = image.tobytes()
    assert len(set(signatures.values())) == len(BIOMES), "biome canopy reuse"

    # The former screen overlay remains only as source-art provenance. Runtime
    # vegetation now uses one world-space atlas and actor module.
    world_atlas = Image.open(ROOT / "assets/scenery/biomes/world-vines-atlas-pixel-v1.png").convert("RGBA")
    assert world_atlas.size == (960, 224)
    assert set(world_atlas.getchannel("A").get_flattened_data()) <= {0, 255}
    assert len({pixel for pixel in world_atlas.get_flattened_data() if pixel[3]}) >= 12
    source = (ROOT / "src" / "biome_vines.lua").read_text(encoding="utf-8")
    game = (ROOT / "src" / "game.lua").read_text(encoding="utf-8")
    world = (ROOT / "src" / "world.lua").read_text(encoding="utf-8")
    for token in ('setFilter("nearest","nearest")', "attached=", "ground=", "sortBias=.02", "rustle", "cutRadius"):
        assert token in source, token
    assert "BiomeCanopy" not in game
    assert not (ROOT / "src/biome_canopy.lua").exists()
    assert "BiomeVines.queue" in world
    print("BIOME_VINES_ASSET_OK atlas=960x224 states=6 layer=world screen_overlay=removed")


if __name__ == "__main__":
    main()
