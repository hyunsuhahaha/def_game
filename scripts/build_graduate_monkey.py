"""Build the shared graduation-companion monkey and its weapon props.

모든 무기 졸업 동료는 같은 원숭이 몸체를 쓰고 손에 든 무기만 다르다. 그래서 몸체
아틀라스에는 무기를 굽지 않고, 무기는 프레임별 손 앵커에 붙이는 별도 스프라이트로
만든다(AGENTS.md의 장비 규칙). 졸업 동료를 새로 추가할 때는 무기 프롭만 그리면 된다.

몸체  graduate-monkey-atlas-pixel-v1.png   6프레임 x 2행 (걷기 / 휘두르기)
프롭  graduate-monkey-props-pixel-v1.png   1행에 무기 하나씩, 셀 48x48

셀 128x128, 발선 y=116. 4px 고정 블록 그리드 — 회색 고양이와 같은 픽셀 밀도.
실루엣 식별점은 무릎까지 내려오는 긴 팔이다(두더지=어두운 굴착, 고양이=회색 매끈).
"""
from pathlib import Path

import math

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "characters" / "companions"
PREVIEW = ROOT / "docs" / "previews"

PX = 4
CELL = 128
PROP = 48
COLS, ROWS = 6, 2

# 전체가 밝은 살구빛이고 어두운 건 윤곽선과 머리 위 털뿐이다. 어두운 머리에 창백한
# 얼굴판을 얹으면 가면처럼 읽혀서 귀엽지 않다.
INK = (62, 42, 32, 255)
SKIN = (226, 178, 140, 255)
SKIN_HI = (243, 206, 172, 255)
SKIN_SH = (196, 146, 110, 255)
HAIR = (150, 100, 66, 255)
HAIR_SH = (118, 76, 50, 255)
WHITE = (246, 241, 229, 255)
EYE = (34, 26, 22, 255)
HANDLE = (168, 118, 66, 255)
HANDLE_SH = (124, 84, 46, 255)
STEEL = (154, 166, 180, 255)
STEEL_HI = (216, 224, 232, 255)


def px(d, gx, gy, w, h, color):
    d.rectangle([gx * PX, gy * PX, gx * PX + w * PX - 1, gy * PX + h * PX - 1], fill=color)


def profile(w, h, cut=None):
    """행별 (들여쓰기, 폭). 모서리를 깎는 대신 타원식으로 계산해야 진짜로 둥글다.
    모서리만 깎으면 위아래가 평평해서 상자로 읽힌다."""
    rows = []
    a, b = w / 2, h / 2
    for y in range(h):
        dy = (y + 0.5 - b) / b
        half = a * math.sqrt(max(0.0, 1 - dy * dy))
        ww = max(1, int(round(half * 2)))
        rows.append((int(round((w - ww) / 2)), ww))
    return rows


def blob(d, gx, gy, w, h, fill, cut=2):
    """1블록 잉크 외곽선을 두른 둥근 덩어리. 사각 rect 조합보다 실루엣이 산다."""
    rows = profile(w, h, cut)
    for y, (ins, ww) in enumerate(rows):
        px(d, gx + ins - 1, gy + y, ww + 2, 1, INK)
    px(d, gx + rows[0][0], gy - 1, rows[0][1], 1, INK)
    px(d, gx + rows[-1][0], gy + h, rows[-1][1], 1, INK)
    for y, (ins, ww) in enumerate(rows):
        px(d, gx + ins, gy + y, ww, 1, fill)
    return rows


def limb(d, a, b, color):
    """둥근 끝을 가진 팔다리. 몸통 실루엣 밖으로 나가야 긴 팔이 읽힌다."""
    steps = max(abs(b[0] - a[0]), abs(b[1] - a[1])) or 1
    for i in range(steps + 1):
        gx = round(a[0] + (b[0] - a[0]) * i / steps)
        gy = round(a[1] + (b[1] - a[1]) * i / steps)
        px(d, gx - 1, gy, 4, 2, INK)
        px(d, gx, gy - 1, 2, 4, INK)
        px(d, gx, gy, 2, 2, color)


