from pathlib import Path
from PIL import Image, ImageChops

ROOT=Path(__file__).resolve().parents[1]
path=ROOT/"assets"/"fx"/"oil-trail"/"oil-fire-object-atlas-pixel-v3.png"
image=Image.open(path).convert("RGBA")
assert image.size==(768,384),image.size
alpha=image.getchannel("A")
assert set(alpha.get_flattened_data())<={0,255},"oil-fire alpha is not hard pixel alpha"
for row in range(3):
    frames=[]
    for frame in range(6):
        cell=image.crop((frame*128,row*128,(frame+1)*128,(row+1)*128))
        assert cell.getbbox(),f"empty oil-fire cell {row}:{frame}"
        colors={pixel for pixel in cell.get_flattened_data()if pixel[3]}
        assert len(colors)>=12,f"oil-fire cell lacks stepped material colors {row}:{frame}={len(colors)}"
        box=cell.getchannel("A").getbbox()
        assert box[3]>=114 and box[1]<=82,f"oil-fire lost root or tongue {row}:{frame}:{box}"
        frames.append(cell)
    assert any(ImageChops.difference(frames[0],other).getbbox()for other in frames[1:]),f"static fire row {row}"
print("OIL_FIRE_OBJECTS_V3_OK atlas=768x384 variants=3 frames=6 colors>=12 root=stable")
