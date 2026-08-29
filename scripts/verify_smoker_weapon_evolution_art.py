"""Quality and animation gates for max-rank smoker weapon atlases."""
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
equipment=Image.open(ROOT/'assets/characters/ingame/smoker-weapon-evolution-equipment-v1.png').convert('RGBA')
fx=Image.open(ROOT/'assets/effects/smoker-weapon-evolution-fx-v1.png').convert('RGBA')
assert equipment.size==(256,96) and fx.size==(1152,576)
assert set(equipment.getchannel('A').get_flattened_data()) <= {0,255}

for index in range(2):
 cell=equipment.crop((index*128,0,(index+1)*128,96));pixels=[p for p in cell.get_flattened_data() if p[3]]
 assert len(pixels)>800,(index,len(pixels));assert len({p[:3] for p in pixels})>=16,(index,len({p[:3] for p in pixels}))

rows=[]
for row in range(3):
 signatures=[]
 for frame in range(6):
  cell=fx.crop((frame*192,row*192,(frame+1)*192,(row+1)*192));alpha=cell.getchannel('A')
  assert alpha.getbbox(),(row,frame);signatures.append(bytes(alpha.get_flattened_data()))
 assert len(set(signatures))==6,"animation row repeats a static silhouette: %d"%row
 rows.append(signatures)

burst=fx.crop((0,384,1152,576));colors={p[:3] for p in burst.get_flattened_data() if p[3]}
for expected in [(255,67,41),(57,222,235),(104,232,86),(245,76,196)]:
 assert expected in colors,"firework lost multicolour channel %r"%(expected,)
print('SMOKER_WEAPON_EVOLUTION_ART_OK equipment=2 colors>=16 fx=3x6 silhouettes=animated fireworks=multicolour')
