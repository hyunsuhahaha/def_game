"""Bake the fixed mystical regeneration sanctum into a coherent 6x2 native atlas."""
from pathlib import Path
import json

import moderngl
import numpy as np
from PIL import Image, ImageDraw

from build_cigarette_pixel_sprite import VERTEX, love_fragment, render
from build_forest_enemy_atlases import make_lut, make_palette

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'assets/enemies/concepts/regrowth-sanctum-model-v2.png'
OUT=ROOT/'assets/enemies/arcade/planter-atlas-v2.png'
PREVIEW=ROOT/'docs/previews/regrowth-sanctum-atlas-v2.png'
REPORT=ROOT/'docs/previews/regrowth-sanctum-v2-build.json'
CELL,FOOT=256,248
MATERIALS=['1c2115','344024','66722b','a5a936','49301d','76502a','b77a35','bcebd0']


def alpha_bounds(image):
    pixels=np.asarray(image)
    ys,xs=np.nonzero(pixels[:,:,3]>=24)
    return int(xs.min()),int(ys.min()),int(xs.max()-xs.min()+1),int(ys.max()-ys.min()+1)


def main():
    source=Image.open(SOURCE).convert('RGBA')
    assert source.getchannel('A').getextrema()==(0,255)
    ctx=moderngl.create_standalone_context()
    shader=ctx.program(vertex_shader=VERTEX,fragment_shader=love_fragment(ROOT/'assets/shaders/forest-arcade-bake.glsl'))
    texture=ctx.texture(source.size,4,source.tobytes());texture.filter=(moderngl.NEAREST,moderngl.NEAREST)
    crop=alpha_bounds(source)
    fit=min((CELL-12)/crop[2],(FOOT-5)/crop[3])
    body_w,body_h=round(crop[2]*fit),round(crop[3]*fit)
    shader['paletteLut'].value=1;shader['sourceSize'].value=source.size;shader['chromaKey'].value=0
    shader['sourceRect'].value=crop;shader['bodyRect'].value=((CELL-body_w)//2,FOOT-body_h,body_w,body_h)
    shader['outputSize'].value=(CELL,CELL);shader['motion'].value=2;shader['outlinePixels'].value=1;shader['biomeRig'].value=.28;shader['flightRig'].value=0
    lut=make_lut(ctx,make_palette(MATERIALS));lut.use(1)
    atlas=Image.new('RGBA',(CELL*6,CELL*2));frames=[]
    for index in range(12):
        shader['actionRow'].value=float(index//6)
        shader['phase'].value=(index%6)/(5 if index>=6 else 6)
        frame=render(ctx,shader,(CELL,CELL),texture)
        atlas.paste(frame,((index%6)*CELL,(index//6)*CELL));frames.append(frame)
    rgba=np.asarray(atlas);colors={tuple(p[:3]) for p in rgba.reshape(-1,4) if p[3]}
    assert set(np.unique(rgba[:,:,3]).tolist())=={0,255}
    assert 72<=len(colors)<=128,len(colors)
    assert len({frame.tobytes() for frame in frames[:6]})==6
    assert len({frame.tobytes() for frame in frames[6:]})>=5
    atlas.save(OUT,optimize=True)
    preview=Image.new('RGB',(6*288,2*288),(49,70,38));pen=ImageDraw.Draw(preview)
    for i,frame in enumerate(frames):
        show=frame.resize((288,288),Image.Resampling.NEAREST);x=(i%6)*288;y=(i//6)*288
        preview.paste(show,(x,y),show);pen.text((x+8,y+7),f'{i+1:02d}',fill=(231,231,178))
    preview.save(PREVIEW)
    report={'id':'planter','source':str(SOURCE.relative_to(ROOT)),'file':str(OUT.relative_to(ROOT)),
            'cell':CELL,'foot':FOOT,'bodyWidth':body_w,'height':body_h,'worldWidth':90,'colors':len(colors),'frames':12}
    REPORT.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    print('REGROWTH_SANCTUM_GPU_OK',report,ctx.info['GL_RENDERER'])


if __name__=='__main__': main()
