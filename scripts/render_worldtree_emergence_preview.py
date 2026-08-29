from pathlib import Path
from PIL import Image,ImageDraw

ROOT=Path(__file__).resolve().parents[1]
tree=Image.open(ROOT/'assets/enemies/arcade/worldtree-siege-atlas-v1.png').convert('RGBA').crop((0,0,1024,1024))
fx=Image.open(ROOT/'assets/fx/worldtree/worldtree-emergence-atlas-v2.png').convert('RGBA')
sky=Image.open(ROOT/'assets/scenery/skyview/forest-sun-skyview-pixel-v2.png').convert('RGB')
ground=Image.open(ROOT/'assets/forest-ground-tile-v1.png').convert('RGB')
W,H=320,420; TIMES=(.55,1.15,2.15,3.55,5.75,6.70)

def panel(t):
    out=Image.new('RGBA',(W,H));out.alpha_composite(sky.resize((W,188),Image.Resampling.LANCZOS).convert('RGBA'),(0,0))
    floor=Image.new('RGB',(W,H-188))
    for y in range(0,H-188,ground.height):
        for x in range(0,W,ground.width):floor.paste(ground,(x,y))
    out.alpha_composite(floor.convert('RGBA'),(0,188))
    draw=ImageDraw.Draw(out);draw.polygon(((0,176),(W,176),(W,211),(0,199)),fill=(28,57,27,255))
    rise=max(0,min(1,(t-1.15)/4.8))
    f=min(5,int(max(.01,rise)*6));cell=fx.crop((f*512,0,(f+1)*512,384)).resize((306,230),Image.Resampling.NEAREST)
    cell.putalpha(cell.getchannel('A').point(lambda a:round(a*(.18 if t<1.15 else min(1,.48+rise*1.4)))))
    out.alpha_composite(cell,(7,180))
    if rise>0:
        sprite=tree.resize((344,344),Image.Resampling.NEAREST)
        y=255+round((1-rise)**2*520)-round(344*.969)
        layer=Image.new('RGBA',(W,H));layer.alpha_composite(sprite,((W-344)//2,y))
        # Keep the same uncut source sprite, but hide pixels below the ground lip.
        alpha=layer.getchannel('A');clip=Image.new('L',(W,H));ImageDraw.Draw(clip).rectangle((0,0,W,359),fill=255)
        layer.putalpha(Image.composite(alpha,Image.new('L',(W,H)),clip));out=Image.alpha_composite(out,layer)
    d=ImageDraw.Draw(out);d.rounded_rectangle((9,9,101,33),4,fill=(12,25,15,220),outline=(218,166,72,255),width=1)
    phase='SKY' if t<1.15 else ('RISE' if t<5.95 else 'RETURN')
    d.text((16,14),f'{t:0.2f}s {phase}',fill=(255,239,176,255))
    return out.convert('RGB')

sheet=Image.new('RGB',(W*len(TIMES),H),(0,0,0))
for i,t in enumerate(TIMES):sheet.paste(panel(t),(i*W,0))
path=ROOT/'docs/previews/worldtree-emergence-v3-sky-rise-return.png';sheet.save(path);print(path)
