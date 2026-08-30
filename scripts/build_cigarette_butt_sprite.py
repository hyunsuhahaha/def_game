"""Bake native GLSL discarded-cigarette artwork with no game window."""
from pathlib import Path
import moderngl
from build_cigarette_pixel_sprite import VERTEX,love_fragment,render

ROOT=Path(__file__).resolve().parents[1]
def main():
    import argparse
    parser=argparse.ArgumentParser();parser.add_argument('--preview',action='store_true');args=parser.parse_args()
    ctx=moderngl.create_standalone_context()
    shader=ctx.program(vertex_shader=VERTEX,fragment_shader=love_fragment(ROOT/'assets/shaders/cigarette-butt-material.glsl'))
    image=render(ctx,shader,(256,64))
    assert set(image.getchannel('A').tobytes())=={0,255}
    colors={p[:3] for p in image.get_flattened_data() if p[3]}
    assert 50<=len(colors)<=128,len(colors)
    image.save(ROOT/'assets/characters/ingame/smoker-cigarette-butt-pixel-v1.png')
    image.resize((1024,256),resample=0).save(ROOT/'docs/previews/smoker-ground-butt-pixels.png')
    texture=ctx.texture(image.size,4,image.tobytes());texture.filter=(moderngl.NEAREST,moderngl.NEAREST)
    burn=ctx.program(vertex_shader=VERTEX,fragment_shader=love_fragment(ROOT/'assets/shaders/cigarette-butt-burn.glsl'))
    burn['emberTime'].value=1.0
    for progress,heat in [(0,1),(.5,1),(1,0)]:
        burn['burnProgress'].value=progress;burn['heat'].value=heat
        result=render(ctx,burn,image.size,texture)
        assert set(result.getchannel('A').tobytes())=={0,255}
    fx=ctx.program(vertex_shader=VERTEX,fragment_shader=love_fragment(ROOT/'assets/shaders/cigarette-ground-fx.glsl'))
    fx['fxGrid'].value=(192,384);fx['fxTime'].value=1;fx['strength'].value=1
    for kind in range(3):
        fx['fxKind'].value=kind
        result=render(ctx,fx,(192,384))
        assert result.getchannel('A').getbbox(),kind
    print('CIGARETTE_BUTT_GPU_OK colors='+str(len(colors))+' renderer='+ctx.info['GL_RENDERER'])
    if args.preview:
        from headless_lua import run
        from verify_forest_arcade_assets import replay
        from PIL import Image,ImageDraw,ImageFont
        run(ROOT/'scripts/verify_smoker_objects_and_developer_range.lua','SMOKER_GROUND_CAPTURE=true')
        out=ROOT/'docs/previews'
        frames,renderer,count=replay([out/f'smoker-ground-draws-{i}.json' for i in range(45)],size=(640,460))
        cold,_,_=replay([out/'smoker-ground-expired.json'],size=(640,460))
        font=ImageFont.truetype(str(ROOT/'assets/font-korean-regular.ttf'),16)
        def caption(image,label,zoom=False):
            image=image.resize((461,331),Image.Resampling.NEAREST) if zoom else image
            panel=Image.new('RGB',(image.width,image.height+36),(26,32,24));panel.paste(image,(0,0))
            ImageDraw.Draw(panel).text((12,image.height+8),label,font=font,fill=(241,217,170))
            return panel
        selected=[(1,'0.1s 빠른 투척 중'),(3,'0.3s 착지 → 바닥에 잔류'),(4,'0.4s 첫 착화 실패 → 짧게 재시도'),(10,'1.0s 성공한 불씨가 나무로 이동'),(12,'1.2s 불씨 도착 → 밑동에서 점화')]
        panels=[caption(frames[i],label,True) for i,label in selected]
        panels.append(caption(cold[0],'7.5s 별도 실패 사례 → 꺼진 꽁초',True))
        sheet=Image.new('RGB',(461*3,367*2),(26,32,24))
        for i,panel in enumerate(panels):sheet.paste(panel,((i%3)*461,(i//3)*367))
        sheet.save(out/'smoker-ground-lifecycle.png')
        labeled=[]
        for i,frame in enumerate(frames):
            phase='빠른 투척' if i<3 else ('잔류 · 즉시 착화 대기' if i<4 else ('첫 시도 실패 · 재시도' if i<10 else ('불씨 전이' if i<12 else '밑동 착화')))
            labeled.append(caption(frame,f'오프스크린 검증  {i/10:.1f}s  |  {phase}'))
        labeled[0].save(out/'smoker-ground-lifecycle.gif',save_all=True,append_images=labeled[1:],duration=100,loop=0)
        frames[10].crop((330,260,500,400)).resize((680,560),Image.Resampling.NEAREST).save(out/'smoker-ground-transfer-zoom.png')
        print('SMOKER_GROUND_VISUAL_OK shaders='+str(count)+' renderer='+renderer)
if __name__=='__main__':main()
