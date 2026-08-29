"""Build distinct native-pixel landmark badges for the rotating stage globe."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
CELL = 64
IDS = ("forest", "mangrove", "madagascar", "island", "beginner")
OUT = ROOT / "assets/ui/globe-stage-landmarks-pixel-v1.png"
PREVIEW = ROOT / "docs/previews/globe-stage-landmarks-pixel-v1-4x.png"

INK = (15, 26, 24, 255)
DEEP = (25, 48, 39, 255)
PAPER = (235, 225, 175, 255)


def stepped_ellipse(d, box, ramp):
    x0, y0, x1, y1 = box
    d.ellipse(box, fill=ramp[0])
    d.ellipse((x0 + 2, y0 + 2, x1 - 2, y1 - 3), fill=ramp[1])
    d.ellipse((x0 + 5, y0 + 4, x1 - 5, y1 - 7), fill=ramp[2])
    d.arc((x0 + 4, y0 + 3, x1 - 5, y1 - 6), 195, 305, fill=ramp[3], width=2)


def badge_base(d, accent):
    d.polygon([(32, 2), (54, 10), (62, 31), (54, 54), (32, 62), (10, 54), (2, 31), (10, 10)], fill=INK)
    d.polygon([(32, 5), (52, 12), (59, 31), (51, 51), (32, 59), (12, 51), (5, 31), (12, 12)], fill=accent)
    d.polygon([(32, 8), (50, 14), (56, 31), (49, 48), (32, 55), (15, 48), (8, 31), (15, 14)], fill=DEEP)
    d.line([(16, 47), (32, 53), (48, 47)], fill=(77, 100, 76, 255), width=2)
    # Purposeful two-step glint instead of a smooth vector highlight.
    d.line([(14, 18), (19, 12), (28, 9)], fill=PAPER, width=2)
    d.point([(14, 22), (17, 16), (23, 12)], fill=(255, 245, 196, 255))


def forest(d):
    badge_base(d, (116, 145, 55, 255))
    d.polygon([(31, 12), (19, 31), (25, 30), (16, 42), (29, 39), (29, 49), (36, 49), (36, 39), (49, 42), (40, 30), (46, 31)], fill=INK)
    d.polygon([(32, 13), (22, 29), (29, 27), (20, 39), (31, 35), (31, 47), (34, 47), (34, 35), (45, 39), (36, 27), (43, 29)], fill=(72, 119, 54, 255))
    d.polygon([(32, 15), (26, 27), (32, 24), (25, 36), (32, 32), (32, 43)], fill=(139, 168, 72, 255))
    d.line([(34, 17), (39, 28), (36, 27)], fill=(202, 193, 101, 255), width=1)


def mangrove(d):
    badge_base(d, (48, 157, 144, 255))
    d.rectangle((14, 42, 50, 48), fill=(18, 68, 78, 255))
    d.line([(15, 44), (24, 42), (32, 45), (42, 42), (49, 44)], fill=(83, 208, 191, 255), width=2)
    d.polygon([(30, 24), (34, 24), (35, 38), (45, 48), (41, 49), (33, 40), (25, 50), (20, 48), (29, 37)], fill=(91, 58, 37, 255))
    d.line([(31, 25), (32, 38), (25, 47)], fill=(183, 112, 57, 255), width=2)
    stepped_ellipse(d, (14, 12, 35, 30), ((9, 31, 24, 255), (31, 89, 55, 255), (54, 137, 73, 255), (129, 181, 92, 255)))
    stepped_ellipse(d, (29, 10, 51, 30), ((9, 31, 24, 255), (27, 83, 52, 255), (48, 128, 68, 255), (122, 176, 88, 255)))


def madagascar(d):
    badge_base(d, (200, 91, 49, 255))
    d.polygon([(27, 45), (30, 28), (25, 21), (28, 15), (36, 15), (40, 21), (35, 28), (38, 45)], fill=INK)
    d.polygon([(30, 44), (32, 27), (28, 21), (30, 17), (34, 17), (37, 21), (33, 28), (35, 44)], fill=(143, 80, 43, 255))
    d.line([(32, 29), (35, 42)], fill=(226, 139, 66, 255), width=2)
    for box in ((13, 10, 31, 26), (24, 7, 43, 25), (36, 11, 53, 27)):
        stepped_ellipse(d, box, ((43, 36, 25, 255), (91, 92, 42, 255), (145, 136, 55, 255), (221, 175, 76, 255)))
    d.rectangle((21, 47, 44, 49), fill=(116, 45, 31, 255))


def island(d):
    badge_base(d, (42, 139, 192, 255))
    d.line([(12, 44), (21, 42), (30, 45), (40, 42), (51, 45)], fill=(104, 221, 222, 255), width=2)
    d.polygon([(17, 43), (25, 37), (42, 37), (49, 43)], fill=(219, 168, 75, 255))
    d.line([(23, 40), (43, 40)], fill=(255, 213, 112, 255), width=2)
    d.line([(34, 38), (32, 20)], fill=INK, width=5)
    d.line([(34, 37), (32, 20)], fill=(142, 82, 41, 255), width=2)
    d.polygon([(31, 21), (17, 16), (27, 12)], fill=INK)
    d.polygon([(33, 20), (45, 10), (48, 17)], fill=INK)
    d.polygon([(31, 20), (20, 17), (28, 14)], fill=(67, 147, 72, 255))
    d.polygon([(34, 19), (44, 12), (46, 16)], fill=(104, 179, 83, 255))
    d.line([(22, 17), (27, 15)], fill=(190, 208, 96, 255), width=1)


def beginner(d):
    badge_base(d, (138, 169, 76, 255))
    d.polygon([(19, 42), (29, 28), (26, 28), (33, 15), (40, 29), (37, 29), (48, 42)], fill=INK)
    d.polygon([(23, 40), (31, 27), (29, 27), (33, 19), (37, 31), (35, 31), (43, 40)], fill=(111, 150, 62, 255))
    d.rectangle((16, 43, 49, 49), fill=(78, 48, 31, 255))
    d.rectangle((18, 44, 47, 46), fill=(205, 146, 70, 255))
    d.rectangle((29, 34, 35, 47), fill=INK)
    d.rectangle((31, 35, 33, 45), fill=(235, 225, 175, 255))
    d.rectangle((30, 37, 34, 39), fill=(235, 225, 175, 255))


def main():
    atlas = Image.new("RGBA", (CELL * len(IDS), CELL), (0, 0, 0, 0))
    makers = (forest, mangrove, madagascar, island, beginner)
    for i, maker in enumerate(makers):
        cell = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
        maker(ImageDraw.Draw(cell))
        atlas.alpha_composite(cell, (i * CELL, 0))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(OUT, optimize=True)
    atlas.resize((atlas.width * 4, atlas.height * 4), Image.Resampling.NEAREST).save(PREVIEW)
    colors = {p[:3] for p in atlas.get_flattened_data() if p[3]}
    assert 30 <= len(colors) <= 96, len(colors)
    print(f"GLOBE_LANDMARKS_V1_OK atlas={atlas.size[0]}x{atlas.size[1]} cell={CELL} maps={len(IDS)} colors={len(colors)}")


if __name__ == "__main__":
    main()