def monkey(d, bob, legs, arms, lean=0):
    """치비 비율 + 밝은 살구빛 한 톤. 머리가 전체의 절반, 귀는 크고 밝게 튀어나오고,
    어두운 색은 윤곽선과 머리 위 털에만 쓴다."""
    base = 29 + bob
    body_top = base - 12 + lean
    head_top = body_top - 16

    for tx, ty in ((22, base - 6), (24, base - 5), (25, base - 3)):
        px(d, tx - 1, ty - 1, 3, 3, INK)
        px(d, tx, ty, 1, 1, SKIN_SH)

    for lx, drop in legs:
        blob(d, lx, base - 4 + drop, 4, 4, SKIN)
        px(d, lx, base - 2 + drop, 4, 1, SKIN_SH)

    (el, hl), (er, hr) = arms
    limb(d, (11, body_top + 2), hl, SKIN)

    blob(d, 11, body_top, 10, 9, SKIN)
    px(d, 13, body_top + 5, 6, 3, SKIN_SH)

    # 귀: 크고 밝게, 머리 실루엣 밖으로 확실히 나온다
    blob(d, 3, head_top + 6, 6, 7, SKIN)
    blob(d, 23, head_top + 6, 6, 7, SKIN)
    px(d, 5, head_top + 8, 2, 3, SKIN_SH)
    px(d, 25, head_top + 8, 2, 3, SKIN_SH)

    # 머리: 얼굴판을 따로 두지 않고 통째로 살구빛. 위쪽만 털색 모자.
    rows = profile(20, 17, None)
    for y, (ins, ww) in enumerate(rows):
        px(d, 6 + ins - 1, head_top + y, ww + 2, 1, INK)
    px(d, 6 + rows[0][0], head_top - 1, rows[0][1], 1, INK)
    px(d, 6 + rows[-1][0], head_top + 17, rows[-1][1], 1, INK)
    for y, (ins, ww) in enumerate(rows):
        px(d, 6 + ins, head_top + y, ww, 1, HAIR if y < 4 else SKIN)
    px(d, 6 + rows[4][0], head_top + 4, rows[4][1], 1, HAIR_SH)
    for y in range(6, 9):
        px(d, 9, head_top + y, 3, 1, SKIN_HI)

    # 큰 둥근 눈 + 흰 점 하나. 밝은 얼굴 위에 바로 얹는다.
    for ex in (10, 18):
        blob(d, ex, head_top + 8, 4, 5, INK)
        px(d, ex, head_top + 9, 3, 3, (28, 22, 20, 255))
        px(d, ex + 1, head_top + 9, 1, 1, (255, 255, 255, 255))
    px(d, 15, head_top + 12, 2, 1, SKIN_SH)
    px(d, 14, head_top + 14, 4, 1, INK)
    px(d, 13, head_top + 13, 1, 1, INK)
    px(d, 18, head_top + 13, 1, 1, INK)

    limb(d, (21, body_top + 2), hr, SKIN)


# (bob, legs, ((왼팔 미사용, 왼손), (오른팔 미사용, 오른손)), 프롭 각도)
WALK = [
    (0, [(11, 0), (17, 0)], (((0, 0), (9, 22)), ((0, 0), (23, 22))), 0.0),
    (-1, [(11, 0), (17, 1)], (((0, 0), (9, 23)), ((0, 0), (23, 21))), 0.0),
    (0, [(12, 0), (16, 0)], (((0, 0), (10, 23)), ((0, 0), (22, 22))), 0.0),
    (0, [(11, 1), (17, 0)], (((0, 0), (9, 22)), ((0, 0), (23, 23))), 0.0),
    (-1, [(11, 0), (17, 0)], (((0, 0), (9, 23)), ((0, 0), (23, 21))), 0.0),
    (0, [(12, 0), (16, 1)], (((0, 0), (10, 22)), ((0, 0), (22, 22))), 0.0),
]
SWING = [
    (0, [(11, 0), (17, 0)], (((0, 0), (9, 22)), ((0, 0), (26, 19))), -0.40),
    (-1, [(11, 0), (17, 0)], (((0, 0), (9, 22)), ((0, 0), (28, 15))), -1.05),
    (-1, [(11, 0), (17, 0)], (((0, 0), (9, 21)), ((0, 0), (28, 11))), -1.70),
    (1, [(11, 0), (17, 0)], (((0, 0), (9, 23)), ((0, 0), (23, 24))), 1.20),
    (1, [(11, 0), (17, 0)], (((0, 0), (9, 24)), ((0, 0), (21, 26))), 1.85),
    (0, [(11, 0), (17, 0)], (((0, 0), (9, 23)), ((0, 0), (23, 23))), 0.35),
]

