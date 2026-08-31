from pathlib import Path
import math
import random
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / "assets/fx/oil-drum-spill"
PREVIEW = ROOT / "docs/previews"
PREVIEW.mkdir(parents=True, exist_ok=True)
W, H, FRAMES = 256, 200, 8

OUTLINE = [(20,164),(29,154),(50,151),(43,143),(65,137),(91,139),(107,132),
           (132,137),(151,133),(169,141),(193,140),(202,148),(228,151),(238,160),
           (229,168),(207,171),(215,178),(190,181),(169,178),(153,185),(128,181),
           (106,187),(91,180),(65,182),(52,175),(31,176)]

def polygon(draw, points, color):
    draw.polygon([(round(x), round(y)) for x, y in points], fill=color)

def puddle_cell():
    im = Image.new("RGBA", (W, H))
    d = ImageDraw.Draw(im)
    polygon(d, OUTLINE, (24, 20, 22, 255))
    polygon(d, [(25,161),(37,154),(63,153),(55,146),(86,142),(109,145),(126,139),
                (151,141),(168,137),(187,146),(218,154),(231,161),(214,166),(185,168),
                (168,174),(143,171),(125,177),(101,174),(83,177),(63,171),(38,172)],
            (42, 36, 37, 255))
    polygon(d, [(35,158),(63,153),(91,151),(111,145),(140,145),(160,141),(184,148),
                (205,153),(188,157),(158,156),(140,162),(111,158),(83,163),(57,160)],
            (60, 50, 47, 255))
    polygon(d, [(42,154),(68,150),(91,150),(108,146),(122,147),(109,151),(84,154),(61,155)],
            (92, 70, 56, 255))
    polygon(d, [(151,145),(166,142),(184,148),(178,150),(158,148)], (110, 78, 55, 255))
    for x, y, length in [(46,160,15),(74,147,12),(94,156,17),(132,145,11),(176,153,14),(198,160,10)]:
        d.line((x,y,x+length,y-2), fill=(137,92,58,255), width=2)
        d.point((x+3,y-1), fill=(194,132,72,255))
    # Ordered, material-following glints instead of random noise.
    for y in range(151,171,4):
        for x in range(39+(y//4)%2*3,216,8):
            if im.getpixel((x,y))[3] and (x*3+y*5)%17<4:
                im.putpixel((x,y),(72,58,52,255))
    return im

def flame_shape(d, cx, base, height, width, lean, phase):
    sway = math.sin(phase) * width * .18
    outer = [(cx-width,base),(cx-width*.78,base-height*.28),(cx-width*.42+sway,base-height*.48),
             (cx-width*.26+lean,base-height*.72),(cx+lean*.55+sway,base-height),
             (cx+width*.28+lean,base-height*.66),(cx+width*.55,base-height*.43),(cx+width,base)]
    polygon(d, outer, (151,43,20,255))
    mid = [(cx-width*.68,base-2),(cx-width*.43,base-height*.29),(cx-width*.12+sway,base-height*.49),
           (cx+lean*.5,base-height*.77),(cx+width*.23+lean,base-height*.48),(cx+width*.61,base-2)]
    polygon(d, mid, (244,103,16,255))
    core = [(cx-width*.39,base-3),(cx-width*.16,base-height*.27),(cx+sway*.3,base-height*.51),
            (cx+width*.2,base-height*.28),(cx+width*.35,base-3)]
    polygon(d, core, (255,213,60,255))
    polygon(d, [(cx-width*.18,base-4),(cx,base-height*.24),(cx+width*.15,base-4)], (255,246,174,255))

def fire_cell(frame):
    im = Image.new("RGBA", (W, H))
    d = ImageDraw.Draw(im)
    specs = [(48,157,39,17,-4),(82,162,58,22,4),(120,160,45,19,-3),
             (157,159,63,23,5),(199,158,42,18,-4)]
    for i,(cx,base,height,width,lean) in enumerate(specs):
        phase=frame*.92+i*1.37
        flame_shape(d,cx,base,height+round(math.sin(phase)*6),width,lean+round(math.cos(phase)*4),phase)
    # Detached embers and stepped smoke move, but the grounded oil never does.
    for i in range(5):
        x=45+i*38+round(math.sin(frame*.8+i)*7)
        y=104-(i%2)*14-round((frame*5+i*11)%23)
        color=(244,102,18,255) if i%2 else (255,196,43,255)
        d.rectangle((x,y,x+3+(i%2),y+3+(i%3)),fill=color)
    for i in range(3):
        x=77+i*57+round(math.sin(frame*.7+i)*5)
        y=83-i*9-round((frame*3+i*7)%15)
        polygon(d,[(x-7,y+7),(x-4,y),(x+2,y-5),(x+8,y),(x+6,y+8),(x,y+11)],
                (68,54,48,190))
    return im

def atlas(frames):
    out=Image.new("RGBA",(W*4,H*2))
    for i,frame in enumerate(frames): out.alpha_composite(frame,((i%4)*W,(i//4)*H))
    return out

def clear_connected_light_background(source):
    """Remove only the concept board's border-connected pale checkerboard."""
    im=source.convert("RGBA")
    px=im.load();seen=set();stack=[]
    for x in range(im.width): stack.extend(((x,0),(x,im.height-1)))
    for y in range(im.height): stack.extend(((0,y),(im.width-1,y)))
    while stack:
        x,y=stack.pop()
        if (x,y) in seen or not(0<=x<im.width and 0<=y<im.height): continue
        seen.add((x,y));r,g,b,a=px[x,y]
        if a and min(r,g,b)>=174 and max(r,g,b)-min(r,g,b)<=18:
            px[x,y]=(r,g,b,0)
            stack.extend(((x-1,y),(x+1,y),(x,y-1),(x,y+1)))
    return im

def prepare_concept(crop, target_height):
    source=clear_connected_light_background(Image.open(ASSET / "oil-puddle-fire-concept-v2.png").crop(crop))
    box=source.getbbox();source=source.crop(box)
    scale=min(230/source.width,target_height/source.height)
    source=source.resize((round(source.width*scale),round(source.height*scale)),Image.Resampling.NEAREST)
    # Hard alpha and a restrained shared pixel palette keep the baked concept crisp.
    alpha=source.getchannel("A").point(lambda a:255 if a>=96 else 0)
    rgb=source.convert("RGB").quantize(colors=72,method=Image.Quantize.MEDIANCUT).convert("RGB")
    rgb.putalpha(alpha)
    cell=Image.new("RGBA",(W,H));cell.alpha_composite(rgb,((W-rgb.width)//2,185-rgb.height))
    return cell

ground_model=prepare_concept((35,420,700,755),86)
burning_model=prepare_concept((700,245,1400,765),154)

# Extract the flame/smoke layer while keeping the separately drawn ground model fixed.
fire_model=Image.new("RGBA",(W,H));src=burning_model.load();dst=fire_model.load()
for y in range(H):
    for x in range(W):
        r,g,b,a=src[x,y]
        hot=a and r>=92 and r>=g*1.06 and b<=150
        smoke=a and y<139 and max(r,g,b)<155
        if hot or smoke: dst[x,y]=(r,g,b,255)

ground=[ground_model.copy() for _ in range(FRAMES)]
fire=[]
for frame in range(FRAMES):
    cell=Image.new("RGBA",(W,H))
    # Flame bodies sway above the ignition line; their grounded roots never translate.
    upper=fire_model.crop((0,0,W,148))
    offset=(-2,-1,1,2,1,0,-1,-2)[frame]
    cell.alpha_composite(upper,(offset,0))
    cell.alpha_composite(fire_model.crop((0,148,W,H)),(0,148))
    fire.append(cell)
atlas(ground).save(ASSET / "oil-puddle-atlas-pixel-v2.png")
atlas(fire).save(ASSET / "oil-fire-overlay-atlas-pixel-v2.png")

combined=[]
for i in range(FRAMES):
    frame=ground[i].copy();frame.alpha_composite(fire[i]);combined.append(frame)
combined[0].save(PREVIEW / "oil-puddle-fire-v2-runtime.gif",save_all=True,
                 append_images=combined[1:],duration=120,loop=0,disposal=2)
board=Image.new("RGBA",(W*2,H*2),(48,59,38,255))
board.alpha_composite(ground[0],(0,0));board.alpha_composite(combined[0],(W,0))
zoom=Image.new("RGBA",(W*2,H),(48,59,38,255));zoom.alpha_composite(combined[3],(0,0))
zoom=zoom.resize((W*4,H*2),Image.Resampling.NEAREST)
board.alpha_composite(zoom.resize((W*2,H),Image.Resampling.NEAREST),(0,H))
board.save(PREVIEW / "oil-puddle-fire-v2-board.png")
print("OIL_PUDDLE_FIRE_V2_OK ground=stable fire=8 atlas=1024x400 cell=256x200")
