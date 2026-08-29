"""Build the boss vacuum pickup as authored native-grid pixel art."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/pickups/boss-magnet-pickup-pixel-v1.png"
SIZE = 128


def main():
    image = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    ink = (31, 24, 29, 255)
    red0, red1, red2, red3 = (91, 25, 28, 255), (151, 35, 37, 255), (210, 52, 48, 255), (245, 104, 64, 255)
    steel0, steel1, steel2, steel3 = (52, 62, 70, 255), (106, 121, 128, 255), (173, 186, 181, 255), (230, 226, 196, 255)
    # Thick stepped horseshoe silhouette, open at the bottom.
    d.polygon([(27,20),(46,12),(82,12),(101,20),(110,37),(110,78),(99,101),(84,113),(72,113),(72,83),(80,78),(84,69),(84,41),(78,35),(50,35),(44,41),(44,69),(48,78),(56,83),(56,113),(44,113),(29,101),(18,78),(18,37)],fill=ink)
    d.polygon([(29,24),(47,17),(81,17),(98,24),(104,39),(104,76),(95,95),(82,106),(77,106),(77,86),(85,81),(90,70),(90,39),(80,29),(48,29),(38,39),(38,70),(43,81),(51,86),(51,106),(46,106),(33,95),(24,76),(24,39)],fill=red0)
    d.polygon([(33,27),(49,21),(79,21),(94,28),(99,41),(99,73),(91,89),(82,96),(82,86),(89,79),(94,68),(94,43),(84,33),(46,33),(34,45),(34,70),(40,84),(46,89),(46,99),(37,91),(29,74),(29,41)],fill=red2)
    d.line([(37,29),(51,24),(76,24),(90,30)],fill=red3,width=4)
    d.line([(31,43),(31,70),(38,86)],fill=red1,width=4)
    d.line([(97,43),(97,68),(90,83)],fill=(249,77,51,255),width=3)
    # Steel pole caps with four material steps.
    for x0,x1 in ((38,57),(71,90)):
        d.rectangle((x0,82,x1,113),fill=ink)
        d.rectangle((x0+4,84,x1-2,109),fill=steel0)
        d.rectangle((x0+7,85,x1-3,106),fill=steel1)
        d.rectangle((x0+9,87,x1-5,102),fill=steel2)
        d.line((x0+10,88,x1-6,88),fill=steel3,width=2)
        d.rectangle((x0+4,105,x1-2,109),fill=(79,86,88,255))
    # Pixel glints and small magnetic motes provide pickup readability.
    d.rectangle((19,14,23,20),fill=(255,222,104,255));d.rectangle((16,17,26,19),fill=(255,222,104,255))
    d.rectangle((104,22,107,28),fill=(255,237,151,255));d.rectangle((101,24,110,26),fill=(255,237,151,255))
    d.rectangle((12,63,15,66),fill=(226,91,53,255));d.rectangle((113,57,116,60),fill=(226,91,53,255))
    # Controlled one-pixel dithering on the red ceramic body.
    for x,y in ((39,35),(45,30),(54,25),(66,24),(79,29),(88,35),(31,55),(96,52),(36,75),(92,73),(43,91),(85,90)):
        d.point((x,y),fill=(255,137,72,255))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUT, optimize=True)
    colors = image.getcolors(SIZE*SIZE) or []
    assert len(colors) >= 16 and image.getchannel("A").getbbox(), "pickup lost authored material detail"
    print(f"BOSS_MAGNET_PICKUP_OK {OUT.relative_to(ROOT)} {SIZE}x{SIZE} colors={len(colors)}")


if __name__ == "__main__":
    main()
