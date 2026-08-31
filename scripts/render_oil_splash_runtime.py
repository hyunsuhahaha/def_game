"""Replay the code-native oil and flame draw calls without opening a window."""
from pathlib import Path
import json, math
from PIL import Image, ImageDraw, ImageChops
from headless_lua import run

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"docs"/"previews"
CAPTURE=OUT/"oil-splash-runtime-v3-draws.json"

def rgba(values):
    return tuple(max(0,min(255,round(value*255))) for value in values)

run(ROOT/"scripts"/"capture_oil_splash_runtime.lua")
canvas=Image.new("RGBA",(1200,420),(0,0,0,255))
draw=ImageDraw.Draw(canvas,"RGBA")
for op in json.loads(CAPTURE.read_text(encoding="utf-8")):
    kind,args,color=op["op"],op["args"],rgba(op["color"])
    if kind=="rectangle":
        x,y,w,h=args;draw.rectangle((x,y,x+w,y+h),fill=color)
    elif kind=="polygon":
        draw.polygon([(args[i],args[i+1]) for i in range(0,len(args),2)],fill=color)
    elif kind=="draw":
        sprite=Image.open(ROOT/op["file"]).convert("RGBA")
        qx,qy,qw,qh=map(round,op.get("quad",(0,0,sprite.width,sprite.height))[:4])
        sprite=sprite.crop((qx,qy,qx+qw,qy+qh))
        x,y=args[:2];angle=args[2]if len(args)>2 else 0;sx=args[3]if len(args)>3 else 1;sy=args[4]if len(args)>4 else sx
        ox=args[5]if len(args)>5 else 0;oy=args[6]if len(args)>6 else 0
        sprite=sprite.resize((max(1,round(sprite.width*abs(sx))),max(1,round(sprite.height*abs(sy)))),Image.Resampling.NEAREST)
        pivot=(round(ox*abs(sx)),round(oy*abs(sy)))
        rgb=ImageChops.multiply(sprite.convert("RGB"),Image.new("RGB",sprite.size,color[:3]))
        alpha=sprite.getchannel("A").point(lambda a:a*color[3]//255);sprite=rgb.convert("RGBA");sprite.putalpha(alpha)
        layer=Image.new("RGBA",canvas.size,(0,0,0,0));layer.alpha_composite(sprite,(round(x-pivot[0]),round(y-pivot[1])))
        if angle:layer=layer.rotate(-math.degrees(angle),resample=Image.Resampling.NEAREST,center=(round(x),round(y)))
        canvas.alpha_composite(layer)
image=canvas.convert("RGB")
image.save(OUT/"oil-fire-runtime-v3-actual.png")
image.crop((385,90,720,330)).resize((1340,960),Image.Resampling.NEAREST).save(OUT/"oil-fire-runtime-v3-4x.png")
print("OIL_FIRE_RUNTIME_RENDER_OK actual=1200x420 enlarged=1340x960 window=none")
