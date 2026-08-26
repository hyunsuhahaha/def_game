"""Bake native terrain props with the approved forest material shader.

Generated concepts remain unchanged. The GPU fixes sprite grids, material ramps,
hard alpha and shaded rims. No LÖVE window; no runtime concept downscaling.
"""
from pathlib import Path
import json
import numpy as np
import moderngl
from PIL import Image, ImageDraw
from build_cigarette_pixel_sprite import VERTEX, love_fragment, render
from build_forest_enemy_atlases import make_palette, make_lut

ROOT=Path(__file__).resolve().parents[1]
SPECS=[
    ('rock',(256,192),.90,['8f887c','b7ab90','696a68','4e5558','46523d','738344','92954b','353b30']),
    ('fern',(256,160),.93,['71813a','a0a14c','4e683b','304e36','829546','526631','b0a858','293c2d']),
    ('leaves',(256,160),.53,['8d6033','a3773d','6e4930','a05a32','786838','b18b52','53452e','625638']),
    ('log',(320,160),.88,['795432','533c29','a27c4a','c49b5c','695436','5b7038','869047','302e24']),
]

def main():
    ctx=moderngl.create_standalone_context()
    shader=ctx.program(vertex_shader=VERTEX,fragment_shader=love_fragment(ROOT/'assets/shaders/forest-arcade-bake.glsl'))
    shader['paletteLut'].value=1
    shader['phase'].value=0;shader['motion'].value=0;shader['actionRow'].value=0;shader['chromaKey'].value=0
    board=Image.new('RGB',(1360,620),(44,55,37));pen=ImageDraw.Draw(board)
    report=[]
    for i,(name,size,foot,materials) in enumerate(SPECS):
        source=Image.open(ROOT/f'assets/scenery/forest/concepts/{name}-v1.png').convert('RGBA')
        pixels=np.asarray(source)
        assert pixels[:,:,3].min()==0,'concept lacks true transparency'
        yy,xx=np.nonzero(pixels[:,:,3]>=180)
        crop=(int(xx.min()),int(yy.min()),int(xx.max()-xx.min()+1),int(yy.max()-yy.min()+1))
        usable_height=(size[1]-16) if name=='leaves' else (round(size[1]*foot)-8)
        fit=min((size[0]-20)/crop[2],usable_height/crop[3])
        bw,bh=round(crop[2]*fit),round(crop[3]*fit)
        top=(size[1]-bh)//2 if name=='leaves' else round(size[1]*foot)-bh
        texture=ctx.texture(source.size,4,source.tobytes());texture.filter=(moderngl.NEAREST,moderngl.NEAREST)
        lut=make_lut(ctx,make_palette(materials));lut.use(1)
        shader['sourceSize'].value=source.size;shader['sourceRect'].value=crop
        shader['bodyRect'].value=((size[0]-bw)//2,top,bw,bh);shader['outputSize'].value=size
        sprite=render(ctx,shader,size,texture)
        colors={tuple(c) for c in np.asarray(sprite).reshape(-1,4)}
        assert {c[3] for c in colors}=={0,255}
        count=len({c[:3] for c in colors if c[3]})
        assert 35<=count<=128,(name,count)
        file=f'assets/scenery/forest/{name}-pixel-v1.png';sprite.save(ROOT/file)
        report.append(dict(id=name,file=file,size=size,colors=count,bbox=sprite.getbbox(),foot=foot))
        x=20+i*340
        pen.text((x,16),name+' / native '+str(size),fill=(239,225,187))
        # Each object's native grid, then a small gameplay-sized specimen.
        board.paste(sprite,(x,46),sprite)
        display_width={'rock':100,'fern':86,'leaves':174,'log':132}[name]
        tiny=sprite.resize((display_width,round(size[1]*display_width/size[0])),Image.Resampling.NEAREST)
        board.paste(tiny,(x,278),tiny)
        pen.text((x,254),'world scale (before camera)',fill=(206,207,161))
        cx,cy=size[0]//2,size[1]//2
        detail=sprite.crop((cx-48,cy-36,cx+48,cy+36)).resize((288,216),Image.Resampling.NEAREST)
        pen.rectangle((x,370,x+300,606),fill=(178,179,142))
        board.paste(detail,(x,378),detail)
        pen.text((x,350),'pixel/edge inspection',fill=(206,207,161))
        texture.release();lut.release()
        print('SCENERY_BAKED',name,size,count)
    (ROOT/'docs/previews/forest-scenery-v1-build.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    board.save(ROOT/'docs/previews/forest-scenery-v1-assets.png')
    print('FOREST_SCENERY_GPU_OK',ctx.info['GL_RENDERER'])

if __name__=='__main__':main()
