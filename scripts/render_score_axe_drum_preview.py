"""Replay the real Lua draw calls with nearest-neighbor rotation, no window."""
from pathlib import Path
import json, math
from PIL import Image, ImageDraw, ImageFont, ImageChops
from headless_lua import run

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"docs"/"previews"
CAPTURE=OUT/"score-axe-contact-v4-draws.json"

def rgba(values):return tuple(max(0,min(255,round(value*255)))for value in values)

def replay(capture=CAPTURE):
    canvas=Image.new("RGBA",(960,360),(0,0,0,255));draw=ImageDraw.Draw(canvas,"RGBA")
    for op in json.loads(capture.read_text(encoding="utf-8")):
        kind,args,color=op["op"],op["args"],rgba(op["color"])
        if kind=="rectangle":
            x,y,w,h=args;draw.rectangle((x,y,x+w,y+h),fill=color)
        elif kind=="ellipse":
            x,y,rx,ry=args;draw.ellipse((x-rx,y-ry,x+rx,y+ry),fill=color)
        elif kind=="text":
            x,y,_=args;font=ImageFont.truetype(str(ROOT/op["file"]),round(op["size"]));draw.text((x,y),op["text"],font=font,fill=color)
        elif kind=="draw":
            image=Image.open(ROOT/op["file"]).convert("RGBA")
            qx,qy,qw,qh=map(round,op.get("quad",(0,0,image.width,image.height))[:4]);image=image.crop((qx,qy,qx+qw,qy+qh))
            x,y=args[:2];angle=args[2]if len(args)>2 else 0;sx=args[3]if len(args)>3 else 1;sy=args[4]if len(args)>4 else sx
            ox=args[5]if len(args)>5 else 0;oy=args[6]if len(args)>6 else 0
            image=image.resize((max(1,round(image.width*abs(sx))),max(1,round(image.height*abs(sy)))),Image.Resampling.NEAREST)
            pivot=(round(ox*abs(sx)),round(oy*abs(sy)))
            if sx<0:image=image.transpose(Image.Transpose.FLIP_LEFT_RIGHT);pivot=(image.width-pivot[0],pivot[1])
            if sy<0:image=image.transpose(Image.Transpose.FLIP_TOP_BOTTOM);pivot=(pivot[0],image.height-pivot[1])
            rgb=ImageChops.multiply(image.convert("RGB"),Image.new("RGB",image.size,color[:3]));alpha=image.getchannel("A").point(lambda a:a*color[3]//255)
            image=rgb.convert("RGBA");image.putalpha(alpha)
            layer=Image.new("RGBA",canvas.size,(0,0,0,0));layer.alpha_composite(image,(round(x-pivot[0]),round(y-pivot[1])))
            if angle:layer=layer.rotate(-math.degrees(angle),resample=Image.Resampling.NEAREST,center=(round(x),round(y)))
            canvas.alpha_composite(layer)
    return canvas

if __name__=="__main__":
    run(ROOT/"scripts"/"capture_score_axe_drum.lua")
    image=replay();image.save(OUT/"score-axe-contact-v4-display-scale.png")
    image.crop((0,100,960,350)).resize((1920,500),Image.Resampling.NEAREST).save(OUT/"score-axe-contact-v4-2x.png")
    print("SCORE_AXE_DRUM_RENDER_OK v4 display=960x360 enlarged=1920x500 window=none")
