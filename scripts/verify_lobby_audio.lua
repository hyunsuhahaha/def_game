-- 로비 배경음 회귀 검사.
--
-- 로비에는 재생/정지 버튼과 트랙 이름 셋이 붙은 플레이어 UI가 먼저 있었고 소리는
-- 없었다. 이 검사는 세 트랙이 실제로 소리를 내는지, 그리고 무한 반복되는 음악에서
-- 제일 먼저 티가 나는 두 가지 — 루프 이음매의 딸깍임과 클리핑 — 을 고정한다.
--
-- 귀로만 잡을 수 있는 것(좋게 들리는지)은 여기서 못 잡는다. 사람이 들어야 한다.
-- scripts/export_lobby_audio.lua 가 같은 코드로 wav 를 뽑는다.
package.path = "./?.lua;./?/init.lua;" .. package.path

local LobbyAudio = require("src.lobby_audio")

assert(#LobbyAudio.TRACKS == 7, "로비 트랙 수가 UI 목록과 어긋났다")

for index, track in ipairs(LobbyAudio.TRACKS) do
    local buffer, count = LobbyAudio.render(index)
    local label = track.name
    assert(buffer and count > 0, label .. ": 렌더 결과가 비었다")

    -- 길이는 템포에서 나온다. 마디에 맞지 않으면 루프마다 박자가 밀린다.
    local expected = math.floor(60 / track.bpm * track.beats * LobbyAudio.RATE)
    assert(count == expected, label .. ": 루프 길이가 템포·마디 수와 맞지 않는다")

    local peak, sum, dc, step = 0, 0, 0, 0
    for i = 0, count - 1 do
        local v = buffer[i]
        assert(v >= -1 and v <= 1, label .. ": 샘플이 범위를 벗어났다")
        local a = v < 0 and -v or v
        if a > peak then peak = a end
        sum = sum + v * v
        dc = dc + v
        if i > 0 then
            local d = v - buffer[i - 1]
            step = step + (d < 0 and -d or d)
        end
    end
    local rms = math.sqrt(sum / count)
    local meanStep = step / (count - 1)
    dc = dc / count

    -- 무음이나 거의 무음이면 UI만 움직이던 예전과 다를 게 없다.
    assert(rms > .02, label .. ": 사실상 무음이다")
    -- 봉우리를 1.0 까지 밀면 재생 경로 어디서든 조금만 더해도 깨진다.
    assert(peak > .1 and peak <= .5,
        label .. ": 음량이 너무 작거나 클리핑 여유가 없다")
    assert(math.abs(dc) < .02, label .. ": DC 오프셋이 남아 스피커를 밀고 있다")

    -- 루프 이음매. 마지막 샘플에서 첫 샘플로 넘어가는 단차가 평소 샘플 간
    -- 변화보다 크게 튀면 반복할 때마다 딸깍 소리가 난다. 꼬리를 버퍼 앞으로
    -- 감아서(wrap) 더하는 이유가 이것이다.
    local seam = math.abs(buffer[0] - buffer[count - 1])
    assert(seam < meanStep * 12,
        label .. ": 루프 이음매가 튄다 — 반복할 때마다 딸깍거린다")
end

-- 같은 트랙은 실행마다 같은 소리여야 한다. 노이즈를 love.math 에 맡기면
-- 헤드리스로 내보낸 wav 와 게임 안에서 들리는 소리가 달라진다.
local first = LobbyAudio.render(1)
local again = LobbyAudio.render(1)
for i = 0, 400 do
    assert(first[i] == again[i], "트랙이 실행마다 다르게 렌더된다")
end

-- 재생 상태 기계. 렌더가 멀쩡해도 여기서 틀리면 작전 중에 로비 음악이 계속
-- 흐르거나, 트랙을 넘겨도 앞 곡이 겹쳐 난다. 소리로만 드러나는 부분이라 검사로 고정한다.
do
    local log = {}
    local function stubSource(id)
        return {
            setLooping = function() end, setVolume = function() end,
            play = function() log[#log+1] = "play" .. id end,
            pause = function() log[#log+1] = "pause" .. id end,
            stop = function() log[#log+1] = "stop" .. id end,
        }
    end
    local made = 0
    love = {
        sound = {newSoundData = function() return {setSample = function() end} end},
        audio = {newSource = function() made = made + 1; return stubSource(made) end},
    }

    local audio = LobbyAudio.new()
    audio:sync(1, true)
    assert(log[#log] == "play1", "재생을 눌러도 곡이 시작되지 않는다")
    audio:sync(1, true)
    assert(#log == 1, "이미 흐르는 곡을 매 프레임 다시 재생하고 있다")

    audio:sync(1, false)
    assert(log[#log] == "pause1", "정지를 눌러도 곡이 멎지 않는다")
    audio:sync(1, false)
    assert(#log == 2, "멎어 있는 곡에 정지를 매 프레임 다시 걸고 있다")

    audio:sync(1, true)
    assert(log[#log] == "play1", "정지 뒤 재개가 되지 않는다")

    audio:sync(2, true)
    assert(log[#log - 1] == "stop1" and log[#log] == "play2",
        "트랙을 넘길 때 앞 곡이 멎지 않아 두 곡이 겹친다")
    assert(made == 2, "트랙마다 소스를 새로 만들고 있다")

    -- 소리 장치가 없는 기기: 한 번 실패하면 다시 시도하지 않는다. 매 프레임
    -- 재합성하면 로비가 통째로 멎는다.
    love.sound.newSoundData = function() error("no audio device") end
    local silent = LobbyAudio.new()
    silent:sync(1, true)
    local attempts = 0
    love.sound.newSoundData = function() attempts = attempts + 1; error("no audio device") end
    for _ = 1, 5 do silent:sync(1, true) end
    assert(attempts == 0, "합성에 실패한 트랙을 매 프레임 다시 만들고 있다")
end

print("LOBBY_AUDIO_OK tracks=7 synth=runtime loop=wrapped seam=click_free")
