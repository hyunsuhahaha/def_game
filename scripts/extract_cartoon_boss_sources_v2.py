"""Extract the locked v2 cartoon boss models from their source boards.

This is a source-preparation step only. Final atlases are built deterministically
from the resulting transparent cutouts by build_biome_boss_atlases_v2.py.
Optional source-preparation dependencies: opencv-python-headless and rembg.
The checked-in transparent cutouts and final atlases do not need them at runtime.
"""
from pathlib import Path
import cv2
import numpy as np
from PIL import Image
from rembg import remove

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets/enemies/biome-bosses/concepts"
OUT = SRC / "cartoon-v2"

SPECS = {
    "beginner": ("tree-boss-cartoon-models-v2.png", (0, 150, 700, 874)),
    "forest": ("tree-boss-cartoon-models-v2.png", (610, 0, 926, 1024)),
    "mangrove": ("biome-boss-cartoon-models-v2.png", (890, 0, 646, 590)),
    "madagascar": ("biome-boss-cartoon-models-v2.png", (80, 380, 720, 644)),
    "island": ("biome-boss-cartoon-models-v2.png", (670, 380, 866, 644)),
}

def extract(source_path, rect):
    image = cv2.imread(str(source_path), cv2.IMREAD_COLOR)
    x, y, w, h = rect
    crop = image[y:y+h, x:x+w].copy()
    rgba=np.asarray(remove(Image.fromarray(cv2.cvtColor(crop,cv2.COLOR_BGR2RGB)).convert("RGBA"),alpha_matting=False))
    alpha=np.where(rgba[:,:,3]>=160,255,0).astype(np.uint8)
    alpha=cv2.morphologyEx(alpha,cv2.MORPH_CLOSE,np.ones((3,3),np.uint8))
    # Remove disconnected glow flecks, keeping the largest coherent model.
    count, labels, stats, _ = cv2.connectedComponentsWithStats(alpha, 8)
    if count > 1:
        keep = 1 + np.argmax(stats[1:,cv2.CC_STAT_AREA])
        alpha = np.where(labels==keep,255,0).astype(np.uint8)
    alpha=cv2.dilate(alpha,np.ones((3,3),np.uint8),iterations=1)
    rgba=cv2.cvtColor(rgba,cv2.COLOR_RGBA2BGRA);rgba[:,:,3]=alpha
    ys,xs=np.nonzero(alpha)
    pad=8; x0=max(0,xs.min()-pad);x1=min(crop.shape[1],xs.max()+pad+1);y0=max(0,ys.min()-pad);y1=min(crop.shape[0],ys.max()+pad+1)
    return rgba[y0:y1,x0:x1]

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    for name,(board,rect) in SPECS.items():
        cutout=extract(SRC/board,rect)
        # Remove board neighbours that overlap the rectangular crop but are not
        # part of this model. Coordinates are intentionally tied to the locked
        # v2 boards above.
        if name=="forest": cutout[650:,:34,3]=0
        elif name=="mangrove": cutout[430:,:175,3]=0
        elif name=="island": cutout[:92,430:,3]=0
        path=OUT/f"{name}-source-v2.png";cv2.imwrite(str(path),cutout)
        print("WROTE",path.relative_to(ROOT),cutout.shape[1],cutout.shape[0])

if __name__ == "__main__": main()
