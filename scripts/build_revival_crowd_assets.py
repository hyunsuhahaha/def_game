"""Bake three locked follower models into a 6-frame cheering atlas."""
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'assets/characters/concepts/philosopher-followers-keyart-v1.png'
OUT=ROOT/'assets/fx/philosopher/revival-crowd-atlas-pixel-v1.png'
PREVIEW=ROOT/'docs/previews/philosopher-revival-crowd-v1.png'
CW,CH,FOOT=96,160,157

def key(im):
    im=im.convert('RGBA'); p=im.load()
    for y in range(im.height):
        for x in range(im.width):
            r,g,b,a=p[x,y]; p[x,y]=(r,g,b,0 if r>210 and b>185 and g<100 else 255)
    return im

def cell(im,col,row):
    x1=round(col*im.width/3);x2=round((col+1)*im.width/3);y1=round(row*im.height/2);y2=round((row+1)*im.height/2)
    part=im.crop((x1,y1,x2,y2));box=part.getchannel('A').getbbox();return part.crop(box)

def place(atlas,frame,col,row,bob=0,sway=0):
    scale=min(86/frame.width,148/frame.height);size=(round(frame.width*scale),round(frame.height*scale));frame=frame.resize(size,Image.Resampling.NEAREST)
    if sway:
        head=frame.crop((0,0,frame.width,round(frame.height*.58))); frame.alpha_composite(head,(sway,0))
    x=col*CW+(CW-frame.width)//2;y=row*CH+FOOT-frame.height-bob;atlas.alpha_composite(frame,(x,y))

def main():
    src=key(Image.open(SOURCE));atlas=Image.new('RGBA',(CW*6,CH*3));motion=[(0,0),(2,1),(5,-1),(2,0),(6,1),(3,-1)]
    for who in range(3):
        calm,cheer=cell(src,who,0),cell(src,who,1)
        place(atlas,calm,0,who)
        for frame,(bob,sway) in enumerate(motion[1:],1):place(atlas,cheer,frame,who,bob,sway)
    alpha=atlas.getchannel('A');rgb=Image.new('RGB',atlas.size);rgb.paste(atlas.convert('RGB'),mask=alpha)
    atlas=rgb.quantize(colors=104,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE).convert('RGBA');atlas.putalpha(alpha.point(lambda v:255 if v else 0))
    OUT.parent.mkdir(parents=True,exist_ok=True);PREVIEW.parent.mkdir(parents=True,exist_ok=True);atlas.save(OUT)
    bg=Image.new('RGB',(720,560),(86,123,59));bg.paste(atlas,(72,40),atlas);bg.save(PREVIEW)
    assert atlas.size==(576,480);print('REVIVAL_CROWD_BUILD_OK followers=3 frames=18')
if __name__=='__main__':main()
