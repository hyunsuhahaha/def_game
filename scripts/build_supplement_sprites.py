"""Fixed sprite models for the eight supplement FX; GPU native-pixel material bake."""
from pathlib import Path
import json
import numpy as np
import moderngl
from PIL import Image,ImageDraw
from build_cigarette_pixel_sprite import VERTEX,love_fragment,render
from build_forest_enemy_atlases import make_palette,make_lut
ROOT=Path(__file__).resolve().parents[1]
SPECS=[
 ('bat',(192,128),6,48,['3c294d','775178','ad80ac','4c405a','302f42','ad905b','dbbb78','697388']),
 ('crow',(224,160),6,70,['283342','46556b','738698','a8b3b6','222a34','3b4a5c','737b83','b1a889']),
 ('axe',(160,160),1,49,['667a88','a2b4b6','d9e2d4','374553','977041','c19454','694735','433c38']),
 ('seed',(128,160),1,31,['80542d','b17c3b','d5a853','584329','496d34','8caa49','e4cb7c','a39545']),
]
def main():
 out=ROOT/'assets/fx/supplement';out.mkdir(parents=True,exist_ok=True)
 ctx=moderngl.create_standalone_context()
 shader=ctx.program(vertex_shader=VERTEX,fragment_shader=love_fragment(ROOT/'assets/shaders/forest-arcade-bake.glsl'))
 for k,v in dict(paletteLut=1,motion=0,actionRow=0,chromaKey=0,outlinePixels=2,biomeRig=0).items():shader[k].value=v
 catalog=['-- Generated native skill sprites; +Y tail, -Y head for flight models.','return {'];report=[]
 board=Image.new('RGB',(1100,450),(44,54,37));pen=ImageDraw.Draw(board)
 for i,(name,size,count,width,materials) in enumerate(SPECS):
  source=Image.open(out/f'concepts/{name}-v1.png').convert('RGBA');a=np.asarray(source)
  assert a[:,:,3].min()==0,(name,'no alpha')
  yy,xx=np.nonzero(a[:,:,3]>=180);crop=(int(xx.min()),int(yy.min()),int(xx.max()-xx.min()+1),int(yy.max()-yy.min()+1))
  fit=min((size[0]-14)/crop[2],(size[1]-14)/crop[3]);bw,bh=round(crop[2]*fit),round(crop[3]*fit)
  tex=ctx.texture(source.size,4,source.tobytes());tex.filter=(moderngl.NEAREST,moderngl.NEAREST)
  lut=make_lut(ctx,make_palette(materials));lut.use(1)
  for k,v in dict(sourceSize=source.size,sourceRect=crop,bodyRect=((size[0]-bw)//2,(size[1]-bh)//2,bw,bh),outputSize=size,flightRig=1 if count>1 else 0).items():shader[k].value=v
  atlas=Image.new('RGBA',(size[0]*count,size[1]));frames=[]
  for j in range(count):
   shader['phase'].value=j/count
   frame=render(ctx,shader,size,tex);atlas.paste(frame,(j*size[0],0));frames.append(frame)
  assert len({im.tobytes() for im in frames})==count
  a=np.asarray(atlas);colors=len({tuple(c) for c in a[a[:,:,3]>0,:3]})
  assert set(np.unique(a[:,:,3]))=={0,255} and 50<=colors<=128,(name,colors)
  file=f'assets/fx/supplement/{name}-atlas-v1.png';atlas.save(ROOT/file)
  catalog.append(f' {name}={{file="{file}",w={size[0]},h={size[1]},frames={count},bodyWidth={bw},width={width}}},')
  x=20+i*270;pen.text((x,16),name+' / native '+str(size),fill=(232,224,184));board.paste(frames[0],(x,45),frames[0])
  scale=width/bw*.72;small=frames[0].resize((round(size[0]*scale),round(size[1]*scale)),Image.Resampling.NEAREST)
  pen.text((x,225),'game .72',fill=(215,216,180));board.paste(small,(x,249),small)
  detail=frames[0].crop((size[0]//2-24,size[1]//2-20,size[0]//2+24,size[1]//2+20)).resize((144,120),Image.Resampling.NEAREST)
  board.paste(detail,(x,315),detail)
  report.append(dict(id=name,grid=size,frames=count,colors=colors,width=width))
  tex.release();lut.release()
 catalog.append('}')
 (ROOT/'src/supplement_sprite_catalog.lua').write_text('\n'.join(catalog)+'\n',encoding='utf-8')
 board.save(ROOT/'docs/previews/supplement-sprites-v1.png')
 (ROOT/'docs/previews/supplement-sprites-v1.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
 print('SUPPLEMENT_SPRITES_OK species=4 wing_frames=6',ctx.info['GL_RENDERER'])
if __name__=='__main__':main()
