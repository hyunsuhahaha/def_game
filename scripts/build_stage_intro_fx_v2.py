"""Build high-density birds and authored leaf/feather debris for the v2 entry action."""
from pathlib import Path
from PIL import Image,ImageDraw

ROOT=Path(__file__).resolve().parents[1]
CW,CH,FRAMES,ROWS=160,112,8,4
BIRD_OUT=ROOT/'assets/fx/stage-intro/stage-intro-birds-atlas-pixel-v2.png'
DEBRIS_OUT=ROOT/'assets/fx/stage-intro/stage-intro-debris-atlas-pixel-v2.png'
PRE=ROOT/'docs/previews/stage-intro-fx-pixel-v2-2x.png'
WINGS=(-4,-25,-47,-65,-24,17,39,12)
PALETTES=(
 ((8,15,19),(20,32,39),(39,57,66),(68,88,96),(113,132,134),(190,201,192),(239,235,202),(108,49,31),(222,126,42),(255,192,74),(255,248,218),(52,74,78)),
 ((6,20,27),(10,43,54),(15,78,91),(22,121,133),(43,164,168),(108,206,192),(214,232,198),(112,50,29),(229,118,36),(255,177,57),(255,240,190),(55,139,142)),
 ((8,16,28),(16,35,66),(23,61,107),(32,93,148),(51,135,184),(108,183,207),(204,226,214),(91,39,34),(217,94,39),(251,153,55),(247,228,179),(71,129,168)),
 ((8,20,14),(17,49,27),(26,86,38),(39,128,48),(68,163,61),(137,194,85),(221,220,126),(112,38,27),(233,91,31),(255,151,38),(255,229,146),(93,148,62)),
)


def feather_polygon(root,tip,width):
    rx,ry=root;tx,ty=tip;dx,dy=tx-rx,ty-ry;n=max(1,(dx*dx+dy*dy)**.5);px,py=-dy/n*width,dx/n*width
    return [(round(rx+px),round(ry+py)),(round(tx+px*.18),round(ty+py*.18)),(tx,ty),(round(tx-px*.18),round(ty-py*.18)),(round(rx-px),round(ry-py))]


def bird(row,frame):
    im=Image.new('RGBA',(CW,CH));d=ImageDraw.Draw(im);p=PALETTES[row]
    ink,deep,s1,s2,s3,s4,belly,throat,beak,beak_hi,glint,mute=p;cy=64;wing=WINGS[frame]
    # Tail fan with individually readable feathers.
    for j,(tx,ty) in enumerate(((20,52),(13,62),(21,72))):
        d.polygon(feather_polygon((59,62),(tx,ty),5),fill=(ink if j==1 else deep)+(255,))
        d.line([(54,62),(tx+5,ty)],fill=mute+(255,),width=2)
    # Rear wing silhouette and six stepped primary feathers.
    shoulder=(76,58);up=wing<0
    tips=[]
    if up:
        for j in range(6):tips.append((48+j*7,20+wing+j*3))
    else:
        for j in range(6):tips.append((48+j*7,80+wing-j*2))
    d.polygon([shoulder]+tips+[(93,64)],fill=ink+(255,))
    for j,tip in enumerate(tips):
        root=(72+j*3,59+j%2);d.polygon(feather_polygon(root,tip,4.2),fill=(s1,s2,s3,s2,s1,s3)[j]+(255,))
        d.line([root,tip],fill=(s4 if j in (1,4) else mute)+(255,),width=1)
    # Body volume in material-specific stepped ramps.
    d.ellipse((48,48,119,83),fill=ink+(255,));d.ellipse((52,50,116,80),fill=deep+(255,));d.ellipse((57,51,115,76),fill=s2+(255,))
    d.polygon([(59,53),(93,49),(113,58),(103,63),(75,62)],fill=s4+(255,))
    d.polygon([(58,65),(80,58),(108,64),(101,78),(69,79)],fill=belly+(255,))
    d.line([(65,73),(92,76),(103,71)],fill=glint+(255,),width=2)
    # Shoulder coverts communicate wing attachment rather than a pasted triangle.
    d.ellipse((63,48,91,68),fill=deep+(255,));d.polygon([(67,51),(84,49),(89,57),(77,65),(65,60)],fill=s3+(255,))
    d.line([(69,54),(84,53),(78,61)],fill=s4+(255,),width=2)
    # Head, throat patch, beak and eye.
    d.ellipse((104,38,139,70),fill=ink+(255,));d.ellipse((108,41,136,67),fill=s2+(255,));d.polygon([(108,55),(124,61),(113,69),(102,65)],fill=throat+(255,))
    d.polygon([(135,49),(157,56),(136,62)],fill=ink+(255,));d.polygon([(137,52),(153,56),(137,59)],fill=beak+(255,));d.line([(139,53),(151,56)],fill=beak_hi+(255,),width=2)
    d.rectangle((123,45,130,52),fill=ink+(255,));d.rectangle((125,46,128,49),fill=glint+(255,))
    # Directional feather texture, kept off empty areas.
    for x,y in ((61,57),(69,69),(78,72),(87,68),(96,57),(102,72),(113,47),(116,60)):
        d.line([(x,y),(x+4,y-1)],fill=(s4 if (x+frame)%3 else mute)+(255,),width=1)
    return im


