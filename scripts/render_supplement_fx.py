"""Offscreen real Lua draw replay for shared skill FX. Not a live engine capture."""
from pathlib import Path
import json
import numpy as np
from PIL import Image,ImageDraw,ImageFont
from headless_lua import run
from verify_forest_arcade_assets import replay
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'docs/previews'
CASES=[('bat_swarm','박쥐 떼','날갯짓 · 근접 궤도',7),('thorn_aura','가시 오라','가시 덩굴 · 타격 펄스',1),
 ('crow_strike','까마귀 습격','최원거리 접촉 · 깃털 비산',3),('vine_whip','덩굴 채찍','부채꼴 후려치기 · 잔상',4),
 ('boomerang_axe','부메랑 도끼','회전 · 왕복 잔상',6),('seed_mine','씨앗 지뢰','발아 예고 · 껍질 폭발',18),
 ('chain_lightning','번개 사슬','피격 대상 연결 · 전기 가지',3)]
def board(frames):
    canvas=Image.new('RGB',(1280,1904),(21,29,29));p=ImageDraw.Draw(canvas)
    title=ImageFont.truetype(str(ROOT/'assets/font-korean-bold.ttf'),26)
    small=ImageFont.truetype(str(ROOT/'assets/font-korean-regular.ttf'),18)
    p.text((20,12),'보조 스킬 7종 / 실제 Lua + 셰이더 오프스크린 렌더',font=title,fill=(231,225,189))
    p.text((20,50),'카메라 0.72 · 제어된 표적 · HUD 제외 · 게임 창 실행 없음',font=small,fill=(163,183,176))
    for i,(frame,case) in enumerate(zip(frames,CASES)):
        x,y=(i%2)*640,88+(i//2)*454
        p.text((x+15,y),case[1],font=title,fill=(237,226,173))
        p.text((x+215,y+7),case[2],font=small,fill=(169,188,173))
        canvas.paste(frame,(x,y+45))
    return canvas
def main():
    run(ROOT/'scripts/verify_supplement_fx.lua')
    run(ROOT/'scripts/capture_supplement_fx.lua')
    paths=[OUT/f'supplement-{case[0]}-{n}-draws.json' for case in CASES for n in range(25)]
    allframes,renderer,shaders=replay(paths,(640,400))
    groups=[allframes[i*25:(i+1)*25] for i in range(7)]
    report=[]
    for case,frames in zip(CASES,groups):
        assert len({f.tobytes() for f in frames})>4,(case[0],'stalled motion')
        frames[case[3]].save(OUT/f'supplement-{case[0]}-v1.png')
        frames[0].save(OUT/f'supplement-{case[0]}-v1.gif',save_all=True,append_images=frames[1:],duration=70,loop=0)
        commands=json.loads((OUT/f'supplement-{case[0]}-{case[3]}-draws.json').read_text())
        fx=[c for c in commands if c.get('shader')=='assets/shaders/supplement-fx.glsl' or c.get('file','').startswith('assets/fx/supplement/')]
        assert fx,(case[0],'no skill draws')
        report.append(dict(id=case[0],draws=len(fx),frames=25,distinct=len({f.tobytes() for f in frames})))
    board([frames[c[3]] for c,frames in zip(CASES,groups)]).save(OUT/'supplement-fx-v1.png')
    moving=[board([frames[n] for frames in groups]).resize((960,1428),Image.Resampling.NEAREST) for n in range(25)]
    moving[0].save(OUT/'supplement-fx-v1.gif',save_all=True,append_images=moving[1:],duration=70,loop=0)
    combined_paths=[OUT/f'supplement-all-{n}-draws.json' for n in range(25)]
    combined,_,_=replay(combined_paths,(1280,720))
    combined[1].save(OUT/'supplement-combined-v1.png')
    combined[0].save(OUT/'supplement-combined-v1.gif',save_all=True,append_images=combined[1:],duration=67,loop=0)
    counts=[]
    for path in combined_paths:
        commands=json.loads(path.read_text())
        counts.append(sum(c.get('shader')=='assets/shaders/supplement-fx.glsl' or c.get('file','').startswith('assets/fx/supplement/') for c in commands))
    assert max(counts)<100,'unbounded shared-skill draw submissions'
    (OUT/'supplement-fx-verification.json').write_text(json.dumps(dict(renderer=renderer,shaders=shaders,skills=report,combined_peak_draws=max(counts),window='none',capture='Actual Lua World/Player/skills with fixed stationary targets; each panel shows one activation at an independent playback rate. Combined view retains the generated forest. HUD, generic world debris, live input/audio excluded.'),indent=2),encoding='utf-8')
    print('SUPPLEMENT_RENDER_OK skills=7 frames=200 combined_peak_draws='+str(max(counts))+' shaders='+str(shaders)+' renderer='+renderer)
if __name__=='__main__':main()
