"""Bake environmental species; original concepts preserved, no game window."""
from pathlib import Path
import json
import numpy as np
import moderngl
from PIL import Image,ImageDraw
from build_cigarette_pixel_sprite import VERTEX,love_fragment,render
from build_forest_enemy_atlases import make_palette,make_lut
ROOT=Path(__file__).resolve().parents[1]
SPECS=[
 ('parrot',(192,160),.91,['bb3026','e56732','25395e','376eb0','a68535','eac35c','e6d8b2','313036']),
 ('lemur',(192,192),.91,['747774','a5a399','c6beb0','e2d9c6','383941','252730','a88738','d8a54e']),
 ('crab',(128,112),.91,['b34d2a','d6843c','e2ae69','873427','542c2b','e7d5ab','372a26','a9673f']),
 ('traveller',(256,224),.91,['3f6540','71833c','a4a45a','28503a','7d6037','a57e45','513f2e','343b2b']),
]
def main():
 ctx=moderngl.create_standalone_context()
 shader=ctx.program(vertex_shader=VERTEX,fragment_shader=love_fragment(ROOT/'assets/shaders/forest-arcade-bake.glsl'))
 for k,v in dict(paletteLut=1,phase=0,motion=0,actionRow=0,chromaKey=0,outlinePixels=2).items():shader[k].value=v
 board=Image.new('RGB',(1200,570),(47,57,38));pen=ImageDraw.Draw(board);report=[]
 for i,(name,size,anchor,materials) in enumerate(SPECS):
  shader['outlinePixels'].value=2 if name=='traveller' else 3
  source=Image.open(ROOT/f'assets/scenery/biomes/concepts/{name}-v1.png').convert('RGBA');a=np.asarray(source)
  assert a[:,:,3].min()==0
  yy,xx=np.nonzero(a[:,:,3]>=180);crop=(int(xx.min()),int(yy.min()),int(xx.max()-xx.min()+1),int(yy.max()-yy.min()+1))
  foot=round(size[1]*anchor);fit=min((size[0]-12)/crop[2],(foot-8)/crop[3]);bw,bh=round(crop[2]*fit),round(crop[3]*fit)
  texture=ctx.texture(source.size,4,source.tobytes());texture.filter=(moderngl.NEAREST,moderngl.NEAREST)
  lut=make_lut(ctx,make_palette(materials));lut.use(1)
  for k,v in dict(sourceSize=source.size,sourceRect=crop,bodyRect=((size[0]-bw)//2,foot-bh,bw,bh),outputSize=size).items():shader[k].value=v
  sprite=render(ctx,shader,size,texture);a=np.asarray(sprite)
  colors=len({tuple(c) for c in a[a[:,:,3]>0,:3]});assert 45<=colors<=128 and set(np.unique(a[:,:,3]))=={0,255}
  file=f'assets/scenery/biomes/{name}-pixel-v1.png';sprite.save(ROOT/file)
  report.append(dict(id=name,file=file,size=size,foot=foot,colors=colors))
  x=15+i*300;pen.text((x,15),name+' / native '+str(size),fill=(230,223,183));board.paste(sprite,(x,40),sprite)
  width={'parrot':58,'lemur':66,'crab':36,'traveller':152}[name]
  tiny=sprite.resize((width,round(size[1]*width/size[0])),Image.Resampling.NEAREST)
  board.paste(tiny,(x,290),tiny);pen.text((x,266),'world scale',fill=(230,223,183))
  cx,cy=size[0]//2,size[1]//2
  detail=sprite.crop((cx-32,cy-24,cx+32,cy+24)).resize((192,144),Image.Resampling.NEAREST)
  pen.rectangle((x,409,x+220,565),fill=(176,179,142));board.paste(detail,(x+10,414),detail)
  texture.release();lut.release()
 board.save(ROOT/'docs/previews/biome-life-v1-assets.png')
 (ROOT/'docs/previews/biome-life-v1-build.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
 print('BIOME_LIFE_GPU_OK',[(r['id'],r['colors']) for r in report])
if __name__=='__main__':main()
