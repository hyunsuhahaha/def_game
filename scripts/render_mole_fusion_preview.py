"""Render the real Lua burrow/claw draw calls without opening a game window."""
from pathlib import Path
import json, math, os
from PIL import Image, ImageChops
from headless_lua import run

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"docs/previews"
CAPTURE=OUT/"mole-fusion-v1-draws.json"

def tinted(image,color):
    rgba=tuple(max(0,min(255,round(value*255))) for value in color)
    return ImageChops.multiply(image,Image.new("RGBA",image.size,rgba))

def draw_command(canvas,op):
    qx,qy,w,h,_,_=op["quad"]
    source=Image.open(ROOT/op["file"]).convert("RGBA").crop((qx,qy,qx+w,qy+h))
    x,y,angle,sx,sy,ox,oy=(op["args"]+[0,1,1,0,0])[:7]
    width=max(1,round(w*abs(sx)));height=max(1,round(h*abs(sy)))
    source=source.resize((width,height),Image.Resampling.NEAREST)
    pivot_x,pivot_y=ox*abs(sx),oy*abs(sy)
    if sx<0: source=source.transpose(Image.Transpose.FLIP_LEFT_RIGHT);pivot_x=width-pivot_x
    if sy<0: source=source.transpose(Image.Transpose.FLIP_TOP_BOTTOM);pivot_y=height-pivot_y
    source=tinted(source,op["color"])
    radius=math.ceil(max(pivot_x,width-pivot_x,pivot_y,height-pivot_y))+3
    layer=Image.new("RGBA",(radius*2,radius*2))
    layer.alpha_composite(source,(round(radius-pivot_x),round(radius-pivot_y)))
    if angle: layer=layer.rotate(-math.degrees(angle),Image.Resampling.NEAREST,expand=False)
    canvas.alpha_composite(layer,(round(x-radius),round(y-radius)))

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    os.environ["MOLE_FUSION_CAPTURE"]=str(CAPTURE)
    run(ROOT/"scripts/verify_mole_fusion.lua")
    commands=json.loads(CAPTURE.read_text(encoding="utf-8"))
    canvas=Image.new("RGBA",(400,300),(104,136,54,255))
    for op in commands:
        assert op["op"]=="draw" and op["filter"]=="nearest"
        draw_command(canvas,op)
    actual=OUT/"mole-fusion-v1-display-scale.png"
    zoom=OUT/"mole-fusion-v1-3x.png"
    canvas.convert("RGB").save(actual)
    canvas.crop((60,20,340,240)).resize((840,660),Image.Resampling.NEAREST).convert("RGB").save(zoom)
    CAPTURE.unlink()
    print("MOLE_FUSION_PREVIEW_OK window=none actual=400x300 zoom=3x draws="+str(len(commands)))

if __name__=="__main__":main()
