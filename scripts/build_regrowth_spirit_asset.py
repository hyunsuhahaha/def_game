"""Bake one fixed Regrowth Spirit model into a consistent 6x2 atlas."""
from pathlib import Path
import json
import numpy as np
import moderngl
from PIL import Image, ImageDraw
from build_cigarette_pixel_sprite import VERTEX, love_fragment, render
from build_forest_enemy_atlases import make_palette, make_lut

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'assets/enemies/concepts/regrowth-spirit-model-v1.png'
OUT=ROOT/'assets/enemies/arcade/planter-atlas-v1.png'
PREVIEW=ROOT/'docs/previews/regrowth-spirit-atlas-v1.png'
REPORT=ROOT/'docs/previews/regrowth-spirit-v1-build.json'
CELL,FOOT=160,152
MATERIALS=['0b553f','087e4c','16b64f','83e51e','c8ff3d','68ffd0','925021','e49a42']

def alpha_bounds(source):
    a=np.asarray(source)
    yy,xx=np.nonzero(a[:,:,3]>=24)
    assert len(xx)
    return int(xx.min()),int(yy.min()),int(xx.max()-xx.min()+1),int(yy.max()-yy.min()+1)

def main():
    source=Image.open(SOURCE).convert('RGBA')
    ctx=moderngl.create_standalone_context()
    shader=ctx.program(vertex_shader=VERTEX,fragment_shader=love_fragment(ROOT/'assets/shaders/forest-arcade-bake.glsl'))
    texture=ctx.texture(source.size,4,source.tobytes()); texture.filter=(moderngl.NEAREST,moderngl.NEAREST)
    shader['paletteLut'].value=1; shader['sourceSize'].value=source.size; shader['chromaKey'].value=0
    crop=alpha_bounds(source); fit=min((CELL-14)/crop[2],(FOOT-8)/crop[3])
    bw,bh=round(crop[2]*fit),round(crop[3]*fit)
    shader['sourceRect'].value=crop; shader['bodyRect'].value=((CELL-bw)//2,FOOT-bh,bw,bh)
    shader['outputSize'].value=(CELL,CELL); shader['motion'].value=2
    lut=make_lut(ctx,make_palette(MATERIALS)); lut.use(1)
    atlas=Image.new('RGBA',(CELL*6,CELL*2)); frames=[]
    for i in range(12):
        shader['actionRow'].value=float(i//6); shader['phase'].value=(i%6)/(5 if i>=6 else 6)
        frame=render(ctx,shader,(CELL,CELL),texture); frames.append(frame)
        atlas.paste(frame,((i%6)*CELL,(i//6)*CELL))
    colors={tuple(c) for c in np.asarray(atlas).reshape(-1,4)}; opaque={c[:3] for c in colors if c[3]}
    assert {c[3] for c in colors}=={0,255}
    assert 45<=len(opaque)<=128,len(opaque)
    atlas.save(OUT)
    preview=Image.new('RGB',(6*192,2*192),(14,28,32)); pen=ImageDraw.Draw(preview)
    for i,frame in enumerate(frames):
        show=frame.resize((192,192),Image.Resampling.NEAREST); x=(i%6)*192; y=(i//6)*192
        preview.paste(show,(x,y),show); pen.text((x+8,y+7),f'{i+1:02d}',fill=(210,255,164))
    preview.save(PREVIEW)
    report={'id':'planter','source':str(SOURCE.relative_to(ROOT)),'file':str(OUT.relative_to(ROOT)),
        'cell':CELL,'foot':FOOT,'bodyWidth':bw,'height':bh,'colors':len(opaque),'frames':12}
    REPORT.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    print('REGROWTH_SPIRIT_GPU_OK',report,ctx.info['GL_RENDERER'])

if __name__=='__main__': main()
