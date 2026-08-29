"""Bake coherent native-grid vape/firework equipment and FX atlases."""
from pathlib import Path
from PIL import Image,ImageDraw
import math

ROOT=Path(__file__).resolve().parents[1]
EQUIP=ROOT/'assets/characters/ingame/smoker-weapon-evolution-equipment-v1.png'
FX=ROOT/'assets/effects/smoker-weapon-evolution-fx-v1.png'

ink=(12,14,21,255);deep=(26,28,40,255);steel=(72,77,91,255);silver=(157,169,177,255);shine=(231,239,220,255)
cyan=[(16,57,72,255),(18,95,115,255),(24,139,157,255),(36,190,197,255),(92,230,220,255),(199,255,235,255)]
violet=[(45,30,91,255),(75,50,139,255),(113,76,188,255),(164,111,226,255)]
wood=[(46,28,20,255),(78,43,25,255),(117,66,34,255),(166,103,54,255),(215,157,92,255)]
paper=[(78,51,43,255),(125,72,50,255),(181,103,60,255),(229,149,79,255),(255,208,125,255)]
burst=[(255,67,41,255),(255,173,38,255),(255,235,112,255),(57,222,235,255),(104,232,86,255),(245,76,196,255),(174,112,255,255)]

def ramp(a,b,n=16):
 return [tuple(round(a[k]+(b[k]-a[k])*i/(n-1)) for k in range(3))+(255,) for i in range(n)]

eq=Image.new('RGBA',(256,96),(0,0,0,0));d=ImageDraw.Draw(eq)
def off(cell,pts):return [(cell*128+x,y) for x,y in pts]
def poly(cell,pts,fill,outline=ink,w=2):
 d.polygon(off(cell,pts),fill=fill)
 if outline:d.line(off(cell,pts+[pts[0]]),fill=outline,width=w)
def rect(cell,b,fill,outline=None,w=1):
 x0,y0,x1,y1=b;d.rectangle((cell*128+x0,y0,cell*128+x1,y1),fill=fill,outline=outline,width=w)
def ellipse(cell,b,fill,outline=None,w=1):
 x0,y0,x1,y1=b;d.ellipse((cell*128+x0,y0,cell*128+x1,y1),fill=fill,outline=outline,width=w)

# Compact vape: steel battery, glass tank, stepped liquid and luminous nozzle.
poly(0,[(39,63),(43,29),(77,24),(92,35),(88,67),(70,77),(48,74)],deep)
poly(0,[(48,60),(51,34),(75,30),(84,38),(81,62),(68,69),(53,67)],steel)
rect(0,(57,13,80,42),(25,47,59,255),ink,2);rect(0,(60,16,77,38),cyan[1],cyan[4],2)
for y,shade in [(33,cyan[2]),(29,cyan[3]),(25,cyan[4])]:rect(0,(61,y,76,y+3),shade)
poly(0,[(62,13),(65,6),(77,6),(81,13)],silver);rect(0,(68,1,78,7),violet[2],ink,1)
ellipse(0,(57,45,70,58),cyan[4],ink,2);ellipse(0,(61,48,67,54),cyan[5])
for i,(x,y) in enumerate([(45,35),(48,30),(53,27),(82,33),(85,42),(83,58),(75,69),(57,70)]):rect(0,(x,y,x+1,y+1),ramp(steel,shine)[i*2])

# Firework launcher: bundled paper rockets, brass collar and readable wooden grip.
poly(1,[(27,52),(39,29),(87,24),(104,40),(91,57),(45,63)],wood[1])
poly(1,[(43,32),(86,27),(96,38),(87,49),(43,52)],paper[1])
for j,y in enumerate((25,36,47)):
 poly(1,[(52,y),(88,y-5),(101,y+4),(89,y+12),(52,y+14)],paper[2+j%2],ink,2)
 poly(1,[(88,y-5),(106,y+3),(89,y+12)],(226,55,39,255),ink,2)
 rect(1,(59,y+2,64,y+7),burst[(j+1)%len(burst)])
poly(1,[(49,57),(66,56),(61,85),(45,87),(40,72)],wood[2]);poly(1,[(48,61),(59,61),(55,81),(47,82)],wood[4],ink,1)
for x in (46,70,88):rect(1,(x,28,x+4,55),(206,158,82,255),ink,1)
for i,(x,y) in enumerate([(42,31),(52,28),(65,25),(78,23),(91,28),(94,46),(82,54),(62,58)]):rect(1,(x,y,x+1,y+1),ramp(paper[1],paper[4])[i*2])

EQUIP.parent.mkdir(parents=True,exist_ok=True);eq.save(EQUIP)

CELL=192;COLS=6;ROWS=3
fx=Image.new('RGBA',(CELL*COLS,CELL*ROWS),(0,0,0,0));q=ImageDraw.Draw(fx)
def X(frame,x):return frame*CELL+x
def Y(row,y):return row*CELL+y
def qline(row,frame,pts,fill,w=1):q.line([(X(frame,x),Y(row,y)) for x,y in pts],fill=fill,width=w,joint='curve')
def qellipse(row,frame,b,fill,outline=None,w=1):
 x0,y0,x1,y1=b;q.ellipse((X(frame,x0),Y(row,y0),X(frame,x1),Y(row,y1)),fill=fill,outline=outline,width=w)
