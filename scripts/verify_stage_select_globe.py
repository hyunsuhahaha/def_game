from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
image=Image.open(ROOT/'assets/ui/globe-world-pixel-v1.png').convert('RGB')
assert image.size==(1024,512),image.size
colors=len(set(image.get_flattened_data()))
assert 35<=colors<=180,colors
shader=(ROOT/'assets/shaders/stage-select-globe.glsl').read_text(encoding='utf-8')
lua=(ROOT/'src/stage_select_globe.lua').read_text(encoding='utf-8')
select=(ROOT/'src/clearcut_map_select.lua').read_text(encoding='utf-8')
maps=(ROOT/'src/clearcut_maps.lua').read_text(encoding='utf-8')
builder=(ROOT/'scripts/build_globe_map_v1.py').read_text(encoding='utf-8')
assert 'atan(world.x, world.z)' in shader and 'globeYaw' in shader and 'globePitch' in shader
assert 'function Globe.mousemoved' in lua and 'function Globe.mousereleased' in lua and 's.moved' in lua
assert 'z>.045' in lua and 'wrap(s.dragYaw-totalX' in lua
assert 'function Globe.wheelmoved' in lua and '.70,1.15' in lua
assert 'function Globe.routes' in lua and 'routeOrder={1,2,3,4}' in lua and 'drawRoutes(game,w,h' in lua
assert maps.count('globeLat=')==4 and maps.count('globeLon=')==4
assert 'local displayIndex=hover or game.clearcutMapFocus' in select and 'imageFor(def)' in select
assert 'isMapCleared(m.def.id)' in select and '완료' in select
assert 'globe-stage-landmarks-pixel-v1.png' in select and 'landmarkQuads[m.index]' in select
landmarks=Image.open(ROOT/'assets/ui/globe-stage-landmarks-pixel-v1.png').convert('RGBA')
assert landmarks.size==(320,64),landmarks.size
assert len({p[:3] for p in landmarks.get_flattened_data() if p[3]})>=30
for source in ('ne_50m_land.geojson','ne_50m_lakes.geojson'):
    path=ROOT/'assets/ui/sources'/source
    assert path.stat().st_size>500_000,(source,path.stat().st_size)
assert 'Natural Earth' in builder and 'continents = [' not in builder
print(f'STAGE_SELECT_GLOBE_OK map=1024x512 colors={colors} source=NaturalEarth50m rotation=360 zoom=.70..1.15 active_landmarks=4 atlas_cells=5 routes=dotted cleared=visible')
