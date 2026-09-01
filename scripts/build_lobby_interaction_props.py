"""Build high-density fixed-grid props for lobby companion interactions."""
from pathlib import Path
from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / "assets/characters/companions/lobby-interaction-props-atlas-pixel-v1.png"
CELL = 64
FRAMES = 6
ROWS = 5


def px(draw, box, color):
    draw.rectangle(box, fill=color)


def feather(draw, frame):
    sway = (-2, -1, 0, 2, 1, 0)[frame]
    # Black-green ferrule and layered feather bundle: lime, orange, and cyan.
    px(draw, (30, 43, 34, 54), "#17251d"); px(draw, (31, 43, 33, 53), "#b98935")
    ramps = (
        ((30+sway, 10, 35+sway, 44), ("#173b24", "#2f6d32", "#72a93d", "#b9d95a")),
        ((18+sway, 18, 32+sway, 43), ("#60331f", "#a95628", "#df8c31", "#f1c45a")),
        ((34+sway, 17, 47+sway, 44), ("#164654", "#267887", "#51a8a2", "#96d1b3")),
    )
    for (x1, y1, x2, y2), colors in ramps:
        draw.polygon([(32+sway, 43), (x1, y1+7), ((x1+x2)//2, y1), (x2, y1+8)], fill=colors[0])
        draw.polygon([(32+sway, 41), (x1+2, y1+8), ((x1+x2)//2, y1+3), (x2-2, y1+9)], fill=colors[1])
        draw.line([(32+sway, 40), ((x1+x2)//2, y1+4)], fill=colors[2], width=2)
        for step in range(4):
            x = x1 + 3 + step * max(2, (x2-x1-6)//4)
            y = y1 + 9 + (step % 2) * 3
            px(draw, (x, y, x+1, y+1), colors[3])


def banana(draw, frame):
    lift = (0, -1, -2, -1, 0, 1)[frame]
    y = 30 + lift
    outline = [(15,y-5),(22,y-10),(37,y-9),(48,y-2),(43,y+8),(30,y+12),(19,y+8)]
    draw.polygon(outline, fill="#33251a")
    body = [(18,y-4),(24,y-7),(36,y-6),(44,y-1),(40,y+5),(30,y+8),(21,y+5)]
    draw.polygon(body, fill="#d69a2f")
    draw.line([(22,y-4),(30,y-2),(39,y-3)], fill="#f4d66b", width=3)
    draw.line([(21,y+5),(30,y+7),(39,y+4)], fill="#8e5c24", width=2)
    px(draw,(14,y-7,19,y-3),"#4b3420"); px(draw,(43,y-3,49,y),"#5c4020")
    for x in (25,34,39): px(draw,(x,y+2,x+1,y+3),"#ad7624")


def sparkle(draw, frame):
    radius = (8, 11, 14, 11, 8, 5)[frame]
    cx, cy = 32, 31
    dark, mid, light = "#5d6428", "#d1b64a", "#fff0a0"
    draw.polygon([(cx,cy-radius),(cx+3,cy-3),(cx+radius,cy),(cx+3,cy+3),
                  (cx,cy+radius),(cx-3,cy+3),(cx-radius,cy),(cx-3,cy-3)], fill=dark)
    draw.polygon([(cx,cy-radius+3),(cx+2,cy-2),(cx+radius-3,cy),(cx+2,cy+2),
                  (cx,cy+radius-3),(cx-2,cy+2),(cx-radius+3,cy),(cx-2,cy-2)], fill=mid)
    px(draw,(cx-2,cy-2,cx+2,cy+2),light)
    if frame in (1,2,3):
        px(draw,(14,16,17,19),light); px(draw,(48,43,51,46),mid)


def dirt(draw, frame):
    spread = (0, 2, 4, 3, 1, 0)[frame]
    dark, soil, mid, light = "#241c16", "#4a3020", "#73502b", "#a77b40"
    draw.ellipse((10-spread,34,54+spread,54),fill=dark)
    draw.polygon([(13-spread,46),(20,36),(31,31-spread//2),(43,36),(52+spread,47)],fill=soil)
    draw.polygon([(19,44),(26,35),(36,34),(46,43)],fill=mid)
    draw.line([(21,42),(29,36),(39,38)],fill=light,width=2)
    for x,y in ((16,47),(25,49),(34,43),(44,48),(51,45)):
        px(draw,(x,y,x+2,y+1),light if (x+frame)%2 else dark)
    if spread>=3:
        px(draw,(8,28,12,31),mid); px(draw,(53,24,57,28),soil); px(draw,(46,18,49,21),light)


def puff(draw, frame):
    radius = (4,7,10,13,10,6)[frame]
    outline, shade, light = "#314535", "#78916e", "#c4d3a5"
    for dx,dy,scale in ((-10,1,1),(0,-5,1.2),(10,1,.9),(0,7,.8)):
        r=max(2,round(radius*scale/2))
        draw.ellipse((32+dx-r,32+dy-r,32+dx+r,32+dy+r),fill=outline)
        draw.ellipse((33+dx-r,31+dy-r,31+dx+r,31+dy+r),fill=shade)
        if r>3:px(draw,(30+dx-r//2,29+dy-r//2,32+dx-r//2,31+dy-r//2),light)


def main():
    atlas=Image.new("RGBA",(CELL*FRAMES,CELL*ROWS),(0,0,0,0))
    painters=(feather,banana,sparkle,dirt,puff)
    for row,painter in enumerate(painters):
        for frame in range(FRAMES):
            tile=Image.new("RGBA",(CELL,CELL),(0,0,0,0));draw=ImageDraw.Draw(tile)
            painter(draw,frame);atlas.alpha_composite(tile,(frame*CELL,row*CELL))
    TARGET.parent.mkdir(parents=True,exist_ok=True);atlas.save(TARGET,optimize=True)
    colors=len({p for p in atlas.getdata() if p[3]})
    assert set(atlas.getchannel("A").getdata()) <= {0,255}
    print(f"LOBBY_INTERACTION_PROPS_OK {atlas.width}x{atlas.height} rows={ROWS} frames={FRAMES} colors={colors} hard_alpha=1")


if __name__=="__main__": main()
