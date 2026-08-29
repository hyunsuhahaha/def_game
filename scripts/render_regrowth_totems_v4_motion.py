"""Render all four v4 totems at the approved .72 gameplay camera scale."""
from pathlib import Path
from PIL import Image, ImageDraw


ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"docs/previews/regrowth-totems-v4-runtime-motion.gif"
PRISM=Image.open(ROOT/"assets/enemies/arcade/regrowth-prism-rotation-atlas-v1.png").convert("RGBA")
CAMERA=.72
SPECS=[
    ("TEMPERATE","forest",68,206,0,42,43),
    ("MANGROVE","mangrove",70,210,1,42,43),
    ("MADAGASCAR","madagascar",72,212,2,44,44),
    ("ISLAND","island",74,214,3,44,43),
]


def nearest(image,size):return image.resize(size,Image.Resampling.NEAREST)


def main():
    frames=[]
    bodies={}
    for _,name,width,body_width,_,_,_ in SPECS:
        atlas=Image.open(ROOT/f"assets/enemies/arcade/planter-{name}-atlas-v4.png").convert("RGBA")
        body=atlas.crop((0,0,256,256));scale=width/body_width*CAMERA
        bodies[name]=nearest(body,(round(256*scale),round(256*scale)))
    for frame in range(24):
        canvas=Image.new("RGBA",(640,180),(57,86,42,255));draw=ImageDraw.Draw(canvas)
        draw.rectangle((0,121,640,180),fill=(66,96,46,255))
        for i,(label,name,width,body_width,row,prism_width,prism_y) in enumerate(SPECS):
            x=80+i*160;foot=133;body=bodies[name];body_scale=width/body_width*CAMERA
            canvas.alpha_composite(body,(round(x-body.width/2),round(foot-248*body_scale)))
            core=PRISM.crop((frame*64,row*64,(frame+1)*64,(row+1)*64))
            size=round(prism_width*CAMERA);core=nearest(core,(size,size))
            canvas.alpha_composite(core,(round(x-size/2),round(foot-prism_y*CAMERA-size/2)))
            draw.text((x-30,151),label,fill=(219,226,164,255))
        # 2x nearest presentation; the authored sprite sizes above remain .72-camera exact.
        frames.append(canvas.resize((1280,360),Image.Resampling.NEAREST).convert("P",palette=Image.Palette.ADAPTIVE,colors=255))
    OUT.parent.mkdir(parents=True,exist_ok=True)
    frames[0].save(OUT,save_all=True,append_images=frames[1:],duration=50,loop=0,disposal=2)
    print("REGROWTH_TOTEMS_V4_MOTION_OK",OUT.relative_to(ROOT),"frames=24 camera=.72 fps=20")


if __name__=="__main__":main()
