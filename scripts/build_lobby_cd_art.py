"""Build the 16-frame lobby CD that spins above the pixel audio player.

큰 형태는 단순한 원반 하나, 그 안의 픽셀 명암은 데이터 트랙 링과 무지개 광택으로
정교하게 만든다. 색은 로비 플레이어 패널(짙은 녹색 + 주황 강조)에서 가져와 UI에
붙어 보이게 한다.

회전하는 것은 실루엣이 아니라 광택이다. 원반은 어차피 원이라 실루엣을 돌리면
화면에서 아무 일도 일어나지 않는다.

광택은 원반을 덮어 칠하지 않고 트랙 링 위에 단계로 섞는다. 통짜로 칠하면 여섯
개의 색종이를 붙인 것처럼 보이고 원반의 재질이 사라진다. 단계 경계에만 2x2 정렬
디더를 넣는다 — 전면 디더는 재질이 아니라 노이즈다.
"""
import math
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/ui/lobby-cd-spin-pixel-v1.png'
CELL, FRAMES = 48, 16
R_OUT, R_RIM, R_HUB, R_HOLE = 22.5, 21.0, 8.0, 4.0

OUTLINE = (7, 20, 15)
RING_DARK = (22, 44, 36)
RING_MID = (38, 70, 58)
HUB_RING = (150, 186, 164)
HUB_FILL = (28, 52, 43)
SPEC = (214, 236, 220)

# 무지개 광택. 실제 CD 분광을 그대로 쓰면 UI에서 혼자 튀므로 로비의 주황·녹색·
# 청록 범위 안에서만 단계를 만든다.
SHEEN = [
    (247, 166, 52), (255, 205, 108), (176, 212, 118),
    (94, 192, 146), (74, 172, 180), (112, 152, 190),
]
# 갈래를 넓히면 원반 전체가 무지개가 되어 CD 가 아니라 바람개비로 읽힌다. 어두운
# 원반이 대부분 남고 좁은 광택 두 줄기가 지나가야 CD 다.
SHEEN_ARC = 62.0    # 한 갈래가 차지하는 각도
LEVELS = 5          # 섞는 단계 수. 매끈한 그라데이션이 아니라 계단이어야 한다
BAYER = ((0, 2), (3, 1))


def mix(a, b, k):
    return tuple(int(a[i] + (b[i] - a[i]) * k + .5) for i in range(3))


def build():
    atlas = Image.new('RGBA', (CELL * FRAMES, CELL), (0, 0, 0, 0))
    cx = cy = CELL / 2 - .5
    for frame in range(FRAMES):
        rot = frame * (360 / FRAMES)
        tile = Image.new('RGBA', (CELL, CELL), (0, 0, 0, 0))
        px = tile.load()
        for y in range(CELL):
            for x in range(CELL):
                dx, dy = x - cx, y - cy
                r = math.hypot(dx, dy)
                if r > R_OUT or r <= R_HOLE:
                    continue
                if r > R_RIM:
                    px[x, y] = OUTLINE + (255,)
                    continue
                if r <= R_HUB:
                    px[x, y] = (HUB_RING if r > R_HUB - 1.6 else HUB_FILL) + (255,)
                    continue

                # 데이터 트랙: 2px 주기의 동심 링. 원반을 한 색으로 채우지 않는다.
                base = RING_MID if int(r) % 2 else RING_DARK
                # 림으로 갈수록 살짝 어둡게 해서 원반이 평면 원판으로 안 보이게 한다.
                base = mix(base, RING_DARK, min(1, max(0, (r - 14) / 8)) * .5)

                angle = math.degrees(math.atan2(dy, dx)) % 360
                # 광택 두 갈래가 180도 마주 본다.
                w = ((angle - rot) % 180) / SHEEN_ARC
                if w < 1:
                    # 색은 각도뿐 아니라 반지름을 따라서도 넘어간다. 각도로만 나누면
                    # 부챗살 무늬가 되고 CD 의 분광으로 안 읽힌다.
                    index = int(w * 3.2 + r * .22) % len(SHEEN)
                    hue = SHEEN[index]
                    strength = math.sin(w * math.pi) ** .7 * .95
                else:
                    hue, strength = SHEEN[0], 0.0

                if strength > 0:
                    # 단계 경계에만 정렬 디더가 걸린다.
                    dither = (BAYER[y % 2][x % 2] + .5) / 4 - .5
                    level = int(strength * (LEVELS - 1) + dither + .5)
                    level = max(0, min(LEVELS - 1, level))
                    px[x, y] = mix(base, hue, level / (LEVELS - 1)) + (255,)
                else:
                    px[x, y] = base + (255,)

                # 고정 반사광. 빛은 원반과 같이 돌지 않는다. 이 대비가 나머지를
                # 돌게 보이게 한다.
                gloss = math.cos(math.radians(angle - 215))
                if gloss > .93 and r > R_HUB + 2:
                    px[x, y] = mix(px[x, y][:3], SPEC, (gloss - .93) / .07 * .55) + (255,)

        atlas.alpha_composite(tile, (frame * CELL, 0))

    OUT.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(OUT, optimize=True)
    colors = len({p for p in atlas.convert('RGBA').getdata() if p[3]})
    print(f'LOBBY_CD_ATLAS_OK {OUT.relative_to(ROOT)} {FRAMES}x{CELL} colors={colors}')


if __name__ == '__main__':
    build()
