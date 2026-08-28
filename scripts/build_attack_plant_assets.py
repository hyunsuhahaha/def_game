from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets/enemies/concepts/attack-plants"
OUT = ROOT / "assets/enemies/arcade"
PRE = ROOT / "docs/previews/attack-plants"
CELL, FOOT = 160, 152

SPECS = {
    "thornHunter": ("thorn-hunter-source-v1.png", 126, 142),
    "hammerBloom": ("hammer-bloom-source-v1.png", 118, 142),
    "seedPod": ("seed-pod-source-v1.png", 116, 138),
    "bambooCannon": ("bamboo-cannon-source-v1.png", 126, 138),
    "resinSprayer": ("resin-sprayer-source-v1.png", 122, 140),
}

def fitted(path, width, height):
    im = Image.open(path).convert("RGBA")
    box = im.getbbox(); im = im.crop(box)
    im.thumbnail((width, height), Image.Resampling.LANCZOS)
    # Shared compact arcade palette, hard alpha and no translucent halo.
    rgb = im.convert("RGB").quantize(colors=88, method=Image.Quantize.MEDIANCUT).convert("RGB")
    a = im.getchannel("A").point(lambda v: 255 if v >= 70 else 0)
    rgb.putalpha(a)
    return rgb

def pose(base, kind, frame, action):
    canvas = Image.new("RGBA", (CELL, CELL))
    bw, bh = base.size
    x, y = (CELL-bw)//2, FOOT-bh
    canvas.alpha_composite(base, (x, y))
    if not action:
        dx = (-1,0,1,0,-1,0)[frame]
        if dx:
            shifted=Image.new("RGBA",canvas.size); shifted.alpha_composite(canvas,(dx,0)); canvas=shifted
        return canvas
    # Rooted feet stay planted; only the readable upper weapon/body performs.
    pivot = 112
    upper = canvas.crop((0,0,CELL,pivot))
    lower = canvas.crop((0,pivot,CELL,CELL))
    if kind == "hammerBloom":
        angles=(-8,-15,-22,18,10,3); shifts=(-3,-6,-9,8,5,1)
        upper=upper.rotate(angles[frame],resample=Image.Resampling.NEAREST,center=(80,108),expand=False)
        ox=shifts[frame]
    elif kind == "thornHunter":
        angles=(-5,-10,-14,13,7,2); shifts=(-2,-5,-7,9,5,1)
        upper=upper.rotate(angles[frame],resample=Image.Resampling.NEAREST,center=(80,108),expand=False); ox=shifts[frame]
    elif kind == "seedPod":
        scales=(1.02,1.08,1.15,.91,.97,1.0); s=scales[frame]
        upper=upper.resize((round(CELL*s),round(pivot*(2-s*.55))),Image.Resampling.NEAREST); ox=(CELL-upper.width)//2
    elif kind == "bambooCannon":
        sx=(.93,.85,.78,1.18,1.08,1.0)[frame]
        upper=upper.resize((round(CELL*sx),pivot),Image.Resampling.NEAREST); ox=(CELL-upper.width)//2 + (10 if frame==3 else 0)
    else:
        sx=(1.02,1.07,1.12,.94,.98,1.0)[frame]
        upper=upper.resize((round(CELL*sx),round(pivot*(2-sx*.55))),Image.Resampling.NEAREST); ox=(CELL-upper.width)//2
    out=Image.new("RGBA",canvas.size); out.alpha_composite(lower,(0,pivot)); out.alpha_composite(upper,(ox,0))
    return out

def build_nature_fx():
    # Image-authored source, normalized onto the same compact arcade grid.
    source=Image.open(ROOT/"assets/fx/concepts/nature-counterattack-source-v1.png").convert("RGBA")
    halves=(source.crop((0,0,source.width//2,source.height)),source.crop((source.width//2,0,source.width,source.height)))
    objects=[]
    for half,size in zip(halves,((132,126),(132,105))):
        alpha=half.getchannel("A").point(lambda v:255 if v>=150 else 0);half.putalpha(alpha);half=half.crop(half.getbbox());half.thumbnail(size,Image.Resampling.LANCZOS)
        rgb=half.convert("RGB").quantize(colors=72,method=Image.Quantize.MEDIANCUT).convert("RGB");rgb.putalpha(half.getchannel("A").point(lambda v:255 if v>=90 else 0));objects.append(rgb)
    root,branch=objects
    sheet=Image.new("RGBA",(CELL*6,CELL*2));
    for f in range(6):
        grow=(.16,.32,.52,.74,.91,1)[f]; r=root.resize((root.width,max(3,round(root.height*grow))),Image.Resampling.NEAREST)
        sheet.alpha_composite(r,(f*CELL+(CELL-r.width)//2,FOOT-r.height))
        fall=(.02,.17,.36,.58,.8,1)[f]; y=round(-branch.height+(FOOT+branch.height)*fall)
        sheet.alpha_composite(branch,(f*CELL+(CELL-branch.width)//2,y))
    path=ROOT/"assets/fx/nature-counterattack-atlas-v1.png"; path.parent.mkdir(parents=True,exist_ok=True); sheet.save(path)

def main():
    OUT.mkdir(parents=True,exist_ok=True); PRE.mkdir(parents=True,exist_ok=True)
    for kind,(name,w,h) in SPECS.items():
        base=fitted(SRC/name,w,h); sheet=Image.new("RGBA",(CELL*6,CELL*2))
        for row in range(2):
            for f in range(6): sheet.alpha_composite(pose(base,kind,f,row==1),(f*CELL,row*CELL))
        sheet.save(OUT/f"{kind}-atlas-v1.png")
        sheet.resize((sheet.width*2,sheet.height*2),Image.Resampling.NEAREST).save(PRE/f"{kind}-atlas-v1-2x.png")
    build_nature_fx()

if __name__ == "__main__": main()
