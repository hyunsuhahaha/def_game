"""Fixed models -> native 6 walk / 6 attack phase atlases on the shared GPU rig."""
from pathlib import Path
import json
import numpy as np
import moderngl
from PIL import Image,ImageDraw
from build_cigarette_pixel_sprite import VERTEX,love_fragment,render
from build_forest_enemy_atlases import make_palette,make_lut
ROOT=Path(__file__).resolve().parents[1]
SPECS=[
 ('crocodile','assets/enemies/biomes/concepts/crocodile-v1.png',224,92,['536c35','839149','b5ac64','324f32','27392c','8b794b','d6c79c','424534']),
 ('angryLemur','assets/enemies/biomes/concepts/angryLemur-v2.png',192,53,['747774','a5a399','c6beb0','e2d9c6','383941','252730','a88738','d8a54e']),
 ('marshCrab','assets/scenery/biomes/concepts/crab-v1.png',128,39,['b34d2a','d6843c','e2ae69','873427','542c2b','e7d5ab','372a26','a9673f']),
]
def main():
 (ROOT/'assets/enemies/biomes').mkdir(parents=True,exist_ok=True)
 ctx=moderngl.create_standalone_context()
 shader=ctx.program(vertex_shader=VERTEX,fragment_shader=love_fragment(ROOT/'assets/shaders/forest-arcade-bake.glsl'))
 for k,v in dict(paletteLut=1,motion=1,chromaKey=0,outlinePixels=2,biomeRig=1).items():shader[k].value=v
 catalog=['-- Generated native biome fauna atlases.','return {'];report=[]
 board=Image.new('RGB',(1000,470),(47,57,38));pen=ImageDraw.Draw(board)
 for i,(name,sourcefile,cell,width,materials) in enumerate(SPECS):
  source=Image.open(ROOT/sourcefile).convert('RGBA');a=np.asarray(source);assert a[:,:,3].min()==0
  yy,xx=np.nonzero(a[:,:,3]>=180);crop=(int(xx.min()),int(yy.min()),int(xx.max()-xx.min()+1),int(yy.max()-yy.min()+1))
  foot=cell-8;fit=min((cell-20)/crop[2],(foot-10)/crop[3]);bw,bh=round(crop[2]*fit),round(crop[3]*fit)
  texture=ctx.texture(source.size,4,source.tobytes());texture.filter=(moderngl.NEAREST,moderngl.NEAREST)
  lut=make_lut(ctx,make_palette(materials));lut.use(1)
  for k,v in dict(sourceSize=source.size,sourceRect=crop,bodyRect=((cell-bw)//2,foot-bh,bw,bh),outputSize=(cell,cell)).items():shader[k].value=v
  atlas=Image.new('RGBA',(cell*6,cell*2));frames=[]
  for j in range(12):
   shader['phase'].value=(j%6)/(5 if j>=6 else 6);shader['actionRow'].value=j//6
   frame=render(ctx,shader,(cell,cell),texture);frames.append(frame);atlas.paste(frame,((j%6)*cell,(j//6)*cell))
  assert len({im.tobytes() for im in frames[:6]})==6
  assert len({im.tobytes() for im in frames[6:]})==6
  assert all(im.getbbox()[3]==foot for im in frames),'foot plane drift'
  a=np.asarray(atlas);colors=len({tuple(c) for c in a[a[:,:,3]>0,:3]});assert 45<=colors<=128 and set(np.unique(a[:,:,3]))=={0,255}
  file=f'assets/enemies/biomes/{name}-atlas-v1.png';atlas.save(ROOT/file)
  spec=f'{{file="{file}",cell={cell},foot={foot},width={width},bodyWidth={bw},height={bh},motion=1,facing=1,biome=true}}'
  catalog.append(f'    {name}={spec},')
  if name=='marshCrab':catalog.append(f'    shoreCrab={spec},')
  report.append(dict(id=name,file=file,cell=cell,foot=foot,colors=colors,frames=12,width=width))
  x=25+i*330;pen.text((x,15),name,fill=(230,223,183));board.paste(frames[0],(x,42),frames[0])
  show=frames[0].resize((round(cell*width/bw),round(cell*width/bw)),Image.Resampling.NEAREST);board.paste(show,(x,310),show)
  texture.release();lut.release()
 catalog.append('}')
 (ROOT/'src/biome_enemy_catalog.lua').write_text('\n'.join(catalog)+'\n',encoding='utf-8')
 (ROOT/'docs/previews/biome-enemies-v1-build.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
 board.save(ROOT/'docs/previews/biome-enemies-v1-assets.png')
 print('BIOME_ENEMY_GPU_OK species=3 variants=4 phases=12',ctx.info['GL_RENDERER'])
if __name__=='__main__':main()
