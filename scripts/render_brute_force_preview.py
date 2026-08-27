from pathlib import Path
import math
from PIL import Image,ImageDraw,ImageFont

root=Path(__file__).resolve().parents[1]
ground=Image.open(root/"assets/forest-ground-tile-v1.png").convert("RGB").resize((960,440),Image.Resampling.BICUBIC)
draw=ImageDraw.Draw(ground)
font=ImageFont.truetype(str(root/"assets/font-korean-bold.ttf"),28)
small=ImageFont.truetype(str(root/"assets/font-korean-bold.ttf"),20)
cx,cy=480,225
draw.ellipse((cx-31,cy-85,cx+31,cy-23),fill=(8,27,12),outline=(95,255,89),width=4)
draw.ellipse((cx-24,cy-78,cx+24,cy-30),fill=(242,132,12),outline=(255,213,73),width=3)
draw.text((cx-10,cy-72),"B",font=font,fill=(42,24,5))
draw.line((cx-13,cy-38,cx-13,cy-58,cx+13,cy-58,cx+13,cy-38),fill=(48,255,92),width=4)
draw.rectangle((cx-17,cy-41,cx+17,cy-14),outline=(48,255,92),width=3)
for i in range(34):
    a=i/34*math.tau;r=55+(i%3)*24;x=cx+math.cos(a)*r;y=cy-32+math.sin(a)*r*.52
    v=str((i*7+3)%10)
    draw.text((x+2,y+3),v,font=small,fill=(3,25,8));draw.text((x-1,y),v,font=small,fill=(242,147,20));draw.text((x,y-1),v,font=small,fill=(75,255,91))
for i in range(20):
    a=i/20*math.tau;r0=145;r1=250+(i%4)*18;v=str((i*9+1)%10)
    for q,alpha in ((.72,(50,140,54)),(.86,(90,205,70)),(1,(205,255,176))):
        r=r0+(r1-r0)*q;x=cx+math.cos(a)*r;y=cy+math.sin(a)*r*.58
        draw.text((x,y),v,font=font,fill=alpha)
out=root/"docs/previews/brute-force-runtime-v2.png";out.parent.mkdir(parents=True,exist_ok=True);ground.save(out);print(out)
