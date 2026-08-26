"""Actual Lua world-render replay using the standalone GPU; no game window."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
from headless_lua import run
from verify_forest_arcade_assets import replay

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/previews'

def main():
    run(ROOT/'scripts/verify_forest_scenery.lua','SCENERY_CAPTURE=true')
    views=['ridge','woodland','hollow','dry','without']
    frames,renderer,count=replay([OUT/f'forest-scenery-{name}-draws.json' for name in views],size=(1600,1000))
    panels=[]
    font=ImageFont.truetype(str(ROOT/'assets/font-korean-regular.ttf'),20)
    for name,frame,label in zip(views,frames,['바위 능선','숲속 공터','수풀 지대','낙엽 숲','장식물 없는 동일 배치']):
        frame.save(OUT/f'forest-scenery-{name}-native.png')
        view=frame.resize((1152,720),Image.Resampling.NEAREST)
        view.save(OUT/f'forest-scenery-{name}-camera072.png')
        if name!='without':
            panel=Image.new('RGB',(768,510),(29,39,29));panel.paste(view.resize((768,480),Image.Resampling.NEAREST),(0,0))
            ImageDraw.Draw(panel).text((14,484),label,font=font,fill=(231,215,167));panels.append(panel)
    sheet=Image.new('RGB',(1536,1020))
    for i,panel in enumerate(panels):sheet.paste(panel,((i%2)*768,(i//2)*510))
    sheet.save(OUT/'forest-scenery-regions.png')
    frames[1].crop((350,350,1050,850)).resize((1400,1000),Image.Resampling.NEAREST).save(OUT/'forest-scenery-detail.png')
    print('FOREST_SCENERY_RENDER_OK views=5 shaders='+str(count)+' renderer='+renderer)

if __name__=='__main__':main()
