"""Bake the locked Zarathustra key art into a shared-palette 6x2 atlas and FX strip."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/"assets/characters/concepts/philosopher-keyart-v2.png"
ATLAS=ROOT/"assets/characters/ingame/philosopher-atlas-pixel-v2.png"
FX=ROOT/"assets/fx/philosopher/philosopher-sermon-fx-pixel-v1.png"
PREVIEW=ROOT/"docs/previews/philosopher-motion-v1.png"
CELL_W,CELL_H,FOOT=96,192,190

def keyed(im):
    im=im.convert("RGBA"); p=im.load()
    for y in range(im.height):
        for x in range(im.width):
            r,g,b,a=p[x,y]
            if r>210 and b>190 and g<90: p[x,y]=(0,0,0,0)
            else: p[x,y]=(r,g,b,255)
    return im

def components(im):
    a=im.getchannel("A"); mid=im.width//2
    out=[]
    for bounds in ((0,0,mid,im.height),(mid,0,im.width,im.height)):
        part=im.crop(bounds); box=part.getchannel("A").getbbox()
        out.append(part.crop(box))
    return out

def stride(frame, amount):
    """Move the two boot/hem masses in opposition without changing the model."""
    if not amount: return frame
    out=frame.copy(); split=round(frame.height*.72); lower=frame.crop((0,split,frame.width,frame.height)); out.paste((0,0,0,0),(0,split,frame.width,frame.height))
    half=frame.width//2
    out.alpha_composite(lower.crop((0,0,half,lower.height)),(amount,split))
    out.alpha_composite(lower.crop((half,0,lower.width,lower.height)),(half-amount,split))
    return out

def articulate(frame, amount):
    """Animate the mouth/jaw only; the quiet hands and body remain locked."""
    if not amount: return frame
    out=frame.copy(); x1,x2=round(frame.width*.56),round(frame.width*.77); y1,y2=round(frame.height*.20),round(frame.height*.37); mid=round((y1+y2)*.55)
    jaw=frame.crop((x1,mid,x2,y2)); out.paste((0,0,0,0),(x1,mid,x2,y2)); out.alpha_composite(jaw,(x1,mid+amount))
    return out

def place(canvas, frame, col, row, scale, dx=0, dy=0, step=0, mouth=0):
    size=(round(frame.width*scale),round(frame.height*scale))
    frame=articulate(stride(frame.resize(size,Image.Resampling.NEAREST),step),mouth)
    x=col*CELL_W+(CELL_W-frame.width)//2+dx
    y=row*CELL_H+FOOT-frame.height+dy
    canvas.alpha_composite(frame,(x,y))

def build_atlas():
    walk,preach=components(keyed(Image.open(SOURCE)))
    scale=min(86/walk.width,174/walk.height,86/preach.width,174/preach.height)
    atlas=Image.new("RGBA",(CELL_W*6,CELL_H*2))
    walk_moves=[(0,0,1.0,0),(-1,-2,1.0,2),(1,-1,.995,4),(0,0,1.0,0),(1,-2,1.0,-2),(-1,-1,.995,-4)]
    action_moves=[(-1,0,.985,0),(0,-1,1.0,1),(0,-1,1.0,2),(0,-1,1.0,1),(-1,0,.99,0),(0,-1,1.0,2)]
    for i,(dx,dy,s,step) in enumerate(walk_moves): place(atlas,walk,i,0,scale*s,dx,dy,step)
    for i,(dx,dy,s,mouth) in enumerate(action_moves): place(atlas,preach,i,1,scale*s,dx,dy,mouth=mouth)
    alpha=atlas.getchannel("A")
    rgb=Image.new("RGB",atlas.size); rgb.paste(atlas.convert("RGB"),mask=alpha)
    q=rgb.quantize(colors=104,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE).convert("RGBA")
    q.putalpha(alpha.point(lambda v:255 if v else 0)); return q

def build_fx():
    cell=192; sheet=Image.new("RGBA",(cell*6,cell))
    ramps=[(34,44,14,255),(75,91,24,255),(124,145,39,255),(175,194,61,255),(218,226,102,255),(242,241,170,255)]
    for f in range(6):
        d=ImageDraw.Draw(sheet); ox=f*cell; length=28+f*24
        for x in range(10,length):
            width=max(2,round((7+f*1.4)*(1-x/(length+20))))
            for y in range(-width,width+1):
                if ((x+y*3+f*5)&3)==0 or abs(y)<width*.55:
                    shade=min(5,max(0,3-y//3+(1 if (x+y)&1 else 0)))
                    d.point((ox+x,96+y+round(3*__import__('math').sin(x*.16+f))),fill=ramps[shade])
        for j in range(4+f):
            x=ox+24+(j*31+f*13)%max(36,length); y=76+((j*17+f*7)%39)
            r=2+(j+f)%3; d.ellipse((x-r,y-r,x+r,y+r),fill=ramps[3+(j%3)])
    return sheet

def main():
    atlas=build_atlas(); fx=build_fx(); ATLAS.parent.mkdir(parents=True,exist_ok=True); FX.parent.mkdir(parents=True,exist_ok=True); PREVIEW.parent.mkdir(parents=True,exist_ok=True)
    atlas.save(ATLAS); fx.save(FX)
    board=Image.new("RGB",(720,430),(86,123,59)); board.paste(atlas,(72,20),atlas); board.paste(fx.resize((576,96),Image.Resampling.NEAREST),(72,320),fx.resize((576,96),Image.Resampling.NEAREST)); board.save(PREVIEW)
    colors={p[:3] for p in atlas.getdata() if p[3]}; assert atlas.size==(576,384) and 70<=len(colors)<=104
    print(f"PHILOSOPHER_BUILD_OK atlas={atlas.size} colors={len(colors)} fx={fx.size}")
if __name__=="__main__": main()
