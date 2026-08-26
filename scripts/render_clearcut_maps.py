"""Real Lua world/camera draw replay on offscreen GPU, plus map menu layout QA."""
from pathlib import Path
import json
from PIL import Image,ImageDraw,ImageFont
from headless_lua import run
from verify_forest_arcade_assets import replay
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'docs/previews'

def menu(path,size):
 canvas=Image.new('RGBA',size);bounds=[]
 for op in json.loads(path.read_text(encoding='utf-8')):
  layer=Image.new('RGBA',size);pen=ImageDraw.Draw(layer)
  color=tuple(round(c*255) for c in op['color']);args=op['args']
  if op['op']=='rectangle':
   x,y,w,h=args;opts={'fill':color} if op['mode']=='fill' else {'outline':color,'width':max(1,round(op['lineWidth']))}
   pen.rounded_rectangle((x,y,x+w,y+h),radius=op.get('radius',0),**opts)
  elif op['op']=='draw':
   image=Image.open(ROOT/op['file']).convert('RGBA');x,y,angle,sx,sy,ox,oy=args
   assert angle==0 and not op.get('shader')
   image=image.resize((round(image.width*sx),round(image.height*sy)),Image.Resampling.NEAREST)
   layer.paste(image,(round(x-ox*sx),round(y-oy*sy)),image)
  elif op['op']=='text':
   font=ImageFont.truetype(str(ROOT/op['file']),round(op['size']));x,y,w=args;lines=[]
   for para in op['text'].split('\n'):
    line=''
    for word in para.split(' '):
     candidate=(line+' '+word).strip()
     if w and line and font.getlength(candidate)>w:lines.append(line);line=word
     else:line=candidate
    lines.append(line)
   for line in lines:
    length=font.getlength(line);xx=x+(w-length)/2 if op['align']=='center' else x
    assert (not w or length<=w) and xx>=0 and xx+length<=size[0] and y+op['size']*1.3<=size[1],(line,size)
    pen.text((xx,y),line,font=font,fill=color,anchor='lt');bounds.append((line,xx,y,length,op['size']*1.3));y+=op['size']*1.3
  else:raise AssertionError(op['op'])
  canvas=Image.alpha_composite(canvas,layer)
 dest=path.with_name(path.name.replace('-draws.json','.png'));canvas.convert('RGB').save(dest)
 return bounds

def main():
 run(ROOT/'scripts/verify_clearcut_maps.lua','MAP_CAPTURE=true')
 ids=['forest','mangrove','madagascar','island']
 frames,renderer,shaders=replay([OUT/f'map-{name}-draws.json' for name in ids],(1280,720))
 (ROOT/'assets/maps').mkdir(exist_ok=True)
 board=Image.new('RGB',(1536,964),(21,32,31));pen=ImageDraw.Draw(board)
 font=ImageFont.truetype(str(ROOT/'assets/font-korean-bold.ttf'),25)
 labels=['온대 숲 / 기존 맵','맹그로브 / 얕은 물길','마다가스카르 / 붉은 땅','무인도 / 사방의 바다']
 for i,(name,frame) in enumerate(zip(ids,frames)):
  frame.save(OUT/f'map-{name}-v1.png')
  frame.resize((384,216),Image.Resampling.NEAREST).save(ROOT/f'assets/maps/{name}-preview-v1.png')
  if name!='forest':
   moving,_,_=replay([OUT/f'map-{name}-motion-{n}-draws.json' for n in range(1,6)],(1280,720))
   assert len({im.tobytes() for im in moving})>1,'ambient motion stalled'
   frame.save(OUT/f'map-{name}-motion-v1.gif',save_all=True,append_images=moving,duration=220,loop=0)
  x,y=(i%2)*768,(i//2)*482
  pen.text((x+16,y+12),labels[i],font=font,fill=(232,223,178))
  board.paste(frame.resize((768,432),Image.Resampling.NEAREST),(x,y+50))
 board.save(OUT/'clearcut-maps-v1.png')
 for name in ['crocodile','angryLemur']:
  action,_,_=replay([OUT/f'biome-action-{name}-{n}-draws.json' for n in range(15)],(1280,720))
  assert len({im.tobytes() for im in action})>8,'attack animation stalled'
  action=[im.crop((280,160,1000,560)) for im in action]
  action[0].save(OUT/f'biome-action-{name}-v1.gif',save_all=True,append_images=action[1:],duration=100,loop=0)
  contact=Image.new('RGB',(1440,800))
  for i,frame in enumerate([0,3,6,9]):contact.paste(action[frame],((i%2)*720,(i//2)*400))
  contact.save(OUT/f'biome-action-{name}-v1.png')
 run(ROOT/'scripts/verify_clearcut_maps.lua','MAP_UI_CAPTURE=true')
 layouts={str(w):menu(OUT/f'map-select-{w}-draws.json',(w,h)) for w,h in [(960,540),(1280,720)]}
 (OUT/'clearcut-maps-verification.json').write_text(json.dumps(dict(renderer=renderer,shaders=shaders,maps=ids,native_tree_species=9,attacks=['crocodile','angryLemur'],layout=layouts,window='none',capture='Lua world, camera, player and combat overlay; HUD excluded'),ensure_ascii=False,indent=2),encoding='utf-8')
 print('CLEARCUT_MAP_RENDER_OK maps=4 motion=3 attacks=2 menu=960x540/1280x720 shaders='+str(shaders)+' renderer='+renderer)
if __name__=='__main__':main()