def qpoly(row,frame,pts,fill,outline=None,w=1):
 shifted=[(X(frame,x),Y(row,y)) for x,y in pts];q.polygon(shifted,fill=fill)
 if outline:q.line(shifted+[shifted[0]],fill=outline,width=w)
def qrect(row,frame,b,fill):
 x0,y0,x1,y1=b;q.rectangle((X(frame,x0),Y(row,y0),X(frame,x1),Y(row,y1)),fill=fill)

# Row 0: six genuinely changing vapor curls, with detached condensate pixels.
for frame in range(6):
 length=72+frame*9;phase=frame*.72
 qellipse(0,frame,(18,76,38,116),deep,ink,2);qellipse(0,frame,(22,81,34,111),violet[2],cyan[4],2)
 for k in range(9):
  u=k/8;x=34+u*length;y=96+math.sin(u*math.pi*3+phase)*(11+frame*.7)
  radius=11+math.sin(u*math.pi)*8
  color=cyan[min(5,1+(k+frame)%5)] if k%3 else violet[1+(k+frame)%3]
  qellipse(0,frame,(x-radius,y-radius*.62,x+radius,y+radius*.62),color,ink if k in (0,8) else None,1)
  qellipse(0,frame,(x-radius*.42,y-radius*.24,x+radius*.38,y+radius*.22),cyan[5])
 for k in range(8):
  x=45+((k*23+frame*11)%(length+24));y=62+((k*19+frame*7)%68)
  qrect(0,frame,(x,y,x+2+(k%2),y+2+(k%3==0)),cyan[2+(k+frame)%4])
 # sliced gaps keep the plume from becoming one static sausage.
 for k in range(3):
  x=55+k*31+(frame%2)*5;qline(0,frame,[(x,75),(x-7,88)],(0,0,0,0),3)

# Row 1: accelerating paper rocket with a changing multicolor spark train.
for frame in range(6):
 x=52+frame*14;y=96+round(math.sin(frame*.9)*5);trail=32+frame*7
 qpoly(1,frame,[(x-22,y-8),(x+15,y-8),(x+28,y),(x+15,y+8),(x-22,y+8)],paper[2],ink,2)
 qpoly(1,frame,[(x+15,y-8),(x+31,y),(x+15,y+8)],(230,57,39,255),ink,1)
 qrect(1,frame,(x-15,y-5,x-10,y),burst[(frame+3)%len(burst)])
 qpoly(1,frame,[(x-23,y-6),(x-trail,y),(x-23,y+6)],paper[4],None)
 for k in range(13):
  sx=x-25-(k*trail/13);sy=y+math.sin(k*1.8+frame)*12*(k/13)
  color=burst[(k+frame*2)%len(burst)];size=1+(k+frame)%3
  qrect(1,frame,(sx-size,sy-size,sx+size,sy+size),color)

# Row 2: one authored six-beat multicolour burst, not a translated static star.
for frame in range(6):
 progress=(frame+1)/6;cx,cy=96,96
 glow=18+frame*5
 qellipse(2,frame,(cx-glow,cy-glow,cx+glow,cy+glow),(255,126,44,max(38,118-frame*14)))
 qellipse(2,frame,(cx-13-frame,cy-13-frame,cx+13+frame,cy+13+frame),burst[(frame+2)%len(burst)],burst[2],3)
 qellipse(2,frame,(cx-6,cy-6,cx+6,cy+6),shine)
 rays=14+frame*2
 for k in range(rays):
  angle=k/rays*math.pi*2+frame*.14;color=burst[(k+frame)%len(burst)]
  inner=10+frame*3;outer=25+progress*58+(k%3)*5
  x0=cx+math.cos(angle)*inner;y0=cy+math.sin(angle)*inner
  x1=cx+math.cos(angle)*outer;y1=cy+math.sin(angle)*outer
  qline(2,frame,[(x0,y0),(x1,y1)],ink,7 if k%4==0 else 5)
  qline(2,frame,[(x0,y0),(x1,y1)],color,5 if k%4==0 else 3)
  mid=.72;mx=x0+(x1-x0)*mid;my=y0+(y1-y0)*mid
  side=5+(k%3);qline(2,frame,[(mx-math.sin(angle)*side,my+math.cos(angle)*side),(mx+math.sin(angle)*side,my-math.cos(angle)*side)],color,2)
  if frame>=2:
   gap=8+frame*2;ex=x1+math.cos(angle)*gap;ey=y1+math.sin(angle)*gap
   qrect(2,frame,(ex-2,ey-2,ex+2,ey+2),burst[(k+frame+2)%len(burst)])
 for k in range(12):
  angle=(k*.83+frame*.31);rad=35+frame*11+(k%4)*6
  x=cx+math.cos(angle)*rad;y=cy+math.sin(angle)*rad
  color=burst[(k*2+frame)%len(burst)];qrect(2,frame,(x-2,y-2,x+3,y+3),ink);qrect(2,frame,(x-1,y-1,x+2,y+2),color)

FX.parent.mkdir(parents=True,exist_ok=True);fx.save(FX)
print(f'WROTE {EQUIP} {eq.width}x{eq.height} cells=2')
print(f'WROTE {FX} {fx.width}x{fx.height} grid=6x3 cell={CELL}')
