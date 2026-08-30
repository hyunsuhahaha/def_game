"""Build a six-frame high-density pixel coin used by the lumber settlement UI."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/ui/research-coin-spin-pixel-v1.png'
CELL=64
WIDTHS=[46,34,18,8,18,34]
palette={
    'outline':(69,43,12,255),'deep':(117,67,12,255),'shadow':(166,94,13,255),
    'mid':(218,139,22,255),'gold':(244,184,42,255),'light':(255,224,106,255),
    'shine':(255,245,174,255),'stamp':(128,73,13,255),
}

atlas=Image.new('RGBA',(CELL*6,CELL),(0,0,0,0))
for frame,width in enumerate(WIDTHS):
    tile=Image.new('RGBA',(CELL,CELL),(0,0,0,0));d=ImageDraw.Draw(tile)
    cx,cy=CELL//2,CELL//2;left,right=cx-width//2,cx+(width-1)//2;top,bottom=7,56
    d.ellipse((left-2,top-2,right+2,bottom+2),fill=palette['outline'])
    d.ellipse((left,top,right,bottom),fill=palette['deep'])
    if width>=14:
        d.ellipse((left+2,top+2,right-2,bottom-2),fill=palette['shadow'])
        d.ellipse((left+4,top+3,right-3,bottom-5),fill=palette['mid'])
        d.ellipse((left+6,top+5,right-5,bottom-8),fill=palette['gold'])
        # Stepped upper-left material ramp and ordered edge dithering.
        d.arc((left+5,top+4,right-4,bottom-6),196,318,fill=palette['light'],width=3)
        d.arc((left+8,top+7,right-7,bottom-10),202,292,fill=palette['shine'],width=2)
        for yy in range(top+12,bottom-8,4):
            xx=left+5+((yy//4+frame)%2)
            if xx<right-4:d.point((xx,yy),fill=palette['light'])
        # A simple stamped tree-ring mark remains readable during the wide frames.
        if width>=28:
            d.ellipse((cx-8,cy-9,cx+8,cy+9),outline=palette['stamp'],width=2)
            d.line((cx,cy-7,cx,cy+7),fill=palette['stamp'],width=2)
            d.line((cx,cy-1,cx-5,cy+4),fill=palette['stamp'],width=2)
            d.line((cx,cy+1,cx+5,cy+5),fill=palette['stamp'],width=2)
    else:
        d.rectangle((left+2,top+3,right-2,bottom-4),fill=palette['mid'])
        d.line((left+2,top+6,left+2,bottom-8),fill=palette['light'],width=1)
    atlas.alpha_composite(tile,(frame*CELL,0))

OUT.parent.mkdir(parents=True,exist_ok=True)
atlas.save(OUT,optimize=True)
print(f'RESEARCH_COIN_ATLAS_OK {OUT.relative_to(ROOT)} 6x{CELL} binary_alpha')
