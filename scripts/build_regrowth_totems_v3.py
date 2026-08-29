"""Build compact biome regeneration totems with a six-frame prism cycle."""
from pathlib import Path
import json, math

import moderngl
import numpy as np
from PIL import Image, ImageDraw

from build_cigarette_pixel_sprite import VERTEX, love_fragment, render
from build_forest_enemy_atlases import make_lut, make_palette

ROOT=Path(__file__).resolve().parents[1]
CELL,FOOT=256,248
SPECS={
    'forest':('assets/enemies/concepts/regrowth-sanctum-model-v2.png',68,
        ['172016','314125','637037','9aa248','49301f','76522f','b98142','d6f3c4'],(128,153),('b7fff0','4fe7c7','137f78')),
    'mangrove':('assets/enemies/concepts/regrowth-mangrove-model-v3.png',70,
        ['10241d','174836','397a4c','77b955','3d2a19','77502d','b98249','73eddf'],(128,150),('d8ffff','5feee0','159c91')),
    'madagascar':('assets/enemies/concepts/regrowth-madagascar-model-v3.png',72,
        ['251b10','48301a','86451d','c86d29','e49a44','667424','a5b943','f4e58c'],(128,144),('ffffb3','bde94c','668b21')),
    'island':('assets/enemies/concepts/regrowth-island-model-v3.png',74,
        ['102629','174d51','178987','55d8cf','5c422d','b88a57','f1d39a','ff7559'],(128,142),('eaffff','54e9ef','168da8')),
}

def alpha_bounds(image):
    pixels=np.asarray(image);ys,xs=np.nonzero(pixels[:,:,3]>=24)
    return int(xs.min()),int(ys.min()),int(xs.max()-xs.min()+1),int(ys.max()-ys.min()+1)

def rgb(value): return tuple(int(value[i:i+2],16) for i in (0,2,4))

def prism_cycle(frame,index,center,colors,cast):
    """Crisp authored facets and orbit beads make the centre visibly rotate."""
    draw=ImageDraw.Draw(frame)
    cx,cy=center;phase=(index%6)/6*math.tau
    half=max(3,round(10*abs(math.cos(phase))))
    h=16+(2 if cast else 0)
    dark,mid,light=rgb(colors[2]),rgb(colors[1]),rgb(colors[0])
    outline=(10,31,30,255)
    draw.polygon([(cx,cy-h),(cx+half+2,cy),(cx,cy+h),(cx-half-2,cy)],fill=outline)
    draw.polygon([(cx,cy-h+2),(cx+half,cy),(cx,cy+h-2)],fill=(*mid,255))
    draw.polygon([(cx,cy-h+2),(cx-half,cy),(cx,cy+h-2)],fill=(*dark,255))
    draw.polygon([(cx,cy-h+3),(cx+max(1,half//3),cy-1),(cx,cy+3)],fill=(*light,255))
    # Two orbiting glints: their changing x positions read as a full turn at game size.
    for offset,rad in ((0,22),(math.pi,15)):
        a=phase+offset;x=round(cx+math.cos(a)*rad);y=round(cy+math.sin(a)*rad*.34)
        draw.rectangle((x-2,y-2,x+2,y+2),fill=(*dark,255))
        draw.rectangle((x-1,y-1,x+1,y+1),fill=(*light,255))
    if cast:
        for a in (phase,phase+math.tau/3,phase+math.tau*2/3):
            x=round(cx+math.cos(a)*29);y=round(cy+math.sin(a)*12)
            draw.point((x,y),fill=(*light,255));draw.point((x+1,y),fill=(*mid,255))

def main():
    ctx=moderngl.create_standalone_context()
    shader=ctx.program(vertex_shader=VERTEX,fragment_shader=love_fragment(ROOT/'assets/shaders/forest-arcade-bake.glsl'))
    report={}
    contact=Image.new('RGB',(4*384,2*384),(40,55,34))
    for column,(name,(source_path,world_width,palette,center,prism_colors)) in enumerate(SPECS.items()):
        source=Image.open(ROOT/source_path).convert('RGBA');crop=alpha_bounds(source)
        texture=ctx.texture(source.size,4,source.tobytes());texture.filter=(moderngl.NEAREST,moderngl.NEAREST)
        fit=min(190/crop[2],190/crop[3]);body_w,body_h=round(crop[2]*fit),round(crop[3]*fit)
        body_x,body_y=(CELL-body_w)//2,FOOT-body_h
        shader['paletteLut'].value=1;shader['sourceSize'].value=source.size;shader['chromaKey'].value=0
        shader['sourceRect'].value=crop;shader['bodyRect'].value=(body_x,body_y,body_w,body_h)
        shader['outputSize'].value=(CELL,CELL);shader['motion'].value=2;shader['outlinePixels'].value=1
        shader['biomeRig'].value=.2;shader['flightRig'].value=0
        lut=make_lut(ctx,make_palette(palette));lut.use(1)
        atlas=Image.new('RGBA',(CELL*6,CELL*2));frames=[]
        # Centre coordinates are authored against the 190px fitting box; shift
        # only vertically when a wide source leaves extra space.
        prism_center=(center[0],body_y+round((center[1]/256)*body_h))
        for index in range(12):
            shader['actionRow'].value=float(index//6);shader['phase'].value=(index%6)/(5 if index>=6 else 6)
            frame=render(ctx,shader,(CELL,CELL),texture)
            prism_cycle(frame,index,prism_center,prism_colors,index>=6)
            atlas.paste(frame,((index%6)*CELL,(index//6)*CELL));frames.append(frame)
        out=ROOT/f'assets/enemies/arcade/planter-{name}-atlas-v3.png';atlas.save(out,optimize=True)
        show=frames[2].resize((384,384),Image.Resampling.NEAREST);contact.paste(show,(column*384,0),show)
        show=frames[8].resize((384,384),Image.Resampling.NEAREST);contact.paste(show,(column*384,384),show)
        report[name]={'file':str(out.relative_to(ROOT)),'source':source_path,'worldWidth':world_width,
            'cell':CELL,'foot':FOOT,'bodyWidth':body_w,'height':body_h,'frames':12}
        texture.release();lut.release()
    preview=ROOT/'docs/previews/regrowth-totems-v3-contact-sheet.png';contact.save(preview)
    (ROOT/'docs/previews/regrowth-totems-v3-build.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    print('REGROWTH_TOTEMS_V3_OK',json.dumps(report,ensure_ascii=False),ctx.info['GL_RENDERER'])

if __name__=='__main__': main()
