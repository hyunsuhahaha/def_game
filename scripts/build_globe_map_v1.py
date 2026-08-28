"""Build the stage-select globe from real Natural Earth coastlines.

Natural Earth 1:50m land and lake GeoJSON sources are checked into
assets/ui/sources. Natural Earth data is public domain. This builder preserves
real coastlines and island positions, then applies the project's stepped
cartoon-pixel material treatment without altering the geography.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import json
import math

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/ui/sources"
OUT = ROOT / "assets/ui/globe-world-pixel-v1.png"
W, H = 1024, 512

def xy(point):
    lon, lat = point[:2]
    return ((lon + 180) / 360 * W, (90 - lat) / 180 * H)

def polygon_sets(path):
    data = json.loads(path.read_text(encoding="utf-8"))
    for feature in data["features"]:
        geom = feature.get("geometry") or {}
        coords = geom.get("coordinates") or []
        if geom.get("type") == "Polygon":
            yield coords
        elif geom.get("type") == "MultiPolygon":
            yield from coords

def draw_polygons(target, polygons, outer, hole):
    draw = ImageDraw.Draw(target)
    count = 0
    for rings in polygons:
        if not rings:
            continue
        draw.polygon([xy(p) for p in rings[0]], fill=outer)
        for ring in rings[1:]:
            draw.polygon([xy(p) for p in ring], fill=hole)
        count += 1
    return count

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
land_count = draw_polygons(mask, polygon_sets(SOURCE / "ne_50m_land.geojson"), 1, 0)
# Restore major inland water bodies using the matching Natural Earth lake set.
lake_count = draw_polygons(mask, polygon_sets(SOURCE / "ne_50m_lakes.geojson"), 0, 1)

# A shallow coastal shelf separates the accurate coastline from deep water.
expanded = mask.filter(ImageFilter.MaxFilter(7))
sp, mp = expanded.load(), mask.load()
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
        dryland = ((112 < lon < 151 and -39 < lat < -15)
                   or (53 < lon < 92 and 34 < lat < 48)
                   or (-116 < lon < -99 and 25 < lat < 38))
        if a > 70 + n * 2.2: col = (181, 185, 147)
        elif a > 55 + n * 3.5: col = (51, 85, 62)
        elif sahara: col = (174 + int(n * 3), 140 + int(n * 4), 68)
        elif dryland and n < .95: col = (139 + int(n * 4), 119 + int(n * 3), 62)
        elif a < 16 + n * 1.5: col = (37, 104 + int(n * 5), 62)
        elif a < 32 and n < -.85: col = (108, 119, 60)
        else: col = (75 + int(n * 5), 113 + int(n * 7), 68)
        step = 6 if ((x // 2 + y // 2 + int(n * 2)) & 7) == 0 else 0
        lp[x, y] = tuple(max(0, min(255, c + step)) for c in col)

for y in range(H):
    for x in range(W):
        if mp[x, y]:
            edge = any(not mp[(x + dx) % W, min(H-1, max(0, y + dy))]
                       for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)))
            pix[x, y] = (34, 49, 35) if edge else lp[x, y]

# Geographic mountain chains are a quiet secondary material detail.
draw = ImageDraw.Draw(ocean)
for lon0, lat0, lon1, lat1 in [(-122,54,-106,31),(-78,8,-69,-48),(8,46,28,43),(38,58,94,48),(69,34,96,29),(24,9,31,-30)]:
    points=[]
    for i in range(36):
        t=i/35;lon=lon0+(lon1-lon0)*t;lat=lat0+(lat1-lat0)*t+math.sin(i*1.7)*.45
        x,y=xy((lon,lat))
        if 0<=x<W and 0<=y<H and mp[int(x),int(y)]: points.append((x,y))
    if len(points)>1: draw.line(points,fill=(103,83,45),width=1)

OUT.parent.mkdir(parents=True, exist_ok=True)
ocean=ocean.quantize(colors=96,dither=Image.Dither.NONE).convert("RGB")
ocean.save(OUT)
print(f"GLOBE_MAP_V1_OK size={W}x{H} land_polygons={land_count} lakes={lake_count} source=Natural_Earth_50m")
