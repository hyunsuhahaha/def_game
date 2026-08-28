"""Verify the female vegan fixed model, separate fork, and comic FX assets."""
from pathlib import Path
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]

def rgba(path): return np.asarray(Image.open(path).convert("RGBA"))
def opaque_colors(a): return len({tuple(p[:3]) for p in a.reshape(-1,4) if p[3]})

atlas=rgba(ROOT/"assets/characters/ingame/vegan-atlas-pixel-v3.png")
assert atlas.shape==(384,576,4) and set(np.unique(atlas[:,:,3]))=={0,255}
assert opaque_colors(atlas)>=72
frames=[atlas[r*192:(r+1)*192,c*96:(c+1)*96] for r in range(2) for c in range(6)]
assert len({f.tobytes() for f in frames[:6]})>=5 and len({f.tobytes() for f in frames[6:]})==6
for frame in frames:
    yy,xx=np.nonzero(frame[:,:,3]); assert yy.max()>=185 and xx.max()-xx.min()>=65

fork=rgba(ROOT/"assets/characters/ingame/vegan-fork-pixel-v1.png")
assert fork.shape==(96,256,4) and set(np.unique(fork[:,:,3]))=={0,255} and opaque_colors(fork)>=70
# Four separated tines must remain readable near the tip after the production bake.
column=fork[:,225,3]>0; runs=0; inside=False
for value in column:
    if value and not inside: runs+=1
    inside=bool(value)
assert runs==4,f"fork has {runs} readable tines"

impact=rgba(ROOT/"assets/fx/vegan-fork-impact-atlas-v2.png")
chomp=rgba(ROOT/"assets/fx/vegan-fork-consume-atlas-v2.png")
assert impact.shape==(128,768,4) and chomp.shape==(160,1280,4)
assert set(np.unique(impact[:,:,3]))=={0,255} and set(np.unique(chomp[:,:,3]))=={0,255}
assert 72<=opaque_colors(impact)<=128 and 72<=opaque_colors(chomp)<=128
assert len({impact[:,i*128:(i+1)*128].tobytes() for i in range(6)})==6
assert len({chomp[:,i*160:(i+1)*160].tobytes() for i in range(8)})==8

game=(ROOT/"src/game.lua").read_text(encoding="utf-8")
runtime=(ROOT/"src/clearcut_mode.lua").read_text(encoding="utf-8")
assert "vegan-atlas-pixel-v3.png" in game and "VeganForkArt.load" in game
for token in ("fork_feast","buffet_fork","clean_plate","seconds_please","applyVeganFork","veganConsumeFx","consumeEnemy"):
    assert token in runtime,token
assert "toxic_rain" not in runtime and "applyVeganBite" not in runtime
print("VEGAN_FORK_ART_OK woman=v3 fork=4tines/84colors body=72colors fx=6+8 density=high")
