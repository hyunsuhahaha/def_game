"""Build the selected bean-shaped graduation monkey and detached equipment."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/"assets"/"characters"/"companions";PREVIEW=ROOT/"docs"/"previews"
S=2;LOGICAL=64;CELL=128;PROP_LOGICAL=32;PROP=64;COLS=6
INK=(46,31,24,255);INK2=(75,45,30,255);FUR_D=(116,65,39,255);FUR=(171,99,57,255);FUR_M=(198,124,73,255);FUR_H=(226,158,101,255)
FACE_D=(203,143,96,255);FACE=(235,183,130,255);FACE_H=(250,211,163,255);EYE=(52,35,29,255);EYE_WARM=(105,65,40,255);WHITE=(255,250,232,255);BLUSH=(224,129,105,255)
HAND=(235,176,125,255);STEEL=(148,169,178,255);STEEL_H=(220,235,233,255);WOOD=(163,102,49,255);PAPER=(236,218,178,255)
EMBER=(255,82,25,255);EMBER_H=(255,230,88,255);RED=(190,47,35,255);BLUE=(55,115,156,255)

def box(d,xy,c):d.rectangle(xy,fill=c)
def ellipse(d,xy,c):d.ellipse(xy,fill=c)
def poly(d,pts,c):d.polygon(pts,fill=c)

WALK=[
 dict(bob=0,lean=-1,feet=(-1,1),hands=((17,45),(47,44))),dict(bob=-1,lean=0,feet=(0,2),hands=((18,44),(46,43))),
 dict(bob=0,lean=1,feet=(1,-1),hands=((18,45),(47,45))),dict(bob=1,lean=0,feet=(2,0),hands=((17,46),(46,45))),
 dict(bob=-1,lean=-1,feet=(-1,1),hands=((17,44),(47,43))),dict(bob=0,lean=1,feet=(1,-1),hands=((18,45),(46,44)))]
AXE=[
 dict(bob=0,lean=0,feet=(0,0),hands=((40,40),(47,38)),angle=-.35),dict(bob=-1,lean=-1,feet=(0,1),hands=((39,32),(45,27)),angle=-.95),
 dict(bob=-1,lean=-2,feet=(0,1),hands=((35,25),(41,20)),angle=-1.55),dict(bob=1,lean=2,feet=(1,-1),hands=((42,43),(49,48)),angle=.75),
 dict(bob=2,lean=3,feet=(1,-1),hands=((39,48),(47,53)),angle=1.45),dict(bob=0,lean=1,feet=(0,0),hands=((42,42),(48,42)),angle=.15)]
CIGARETTE=[
 dict(bob=0,lean=0,feet=(0,0),hands=((20,44),(42,37)),angle=-.2),dict(bob=-1,lean=-1,feet=(0,1),hands=((20,43),(40,31)),angle=-.45),
 dict(bob=-1,lean=-1,feet=(0,1),hands=((20,43),(38,27)),angle=-.6),dict(bob=0,lean=1,feet=(1,-1),hands=((20,45),(46,34)),angle=.05),
 dict(bob=1,lean=2,feet=(1,-1),hands=((20,46),(51,32)),angle=.15),dict(bob=0,lean=1,feet=(0,0),hands=((20,44),(46,38)),angle=0)]
FIREWORK=[
 dict(bob=0,lean=0,feet=(0,0),hands=((36,40),(44,37)),angle=-.15),dict(bob=0,lean=-1,feet=(0,0),hands=((38,37),(46,34)),angle=-.25),
 dict(bob=-1,lean=-2,feet=(0,1),hands=((39,35),(48,32)),angle=-.3),dict(bob=1,lean=3,feet=(1,-1),hands=((34,42),(43,39)),angle=-.15),
 dict(bob=2,lean=4,feet=(1,-1),hands=((32,45),(41,42)),angle=-.05),dict(bob=0,lean=1,feet=(0,0),hands=((36,41),(45,38)),angle=-.15)]
ROWS_DEF=[("walk",WALK),("axe",AXE),("cigarette",CIGARETTE),("firework",FIREWORK)]

def limb(d,start,end,width=5):
 d.line([start,end],fill=INK,width=width+4);d.line([start,end],fill=FUR_M,width=width)
 ellipse(d,(end[0]-3,end[1]-3,end[0]+3,end[1]+3),INK);ellipse(d,(end[0]-2,end[1]-2,end[0]+2,end[1]+2),HAND)

def monkey(frame,row_index):
 im=Image.new("RGBA",(LOGICAL,LOGICAL),(0,0,0,0));d=ImageDraw.Draw(im);bob=frame["bob"];lean=frame["lean"];cx=32+lean;top=5+bob
 for fx,delta in ((24,frame["feet"][0]),(38,frame["feet"][1])):
  ellipse(d,(fx+delta-6,55+bob,fx+delta+6,62+bob),INK);ellipse(d,(fx+delta-4,56+bob,fx+delta+5,60+bob),FACE);box(d,(fx+delta+1,57+bob,fx+delta+2,59+bob),FACE_H)
 lh,rh=frame["hands"]
 # Small torso and limbs are deliberately outside the head silhouette, matching
 # the selected concept instead of collapsing the character into a round head.
 limb(d,(cx-11,39+bob),lh);limb(d,(cx+11,39+bob),rh)
 ellipse(d,(cx-17,34+bob,cx+17,59+bob),INK);ellipse(d,(cx-15,35+bob,cx+15,57+bob),FUR)
 ellipse(d,(cx-12,38+bob,cx+10,54+bob),FUR_M);poly(d,[(cx+9,37+bob),(cx+14,42+bob),(cx+12,55+bob),(cx+8,51+bob)],FUR_D)
 # Round head, clearly separate from the narrower body.
 ellipse(d,(cx-22,top,cx+22,top+40),INK);ellipse(d,(cx-20,top+2,cx+20,top+38),FUR)
 ellipse(d,(cx-17,top+4,cx+15,top+34),FUR_M)
 poly(d,[(cx-17,top+14),(cx-13,top+5),(cx-5,top+3),(cx-10,top+16)],FUR_H);poly(d,[(cx+13,top+7),(cx+18,top+15),(cx+16,top+30),(cx+12,top+25)],FUR_D)
 for x,y in ((cx-14,top+9),(cx-11,top+7),(cx+12,top+12),(cx+15,top+18)):box(d,(x,y,x+1,y+1),FUR_H if x<cx else FUR_D)
 for ex in (cx-21,cx+21):
  ellipse(d,(ex-5,top+16,ex+5,top+27),INK);ellipse(d,(ex-3,top+18,ex+3,top+25),FACE_D);ellipse(d,(ex-1,top+20,ex+2,top+23),FACE_H)
 # Working poses bring both forearms in front of the bean body.  The walk row
 # keeps them behind so its silhouette remains clean at actual display size.
 if row_index>0:
  limb(d,(cx-11,40+bob),lh,4);limb(d,(cx+11,40+bob),rh,4)
 ellipse(d,(cx-14,top+13,cx,top+31),FACE);ellipse(d,(cx,top+13,cx+14,top+31),FACE);ellipse(d,(cx-9,top+24,cx+9,top+37),FACE_H)
 for ex in (cx-7,cx+7):
  # Round, warm eyes with two highlights.  Keeping the dark mass small avoids
  # the hollow-socket look of the rejected pass.
  ellipse(d,(ex-4,top+19,ex+4,top+28),INK2);ellipse(d,(ex-3,top+20,ex+3,top+27),EYE)
  ellipse(d,(ex-2,top+20,ex+1,top+23),WHITE);box(d,(ex+1,top+25,ex+2,top+26),EYE_WARM);box(d,(ex-2,top+26,ex,top+27),EYE_WARM)
 box(d,(cx-1,top+28,cx+1,top+30),INK2);box(d,(cx-3,top+33,cx+3,top+34),INK);box(d,(cx-2,top+35,cx+2,top+35),BLUSH)
 box(d,(cx-13,top+30,cx-10,top+31),BLUSH);box(d,(cx+10,top+30,cx+13,top+31),BLUSH)
 d.line([(cx-5,top+2),(cx-8,top-3),(cx-10,top-1)],fill=INK,width=2);d.line([(cx-2,top+2),(cx-1,top-4),(cx+1,top-1)],fill=INK,width=2);d.line([(cx+1,top+3),(cx+6,top-2),(cx+7,top+1)],fill=INK,width=2)
 return im.resize((CELL,CELL),Image.Resampling.NEAREST)

def axe_prop():
 im=Image.new("RGBA",(32,32),(0,0,0,0));d=ImageDraw.Draw(im);d.line([(8,27),(18,6)],fill=INK,width=6);d.line([(9,26),(18,7)],fill=WOOD,width=3)
 poly(d,[(15,4),(26,4),(29,9),(23,15),(15,12)],INK);poly(d,[(17,5),(25,6),(27,9),(22,13),(16,11)],STEEL);poly(d,[(19,6),(25,7),(23,9),(18,9)],STEEL_H);return im.resize((PROP,PROP),Image.Resampling.NEAREST)
def cigarette_prop():
 im=Image.new("RGBA",(32,32),(0,0,0,0));d=ImageDraw.Draw(im);poly(d,[(5,17),(25,12),(26,16),(6,21)],INK);poly(d,[(7,17),(20,14),(21,17),(7,20)],PAPER);poly(d,[(20,14),(25,13),(26,16),(21,17)],(194,136,76,255));box(d,(25,13,28,16),EMBER);box(d,(27,13,29,14),EMBER_H);return im.resize((PROP,PROP),Image.Resampling.NEAREST)
def firework_prop():
 im=Image.new("RGBA",(32,32),(0,0,0,0));d=ImageDraw.Draw(im);poly(d,[(5,20),(21,8),(27,9),(28,15),(12,27)],INK);poly(d,[(8,20),(22,10),(26,11),(26,14),(11,25)],RED);poly(d,[(8,20),(13,16),(17,20),(12,24)],BLUE);poly(d,[(22,9),(29,7),(27,14)],STEEL_H);d.line([(8,23),(4,28)],fill=WOOD,width=2);return im.resize((PROP,PROP),Image.Resampling.NEAREST)
PROPS=[("axe",axe_prop),("cigarette",cigarette_prop),("firework",firework_prop)]

def build():
 OUT.mkdir(parents=True,exist_ok=True);PREVIEW.mkdir(parents=True,exist_ok=True);atlas=Image.new("RGBA",(CELL*6,CELL*4),(0,0,0,0))
 for row,(_,frames) in enumerate(ROWS_DEF):
  for col,frame in enumerate(frames):atlas.alpha_composite(monkey(frame,row),(col*CELL,row*CELL))
 atlas.save(OUT/"graduate-monkey-atlas-pixel-v2.png");props=Image.new("RGBA",(PROP,PROP*3),(0,0,0,0))
 for row,(_,maker) in enumerate(PROPS):props.alpha_composite(maker(),(0,row*PROP))
 props.save(OUT/"graduate-monkey-props-pixel-v2.png")
 board=Image.new("RGBA",atlas.size,(35,48,27,255));board.alpha_composite(atlas);board.resize((atlas.width*2,atlas.height*2),Image.Resampling.NEAREST).save(PREVIEW/"graduate-monkey-v2-body-2x.png")
 equip=Image.new("RGBA",(CELL*3,CELL),(35,48,27,255));first=atlas.crop((0,0,CELL,CELL))
 for i,(_,maker) in enumerate(PROPS):cell=first.copy();cell.alpha_composite(maker(),(62,46));equip.alpha_composite(cell,(i*CELL,0))
 equip.resize((equip.width*2,equip.height*2),Image.Resampling.NEAREST).save(PREVIEW/"graduate-monkey-v2-equipment-2x.png")
 print(f"GRADUATE_MONKEY_BUILD_OK body={atlas.width}x{atlas.height} props={props.width}x{props.height} grid=64")
if __name__=="__main__":build()