# 프레임별 양손 중간점 = 무기 앵커. 런타임이 이 값을 그대로 쓴다.
def anchor(frame):
    (_, _), (_, hr) = frame[2]
    return (hr[0] + 1, hr[1] + 1)


def prop_angle(frame):
    return frame[3]


GRIP = (6, 9)  # 프롭 셀 안에서 손이 쥐는 지점 (그리드)


def axe_prop(d):
    """도끼. 자루 아래끝이 GRIP이고 날은 위로 간다. 손 크기에 맞춰 작게."""
    px(d, 5, 2, 3, 8, INK)
    px(d, 6, 3, 1, 6, HANDLE_SH)
    px(d, 5, 3, 1, 6, HANDLE)
    blob(d, 2, 1, 4, 4, STEEL, cut=1)
    px(d, 2, 1, 2, 2, STEEL_HI)


PROPS = [("axe", axe_prop)]


def place_prop(prop, frame):
    """손 앵커에 프롭을 붙이되 프레임 각도만큼 그립을 축으로 돌린다."""
    import math
    ax, ay = anchor(frame)
    deg = -math.degrees(prop_angle(frame))
    grip_px = (GRIP[0] * PX, GRIP[1] * PX)
    rotated = prop.rotate(deg, resample=Image.NEAREST, center=grip_px)
    return rotated, (int((ax - GRIP[0]) * PX), int((ay - GRIP[1]) * PX))


def build():
    OUT.mkdir(parents=True, exist_ok=True)
    PREVIEW.mkdir(parents=True, exist_ok=True)

    atlas = Image.new("RGBA", (CELL * COLS, CELL * ROWS), (0, 0, 0, 0))
    for row, frames in enumerate((WALK, SWING)):
        for col, frame in enumerate(frames):
            cell = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
            monkey(ImageDraw.Draw(cell), frame[0], frame[1], frame[2], lean=1 if row else 0)
            atlas.alpha_composite(cell, (col * CELL, row * CELL))
    atlas.save(OUT / "graduate-monkey-atlas-pixel-v1.png")

    props = Image.new("RGBA", (PROP, PROP * len(PROPS)), (0, 0, 0, 0))
    for i, (_, draw_prop) in enumerate(PROPS):
        cell = Image.new("RGBA", (PROP, PROP), (0, 0, 0, 0))
        draw_prop(ImageDraw.Draw(cell))
        props.alpha_composite(cell, (0, i * PROP))
    props.save(OUT / "graduate-monkey-props-pixel-v1.png")

    for row, frames in enumerate((WALK, SWING)):
        line = " ".join(f"{{{anchor(f)[0]:.0f},{anchor(f)[1]:.0f},{prop_angle(f):.2f}}}" for f in frames)
        print(f"row{row + 1}: {line}")

    # 검수용: 실제 표시 크기(.34)와 2배 픽셀 뷰
    small = int(CELL * 0.34)
    strip = Image.new("RGBA", (small * COLS, small * ROWS), (24, 28, 20, 255))
    axe_img = props.crop((0, 0, PROP, PROP))
    for row, frames in enumerate((WALK, SWING)):
        for col, frame in enumerate(frames):
            cell = atlas.crop((col * CELL, row * CELL, col * CELL + CELL, row * CELL + CELL)).copy()
            cell.alpha_composite(*place_prop(axe_img, frame))
            strip.alpha_composite(cell.resize((small, small), Image.NEAREST), (col * small, row * small))
    strip.save(PREVIEW / "graduate-monkey-v1-display-scale.png")

    zoom = Image.new("RGBA", atlas.size, (24, 28, 20, 255))
    for row, frames in enumerate((WALK, SWING)):
        for col, frame in enumerate(frames):
            cell = atlas.crop((col * CELL, row * CELL, col * CELL + CELL, row * CELL + CELL)).copy()
            cell.alpha_composite(*place_prop(axe_img, frame))
            zoom.alpha_composite(cell, (col * CELL, row * CELL))
    zoom.resize((atlas.width * 2, atlas.height * 2), Image.NEAREST).save(
        PREVIEW / "graduate-monkey-v1-2x.png")
    print(f"GRADUATE_MONKEY_BUILD_OK body={atlas.width}x{atlas.height} props={props.width}x{props.height}")


if __name__ == "__main__":
    build()
