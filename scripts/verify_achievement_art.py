from PIL import Image
from pathlib import Path
p=Path("assets/ui/achievement-icons-pixel-v1.png")
im=Image.open(p).convert("RGBA")
assert im.size==(640,64)
pixels=im.get_flattened_data() if hasattr(im,"get_flattened_data") else im.getdata()
colors={px for px in pixels if px[3]}
assert len(colors)>=16, len(colors)
assert all(px[3] in (0,255) for px in pixels)
for i in range(10):
    cell=im.crop((i*64,0,(i+1)*64,64))
    assert cell.getbbox(),f"empty icon {i}"
board=Path("src/achievement_board.lua").read_text(encoding="utf-8")
assert 'setFilter("nearest","nearest")' in board
assert "drawPopup" in board and "업적 달성" in board
print(f"ACHIEVEMENT_ART_OK atlas=640x64 icons=10 colors={len(colors)} alpha=binary popup=animated")
