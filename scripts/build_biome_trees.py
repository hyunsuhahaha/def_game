"""Native pixel biome trees, same GPU material pipeline as approved forest v3."""
from pathlib import Path
import json
import numpy as np
import moderngl
from PIL import Image, ImageDraw
from build_cigarette_pixel_sprite import VERTEX, love_fragment, render
from build_forest_enemy_atlases import make_palette, make_lut
ROOT=Path(__file__).resolve().parents[1]
SPECS=[
 ('mangrove',(232,244),['42673c','7b913f','a8aa4a','244b3c','85603b','b58344','523a2e','28382c']),
 ('baobab',(184,252),['79823e','a2a14e','4c6132','ac763d','d09750','7d5033','553932','34382b']),
 ('palm',(188,242),['64843b','a2aa49','315c3e','264334','b48a4e','d1aa66','795332','463827']),
 ('avicennia',(204,218),['82917a','a8b294','4d6d5c','365047','b1a38a','827867','56574f','343d34']),
 ('nypa',(208,188),['496b39','759343','a1a54c','2b503b','8b6a39','b2924f','503e2c','2f3827']),
 ('tamarind',(212,224),['6b7c38','999947','465d2c','b49c58','705035','9d7440','4c3b2b','2d3525']),
 ('commiphora',(188,216),['82916a','a7aa7d','536642','b2a17c','827a63','605c4e','433f34','333b2c']),
 ('pandanus',(196,208),['497239','81964b','b0b363','2e5537','a27b48','ce9e54','80603e','42432e']),
 ('seaalmond',(218,230),['59773c','849344','aeb264','355535','a37f4c','7c5f3e','b2693e','3c3e2a']),
]
def main():
 ctx=moderngl.create_standalone_context()
 shader=ctx.program(vertex_shader=VERTEX,fragment_shader=love_fragment(ROOT/'assets/shaders/forest-arcade-bake.glsl'))
 for key,value in dict(paletteLut=1,phase=0,motion=0,actionRow=0,chromaKey=0,outlinePixels=2).items():shader[key].value=value
 board=Image.new('RGB',(1100,2280),(47,57,38));pen=ImageDraw.Draw(board);report=[]
 for i,(name,size,materials) in enumerate(SPECS):
  version=2 if name in ('baobab','mangrove','palm') else 1
  source=Image.open(ROOT/f'assets/trees/concepts/{name}-v{version}.png').convert('RGBA');a=np.asarray(source)
  assert a[:,:,3].min()==0,(name,'no true alpha')
  yy,xx=np.nonzero(a[:,:,3]>=180)
  crop=(int(xx.min()),int(yy.min()),int(xx.max()-xx.min()+1),int(yy.max()-yy.min()+1))
  foot=round(size[1]*.91);fit=min((size[0]-12)/crop[2],(foot-8)/crop[3]);bw,bh=round(crop[2]*fit),round(crop[3]*fit)
  texture=ctx.texture(source.size,4,source.tobytes());texture.filter=(moderngl.NEAREST,moderngl.NEAREST)
  lut=make_lut(ctx,make_palette(materials));lut.use(1)
  for k,v in dict(sourceSize=source.size,sourceRect=crop,bodyRect=((size[0]-bw)//2,foot-bh,bw,bh),outputSize=size).items():shader[k].value=v
  sprite=render(ctx,shader,size,texture);pixels=np.asarray(sprite)
  colors=len({tuple(c) for c in pixels[pixels[:,:,3]>0,:3]})
  assert set(np.unique(pixels[:,:,3]))=={0,255} and 45<=colors<=128,(name,colors)
  assert abs(sprite.getbbox()[3]-foot)<=1,(name,'foot plane')
  file=f'assets/trees/{name}-tree-pixel-v{version}.png';sprite.save(ROOT/file)
  report.append(dict(id=name,file=file,size=size,foot=foot,colors=colors,bbox=sprite.getbbox()))
  x=20+(i%3)*360;y=(i//3)*760;pen.text((x,y+15),name+' / native '+str(size),fill=(230,223,183));board.paste(sprite,(x+30,y+40),sprite)
  tiny=sprite.resize((round(size[0]*.72),round(size[1]*.72)),Image.Resampling.NEAREST)
  pen.text((x,y+305),'camera .72',fill=(230,223,183));board.paste(tiny,(x+30,y+330),tiny)
  detail=sprite.crop((size[0]//2-45,foot-95,size[0]//2+45,foot-30)).resize((270,195),Image.Resampling.NEAREST)
  pen.rectangle((x,y+545,x+310,y+750),fill=(176,179,142));board.paste(detail,(x+20,y+550),detail)
  texture.release();lut.release()
 board.save(ROOT/'docs/previews/biome-trees-v1-assets.png')
 (ROOT/'docs/previews/biome-trees-v1-build.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
 print('BIOME_TREES_GPU_OK',ctx.info['GL_RENDERER'],[(r['id'],r['colors']) for r in report])
if __name__=='__main__':main()
