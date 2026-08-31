"""Bake coherent native-grid vape/firework equipment and FX atlases."""
from pathlib import Path
from PIL import Image,ImageDraw
import math

ROOT=Path(__file__).resolve().parents[1]
EQUIP=ROOT/'assets/characters/ingame/smoker-weapon-evolution-equipment-v1.png'
FX=ROOT/'assets/effects/smoker-weapon-evolution-fx-v1.png'
BURST_FX=ROOT/'assets/effects/smoker-firework-burst-v2.png'

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

# Row 1: accelerating firework rocket. The old silhouette was a 90 px pencil in
# a 192 px cell, which shrank to an unreadable sliver at gameplay scale, so the
# shell is larger, carries a lit nozzle flame and drags a denser spark train.
for frame in range(6):
 x=74+frame*13;y=96+round(math.sin(frame*.9)*6);trail=44+frame*9
 qpoly(1,frame,[(x-27,y-10),(x-27-trail*.34,y),(x-27,y+10)],(255,170,42,255),None)
 qpoly(1,frame,[(x-27,y-6),(x-27-trail*.21,y),(x-27,y+6)],(255,247,206,255),None)
 qpoly(1,frame,[(x-26,y-11),(x+18,y-11),(x+36,y),(x+18,y+11),(x-26,y+11)],paper[2],ink,3)
 qpoly(1,frame,[(x-26,y-11),(x+18,y-11),(x+18,y-4),(x-26,y-4)],paper[4],None)
 qpoly(1,frame,[(x+18,y-11),(x+38,y),(x+18,y+11)],(230,57,39,255),ink,2)
 qrect(1,frame,(x-17,y-7,x-7,y+7),burst[(frame+3)%len(burst)])
 qrect(1,frame,(x+2,y-7,x+11,y+7),burst[(frame+5)%len(burst)])
 for k in range(22):
  sx=x-31-(k*trail/22);sy=y+math.sin(k*1.35+frame)*15*(k/22)
  color=burst[(k+frame*2)%len(burst)];size=2+(k+frame)%3
  qrect(1,frame,(sx-size-1,sy-size-1,sx+size+1,sy+size+1),ink)
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

# Dedicated 30 fps firework bloom. The old sheet spent only nine frames on a
# 38 px flash and then twenty-one frames on thin confetti, so at the real blast
# scale (cell 384 px stretched over a ~520 px world diameter) the explosion read
# as scattered dust over grass. This sheet keeps the same 30-frame contract but
# gives the burst a growing fireball, a stepped shockwave ring and a much denser
# comet bloom that still fills the damage silhouette while it decays.
BCELL=384;BFRAMES=30;BCOLS=6;BROWS=5
BCX,BCY=192,194
burst_fx=Image.new('RGBA',(BCELL*BCOLS,BCELL*BROWS),(0,0,0,0));bd=ImageDraw.Draw(burst_fx)
bright=[(255,76,48),(255,170,42),(255,235,116),(53,229,235),(91,233,111),(246,81,202),(179,120,255)]
mid=[(163,42,33),(196,101,28),(189,157,54),(24,139,157),(42,151,79),(164,45,139),(103,67,173)]
smoke=[(28,31,48),(43,42,66),(58,53,77),(67,61,80)]

def bo(frame,x,y):return frame%BCOLS*BCELL+x,frame//BCOLS*BCELL+y
def bline(frame,points,fill,width):bd.line([bo(frame,round(x),round(y)) for x,y in points],fill=fill,width=width)
def bellipse(frame,b,fill,outline=None,width=1):
 x0,y0,x1,y1=b;ox,oy=bo(frame,0,0);bd.ellipse((ox+round(x0),oy+round(y0),ox+round(x1),oy+round(y1)),fill=fill,outline=outline,width=width)
def bpoly(frame,points,fill):bd.polygon([bo(frame,round(x),round(y)) for x,y in points],fill=fill)
def brect(frame,b,fill):
 x0,y0,x1,y1=b;ox,oy=bo(frame,0,0);bd.rectangle((ox+round(x0),oy+round(y0),ox+round(x1),oy+round(y1)),fill=fill)

def alpha_color(rgb,a):return rgb+(max(0,min(255,round(a))),)
def ease_out(u):return 1-(1-u)**2.15

