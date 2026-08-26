"""Pixel studies for proposed regional bosses; deliberately NOT a runtime catalog."""
from pathlib import Path
import json
import numpy as np
import moderngl
from PIL import Image, ImageDraw, ImageFont
from build_cigarette_pixel_sprite import VERTEX, love_fragment, render
from build_forest_enemy_atlases import make_palette, make_lut

ROOT=Path(__file__).resolve().parents[1]
SPECS=[
 ('forest','온대 숲 · 속빈 고목왕',176,'뿌리로 길을 나누고, 내려찍은 뒤 약점 노출',
  ['795336','a87943','ce9b54','454e29','778937','a4a14a','eaa431','412b24']),
 ('mangrove','맹그로브 · 뿌리턱 악어왕',216,'물길 잠복 → 방향 고정 돌진 → 꼬리 휩쓸기',
  ['536f40','82904b','b4a766','334e43','658080','765739','d5b979','343932']),
 ('madagascar','마다가스카르 · 바오밥 폭군',164,'세 번의 도약과 나무방망이, 마지막 착지에 빈틈',
  ['767777','a9a7a0','ded2b4','363640','946638','c2934e','a44a2b','dcac3d']),
 ('island','무인도 · 섬등 소라게',188,'껍질 돌진과 갈라지는 파도, 집게를 피해 반격',
  ['b54e37','dc8853','e6c59c','7e668c','b194b5','415f48','83a94b','46a9b3']),
]

def main():
 out=ROOT/'assets/enemies/biome-bosses/studies';out.mkdir(parents=True,exist_ok=True)
 preview=ROOT/'docs/previews'
 ctx=moderngl.create_standalone_context()
 program=ctx.program(vertex_shader=VERTEX,fragment_shader=love_fragment(ROOT/'assets/shaders/forest-arcade-bake.glsl'))
 for key,value in dict(paletteLut=1,phase=0,motion=0,actionRow=0,chromaKey=0,outlinePixels=2,biomeRig=0).items():program[key].value=value
 board=Image.new('RGB',(1440,1200),(24,33,29));pen=ImageDraw.Draw(board)
 title=ImageFont.truetype(str(ROOT/'assets/font-korean-bold.ttf'),29)
 body=ImageFont.truetype(str(ROOT/'assets/font-korean-regular.ttf'),18)
 pen.text((28,16),'맵별 보스 디자인 v1  /  외형·전투 설계 시안 — 인게임 미연결',font=title,fill=(235,220,174))
 report=[]
 for i,(name,label,width,pattern,materials) in enumerate(SPECS):
  concept=ROOT/f'assets/enemies/biome-bosses/concepts/{name}-v1.png'
  # Explicit selected sources: mangrove-v2 is rejected (opaque checkerboard).
  # The shared shader removes v1's low-alpha halo using its actual alpha channel.
  source=Image.open(concept).convert('RGBA');a=np.asarray(source)
  assert a[:,:,3].min()==0,(name,'missing transparent alpha')
  yy,xx=np.nonzero(a[:,:,3]>=180)
  crop=(int(xx.min()),int(yy.min()),int(xx.max()-xx.min()+1),int(yy.max()-yy.min()+1))
  cell,foot=384,368;fit=min(360/crop[2],352/crop[3]);bw,bh=round(crop[2]*fit),round(crop[3]*fit)
  texture=ctx.texture(source.size,4,source.tobytes());texture.filter=(moderngl.NEAREST,moderngl.NEAREST)
  lut=make_lut(ctx,make_palette(materials));lut.use(1)
  for key,value in dict(sourceSize=source.size,sourceRect=crop,bodyRect=((cell-bw)//2,foot-bh,bw,bh),outputSize=(cell,cell)).items():program[key].value=value
  sprite=render(ctx,program,(cell,cell),texture);a=np.asarray(sprite)
  colors=len({tuple(c) for c in a[a[:,:,3]>0,:3]})
  assert set(np.unique(a[:,:,3]))=={0,255} and 60<=colors<=128,(name,colors)
  assert abs(sprite.getbbox()[3]-foot)<=1,(name,'foot drift')
  sprite.save(out/f'{name}-pixel-study-v1.png')
  x,y=(i%2)*720+20,(i//2)*560+68
  pen.rounded_rectangle((x,y,x+680,y+538),radius=12,fill=(43,54,38),outline=(77,87,58),width=1)
  pen.text((x+20,y+14),label,font=title,fill=(239,222,167))
  # Native scale, plus proposed gameplay widths. No hand-drawn replacement art.
  board.paste(sprite,(x+10,y+56),sprite)
  for row,zoom in enumerate([.72,720/1850]):
   size=round(cell*width/bw*zoom)
   small=sprite.resize((size,size),Image.Resampling.NEAREST)
   board.paste(small,(x+410,y+85+row*175),small)
   pen.text((x+407,y+64+row*175),'기본 줌 .72' if row==0 else '확대 섬 전체 조망',font=body,fill=(187,201,163))
  pen.text((x+20,y+460),pattern,font=body,fill=(228,222,189))
  pen.text((x+20,y+492),f'384×384 원생 픽셀 · {colors}색 · 월드 너비 제안 {width}',font=body,fill=(170,188,153))
  report.append(dict(id=name,concept=str(concept.relative_to(ROOT)),study=str((out/f'{name}-pixel-study-v1.png').relative_to(ROOT)),grid=[384,384],foot=foot,colors=colors,width=width,runtime_connected=False))
  texture.release();lut.release()
 board.save(preview/'biome-boss-designs-v1.png')
 (preview/'biome-boss-designs-v1.json').write_text(json.dumps(dict(renderer=ctx.info['GL_RENDERER'],status='design study, not gameplay implementation',bosses=report),ensure_ascii=False,indent=2),encoding='utf-8')
 print('BIOME_BOSS_STUDIES_OK bosses=4 native=384x384 runtime_connected=false',ctx.info['GL_RENDERER'])

if __name__=='__main__':main()