def debris():
    cell=32;atlas=Image.new('RGBA',(cell*8,cell))
    colors=[((24,45,22),(68,112,45),(137,166,74),(218,197,103)),((45,27,18),(126,58,34),(201,105,47),(239,164,70))]
    for i in range(8):
        im=Image.new('RGBA',(cell,cell));d=ImageDraw.Draw(im)
        if i<6:
            ramp=colors[i%2];cx,cy=16,16;tilt=(i-2.5)*.18
            pts=[(cx-11,cy),(cx-3,cy-7+(i%3)),(cx+10,cy-2),(cx+4,cy+7),(cx-5,cy+5)]
            d.polygon(pts,fill=ramp[0]+(255,));d.polygon([(cx-7,cy),(cx-2,cy-4),(cx+7,cy-2),(cx+2,cy+4)],fill=ramp[2]+(255,))
            d.line([(cx-9,cy+1),(cx+8,cy-1)],fill=ramp[3]+(255,),width=1);d.line([(cx,cy),(cx-5,cy-4)],fill=ramp[1]+(255,),width=1)
        else:
            shade=((27,35,42),(113,130,137),(226,225,203),(255,246,214));flip=-1 if i==7 else 1
            d.polygon([(16,5),(21,10),(18,25),(14,29),(12,20),(13,9)],fill=shade[0]+(255,))
            d.polygon([(16,7),(19,11),(17,23),(14,27),(14,11)],fill=shade[2]+(255,));d.line([(15,7),(15,27)],fill=shade[3]+(255,),width=1)
        atlas.alpha_composite(im,(i*cell,0))
    return atlas


def main():
    birds=Image.new('RGBA',(CW*FRAMES,CH*ROWS))
    for row in range(ROWS):
        for frame in range(FRAMES):birds.alpha_composite(bird(row,frame),(frame*CW,row*CH))
    bits=debris();BIRD_OUT.parent.mkdir(parents=True,exist_ok=True);PRE.parent.mkdir(parents=True,exist_ok=True)
    birds.save(BIRD_OUT,optimize=True);bits.save(DEBRIS_OUT,optimize=True)
    board=Image.new('RGBA',(birds.width*2,birds.height*2+bits.height*4),(10,18,15,255));board.alpha_composite(birds.resize((birds.width*2,birds.height*2),Image.Resampling.NEAREST));board.alpha_composite(bits.resize((bits.width*4,bits.height*4),Image.Resampling.NEAREST),(0,birds.height*2));board.save(PRE)
    colors={px[:3] for px in birds.get_flattened_data() if px[3]};assert len(colors)>=48 and set(birds.getchannel('A').get_flattened_data())=={0,255}
    print(f'STAGE_INTRO_FX_V2_OK birds={birds.width}x{birds.height} cell={CW}x{CH} frames={FRAMES} species={ROWS} colors={len(colors)} debris=8x32')

if __name__=='__main__':main()
