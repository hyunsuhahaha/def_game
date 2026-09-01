-- 로비 CD 데크 회귀 검사.
--
-- 그림이 좋은지는 오프스크린 렌더를 눈으로 봐야 한다(render_lobby_cd_preview.py,
-- render_score_attack_lobby.py). 여기서는 눈으로 잘 안 잡히는 것만 고정한다 —
-- 아틀라스 규격, 프레임 선택이 범위를 벗어나는지, 그리고 회전 관성.
package.path = "./?.lua;./?/init.lua;" .. package.path

local CdArt = require("src.lobby_cd_art")

local function read(path)
    local file = assert(io.open(path, "rb")); local data = file:read("*a"); file:close(); return data
end

-- 1. 아틀라스 규격. 셀 크기나 프레임 수가 어긋나면 런타임 quad 가 옆 프레임을 문다.
-- 두 크기를 각자의 격자에서 따로 구웠으므로 둘 다 본다.
local function be32(png, offset)
    local a, b, c, d = png:byte(offset, offset + 3)
    return ((a * 256 + b) * 256 + c) * 256 + d
end

for key, size in pairs(CdArt.SIZES) do
    local png = read(size.file)
    assert(png:sub(2, 4) == "PNG", key .. ": CD 아틀라스가 PNG 가 아니다")
    assert(be32(png, 17) == size.w * CdArt.FRAMES and be32(png, 21) == size.h * CdArt.TRACKS,
        key .. ": CD 아틀라스 크기가 셀·프레임 수와 맞지 않는다")
    assert(png:byte(26) == 6,
        key .. ": CD 아틀라스에 알파 채널이 없다 — 가운데 구멍이 뚫리지 않는다")
    -- 반원만 굽는다. 셀 높이가 지름만큼이면 안 보이는 아래쪽 절반까지 들고 있는 것이다.
    assert(size.h < size.radius * 2 and size.h >= size.radius,
        key .. ": 셀이 반원 규격이 아니다 — 안 보이는 절반까지 굽고 있다")
    assert(size.w >= size.radius * 2, key .. ": 셀 폭이 지름보다 좁아 원반이 잘린다")
end
assert(CdArt.SIZES.large.radius <= 80 and CdArt.SIZES.small.radius <= 56,
    "CD가 다시 메뉴를 덮던 대형 크기로 커졌다")

-- 2. 회전 상태. 프레임 인덱스가 범위를 벗어나면 검은 사각형이 그려진다.
local state = CdArt.newState()
assert(state.speed == 0 and state.angle == 0, "CD 가 멈춘 상태로 시작하지 않는다")

for _ = 1, 400 do CdArt.update(state, 1 / 60, true) end
assert(state.speed > CdArt.SPIN_SPEED * .9, "재생 중인데 CD 가 최고 속도에 못 미친다")
assert(CdArt.SPIN_SPEED <= .20, "CD 반사광이 다시 너무 빠르게 돈다")
assert(state.angle >= 0 and state.angle < 1, "CD 회전각이 0..1 을 벗어났다")

-- 3. 멈출 때는 관성으로 선다. 즉시 꺼지면 기계가 아니라 아이콘으로 보인다.
assert(CdArt.SPIN_DOWN < CdArt.SPIN_UP, "감속이 가속보다 빨라 관성이 읽히지 않는다")
local spinning = state.speed
CdArt.update(state, 1 / 60, false)
assert(state.speed < spinning and state.speed > 0, "정지가 한 프레임 만에 끝났다")
for _ = 1, 900 do CdArt.update(state, 1 / 60, false) end
assert(state.speed == 0, "멈춘 CD 가 계속 아주 조금씩 돌고 있다")

-- 4. 프레임 인덱스는 회전각 전 구간에서 아틀라스 안에 있어야 한다.
local seen = {}
for step = 0, 400 do
    state.angle = step / 400
    local frame = CdArt.frame(state)
    assert(frame >= 1 and frame <= CdArt.FRAMES, "CD 프레임 인덱스가 아틀라스를 벗어난다")
    seen[frame] = true
end
local count = 0
for _ in pairs(seen) do count = count + 1 end
assert(count == CdArt.FRAMES, "회전 한 바퀴에서 쓰이지 않는 프레임이 있다")
state.angle = 0
assert(CdArt.frame(state) == 1, "회전각 0 이 첫 프레임이 아니다")
state.angle = .5
assert(CdArt.frame(state) == CdArt.FRAMES / 2 + 1,
    "반사광이 한 바퀴 대신 반 바퀴마다 반복된다")
assert(CdArt.TRACKS == 3 and CdArt.track(1) == 1 and CdArt.track(2) == 2 and
    CdArt.track(3) == 3 and CdArt.track(99) == 3,
    "세 곡의 고유 CD 행 선택이 깨졌다")

-- 5. 런타임 연결. 자산과 상태 기계가 멀쩡해도 로비가 안 그리면 화면에는 없다.
local lobby = read("src/lobby.lua")
assert(lobby:find("lobby_cd_art", 1, true), "로비가 CD 자산을 연결하지 않았다")
assert(lobby:find("drawAudioDisc", 1, true), "CD 를 그리는 곳이 없다")
-- 바를 먼저 칠하고 원반을 나중에 그리면 원반이 바 앞에 떠서 "뒤에서 솟았다"가 깨진다.
local disc = lobby:find("self:drawAudioDisc", 1, true)
local panel = lobby:find('rectangle("fill",x,y,w,h)', 1, true)
assert(disc and panel and disc < panel, "원반이 바 앞에 그려져 반쪽만 보이지 않는다")
assert(lobby:find("CdArt.update", 1, true), "CD 회전이 갱신되지 않아 멈춰 있다")

assert(lobby:find("self.audioTrack or 1", 1, true), "현재 곡 번호가 CD 디자인에 연결되지 않았다")

print("LOBBY_CD_OK tracks=3 frames=32 half_disc=compact sizes=2 spin=slow_inertial")
