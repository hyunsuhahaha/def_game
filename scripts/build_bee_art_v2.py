"""Build a compact six-frame bee: readable silhouette, restrained detail."""
from pathlib import Path
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]
DEST=ROOT/'assets/fx/bees/bee-flight-simple-pixel-v2.png'
PREVIEW=ROOT/'docs/previews/bee-flight-simple-pixel-v2.png'
W,H,FRAMES=32,24,6
C={'outline':(45,29,13,255),'deep':(75,43,13,255),'brown':(111,61,15,255),
   'gold0':(167,94,13,255),'gold1':(226,151,25,255),'gold2':(255,211,70,255),
   'black':(38,27,18,255),'eye':(255,244,176,255),'wing0':(91,129,150,255),
   'wing1':(166,204,218,255),'wing2':(226,241,237,255)}
wing_poses=[('up',0),('up',1),('mid',0),('down',0),('mid',1),('up',1)]

def polygon(d,pts,color):d.polygon(pts,fill=C[color])
def frame(kind,variant):
    im=Image.new('RGBA',(W,H));d=ImageDraw.Draw(im)
    # Two stepped wings, only three tones; body anchor never moves.
    if kind=='up':
        polygon(d,[(13,11),(10,8-variant),(10,3),(12,2),(15,7),(16,11)],'outline')
        polygon(d,[(11,7-variant),(11,4),(12,3),(14,7),(15,10)],'wing1')
        polygon(d,[(12,4),(13,5),(14,8)],'wing2')
        polygon(d,[(16,11),(15,7),(17,4-variant),(19,5),(19,10)],'outline')
        polygon(d,[(16,9),(17,5-variant),(18,6),(18,10)],'wing0')
    elif kind=='mid':
        polygon(d,[(13,10),(9,7+variant),(7,8+variant),(9,11),(15,12)],'outline')
        polygon(d,[(10,8+variant),(8,8+variant),(10,10),(14,11)],'wing1')
        polygon(d,[(15,10),(17,7+variant),(21,7+variant),(20,10),(17,12)],'outline')
        polygon(d,[(17,8+variant),(20,8+variant),(18,10),(16,11)],'wing2')
    else:
        polygon(d,[(14,12),(11,14),(10,19),(12,21),(15,17),(16,13)],'outline')
        polygon(d,[(12,15),(11,19),(12,20),(14,17),(15,13)],'wing1')
        polygon(d,[(17,12),(17,16),(19,20),(21,19),(20,14)],'outline')
        polygon(d,[(18,13),(18,16),(19,19),(20,18),(19,14)],'wing2')
    # Stinger and compact stepped abdomen.
    polygon(d,[(5,13),(8,11),(8,15)],'outline');polygon(d,[(6,13),(8,12),(8,14)],'eye')
    polygon(d,[(8,10),(11,8),(18,8),(21,11),(21,15),(18,18),(11,18),(8,16)],'outline')
    d.rectangle((9,11,19,16),fill=C['gold1']);d.rectangle((11,9,17,10),fill=C['gold2']);d.rectangle((10,16,18,17),fill=C['gold0'])
    d.rectangle((11,10,12,17),fill=C['black']);d.rectangle((16,9,17,17),fill=C['deep'])
    # Thorax/head, one eye and short antennae.
    polygon(d,[(19,10),(21,8),(25,9),(27,11),(27,15),(25,17),(21,17),(19,15)],'outline')
    d.rectangle((20,11,22,15),fill=C['brown']);d.rectangle((23,10,26,15),fill=C['black']);d.point((25,11),fill=C['eye'])
    d.line((24,9,26,6),fill=C['outline']);d.point((27,6),fill=C['outline']);d.line((26,9,29,8),fill=C['outline'])
    # Small legs, kept secondary.
    d.line((13,18,12,20),fill=C['outline']);d.line((18,18,19,20),fill=C['outline']);d.point((11,20),fill=C['brown']);d.point((20,20),fill=C['brown'])
    return im

def main():
    atlas=Image.new('RGBA',(W*FRAMES,H))
    for i,(kind,v) in enumerate(wing_poses):atlas.alpha_composite(frame(kind,v),(i*W,0))
    DEST.parent.mkdir(parents=True,exist_ok=True);atlas.save(DEST)
    PREVIEW.parent.mkdir(parents=True,exist_ok=True);atlas.resize((W*FRAMES*5,H*5),Image.Resampling.NEAREST).save(PREVIEW)
    colors={p for p in atlas.getdata() if p[3]};print(f'BEE_SIMPLE_V2_OK atlas={atlas.size} frames={FRAMES} colors={len(colors)}')
if __name__=='__main__':main()
