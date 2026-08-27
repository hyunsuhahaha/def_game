from pathlib import Path

from PIL import Image

root=Path(__file__).resolve().parents[1]
path=root/"assets/fx/oil-trail/oil-trail-atlas-pixel-v2.png"
image=Image.open(path).convert("RGBA")
assert image.size==(768,256),image.size
assert set(image.getchannel("A").getdata()) <= {0,255}
cells=[]
for row in range(2):
    for col in range(6):
        cell=image.crop((col*128,row*128,(col+1)*128,(row+1)*128))
        assert cell.getchannel("A").getbbox(),(row,col)
        cells.append(cell.tobytes())
assert len(set(cells))==12
colors={pixel[:3] for pixel in image.getdata() if pixel[3]}
assert 48 <= len(colors) <= 130,len(colors)
for point in ((0,0),(767,0),(0,255),(767,255)):
    assert image.getpixel(point)[3]==0,point
print(f"oil trail atlas ok: size={image.size}, visible_colors={len(colors)}, unique_cells={len(set(cells))}")
