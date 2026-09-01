"""Build the traditional puffed-rice cannon, projectile and contact FX."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
INK=(24,23,20,255);STEEL=[(47,45,40,255),(67,65,58,255),(91,88,77,255),(121,116,99,255),(154,146,121,255),(190,178,143,255),(222,207,164,255),(247,231,185,255)]
IRON=[(29,30,28,255),(38,40,37,255),(49,52,47,255),(61,65,58,255),(74,78,68,255),(88,92,79,255),(105,107,89,255),(124,123,98,255),(148,142,108,255),(176,163,118,255)]
RED=[(70,25,20,255),(105,34,25,255),(145,45,29,255),(190,62,34,255),(230,91,43,255),(255,139,56,255)]
BRASS=[(77,53,21,255),(119,82,29,255),(169,119,40,255),(220,166,62,255),(250,213,115,255)]
RICE=[(94,66,34,255),(145,105,58,255),(196,155,94,255),(232,202,147,255),(250,235,195,255),(255,250,226,255)]
FIRE=[(104,27,12,255),(190,48,15,255),(245,93,22,255),(255,168,44,255),(255,231,122,255)]
BARK=[(49,28,17,255),(78,43,23,255),(113,62,31,255),(151,87,42,255),(194,125,65,255)]

def rect(d,b,c):d.rectangle(tuple(map(int,b)),fill=c)
def poly(d,p,c):d.polygon(tuple((int(x),int(y))for x,y in p),fill=c)

def machine_frame(state):
 im=Image.new('RGBA',(256,192));d=ImageDraw.Draw(im);import math
 heat=min(1,max(0,(state-1)/3))

 # Long stroller handle reaches the monkey's forward hands and stays behind the cart.
 d.line((3,150,61,139),fill=INK,width=9);d.line((4,148,60,138),fill=IRON[6],width=4)
 rect(d,(1,143,16,154),INK);rect(d,(3,145,14,151),RED[3])

 # Low red handcart: a broad, readable base instead of two disconnected sticks.
 poly(d,((42,136),(199,136),(211,148),(199,157),(53,154)),INK)
 poly(d,((49,137),(194,139),(201,147),(193,150),(56,148)),RED[2])
 rect(d,(65,147,77,168),INK);rect(d,(180,147,192,168),INK)
 for cx in (70,187):
  d.ellipse((cx-19,151,cx+19,189),fill=INK);d.ellipse((cx-13,157,cx+13,183),fill=IRON[3])
  d.ellipse((cx-7,163,cx+7,177),fill=IRON[0]);d.ellipse((cx-3,167,cx+3,173),fill=BRASS[3])
  rect(d,(cx-2,157,cx+2,164),IRON[7]);rect(d,(cx-2,176,cx+2,182),IRON[1])

 # Boxy furnace under the pressure vessel, with a hot door and ash lip.
 poly(d,((92,112),(166,106),(177,151),(87,151)),INK)
 poly(d,((98,116),(159,111),(168,145),(94,145)),RED[0])
 rect(d,(105,122,153,145),IRON[1]);rect(d,(110,126,149,143),RED[1])
 if state>=2 and state<=4:
  poly(d,((113,142),(118,126),(124,135),(131,115-state*2),(137,137),(145,123),(149,142)),FIRE[1])
  poly(d,((121,141),(128,128),(134,139),(141,130),(145,141)),FIRE[4])
 rect(d,(101,148,164,154),IRON[0]);rect(d,(108,149,157,151),IRON[6])

 # Build the signature black cast-iron rotating cannon separately and tilt it upward.
 barrel=Image.new('RGBA',(188,88));bd=ImageDraw.Draw(barrel)
 bd.ellipse((4,13,56,75),fill=INK);bd.rectangle((29,13,159,75),fill=INK);bd.ellipse((133,13,181,75),fill=INK)
 for x in range(19,166):
  u=(x-19)/147;shade=max(1,min(9,int(2+(1-abs(.42-u)*1.7)*7)))
  ypad=int(abs(.5-u)*2)
  bd.rectangle((x,18+ypad,x,69-ypad),fill=IRON[shade])
 # soot-dark lower belly and a warm pressure band that glows only when heated
 bd.polygon(((18,54),(166,54),(159,70),(28,72)),fill=IRON[1])
 for bx in (38,111,154):
  bd.rectangle((bx,11,bx+9,77),fill=INK);bd.rectangle((bx+2,15,bx+6,72),fill=BRASS[1 if bx!=154 else 2])
  bd.rectangle((bx+3,18,bx+5,50),fill=BRASS[3])
 if heat>0:
  glow=RED[min(5,1+int(heat*4))]
  for yy in range(51,68,4):bd.rectangle((61,yy,132,yy+1),fill=glow)
 # iron rivets and scuffed highlights keep the barrel materially rich at game scale
 for i in range(18):
  x=54+(i*19)%92;y=24+(i*13)%27
  bd.rectangle((x,y,x+2,y+2),fill=IRON[8 if i%3 else 4])
 bd.ellipse((4,18,48,70),outline=BRASS[2],width=5);bd.ellipse((10,24,42,64),outline=INK,width=5)
 bd.rectangle((163,23,185,65),fill=INK);bd.rectangle((166,27,179,61),fill=BRASS[2]);bd.rectangle((170,30,177,58),fill=BRASS[4])
 barrel=barrel.rotate(350,resample=Image.Resampling.NEAREST,expand=True)
 im.alpha_composite(barrel,(30,43));d=ImageDraw.Draw(im)

 # Large side flywheel and offset crank: the part that sells the old street machine.
 wheel_angle=state*.42
 d.ellipse((29,71,91,133),fill=INK);d.ellipse((35,77,85,127),outline=BRASS[3],width=6)
 d.ellipse((43,85,77,119),outline=IRON[7],width=4);d.ellipse((54,96,66,108),fill=INK)
 for a in (wheel_angle,wheel_angle+math.pi/2):
  dx,dy=math.cos(a)*22,math.sin(a)*22;d.line((60-dx,102-dy,60+dx,102+dy),fill=BRASS[2],width=4)
 hx=60+math.cos(wheel_angle)*30;hy=102+math.sin(wheel_angle)*30
 d.ellipse((hx-5,hy-5,hx+5,hy+5),fill=RED[4])

 # Hopper, gauge and safety valve give the upper silhouette recognizable landmarks.
 poly(d,((105,61),(116,37),(138,37),(145,61)),INK);poly(d,((112,58),(119,42),(135,42),(139,58)),BRASS[2])
 d.ellipse((91,31,127,67),fill=INK);d.ellipse((97,37,121,61),fill=RICE[4]);d.arc((100,40,118,58),180,350,fill=RED[4],width=3)
 needle=-2.65+min(1,state/4)*2.45;d.line((109,49,109+math.cos(needle)*9,49+math.sin(needle)*9),fill=RED[0],width=3)
 rect(d,(145,48,153,62),INK);d.ellipse((140,43,158,53),fill=BRASS[3]);rect(d,(147,37,151,47),RED[3])

 # Clamped muzzle visibly kicks open during the shot.
 if state==4:
  poly(d,((205,55),(231,38),(224,60),(247,62),(225,72)),INK)
  poly(d,((209,56),(229,43),(223,58),(241,63),(221,67)),BRASS[3])
  for i in range(9):
   x=212+i*4;y=68+(i%3)*7-i*2;d.ellipse((x,y,x+6,y+4),fill=RICE[3+i%3])
 elif state==5:
  for i in range(5):
   x=216+i*5;y=60-i*8;d.ellipse((x,y,x+8+i*2,y+5+i),fill=IRON[5+i%3])
 return im

def projectile_frame(frame):
 im=Image.new('RGBA',(128,128));d=ImageDraw.Draw(im);angle=frame*0.7
 import math
 pts=[]
 for i in range(16):
  a=i*math.pi*2/16+angle;r=38+(i%3)*5;pts.append((64+math.cos(a)*r,64+math.sin(a)*r*.72))
 poly(d,pts,INK);d.ellipse((30,37,99,92),fill=RICE[2]);d.ellipse((37,40,95,84),fill=RICE[4]);d.ellipse((44,44,84,69),fill=RICE[5])
 for i in range(24):
  x=35+(i*23+frame*7)%58;y=45+(i*17)%38;rect(d,(x,y,x+2,y+1),RICE[(i+frame)%4+1])
 return im

def impact_frame(frame):
 """Six authored frames: squash, wood-chip burst, rebound streak, then crumbs."""
 import math
 im=Image.new('RGBA',(192,192));d=ImageDraw.Draw(im)
 squash=[(.45,1.35),(.68,1.12),(.92,.86),(1.04,.62),(.74,.42),(.42,.25)][frame]
 cx=80+frame*5;rx=int(34*squash[0]);ry=int(24*squash[1])

 # Short, chunky motion streaks make the incoming hit legible without a soft glow.
 if frame<=2:
  for i,(length,y) in enumerate(((43,75),(57,91),(36,108))):
   x2=54-frame*3-i*4
   rect(d,(x2-length+frame*9,y-2,x2,y+2),RICE[1+i*2])
   rect(d,(x2-length+9+frame*9,y-1,x2-5,y+1),RICE[5])

 # The rice cake visibly compresses against the trunk, then tears into large chunks.
 if frame<=3:
  d.ellipse((cx-rx-4,96-ry-4,cx+rx+4,96+ry+4),fill=INK)
  d.ellipse((cx-rx,96-ry,cx+rx,96+ry),fill=RICE[2])
  d.ellipse((cx-rx+5,96-ry+4,cx+rx-3,96+2),fill=RICE[5])
  for i in range(9):
   px=cx-rx+8+(i*13)%(max(12,rx*2-12));py=88+(i*11)%max(10,ry)
   rect(d,(px,py,px+3+(i%2)*2,py+2),RICE[1+i%5])

 # A hard white contact star is present for only two frames: snap, not a halo.
 if frame<=1:
  s=1+frame*.28
  star=[(101,96),(113,90),(108,79),(120,84),(127,70),(130,88),(147,85),(136,98),
        (151,107),(133,106),(136,124),(123,112),(114,124),(113,107)]
  poly(d,((101+(x-101)*s,96+(y-96)*s)for x,y in star),INK)
  inner=[(104,96),(116,91),(113,85),(123,90),(128,80),(129,93),(140,91),(133,99),
         (143,104),(131,103),(132,114),(123,107),(116,115),(115,104)]
  poly(d,inner,RICE[5])

 # Bark splinters travel farther than rice crumbs and point away from the trunk.
 travel=(frame+1)*13
 for i in range(10):
  a=-1.05+i*.23;dist=22+travel+(i%4)*7
  x=112+math.cos(a)*dist;y=98+math.sin(a)*dist+frame*frame*1.5
  length=max(4,11-frame);tip=(x+math.cos(a)*length,y+math.sin(a)*length)
  poly(d,((x-3,y-2),(tip[0],tip[1]),(x+2,y+4)),BARK[1+i%4])
  if frame<3: rect(d,(x,y,x+2,y+1),BARK[4])

 # Rice breaks into irregular, readable pieces instead of a uniform particle ring.
 for i in range(14):
  a=-2.35+i*.39;dist=15+(frame+1)*(8+i%5*3)
  x=98+math.cos(a)*dist;y=96+math.sin(a)*dist*.82+frame*frame*2
  w=max(2,7-frame//2)+(i%3);h=max(2,5-frame//2)
  if frame>=4 and i%2: continue
  d.ellipse((x-w,y-h,x+w,y+h),fill=INK)
  d.ellipse((x-w+2,y-h+1,x+w-1,y+h-1),fill=RICE[2+i%4])

 # Two angular rebound streaks lead the eye toward the next target.
 if 1<=frame<=4:
  lead=112+frame*11
  poly(d,((lead,82),(lead+24,76),(lead+18,83),(lead+38,86),(lead+16,89)),RICE[4])
  poly(d,((lead-5,112),(lead+20,108),(lead+13,114),(lead+31,119),(lead+10,117)),RICE[2])
 return im

def atlas(frames,cell,path):
 out=Image.new('RGBA',(cell[0]*len(frames),cell[1]));
 for i,im in enumerate(frames):out.alpha_composite(im,(i*cell[0],0))
 path.parent.mkdir(parents=True,exist_ok=True);out.save(path)

def main():
 atlas([machine_frame(i)for i in range(6)],(256,192),ROOT/'assets/automation/popping-machine-atlas-pixel-v2.png')
 atlas([projectile_frame(i)for i in range(4)],(128,128),ROOT/'assets/projectiles/puffed-rice-atlas-pixel-v1.png')
 atlas([impact_frame(i)for i in range(6)],(192,192),ROOT/'assets/fx/puffed-rice-impact-atlas-pixel-v1.png')
 print('POPPING_MACHINE_ART_BUILT machine_v2=1536x192 projectile=512x128 impact=1152x192')
if __name__=='__main__':main()
