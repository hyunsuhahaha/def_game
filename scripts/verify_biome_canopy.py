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

    source = (ROOT / "src" / "biome_canopy.lua").read_text(encoding="utf-8")
    game = (ROOT / "src" / "game.lua").read_text(encoding="utf-8")
    for biome in BIOMES:
        assert biome in source
    for token in ('setFilter("nearest","nearest")', "vines=", "sway=", "parallax=", 'love.graphics.push("all")'):
        assert token in source, token
    assert "BiomeCanopy.draw" in game
    assert game.index("BiomeCanopy.draw") < game.index("self:drawUI()")
    print("BIOME_CANOPY_VERIFY_OK biomes=5 components=25 layer=foreground hud=above")


if __name__ == "__main__":
    main()
