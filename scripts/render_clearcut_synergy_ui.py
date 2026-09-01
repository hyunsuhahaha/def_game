"""Shared headless UI command renderer; former synergy preview entry is retired."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageChops
import json,math
from headless_lua import run
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'docs/previews'
def rgba(c): return tuple(max(0,min(255,round(v*255))) for v in c)
def render_ui(path,size,background=(0,0,0,255)):
 canvas=Image.new('RGBA',size,background);draw=ImageDraw.Draw(canvas,'RGBA')
 def composite_primitive(painter):
  nonlocal draw
  layer=Image.new('RGBA',size,(0,0,0,0));painter(ImageDraw.Draw(layer,'RGBA'));canvas.alpha_composite(layer);draw=ImageDraw.Draw(canvas,'RGBA')
 for op in json.loads(Path(path).read_text(encoding='utf-8')):
  kind,args,color=op['op'],op['args'],rgba(op['color'])
  if kind=='rectangle':
   x,y,w,h=args;x2,y2=x+w,y+h;box=(min(x,x2),min(y,y2),max(x,x2),max(y,y2));radius=op.get('radius') or 0
   radius=min(radius,(box[2]-box[0])/2,(box[3]-box[1])/2)
   if op.get('mode')=='line':
    composite_primitive(lambda d:d.rounded_rectangle(box,radius=radius,outline=color,width=max(1,round(op.get('lineWidth',1)))) if radius>=1 else d.rectangle(box,outline=color,width=max(1,round(op.get('lineWidth',1)))))
   else: composite_primitive(lambda d:d.rounded_rectangle(box,radius=radius,fill=color) if radius>=1 else d.rectangle(box,fill=color))
  elif kind=='ellipse':
   x,y,rx,ry=args;box=(x-rx,y-ry,x+rx,y+ry)
   if op.get('mode')=='line':composite_primitive(lambda d:d.ellipse(box,outline=color,width=max(1,round(op.get('lineWidth',1)))))
   else:composite_primitive(lambda d:d.ellipse(box,fill=color))
  elif kind=='line': composite_primitive(lambda d:d.line(args,fill=color,width=max(1,round(op.get('lineWidth',1))),joint='curve'))
  elif kind=='polygon':
   points=list(zip(args[::2],args[1::2]));composite_primitive(lambda d:d.polygon(points,fill=color if op.get('mode')!='line' else None,outline=color))
  elif kind=='text':
   x,y,w=args;font=ImageFont.truetype(str(ROOT/op['file']),max(8,round(op['size'])))
   text=str(op.get('text',''));align=op.get('align','left')
   if w and w>0:
    lines=[];line=''
    for ch in text:
     trial=line+ch
     if line and draw.textbbox((0,0),trial,font=font)[2]>w:lines.append(line);line=ch
     else:line=trial
    lines.append(line);text='\n'.join(lines)
   tx=x+w/2 if align=='center' else (x+w if align=='right' else x)
   composite_primitive(lambda d:d.multiline_text((tx,y),text,font=font,fill=color,align=align,anchor='ma' if align=='center' else ('ra' if align=='right' else 'la')))
  elif kind=='draw':
   image=Image.open(ROOT/op['file']).convert('RGBA');x,y=args[:2]
   quad=op.get('quad')
   if quad:
    qx,qy,qw,qh=map(round,quad[:4]);image=image.crop((qx,qy,qx+qw,qy+qh))
   sx=args[3] if len(args)>3 else 1;sy=args[4] if len(args)>4 else sx
   out=image.resize((max(1,round(image.width*abs(sx))),max(1,round(image.height*abs(sy)))),Image.Resampling.NEAREST)
   if sx<0:out=out.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
   if sy<0:out=out.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
   rgb=ImageChops.multiply(out.convert('RGB'),Image.new('RGB',out.size,color[:3]))
   alpha=out.getchannel('A').point(lambda a:a*color[3]//255);out=rgb.convert('RGBA');out.putalpha(alpha)
   ox=args[5] if len(args)>5 else 0;oy=args[6] if len(args)>6 else 0
   canvas.alpha_composite(out,(round(x-ox*abs(sx)),round(y-oy*abs(sy))))
 return canvas if background[3]==0 else canvas.convert('RGB')
def main():
 run(ROOT/'scripts/verify_clearcut_synergies.lua')
 print('CLEARCUT_SYNERGY_UI_REMOVED shared_renderer=available window=none')
if __name__=='__main__':main()
