from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "assets" / "scenery" / "biomes"
SOURCE = ROOT / "src" / "forest_floor.lua"

BIOMES = {
    "beginner": ("meadow", "clover", "flowers", "chalk", "chips"),
    "mangrove": ("mud", "puddle", "roots", "shells", "burrows"),
    "madagascar": ("laterite", "cracked", "thorn", "pods", "limestone"),
    "island": ("sand", "coral", "beachGrass", "frond", "volcanic"),
}

CELL_W = 128
CELL_H = 96


def main():
    signatures = {}
    for biome, source_tokens in BIOMES.items():
        path = ASSET_DIR / f"{biome}-floor-decal-atlas-pixel-v1.png"
        assert path.exists(), f"missing atlas: {path}"
        image = Image.open(path).convert("RGBA")
        assert image.size == (640, 192), (biome, image.size)
        alpha = image.getchannel("A")
        assert set(alpha.get_flattened_data()) <= {0, 255}, f"soft alpha in {biome}"
        colors = {pixel for pixel in image.get_flattened_data() if pixel[3]}
        assert len(colors) >= 24, f"palette too shallow in {biome}: {len(colors)}"

        cells = []
        for row in range(2):
            for column in range(5):
                box = (
                    column * CELL_W,
                    row * CELL_H,
                    (column + 1) * CELL_W,
                    (row + 1) * CELL_H,
                )
                cell = image.crop(box)
                assert cell.getbbox(), f"empty cell: {biome} {column},{row}"
                cells.append(cell.tobytes())
        assert len(set(cells)) == 10, f"duplicate decal cells within {biome}"
        signatures[biome] = cells

        source = SOURCE.read_text(encoding="utf-8")
        assert path.name in source
        for token in source_tokens:
            assert token in source, f"missing {biome} material token: {token}"

    names = list(BIOMES)
    for index, left in enumerate(names):
        for right in names[index + 1 :]:
            for cell_index in range(10):
                assert signatures[left][cell_index] != signatures[right][cell_index], (
                    f"cross-biome decal reuse: {left}/{right} cell {cell_index}"
                )

    source = SOURCE.read_text(encoding="utf-8")
    for token in (
        '").channelDistance',
        '").islandDistance',
        "local trail=",
        "readability",
        "clusters",
        "felled",
        'setFilter("nearest","nearest")',
    ):
        assert token in source, f"missing placement/rendering contract: {token}"

    print("BIOME_FLOOR_VERIFY_OK biomes=4 decals=40 unique=true")


if __name__ == "__main__":
    main()
