"""Bake the authored pixel material with an offscreen GPU, never a game window.

Requires moderngl and Pillow. The GLSL is the source artwork; the generated
reference image is deliberately not sampled or downscaled into the sprite.
"""
from pathlib import Path
import argparse
import moderngl
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
VERTEX = '''#version 330
in vec2 position;
out vec2 uv;
void main() { uv=vec2((position.x+1.0)*0.5,(1.0-position.y)*0.5); gl_Position=vec4(position,0,1); }
'''


def love_fragment(path):
    source = path.read_text(encoding="utf-8")
    return ('#version 330\n#define Image sampler2D\n#define Texel texture\n'
            '#define number float\n#define extern uniform\n'
            'uniform sampler2D image; in vec2 uv; out vec4 result;\n' + source +
            '\nvoid main() { result=effect(vec4(1),image,uv,gl_FragCoord.xy); }')


def render(ctx, program, size, texture=None):
    import struct
    vertices = ctx.buffer(struct.pack('8f', -1,-1, 1,-1, -1,1, 1,1))
    vao = ctx.simple_vertex_array(program, vertices, 'position')
    target = ctx.simple_framebuffer(size, components=4)
    target.use(); target.clear(0,0,0,0)
    if texture is not None:
        texture.use(0); program['image'].value=0
    vao.render(moderngl.TRIANGLE_STRIP)
    image = Image.frombytes('RGBA', size, target.read(components=4)).transpose(Image.Transpose.FLIP_TOP_BOTTOM)
    vao.release(); vertices.release(); target.release()
    return image


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, default=ROOT/'assets/characters/ingame/smoker-cigarette-pixel-v2.png')
    parser.add_argument('--preview', type=Path)
    args=parser.parse_args()
    ctx=moderngl.create_standalone_context()
    material=ctx.program(vertex_shader=VERTEX, fragment_shader=love_fragment(ROOT/'assets/shaders/cigarette-material.glsl'))
    image=render(ctx,material,(256,48))
    assert image.getchannel('A').getextrema()==(0,255)
    pixels=list(zip(*[iter(image.tobytes())]*4))
    assert {pixel[3] for pixel in pixels}=={0,255}, 'soft alpha violates the pixel grid'
    colors={pixel[:3] for pixel in pixels if pixel[3]}
    assert 40<=len(colors)<=160, f'unexpected material palette: {len(colors)}'
    args.output.parent.mkdir(parents=True,exist_ok=True); image.save(args.output)
    # Compile and render the actual runtime ember shader, too.
    ember=ctx.program(vertex_shader=VERTEX,fragment_shader=love_fragment(ROOT/'assets/shaders/cigarette-ember.glsl'))
    texture=ctx.texture(image.size,4,image.tobytes()); texture.filter=(moderngl.NEAREST,moderngl.NEAREST)
    ember['emberTime'].value=1.0
    lit=render(ctx,ember,image.size,texture)
    assert lit.getchannel('A').tobytes()==image.getchannel('A').tobytes(), 'ember changed silhouette'
    smoke=ctx.program(vertex_shader=VERTEX,fragment_shader=love_fragment(ROOT/'assets/shaders/cigarette-smoke.glsl'))
    smoke['smokeTime'].value=1.0; smoke['smokeFacing'].value=1.0
    wisp=render(ctx,smoke,(192,384))
    assert wisp.getchannel('A').getextrema()[1]>0, 'smoke shader produced no wisp'
    if args.preview:
        # Nearest enlargement is for inspecting the authored grid, not game use.
        lit.resize((1024,192),Image.Resampling.NEAREST).save(args.preview)
    print(f'CIGARETTE_GPU_OK size={image.size} colors={len(colors)} renderer={ctx.info["GL_RENDERER"]}')
    print(args.output)


if __name__=='__main__':
    main()
