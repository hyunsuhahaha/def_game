"""Verify/bake an offscreen replay of real Lua World/Player/monster draw calls.

No LÖVE window. The fixture omits HUD, camera effects, audio and live input;
this is an actual-asset render test, not a full game capture.
"""
from pathlib import Path
import json, math
import numpy as np
import moderngl
from PIL import Image
from headless_lua import run
from build_cigarette_pixel_sprite import love_fragment
from build_forest_arcade_assets import TREES, ENEMIES

ROOT=Path(__file__).resolve().parents[1]
VERTEX='''#version 330
in vec2 position; in vec2 texcoord; out vec2 uv;
void main(){gl_Position=vec4(position,0,1);uv=texcoord;}
'''
FRAGMENT='''#version 330
uniform sampler2D image; uniform vec4 tint; in vec2 uv; out vec4 result;
void main(){result=texture(image,uv)*tint;}
'''
SHAPE='''#version 330
uniform vec4 tint; uniform int ellipse; uniform int border;
uniform vec2 thickness; in vec2 uv; out vec4 result;
void main(){
 if(ellipse==1){float r=length((uv-.5)*2);if(r>1.0 || (border==1 && r<1.0-thickness.x))discard;}
 else if(border==1 && uv.x>thickness.x && uv.x<1.0-thickness.x && uv.y>thickness.y && uv.y<1.0-thickness.y)discard;
 result=tint;
}
'''

def replay(capture_paths,size=(1280,900)):
    ctx=moderngl.create_standalone_context()
    ctx.enable(moderngl.BLEND); ctx.blend_func=moderngl.SRC_ALPHA,moderngl.ONE_MINUS_SRC_ALPHA
    plain=ctx.program(vertex_shader=VERTEX,fragment_shader=FRAGMENT)
    shape=ctx.program(vertex_shader=VERTEX,fragment_shader=SHAPE)
    programs={}; textures={}
    frames=[]
    # Native world-unit view for pixel QA; default .72 camera view exported too.
    def quad(program,vertices):
        data=np.asarray(vertices,dtype='f4'); vbo=ctx.buffer(data.tobytes())
        vao=ctx.vertex_array(program,[(vbo,'2f 2f','position','texcoord')])
        vao.render(moderngl.TRIANGLE_STRIP); vao.release(); vbo.release()
    def draw_box(program,x,y,w,h,angle=0,sx=1,sy=1,ox=0,oy=0,uv=(0,0,1,1)):
        c,s=math.cos(angle),math.sin(angle)
        coords=[]
        for ax,ay,u,v in [(0,0,uv[0],uv[1]),(w,0,uv[2],uv[1]),(0,h,uv[0],uv[3]),(w,h,uv[2],uv[3])]:
            px,py=(ax-ox)*sx,(ay-oy)*sy
            xx,yy=x+px*c-py*s,y+px*s+py*c
            coords.append((xx/size[0]*2-1,1-yy/size[1]*2,u,v))
        quad(program,coords)
    for capture_path in capture_paths:
        fbo=ctx.simple_framebuffer(size,components=4); fbo.use();fbo.clear(0,0,0,1)
        commands=json.loads(Path(capture_path).read_text(encoding="utf-8"))
        for op in commands:
            args=op['args']; color=op['color']; kind=op['op']
            if kind=='draw':
                path=op['file']
                if path not in textures:
                    im=Image.open(ROOT/path).convert('RGBA')
                    texture=ctx.texture(im.size,4,im.tobytes())
                    texture.filter=(moderngl.NEAREST,moderngl.NEAREST) if op['filter']=='nearest' else (moderngl.LINEAR,moderngl.LINEAR)
                    textures[path]=texture
                program=plain
                if op.get('shader'):
                    shader=op['shader']
                    if shader not in programs:
                        source=love_fragment(ROOT/shader).replace('uniform sampler2D image;', 'uniform vec4 tint; uniform sampler2D image;').replace('effect(vec4(1),image,uv','effect(tint,image,uv')
                        programs[shader]=ctx.program(vertex_shader=VERTEX,fragment_shader=source)
                    program=programs[shader]
                    for name,value in op['uniforms'].items(): program[name].value=value
                program['tint'].value=color
                if 'image' in program: textures[path].use(0);program['image'].value=0
                x,y=args[:2]; angle=args[2] if len(args)>2 else 0
                sx=args[3] if len(args)>3 else 1;sy=args[4] if len(args)>4 else sx
                ox=args[5] if len(args)>5 else 0;oy=args[6] if len(args)>6 else 0
                qx,qy,w,h,tw,th=op['quad']
                draw_box(program,x,y,w,h,angle,sx,sy,ox,oy,(qx/tw,qy/th,(qx+w)/tw,(qy+h)/th))
            else:
                shape['tint'].value=color; shape['ellipse'].value=int(kind=='ellipse')
                shape['border'].value=int(op.get('mode')=='line')
                if kind=='line':
                    for i in range(0,len(args)-2,2):
                        x,y,x2,y2=args[i:i+4];length=math.hypot(x2-x,y2-y)
                        shape['thickness'].value=(0,0)
                        draw_box(shape,x,y,length,op['lineWidth'],math.atan2(y2-y,x2-x),oy=op['lineWidth']/2)
                else:
                    x,y,w,h=args
                    if kind=='ellipse': x-=w;y-=h;w*=2;h*=2
                    shape['thickness'].value=(op['lineWidth']/max(1,w),op['lineWidth']/max(1,h))
                    draw_box(shape,x,y,w,h)
        result=Image.frombytes('RGBA',size,fbo.read(components=4)).transpose(Image.Transpose.FLIP_TOP_BOTTOM).convert('RGB')
        frames.append(result);fbo.release()
    return frames,ctx.info['GL_RENDERER'],len(programs)