# Three related blooms start close together rather than making one geometric
# wheel. The main bloom owns the damage silhouette; satellites add animation
# richness without increasing the gameplay footprint.
blooms=[(192,194,0.00,1.00,0.08,20),(150,168,0.09,.58,.31,12),(236,176,0.15,.52,-.22,10)]
for frame in range(BFRAMES):
 t=frame/(BFRAMES-1)
 # Layered ignition fireball. It grows into the blast silhouette instead of
 # staying a small point, then burns off before the comets take the frame over.
 if t<.26:
  u=t/.26;grow=ease_out(min(1,u/.34));core=round(16+58*grow)
  # The flash has to stay opaque while it is on screen: an alpha ramp that
  # starts falling immediately washes the fireball out against lit grass.
  fade=1 if u<.46 else ((1-u)/.54)**1.15
  pts=[]
  for k in range(22):
   a=k/22*math.pi*2;rr=core*(1.34 if (k+frame)%2 else .92)*(1+math.sin(k*3.1+frame)*.06)
   pts.append((BCX+math.cos(a)*rr,BCY+math.sin(a)*rr))
  bpoly(frame,pts,alpha_color((236,74,26),225*fade))
  for radius_scale,rgb,alpha in ((.86,(255,124,34),248),(.60,(255,178,52),255),(.36,(255,232,120),255),(.16,(255,255,231),255)):
   rr=core*radius_scale
   bellipse(frame,(BCX-rr,BCY-rr,BCX+rr,BCY+rr),alpha_color(rgb,alpha*fade))
  # Stepped ember collar riding the fireball edge keeps the ball from reading
  # as one smooth vector circle.
  for k in range(28):
   if (k+frame)%3:
    a=k/28*math.pi*2;rr=core*1.18+u*26;size=2+(k+frame)%3
    brect(frame,(BCX+math.cos(a)*rr-size,BCY+math.sin(a)*rr-size,BCX+math.cos(a)*rr+size,BCY+math.sin(a)*rr+size),alpha_color(bright[(k+frame)%7],245*fade))

 # Stepped shockwave ring. It reaches the authored damage edge so the player can
 # read the blast footprint from the effect alone.
 if t<.52:
  u=t/.52;ring=48+ease_out(u)*138;ring_alpha=255*(1-u)**.85
  for k in range(44):
   a=k/44*math.pi*2
   if (k+frame)%4==0:continue
   size=2+(k+frame)%2
   rx,ry=BCX+math.cos(a)*ring,BCY+math.sin(a)*ring
   brect(frame,(rx-size,ry-size,rx+size,ry+size),alpha_color((255,238,170) if (k+frame)%3 else bright[(k+frame)%7],ring_alpha))

 for bloom_index,(cx,cy,delay,scale,angle_offset,count) in enumerate(blooms):
  if t<delay:continue
  u=min(1,(t-delay)/(1-delay));travel=ease_out(min(1,u/.80));decay=max(0,1-max(0,u-.58)/.42)
  for k in range(count):
   angle=angle_offset+k/count*math.pi*2+math.sin(k*2.17)*.055
   speed=168*scale*(.86+(k%4)*.075)
   curve=(10+((k*7)%13))*scale*(1 if k%2 else -1)
   def point(at):
    p=ease_out(min(1,at/.80));dist=12*scale+speed*p
    side=math.sin(p*math.pi)*curve
    gravity=(34+(k%3)*6)*scale*at*at
    return cx+math.cos(angle)*dist-math.sin(angle)*side,cy+math.sin(angle)*dist+math.cos(angle)*side+gravity
   head=point(u);trail=[]
   for j in range(11,-1,-1):
    pu=max(0,u-j*.016/(.72+.28*scale))
    if pu<=0 and j>0:continue
    # Detached gaps emerge during the decay instead of cutting the whole ray.
    if u>.62 and (j+frame+k)%6==0:continue
    trail.append(point(pu))
   color_index=(k*2+bloom_index+1)%7;color=bright[color_index];shadow=mid[color_index]
   a=255*decay
   if len(trail)>1:
    bline(frame,trail,alpha_color((19,16,28),a*.82),8 if scale>.7 else 6)
    bline(frame,trail,alpha_color(shadow,a*.94),5 if scale>.7 else 4)
    # Highlight lives only near the moving head, preserving a stepped trail.
    bline(frame,trail[-5:],alpha_color(color,a),3 if scale>.7 else 2)
   hx,hy=head;hs=(5 if scale>.7 else 4)+(1 if (frame+k)%4==0 else 0)
   brect(frame,(hx-hs-1,hy-hs-1,hx+hs+1,hy+hs+1),alpha_color((18,15,27),a*.85))
   brect(frame,(hx-hs,hy-hs,hx+hs,hy+hs),alpha_color(color,a))
   brect(frame,(hx-2,hy-2,hx+2,hy+2),alpha_color((255,255,218),a))
   # Each comet sheds smaller sparks that inherit its curve and then fall.
   if u>.22:
    for s in range(3):
     lag=.050+s*.042;su=max(0,u-lag);sx,sy=point(su)
     fall=max(0,u-.30)*(18+s*11)*scale
     sx+=math.sin(k*1.7+s*2.3)*8*scale*(u-.18);sy+=fall
     ss=2+(s+k)%2
     brect(frame,(sx-ss-1,sy-ss-1,sx+ss+1,sy+ss+1),alpha_color((18,15,27),a*(.55-s*.10)))
     brect(frame,(sx-ss,sy-ss,sx+ss,sy+ss),alpha_color(bright[(color_index+s+2)%7],a*(.86-s*.14)))

 # Smoke is a clustered afterimage, not a translucent full-screen circle.
 if t>.34:
  su=(t-.34)/.66;sa=max(7,150*(1-su))
  for k in range(14):
   angle=k*.91;dist=10+su*(38+(k%4)*7);sx=BCX+math.cos(angle)*dist;sy=BCY+math.sin(angle)*dist*.52-su*20
   rr=9+(k%3)*4+su*11
   bellipse(frame,(sx-rr,sy-rr*.58,sx+rr,sy+rr*.58),alpha_color(smoke[(k+frame//6)%4],sa*(.55+(k%3)*.1)))
  # Repaint a few late embers above smoke so the tail remains legible.
  if t>.50:
   for k in range(26):
    fall=(t-.50)*95*(.5+(k%4)*.13);sx=112+(k*29%164)+math.sin(frame*.34+k)*5;sy=168+(k*17%75)+fall
    a=max(10,205*(1-t));size=2+(k%2)
    brect(frame,(sx-size-1,sy-size-1,sx+size+1,sy+size+1),alpha_color((18,15,27),a*.6))
    brect(frame,(sx-size,sy-size,sx+size,sy+size),alpha_color(bright[(k*3)%7],a))

BURST_FX.parent.mkdir(parents=True,exist_ok=True);burst_fx.save(BURST_FX)
print(f'WROTE {EQUIP} {eq.width}x{eq.height} cells=2')
print(f'WROTE {FX} {fx.width}x{fx.height} grid=6x3 cell={CELL}')
print(f'WROTE {BURST_FX} {burst_fx.width}x{burst_fx.height} grid={BCOLS}x{BROWS} cell={BCELL} fps=30')
