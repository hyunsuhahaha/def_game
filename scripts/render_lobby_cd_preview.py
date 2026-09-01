"""Inspect the lobby CD at real game scale and as an enlarged pixel view."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / 'assets/ui/lobby-cd-spin-pixel-v1.png'
OUT = ROOT / 'docs/previews/lobby-cd-v1-preview.png'
CELL, FRAMES, ZOOM = 48, 16, 6

# 로비 플레이어 패널의 실제 색. 자산을 흰 배경에서 보면 항상 괜찮아 보인다.
PANEL = (5, 18, 13)
BAR_FILL = (5, 18, 13)
BAR_LINE = (87, 184, 128)
ACCENT = (242, 158, 46)
GRASS = (86, 122, 62)


def main():
    atlas = Image.open(SRC).convert('RGBA')
    strip_w = CELL * FRAMES
    page = Image.new('RGB', (strip_w + 32, CELL * 2 + 40 + CELL * ZOOM + 24), GRASS)

    # 1) 실제 게임 크기, 로비 배경(잔디) 위 — 이게 플레이어가 보는 크기다.
    for f in range(FRAMES):
        page.paste(atlas.crop((f * CELL, 0, f * CELL + CELL, CELL)), (16 + f * CELL, 12), atlas.crop((f * CELL, 0, f * CELL + CELL, CELL)))

    # 2) 실제 배치: 플레이어 바 위에 얹힌 모습
    bar_y = 12 + CELL + 14
    bar = Image.new('RGB', (strip_w, CELL), BAR_FILL)
    page.paste(bar, (16, bar_y + 24))
    for x in range(strip_w):
        page.putpixel((16 + x, bar_y + 24), BAR_LINE)
        page.putpixel((16 + x, bar_y + 24 + CELL - 1), BAR_LINE)
    for y in range(CELL):
        for x in range(5):
            page.putpixel((16 + x, bar_y + 24 + y), ACCENT)
    for i, f in enumerate((0, 4, 8, 12)):
        tile = atlas.crop((f * CELL, 0, f * CELL + CELL, CELL))
        page.paste(tile, (40 + i * 150, bar_y - 10), tile)

    # 3) 확대 픽셀 검수 — 경계와 명암 단계 확인
    zoom_y = bar_y + 24 + CELL + 18
    for i, f in enumerate((0, 2, 4, 6)):
        tile = atlas.crop((f * CELL, 0, f * CELL + CELL, CELL))
        flat = Image.new('RGB', (CELL, CELL), PANEL)
        flat.paste(tile, (0, 0), tile)
        page.paste(flat.resize((CELL * ZOOM, CELL * ZOOM), Image.NEAREST), (16 + i * (CELL * ZOOM + 8), zoom_y))

    OUT.parent.mkdir(parents=True, exist_ok=True)
    page.save(OUT)
    print(f'LOBBY_CD_PREVIEW_OK {OUT.relative_to(ROOT)}')


if __name__ == '__main__':
    main()