def main():
    run(ROOT/'scripts/verify_boss_sprites.lua','FOREST_RENDER_CAPTURE=true')
    report_path=ROOT/'docs/previews/forest-arcade-v3-build.json'
    if report_path.exists():
        report=json.loads(report_path.read_text())
    else:
        # Preview reports are intentionally ignored in some checkouts. Rebuild
        # the verification inventory from the tracked builder contract without
        # rewriting any approved runtime asset or catalog.
        report=[]
        for name,size,_ in TREES:
            report.append({'file':f'assets/trees/{name}-tree-cartoon-v3.png','size':list(size),'frames':1,'foot':round(size[1]*.91)})
        for name,_,_,cell,_,_,_ in ENEMIES:
            report.append({'file':f'assets/enemies/arcade/{name}-atlas-v3.png','size':[cell*6,cell*2],'frames':12,'foot':cell-8})
    for entry in report:
        im=Image.open(ROOT/entry['file']).convert('RGBA'); a=np.asarray(im)
        assert im.size==tuple(entry['size'])
        assert set(np.unique(a[:,:,3]))=={0,255}
        opaque=a[a[:,:,3]>0,:3]
        assert not ((opaque[:,0]>180)&(opaque[:,1]<40)&(opaque[:,2]>180)).any(),'magenta key fringe'
        if entry['frames']==12:
            cell=im.height//2
            walk=[im.crop((i*cell,0,(i+1)*cell,cell)) for i in range(6)]
            assert len({f.tobytes() for f in walk})==6,'duplicate motion frames'
            for frame in walk:
                assert frame.getbbox()[3]==entry['foot'],'walking foot plane drift'
    frames,renderer,shader_count=replay([ROOT/f'docs/previews/forest-arcade-draws-{i}.json' for i in range(6)])
    out=ROOT/'docs/previews'
    frames[0].save(out/'forest-arcade-v3-runtime.png')
    frames[0].resize((922,648),Image.Resampling.NEAREST).save(out/'forest-arcade-v3-camera072.png')
    frames[0].crop((380,120,870,570)).resize((980,900),Image.Resampling.NEAREST).save(out/'forest-arcade-v3-zoom.png')
    frames[0].save(out/'forest-arcade-v3-motion.gif',save_all=True,append_images=frames[1:],duration=100,loop=0)
    print('FOREST_ARCADE_ASSETS_OK sprites=11 shaders='+str(shader_count)+' renderer='+renderer)

if __name__=='__main__': main()
