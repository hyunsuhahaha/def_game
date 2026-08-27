from pathlib import Path
from PIL import Image, ImageChops
root=Path(__file__).resolve().parents[1]
atlas=Image.open(root/'assets/characters/ingame/philosopher-atlas-pixel-v2.png').convert('RGBA')
fx=Image.open(root/'assets/fx/philosopher/philosopher-sermon-fx-pixel-v1.png').convert('RGBA')
assert atlas.size==(576,384) and fx.size==(1152,192)
assert set(atlas.getchannel('A').getdata()) <= {0,255}
walk=[atlas.crop((i*96,0,(i+1)*96,192)) for i in range(6)]
action=[atlas.crop((i*96,192,(i+1)*96,384)) for i in range(6)]
assert len({ImageChops.difference(walk[0],f).getbbox() for f in walk[1:]})>2
for frames in (walk,action):
    for frame in frames:
        box=frame.getchannel('A').getbbox(); assert box and box[3]>=188
game=(root/'src/game.lua').read_text(encoding='utf-8')
mode=(root/'src/clearcut_mode.lua').read_text(encoding='utf-8')
assert 'philosopher-atlas-pixel-v2.png' in game
assert 'PhilosopherArt.channel' in mode and 'PhilosopherArt.draw' in mode
assert 'revivalSpread = self.revivalTimer > 0 and 1.5 or 1' in mode
print('PHILOSOPHER_ASSETS_OK frames=12 binary_alpha=true runtime_wired=true')
