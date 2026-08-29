"""Author the native-grid synergy emblem and UI chrome atlases."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
ICON_OUT=ROOT/'assets/ui/synergy-emblems-pixel-v1.png'
CHROME_OUT=ROOT/'assets/ui/synergy-chrome-pixel-v1.png'
S=64
ORDER=['momentum','field','ignition','growth','impact','wild','harvest']

pal={
 'ink':(10,17,18,255),'edge':(25,35,31,255),'bone':(246,232,181,255),'steel':(173,199,188,255),
 'momentum':[(10,45,62,255),(17,92,122,255),(35,160,201,255),(114,224,240,255),(222,255,247,255)],
 'field':[(30,48,19,255),(64,83,28,255),(118,132,45,255),(183,190,73,255),(239,224,133,255)],
 'ignition':[(77,16,12,255),(151,28,14,255),(226,58,17,255),(255,133,28,255),(255,230,96,255)],
 'growth':[(18,52,23,255),(34,91,31,255),(65,147,43,255),(123,207,54,255),(218,240,101,255)],
 'impact':[(62,35,19,255),(116,61,21,255),(193,102,30,255),(246,163,53,255),(255,224,124,255)],
 'wild':[(39,20,62,255),(73,35,111,255),(122,60,172,255),(183,100,222,255),(239,198,255,255)],
 'harvest':[(61,42,15,255),(116,78,22,255),(180,125,35,255),(235,181,60,255),(255,232,137,255)],
}

im=Image.new('RGBA',(S*len(ORDER),S),(0,0,0,0));d=ImageDraw.Draw(im)
def xy(i,p):return [(i*S+x,y) for x,y in p]
def poly(i,p,fill,outline=None,w=1):
 d.polygon(xy(i,p),fill=fill)
 if outline:d.line(xy(i,p+[p[0]]),fill=outline,width=w)
def line(i,p,fill,w=1):d.line(xy(i,p),fill=fill,width=w,joint='curve')
def rect(i,b,fill,outline=None,w=1):
 x0,y0,x1,y1=b;d.rectangle((i*S+x0,y0,i*S+x1,y1),fill=fill,outline=outline,width=w)
def ellipse(i,b,fill,outline=None,w=1):
 x0,y0,x1,y1=b;d.ellipse((i*S+x0,y0,i*S+x1,y1),fill=fill,outline=outline,width=w)
def medallion(i,key):
 c=pal[key]
 poly(i,[(32,3),(49,8),(60,22),(60,42),(49,56),(32,61),(15,56),(4,42),(4,22),(15,8)],pal['ink'])
 poly(i,[(32,6),(47,10),(57,23),(57,41),(47,53),(32,58),(17,53),(7,41),(7,23),(17,10)],c[0])
 poly(i,[(32,8),(46,12),(54,24),(54,39),(45,50),(32,55),(19,50),(10,39),(10,25),(19,12)],c[1])
 # stepped upper-left rim and sparse material pixels
 line(i,[(15,25),(17,18),(24,12),(34,10),(44,13)],c[3],2)
 line(i,[(13,39),(18,48),(29,52)],c[0],2)
 for x,y in [(15,30),(20,16),(27,11),(48,20),(51,35),(42,49),(23,50)]:rect(i,(x,y,x+1,y+1),c[2])

for i,key in enumerate(ORDER):medallion(i,key)

# Momentum: paired wings and a forward arrow, leaving the center open at 32px.
i=0;c=pal['momentum']
poly(i,[(12,35),(20,18),(29,24),(25,30),(18,31),(26,36),(22,41)],c[2],pal['ink'],2)
poly(i,[(52,25),(43,14),(31,30),(38,31),(29,48),(48,32),(42,29)],c[4],pal['ink'],2)
poly(i,[(45,18),(52,25),(45,26)],c[3],None)
line(i,[(13,46),(27,43)],c[4],2);line(i,[(10,51),(23,49)],c[2],2)

# Field: concentric soil rings plus four luminous ward stakes.
i=1;c=pal['field']
ellipse(i,(15,21,49,51),c[0],pal['ink'],2);ellipse(i,(20,26,44,47),c[2],c[4],2);ellipse(i,(27,32,37,42),c[0],c[3],2)
for x,y in [(15,18),(43,18),(12,38),(46,38)]:
 poly(i,[(x,y+9),(x+3,y),(x+6,y+9)],c[4],pal['ink'],1);rect(i,(x+2,y+8,x+4,y+16),c[2],pal['ink'])

# Ignition: two interlocking flame tongues and detached embers.
i=2;c=pal['ignition']
poly(i,[(31,53),(18,45),(17,34),(25,21),(28,31),(37,10),(48,28),(48,42),(40,51)],c[2],pal['ink'],2)
poly(i,[(31,49),(24,42),(26,33),(31,27),(32,36),(39,23),(42,36),(38,46)],c[4],c[3],1)
for x,y,s in [(15,18,3),(47,15,4),(50,47,2),(11,42,2)]:rect(i,(x,y,x+s,y+s),c[3],pal['ink'])

# Growth: rooted bud with leaf pair and a bright central shoot.
i=3;c=pal['growth']
poly(i,[(32,53),(28,40),(17,38),(10,27),(25,29),(31,36)],c[2],pal['ink'],2)
poly(i,[(32,44),(37,31),(52,23),(49,37),(39,43)],c[3],pal['ink'],2)
poly(i,[(29,35),(31,17),(37,9),(42,17),(38,29)],c[4],pal['ink'],2)
line(i,[(31,51),(32,34),(37,17)],c[4],2);line(i,[(18,50),(31,45),(46,51)],c[0],3)

# Impact: golden splitting wedge through shaded rock chunks.
i=4;c=pal['impact']
for p,shade in [([(12,39),(17,28),(28,27),(31,42),(22,50)],1), ([(34,32),(45,24),(53,33),(49,47),(36,48)],2), ([(24,45),(34,38),(40,51),(29,55)],0)]:poly(i,p,c[shade],pal['ink'],2)
poly(i,[(31,9),(43,16),(35,29),(42,31),(27,50),(30,33),(21,30)],c[4],pal['ink'],2)
line(i,[(35,18),(31,29),(35,30)],c[3],2)

# Wild: eye silhouette, bright iris, asymmetrical claw scars.
i=5;c=pal['wild']
poly(i,[(8,32),(18,20),(33,16),(49,22),(57,32),(47,43),(31,48),(16,42)],c[0],pal['ink'],2)
poly(i,[(17,31),(25,24),(37,23),(47,30),(38,40),(25,40)],c[3],c[1],2)
ellipse(i,(27,23,38,41),c[4],pal['ink'],2);rect(i,(31,27,34,37),c[0])
line(i,[(46,15),(38,30)],c[4],2);line(i,[(53,19),(45,34)],c[2],2)

# Harvest: tied logs with cut rings, leaf tie and a small grain hook.
i=6;c=pal['harvest']
poly(i,[(13,40),(18,25),(43,19),(48,35),(25,48)],c[2],pal['ink'],2)
poly(i,[(18,48),(16,34),(42,29),(48,44),(27,54)],c[1],pal['ink'],2)
ellipse(i,(13,25,25,42),c[3],pal['ink'],2);ellipse(i,(16,29,22,38),c[1],c[4],1)
line(i,[(27,24),(31,48)],pal['growth'][3],4);line(i,[(30,24),(34,48)],pal['growth'][0],2)
poly(i,[(37,17),(45,9),(51,10),(46,18)],c[4],pal['ink'],1);line(i,[(44,10),(50,24),(55,28)],c[3],2)

# controlled 1px highlights/dither inside each medallion
for i,key in enumerate(ORDER):
 c=pal[key]
 for x,y in [(18,14),(22,11),(13,27),(49,27),(46,45),(25,54)]:rect(i,(x,y,x+1,y+1),c[3])
 # Sixteen authored rim steps keep the small badge dimensional at 1x without
 # introducing random noise or anti-aliased pixels.
 rim=[(17,13),(21,11),(26,9),(31,8),(36,9),(41,10),(46,13),(50,17),
      (53,22),(54,28),(54,34),(52,40),(49,45),(45,49),(40,52),(34,54)]
 lo,hi=c[1],c[4]
 for step,(x,y) in enumerate(rim):
  t=step/15
  shade=tuple(round(lo[channel]*(1-t)+hi[channel]*t) for channel in range(3))+(255,)
  rect(i,(x,y,x+1,y+1),shade)

ICON_OUT.parent.mkdir(parents=True,exist_ok=True);im.save(ICON_OUT)

# Chrome atlas: four 64px native tiles. 0 panel texture, 1 active socket,
# 2 locked socket, 3 breakpoint crest. Runtime tiles these instead of a flat canvas.
chrome=Image.new('RGBA',(S*4,S),(0,0,0,0));q=ImageDraw.Draw(chrome)
def Q(cell,box,fill,outline=None,w=1):
 x0,y0,x1,y1=box;q.rectangle((cell*S+x0,y0,cell*S+x1,y1),fill=fill,outline=outline,width=w)
for cell in range(4):
 Q(cell,(0,0,63,63),(10,18,17,245))
 for y in range(0,64,8):
  Q(cell,(0,y,63,y+3),(15+(y//8)%2*3,28+(y//8)%2*3,25+(y//8)%2*2,245))
 for x,y in [(6,6),(19,14),(42,8),(52,27),(11,45),(34,52),(57,55)]:Q(cell,(x,y,x+1,y+1),(62,77,61,180))
 # stepped metal edge, not a smooth rounded card
 Q(cell,(0,0,63,2),(122,137,105,255));Q(cell,(0,61,63,63),(3,8,8,255));Q(cell,(0,0,2,63),(68,83,67,255));Q(cell,(61,0,63,63),(3,9,9,255))
# active/locked socket centers and breakpoint crest
for cell,color in [(1,(111,211,222,255)),(2,(85,94,88,255))]:
 pts=[(cell*S+32,5),(cell*S+51,13),(cell*S+59,32),(cell*S+51,51),(cell*S+32,59),(cell*S+13,51),(cell*S+5,32),(cell*S+13,13)]
 q.polygon(pts,fill=(9,16,15,255));q.line(pts+[pts[0]],fill=color,width=3)
 q.line([(cell*S+14,19),(cell*S+22,11),(cell*S+38,8)],fill=(226,232,190,180),width=2)
cell=3
pts=[(cell*S+32,7),(cell*S+53,20),(cell*S+50,45),(cell*S+32,58),(cell*S+14,45),(cell*S+11,20)]
q.polygon(pts,fill=(28,36,28,255));q.line(pts+[pts[0]],fill=(222,173,63,255),width=3)
Q(cell,(29,16,35,48),(241,201,84,255));Q(cell,(19,27,45,34),(241,201,84,255))
chrome.save(CHROME_OUT)
print(f'WROTE {ICON_OUT} {im.size[0]}x{im.size[1]} icons={len(ORDER)}')
print(f'WROTE {CHROME_OUT} {chrome.size[0]}x{chrome.size[1]} cells=4')
