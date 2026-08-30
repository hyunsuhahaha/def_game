"""Replay the real Lua synergy draft/HUD draw paths without opening a window."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageChops
import json,math
from headless_lua import run
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'docs/previews'
def rgba(c): return tuple(max(0,min(255,round(v*255))) for v in c)
def render_ui(path,size):
 canvas=Image.new('RGBA',size,(0,0,0,255));draw=ImageDraw.Draw(canvas,'RGBA')
 def composite_primitive(painter):
  nonlocal draw
  layer=Image.new('RGBA',size,(0,0,0,0));painter(ImageDraw.Draw(layer,'RGBA'));canvas.alpha_composite(layer);draw=ImageDraw.Draw(canvas,'RGBA')
 for op in json.loads(Path(path).read_text(encoding='utf-8')):
  kind,args,color=op['op'],op['args'],rgba(op['color'])
  if kind=='rectangle':
   x,y,w,h=args;box=(x,y,x+w,y+h);radius=op.get('radius') or 0
   if op.get('mode')=='line': composite_primitive(lambda d:d.rounded_rectangle(box,radius=radius,outline=color,width=max(1,round(op.get('lineWidth',1)))))
   else: composite_primitive(lambda d:d.rounded_rectangle(box,radius=radius,fill=color))
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
 return canvas.convert('RGB')
def main():
 run(ROOT/'scripts/verify_clearcut_synergies.lua')
 run(ROOT/'scripts/capture_clearcut_synergy_ui.lua')
 draft=render_ui(OUT/'clearcut-synergy-draft-ui-draws.json',(1280,720));hud=render_ui(OUT/'clearcut-synergy-hud-ui-draws.json',(520,520))
 icons=render_ui(OUT/'clearcut-synergy-hud-icons-only-draws.json',(220,520))
 branch=render_ui(OUT/'clearcut-synergy-branch-ui-draws.json',(1280,720))
 draft.save(OUT/'clearcut-synergy-draft-ui-v3.png');hud.save(OUT/'clearcut-synergy-hud-ui-v3.png');icons.save(OUT/'clearcut-synergy-hud-icons-only-v3.png');branch.save(OUT/'clearcut-synergy-branch-ui-v3.png')
 canvas=Image.new('RGB',(1280,1280),(18,25,22));canvas.paste(draft,(0,0));canvas.paste(hud,(0,740))
 draw=ImageDraw.Draw(canvas);f=ImageFont.truetype(str(ROOT/'assets/font-korean-regular.ttf'),18)
 draw.text((540,780),'왼쪽 HUD는 엠블럼만 · 설명은 아이콘 호버 시 표시',font=f,fill=(203,218,190))
 canvas.save(OUT/'clearcut-synergy-ui-v3.png')
 print('CLEARCUT_SYNERGY_UI_RENDER_OK renderer=Pillow-command-replay shaders=0 window=none')
if __name__=='__main__':main()
