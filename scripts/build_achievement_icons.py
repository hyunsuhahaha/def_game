from PIL import Image,ImageDraw
from pathlib import Path

OUT=Path("assets/ui/achievement-icons-pixel-v1.png")
S=64; names=["axe","rings","crown","spark","map","fire","fork","claw","tree","medal"]
im=Image.new("RGBA",(S*len(names),S),(0,0,0,0));d=ImageDraw.Draw(im)
ink=(31,24,17,255); dark=(76,48,24,255); wood=(139,83,37,255); wood_hi=(210,146,65,255)
gold0=(83,48,15,255);gold1=(157,94,22,255);gold2=(231,167,48,255);gold3=(255,225,119,255)
steel0=(47,57,57,255);steel1=(105,126,118,255);steel2=(188,211,187,255);steel3=(244,239,194,255)
green0=(28,54,32,255);green1=(54,104,49,255);green2=(100,156,65,255);green3=(180,205,98,255)
red=(187,48,24,255);orange=(244,109,28,255);yellow=(255,211,65,255)
def P(i,pts,fill,outline=ink):
 pts=[(i*S+x,y) for x,y in pts];d.polygon(pts,fill=fill)
 if outline:d.line(pts+[pts[0]],fill=outline,width=2,joint="curve")
def R(i,box,fill,outline=None,w=1):
 x0,y0,x1,y1=box;d.rectangle((i*S+x0,y0,i*S+x1,y1),fill=fill,outline=outline,width=w)
def E(i,box,fill,outline=None,w=1):
 x0,y0,x1,y1=box;d.ellipse((i*S+x0,y0,i*S+x1,y1),fill=fill,outline=outline,width=w)
def medal(i):
 E(i,(7,7,57,57),gold0,ink,2);E(i,(11,11,53,53),gold1);E(i,(15,15,49,49),gold2)
 d.arc((i*S+14,14,i*S+50,50),200,330,fill=gold3,width=3)
 for y in range(18,47,4):
  for x in range(18+(y//4)%2,47,5):
   if (x-32)**2+(y-32)**2<210:R(i,(x,y,x+1,y+1),gold3)
for i in range(len(names)):medal(i)
# axe
i=0;P(i,[(19,48),(24,51),(47,20),(42,16)],wood_hi);P(i,[(35,13),(51,11),(55,20),(45,29),(35,25)],steel1);P(i,[(39,15),(50,14),(51,19),(43,24),(38,22)],steel3,None)
# rings
i=1;E(i,(17,15,47,49),wood,ink,2);E(i,(22,20,42,44),wood_hi,dark,2);E(i,(27,25,37,39),gold3,dark,2);d.arc((i*S+19,17,i*S+45,47),25,255,fill=dark,width=2)
# crown
i=2;P(i,[(13,42),(11,20),(23,30),(31,14),(40,30),(53,20),(50,44)],gold2);R(i,(14,40,50,48),gold1,ink,2);R(i,(20,42,44,44),gold3)
# spark
i=3;P(i,[(32,9),(37,25),(53,20),(42,33),(54,45),(37,40),(32,56),(27,40),(10,45),(22,33),(11,20),(27,25)],gold3);P(i,[(32,20),(35,29),(45,27),(39,34),(45,41),(35,39),(32,48),(29,39),(20,41),(26,34),(20,27),(29,29)],yellow,None)
# map
i=4;P(i,[(12,17),(25,12),(39,18),(52,12),(52,47),(39,52),(25,46),(12,52)],green1);d.line([(i*S+25,13),(i*S+25,46),(i*S+39,52),(i*S+39,18)],fill=green3,width=3);d.line([(i*S+16,24),(i*S+24,21),(i*S+31,27),(i*S+46,22)],fill=gold3,width=2)
# fire
i=5;P(i,[(32,52),(17,45),(15,34),(24,20),(27,31),(37,9),(48,27),(50,41),(43,49)],red);P(i,[(32,48),(23,42),(24,33),(30,25),(32,35),(39,22),(43,35),(40,44)],orange,None);P(i,[(32,45),(28,40),(32,32),(37,40)],yellow,None)
# fork
i=6;P(i,[(29,52),(36,52),(36,28),(45,22),(45,11),(41,11),(41,20),(36,22),(36,10),(31,10),(31,22),(26,20),(26,11),(22,11),(22,23),(29,29)],steel2);R(i,(30,29,35,49),steel3)
# claw
i=7;P(i,[(16,45),(20,20),(27,13),(27,33),(31,11),(36,10),(35,33),(42,15),(47,15),(42,40),(35,50),(24,52)],steel1);d.line([(i*S+22,23),(i*S+25,39),(i*S+32,44),(i*S+39,37)],fill=steel3,width=3)
# tree
i=8;P(i,[(27,52),(29,37),(20,39),(11,31),(16,21),(24,18),(28,9),(37,12),(42,20),(51,25),(50,36),(39,41),(36,52)],green0);E(i,(15,17,38,39),green2);E(i,(27,12,50,37),green1);E(i,(22,10,39,29),green3);P(i,[(28,51),(30,32),(36,32),(37,51)],wood)
# medal/star
i=9;P(i,[(20,42),(18,56),(31,49),(44,56),(42,41)],red);E(i,(15,9,49,43),gold2,ink,2);P(i,[(32,14),(36,25),(48,25),(39,32),(43,42),(32,36),(21,42),(25,32),(16,25),(28,25)],gold3,None)
OUT.parent.mkdir(parents=True,exist_ok=True);im.save(OUT)
print(f"WROTE {OUT} {im.size[0]}x{im.size[1]} icons={len(names)}")
