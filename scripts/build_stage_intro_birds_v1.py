"""Build four coherent six-frame pixel bird flights for stage-entry cinematics."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
CELL_W,CELL_H,FRAMES,ROWS=96,64,6,4
OUT=ROOT/'assets/fx/stage-intro/stage-intro-birds-atlas-pixel-v1.png'
PRE=ROOT/'docs/previews/stage-intro-birds-atlas-pixel-v1-3x.png'
WING=(-1,-10,-16,-8,2,8)
PALETTES=(
    # temperate magpie, mangrove kingfisher, Madagascar coua, island parrot
    ((10,18,20),(32,48,53),(69,88,91),(181,196,187),(245,238,185),(172,73,38),(241,160,53),(255,244,209),(91,118,113)),
    ((8,23,29),(18,70,83),(30,126,140),(63,188,183),(202,231,195),(163,76,39),(244,153,54),(250,236,188),(96,157,149)),
    ((12,20,31),(26,55,94),(43,98,151),(67,151,190),(183,217,210),(125,53,38),(232,120,47),(244,224,174),(105,145,164)),
    ((11,25,18),(28,80,42),(53,139,62),(108,184,74),(214,220,115),(161,53,34),(246,130,42),(255,229,151),(104,151,73)),
)


def frame(row,index):
    im=Image.new('RGBA',(CELL_W,CELL_H),(0,0,0,0));d=ImageDraw.Draw(im)
    ink,deep,mid,light,cream,red,orange,glint,mute=PALETTES[row]
    cy=34;wing=WING[index]
    # Tail, back wing and primary feather separation.
    d.polygon([(30,34),(11,27),(17,39),(9,45),(31,41)],fill=ink+(255,))
    d.polygon([(29,35),(15,30),(20,38),(14,43),(32,39)],fill=deep+(255,))
    d.line([(16,31),(29,37)],fill=mute+(255,),width=2)
    if wing<0:
        d.polygon([(42,34),(28,17+wing),(34,8+wing),(46,27)],fill=ink+(255,))
        d.polygon([(40,33),(31,18+wing),(35,12+wing),(45,29)],fill=mid+(255,))
        d.polygon([(38,27),(35,14+wing),(41,23)],fill=light+(255,))
        d.line([(34,18+wing),(41,29)],fill=mute+(255,),width=2)
    else:
        d.polygon([(39,35),(27,43+wing),(35,53+wing//2),(49,39)],fill=ink+(255,))
        d.polygon([(40,37),(31,43+wing),(36,49+wing//2),(47,39)],fill=mid+(255,))
        d.line([(34,44+wing//2),(44,39)],fill=light+(255,),width=2)
    # Stepped oval body and shoulder volume.
    d.ellipse((27,26,68,48),fill=ink+(255,))
    d.ellipse((30,27,65,46),fill=deep+(255,))
    d.ellipse((35,28,64,43),fill=mid+(255,))
    d.polygon([(38,29),(59,29),(64,35),(54,34),(47,39),(35,37)],fill=light+(255,))
    d.polygon([(39,38),(57,35),(62,42),(48,45),(34,41)],fill=cream+(255,))
    # Head, beak and readable eye.
    d.ellipse((56,22,78,42),fill=ink+(255,));d.ellipse((59,24,76,39),fill=mid+(255,))
    d.polygon([(75,29),(90,34),(75,37)],fill=ink+(255,));d.polygon([(76,31),(87,34),(76,35)],fill=orange+(255,))
    d.rectangle((66,27,70,31),fill=ink+(255,));d.point((68,28),fill=glint+(255,))
    d.rectangle((58,37,62,40),fill=red+(255,))
    # Controlled one-pixel feather texture: follows the body, never random noise.
    for x,y in ((36,32),(42,30),(48,33),(54,31),(40,39),(47,42),(55,39)):
        d.point((x+(index%2),y),fill=(glint if (x+y+index)%3==0 else mute)+(255,))
    return im


def main():
    atlas=Image.new('RGBA',(CELL_W*FRAMES,CELL_H*ROWS),(0,0,0,0))
    for row in range(ROWS):
        for i in range(FRAMES):atlas.alpha_composite(frame(row,i),(i*CELL_W,row*CELL_H))
    OUT.parent.mkdir(parents=True,exist_ok=True);PRE.parent.mkdir(parents=True,exist_ok=True)
    atlas.save(OUT,optimize=True)
    atlas.resize((atlas.width*3,atlas.height*3),Image.Resampling.NEAREST).save(PRE)
    colors={p[:3] for p in atlas.get_flattened_data() if p[3]}
    assert len(colors)>=36 and set(atlas.getchannel('A').get_flattened_data())=={0,255}
    print(f'STAGE_INTRO_BIRDS_V1_OK atlas={atlas.width}x{atlas.height} cell={CELL_W}x{CELL_H} frames={FRAMES} species={ROWS} colors={len(colors)} alpha=hard')


if __name__=='__main__':main()
