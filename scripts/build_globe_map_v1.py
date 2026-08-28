"""Build the authored equirectangular pixel map used by the stage-select globe."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import math

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/globe-world-pixel-v1.png"
W, H = 1024, 512

def xy(lon, lat):
    return ((lon + 180) / 360 * W, (90 - lat) / 180 * H)

continents = [
    # North America
    [(-168,72),(-146,71),(-132,58),(-124,50),(-122,39),(-112,31),(-103,20),(-89,18),(-82,24),(-81,31),(-74,40),(-63,47),(-58,56),(-72,63),(-96,72),(-124,74)],
    # South America
    [(-81,12),(-69,10),(-50,4),(-35,-7),(-39,-20),(-48,-29),(-53,-43),(-67,-55),(-75,-42),(-76,-25),(-82,-5)],
    # Greenland
    [(-73,82),(-22,81),(-18,69),(-39,59),(-57,61),(-68,72)],
    # Africa
    [(-18,36),(5,37),(30,32),(43,12),(51,2),(42,-18),(33,-34),(18,-35),(4,-29),(-8,-12),(-17,12)],
    # Eurasia
    [(-11,36),(-10,58),(10,71),(44,72),(72,77),(112,75),(145,67),(178,61),(179,48),(146,44),(128,35),(121,20),(106,9),(96,6),(80,9),(69,24),(53,28),(42,41),(24,39),(10,35)],
    # Arabian peninsula / India / SE Asia mass
    [(35,31),(58,27),(72,20),(80,8),(91,22),(101,15),(111,4),(122,1),(117,-8),(103,-5),(91,5),(76,8),(58,16),(45,12)],
    # Australia
    [(112,-11),(130,-10),(151,-23),(153,-37),(139,-44),(116,-35)],
    # Madagascar
    [(44,-12),(51,-16),(50,-26),(45,-25),(43,-18)],
    # Japan
    [(130,33),(136,36),(142,46),(146,44),(140,34)],
    # New Zealand
    [(166,-34),(178,-42),(173,-47),(164,-41)],
    # Britain
    [(-8,50),(1,50),(2,59),(-5,58)],
    # Indonesia / Philippines island groups
    [(95,5),(107,6),(119,1),(115,-7),(102,-6)],
    [(120,19),(126,18),(127,6),(122,5)],
    [(130,-2),(142,-3),(147,-8),(136,-10)],
]

ocean = Image.new("RGB", (W, H), (12, 55, 67))
pix = ocean.load()
for y in range(H):
    lat = 90 - y / H * 180
    for x in range(W):
        current = math.sin(x * .049 + math.sin(y * .031) * 2.1) + math.cos(y * .071 - x * .013)
        checker = ((x // 3 + y // 3) & 1)
        deep = 5 if abs(lat) > 63 else 0
        pix[x, y] = (10 + checker * 2, 48 + int(current * 3) - deep, 61 + int(current * 4) - deep)

mask = Image.new("1", (W, H), 0)
md = ImageDraw.Draw(mask)
for poly in continents:
    md.polygon([xy(*p) for p in poly], fill=1)

# One-pixel dark coastline and a second submerged shelf band.
expanded = mask.filter(ImageFilter.MaxFilter(7))
shelf = Image.new("1", (W, H), 0)
shelf.paste(expanded)
sp, mp = shelf.load(), mask.load()
for y in range(H):
    for x in range(W):
        if sp[x, y] and not mp[x, y]:
            pix[x, y] = (14, 72 + ((x + y) & 3), 77 + ((x * 3 + y) & 5))

land = Image.new("RGB", (W, H), (0, 0, 0))
lp = land.load()
for y in range(H):
    lat = 90 - y / H * 180
    for x in range(W):
        if not mp[x, y]:
            continue
        lon = x / W * 360 - 180
        n = (math.sin(lon * .19 + lat * .11) + .55 * math.cos(lon * .31 - lat * .17)
             + .28 * math.sin(lon * .73 + lat * .61))
        a = abs(lat)
        sahara = -18 < lon < 58 and 12 < lat < 34
        dryland = (112 < lon < 151 and -39 < lat < -15) or (53 < lon < 92 and 34 < lat < 48) or (-116 < lon < -99 and 25 < lat < 38)
        if a > 70 + n * 2.2: col = (181, 185, 147)
        elif a > 55 + n * 3.5: col = (51, 85, 62)
        elif sahara: col = (174 + int(n * 3), 140 + int(n * 4), 68)
        elif dryland and n < .95: col = (139 + int(n * 4), 119 + int(n * 3), 62)
        elif a < 16 + n * 1.5: col = (37, 104 + int(n * 5), 62)
        elif a < 32 and n < -.85: col = (108, 119, 60)
        else: col = (75 + int(n * 5), 113 + int(n * 7), 68)
        # Two-pixel material clusters, not single-pixel noise.
        step = 6 if ((x // 2 + y // 2 + int(n * 2)) & 7) == 0 else 0
        lp[x, y] = tuple(max(0, min(255, c + step)) for c in col)

coast = mask.filter(ImageFilter.MaxFilter(3))
cp = coast.load()
for y in range(H):
    for x in range(W):
        if mp[x, y]:
            edge = any(not mp[(x + dx) % W, min(H-1, max(0, y + dy))] for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)))
            pix[x, y] = (34, 49, 35) if edge else lp[x, y]

# Sparse authored mountain and river pixels keep the surface readable at 1:1.
draw = ImageDraw.Draw(ocean)
for lon0, lat0, lon1, lat1 in [(-122,54,-106,31),(-78,8,-69,-48),(8,46,28,43),(38,58,94,48),(69,34,96,29),(24,9,31,-30)]:
    pts=[]
    for i in range(28):
        t=i/27; lon=lon0+(lon1-lon0)*t; lat=lat0+(lat1-lat0)*t+math.sin(i*1.7)*.7
        x,y=xy(lon,lat)
        if 0<=x<W and 0<=y<H and mp[int(x),int(y)]: pts.append((x,y))
    if len(pts)>1: draw.line(pts, fill=(103,83,45), width=2)

OUT.parent.mkdir(parents=True, exist_ok=True)
ocean=ocean.quantize(colors=96,dither=Image.Dither.NONE).convert("RGB")
ocean.save(OUT)
print(f"GLOBE_MAP_V1_OK size={W}x{H} continents={len(continents)} mode=RGB")
