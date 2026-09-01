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
local png = read("assets/ui/lobby-cd-spin-pixel-v1.png")
assert(png:sub(2, 4) == "PNG", "CD 아틀라스가 PNG 가 아니다")
local function be32(offset)
    local a, b, c, d = png:byte(offset, offset + 3)
    return ((a * 256 + b) * 256 + c) * 256 + d
end
assert(be32(17) == CdArt.CELL * CdArt.FRAMES and be32(21) == CdArt.CELL,
    "CD 아틀라스 크기가 셀·프레임 수와 맞지 않는다")
assert(png:byte(26) == 6, "CD 아틀라스에 알파 채널이 없다 — 가운데 구멍이 뚫리지 않는다")

-- 2. 회전 상태. 프레임 인덱스가 범위를 벗어나면 검은 사각형이 그려진다.
local state = CdArt.newState()
assert(state.speed == 0 and state.angle == 0, "CD 가 멈춘 상태로 시작하지 않는다")

for _ = 1, 400 do CdArt.update(state, 1 / 60, true) end
assert(state.speed > CdArt.SPIN_SPEED * .9, "재생 중인데 CD 가 최고 속도에 못 미친다")
assert(state.angle >= 0 and state.angle < 1, "CD 회전각이 0..1 을 벗어났다")

-- 3. 멈출 때는 관성으로 선다. 즉시 꺼지면 기계가 아니라 아이콘으로 보인다.
assert(CdArt.SPIN_DOWN < CdArt.SPIN_UP, "감속이 가속보다 빨라 관성이 읽히지 않는다")
local spinning = state.speed
CdArt.update(state, 1 / 60, false)
assert(state.speed < spinning and state.speed > 0, "정지가 한 프레임 만에 끝났다")
for _ = 1, 900 do CdArt.update(state, 1 / 60, false) end
assert(state.speed == 0, "멈춘 CD 가 계속 아주 조금씩 돌고 있다")

-- 4. 프레임 인덱스는 회전각 전 구간에서 아틀라스 안에 있어야 한다.
for step = 0, 200 do
    state.angle = step / 200
    local frame = math.floor(state.angle * CdArt.FRAMES) % CdArt.FRAMES + 1
    assert(frame >= 1 and frame <= CdArt.FRAMES, "CD 프레임 인덱스가 아틀라스를 벗어난다")
end

-- 5. 런타임 연결. 자산과 상태 기계가 멀쩡해도 로비가 안 그리면 화면에는 없다.
local lobby = read("src/lobby.lua")
assert(lobby:find("lobby_cd_art", 1, true), "로비가 CD 자산을 연결하지 않았다")
assert(lobby:find("drawAudioDeck", 1, true), "CD 데크를 그리는 곳이 없다")
assert(lobby:find("CdArt.update", 1, true), "CD 회전이 갱신되지 않아 멈춰 있다")

print("LOBBY_CD_OK frames=16 cell=48 spin=inertial art=baked_rotation")
