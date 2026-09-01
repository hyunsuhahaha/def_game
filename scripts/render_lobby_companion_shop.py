"""Render shop placement and facility motion at actual scale plus pixel zoom."""
from pathlib import Path
from PIL import Image,ImageDraw
from headless_lua import run
from render_clearcut_synergy_ui import render_ui

ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/"docs/previews"

def frame(width,height,opened=False,amenity="ball",moment=0):
    run(ROOT/"scripts/capture_lobby_companion_shop.lua",
        f'CAPTURE_W={width};CAPTURE_H={height};SHOP_OPEN={str(opened).lower()};'
        f'SHOP_AMENITY="{amenity}";SHOP_PREVIEW_TIME={moment}')
    source=OUT/f"lobby-companion-shop-draws-{width}-{'store' if opened else 'world'}.json"
    return render_ui(source,(width,height))

def save_stills():
    world=frame(1280,720,False,"cat_tower",3.45);world.save(OUT/"lobby-companion-shop-v2-world.png")
    store=frame(1280,720,True,"ball",0);store.save(OUT/"lobby-companion-shop-v2-store.png")
    compact=frame(960,540,True,"sand",1.2);compact.save(OUT/"lobby-companion-shop-v2-store-compact.png")

def motion_gif(kind,name,crop):
    frames=[]
    for index in range(36):frames.append(frame(1280,720,False,kind,index/6).crop(crop))
    target=OUT/name
    frames[0].save(target,save_all=True,append_images=frames[1:],duration=110,loop=0,disposal=2,optimize=False)
    return target

def interaction_board():
    scenes=(("BALL CHASE","ball",1.05,(500,430,730,670)),
            ("MOLE BURROW","sand",1.2,(650,455,870,690)),
            ("CAT TOWER LEAP","cat_tower",3.45,(780,410,1070,680)),
            ("SWING RIDE","swing",.8,(930,405,1225,675)))
    board=Image.new("RGB",(590,540),(6,18,13));draw=ImageDraw.Draw(board)
    for i,(label,kind,moment,crop) in enumerate(scenes):
        shot=frame(1280,720,False,kind,moment).crop(crop);shot.thumbnail((285,240),Image.Resampling.NEAREST)
        x=(i%2)*295;y=(i//2)*270;board.paste(shot,(x,y+24));draw.text((x+10,y+6),label,fill=(190,218,170))
    target=OUT/"lobby-companion-shop-v2-interactions.png";board.save(target);return target

def pixel_zoom():
    atlas=Image.open(ROOT/"assets/ui/lobby-playgrounds-pixel-v2.png").convert("RGBA")
    swing=Image.open(ROOT/"assets/ui/lobby-swing-motion-pixel-v1.png").convert("RGBA").crop((4*160,0,5*160,128))
    board=Image.new("RGB",(1280,720),(6,18,13));draw=ImageDraw.Draw(board)
    zoom=atlas.resize((atlas.width*2,atlas.height*2),Image.Resampling.NEAREST)
    board.paste(zoom,(0,36),zoom);draw.text((12,12),"FACILITIES 2X NATIVE PIXELS",fill=(190,218,170))
    swing=swing.resize((swing.width*3,swing.height*3),Image.Resampling.NEAREST)
    board.paste(swing,(400,330),swing);draw.text((412,310),"SWING MOTION FRAME 3X",fill=(190,218,170))
    target=OUT/"lobby-companion-shop-v2-pixel-zoom.png";board.save(target);return target

def motion_contact(gif_path,name):
    source=Image.open(gif_path);board=Image.new("RGB",(source.width*2,source.height*2),(6,18,13))
    for i,frame_index in enumerate((0,9,18,27)):
        source.seek(frame_index);shot=source.convert("RGB")
        board.paste(shot,((i%2)*source.width,(i//2)*source.height))
    target=OUT/name;board.save(target);return target

if __name__=="__main__":
    save_stills();cat=motion_gif("cat_tower","lobby-cat-tower-v1.gif",(700,390,1040,690))
    swing=motion_gif("swing","lobby-swing-v1.gif",(870,390,1240,690))
    made=(interaction_board(),cat,swing,motion_contact(cat,"lobby-cat-tower-v1-contact.png"),
        motion_contact(swing,"lobby-swing-v1-contact.png"),pixel_zoom())
    print("LOBBY_COMPANION_SHOP_PREVIEW_OK "+" ".join(str(p.relative_to(ROOT))for p in made)+" window=none")
