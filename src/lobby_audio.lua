-- 로비 배경음. 이 저장소에는 오디오 파일이 하나도 없고, 효과음(feedback.lua)과
-- 같은 방식으로 샘플을 직접 계산해서 만든다. 파일이 없으니 용량도 라이선스도
-- 붙지 않고, 로비가 UI로 내세우던 "픽셀 오디오"라는 설정과도 맞는다.
--
-- 루프 이음매는 감아서(wrap) 잇는다. 마디 끝을 넘긴 음의 꼬리를 버퍼 앞쪽에
-- 더하면 마지막 샘플의 다음이 그 음의 실제 다음 샘플이라 파형이 이어진다.
-- 페이드로 자르면 루프마다 소리가 숨을 쉬고, 그냥 자르면 딸깍거린다.
local LobbyAudio={}
LobbyAudio.__index=LobbyAudio

local RATE=22050
local TAU=math.pi*2
local A1=55  -- 모든 음을 A1 기준 반음 오프셋으로 적어 화음표를 읽을 수 있게 한다

local function pitch(semitones) return A1*2^(semitones/12) end

-- 사각파를 그대로 쓰면 배음이 끝없이 올라가 나이퀴스트에서 접혀 들어온다.
-- 홀수 배음 셋만 더해 사각파의 성격만 남기고 대역을 제한한다.
local function square3(p)
    return math.sin(p*TAU)*.68+math.sin(p*3*TAU)*.22+math.sin(p*5*TAU)*.10
end
local function warm(p)
    return math.sin(p*TAU)*.82+math.sin(p*2*TAU)*.18
end

-- 음 하나를 버퍼에 더한다. start+i 를 버퍼 길이로 나눈 나머지에 쓰는 것이
-- 위에서 말한 감기다.
local function addNote(buffer,count,kind,t0,dur,freq,gain,rng)
    local start=math.floor(t0*RATE)
    local length=math.floor(dur*RATE)
    if length<2 then return end
    local prev=0
    for i=0,length-1 do
        local t=i/RATE
        local amp,value
        if kind=="pluck" then
            amp=(t<.006 and t/.006 or math.exp(-(t-.006)*4.2))
            value=square3(freq*t)
        elseif kind=="bass" then
            amp=(t<.010 and t/.010 or math.exp(-(t-.010)*2.1))
            value=warm(freq*t)
        elseif kind=="pad" then
            -- 느린 어택과 느린 릴리스. 두 음을 아주 조금 어긋나게 겹쳐 두께를 만든다.
            local attack=math.min(1,t/.42)
            local release=math.min(1,(dur-t)/(dur*.45))
            amp=attack*release*.55
            value=(math.sin(freq*t*TAU)+math.sin(freq*1.006*t*TAU))*.5
        elseif kind=="hat" then
            amp=math.exp(-t*58)
            value=rng()*2-1
        else -- "air": 바람·물소리 바닥. 노이즈를 1차 저역통과로 눕힌다.
            local noise=rng()*2-1
            prev=prev+(noise-prev)*.06
            amp=math.sin(math.min(1,t/dur)*math.pi)
            value=prev*3.2
        end
        local index=(start+i)%count
        buffer[index]=buffer[index]+value*amp*gain
    end
end

-- 마디마다 {베이스 반음, {패드 화음 반음들}}.
local TRACKS={
    {
        name="FOREST DAY / LOOP 07", bpm=96, beats=16, gain=.34,
        chords={{12,{24,27,31}},{8,{20,24,27}},{15,{27,31,34}},{10,{22,26,29}}},
        -- A 단5음. 반음이 없어 어느 화음 위에 얹어도 어긋나지 않는다.
        lead={{0,36,.9},{1.5,39,.7},{2.5,41,.6},{3,39,.9},
              {4,43,.9},{5.5,41,.7},{6.5,39,.6},{7,36,.9},
              {8,39,.9},{9.5,43,.7},{10.5,46,.6},{11,43,.9},
              {12,41,.9},{13.5,39,.7},{15,36,1.2}},
        bassBeats={0,2,3.5}, hat=true, air=0,
    },
    {
        name="RIVER LINE / LOOP 03", bpm=84, beats=16, gain=.30,
        chords={{5,{17,20,24}},{1,{13,17,20}},{8,{20,24,27}},{3,{15,19,22}}},
        -- 멜로디 대신 8분음표 아르페지오가 계속 흐른다. 물줄기 쪽 이름에 맞춘다.
        arp={0,1,2,1,3,2,1,0}, arpOctave=12,
        bassBeats={0,2}, hat=false, air=.055,
    },
    {
        name="OWL SHIFT / LOOP 11", bpm=66, beats=16, gain=.30,
        chords={{7,{19,22,26}},{3,{15,19,22,26}},{0,{24,27,31}},{2,{14,18,21}}},
        -- 부엉이 울음. 두 음이 떨어지는 짧은 동기를 한 루프에 두 번만 둔다.
        lead={{3,43,.5},{3.5,38,1.1},{11,46,.5},{11.5,43,1.3}},
        bassBeats={0}, hat=false, air=.075,
    },
}

LobbyAudio.TRACKS=TRACKS
LobbyAudio.RATE=RATE

-- 결정적 난수. love.math 에 기대면 헤드리스 내보내기와 게임 안 소리가 달라지고,
-- 같은 트랙이 실행마다 다른 노이즈를 갖게 된다.
local function makeRng(seed)
    local state=seed
    return function()
        state=(state*1103515245+12345)%2147483648
        return state/2147483648
    end
end

-- 트랙 하나를 [-1,1] 실수 버퍼로 렌더한다. LÖVE 없이도 돌아가므로 헤드리스
-- 검사와 wav 내보내기가 게임과 같은 코드를 쓴다.
function LobbyAudio.render(index)
    local track=TRACKS[index]
    if not track then return nil end
    local beat=60/track.bpm
    local count=math.floor(beat*track.beats*RATE)
    local rng=makeRng(9176+index*7919)
    local buffer={}
    for i=0,count-1 do buffer[i]=0 end
    local bars=#track.chords
    local beatsPerBar=track.beats/bars
    for bar=0,bars-1 do
        local chord=track.chords[bar+1]
        local barStart=bar*beatsPerBar*beat
        for _,offset in ipairs(track.bassBeats) do
            addNote(buffer,count,"bass",barStart+offset*beat,beat*1.9,pitch(chord[1]),.62,rng)
        end
        for _,semi in ipairs(chord[2]) do
            addNote(buffer,count,"pad",barStart,beatsPerBar*beat*1.05,pitch(semi),.30,rng)
        end
        if track.arp then
            for step,slot in ipairs(track.arp) do
                local tones=chord[2]
                local semi=tones[slot%#tones+1]+(slot>=#tones and track.arpOctave or 0)
                addNote(buffer,count,"pluck",barStart+(step-1)*beatsPerBar*beat/#track.arp,
                    beat*.9,pitch(semi),.26,rng)
            end
        end
        if track.hat then
            for step=0,beatsPerBar*2-1 do
                if step%2==1 then
                    addNote(buffer,count,"hat",barStart+step*beat*.5,.09,0,.085,rng)
                end
            end
        end
        if track.air>0 then
            addNote(buffer,count,"air",barStart,beatsPerBar*beat,0,track.air,rng)
        end
    end
    if track.lead then
        for _,entry in ipairs(track.lead) do
            addNote(buffer,count,"pluck",entry[1]*beat,entry[3]*beat,pitch(entry[2]),.34,rng)
        end
    end
    -- 봉우리를 맞춘 뒤 트랙별 음량으로 낮춘다. 정규화만 하면 세 곡의 체감
    -- 크기가 제각각이라 트랙을 넘길 때마다 볼륨을 다시 만지게 된다.
    local peak=0
    for i=0,count-1 do local v=buffer[i];if v<0 then v=-v end;if v>peak then peak=v end end
    local scale=peak>0 and track.gain/peak or 0
    for i=0,count-1 do
        local v=buffer[i]*scale
        if v>1 then v=1 elseif v<-1 then v=-1 end
        buffer[i]=v
    end
    return buffer,count
end

function LobbyAudio.new()
    local self=setmetatable({sources={},current=nil,playing=false},LobbyAudio)
    return self
end

-- 첫 재생 때만 만든다. 세 트랙을 미리 다 계산하면 로비 진입이 그만큼 늦어지고,
-- 대부분의 판에서 두 번째·세 번째 트랙은 한 번도 안 듣는다.
function LobbyAudio:source(index)
    -- 실패는 false 로 기억한다. nil 로 두면 소리 장치가 없는 기기에서 매 프레임
    -- 다시 합성을 시도해 로비가 통째로 멎는다.
    local cached=self.sources[index]
    if cached~=nil then return cached or nil end
    local ok,source=pcall(function()
        local buffer,count=LobbyAudio.render(index)
        if not buffer then return nil end
        local data=love.sound.newSoundData(count,RATE,16,1)
        for i=0,count-1 do data:setSample(i,buffer[i]) end
        local made=love.audio.newSource(data,"static")
        made:setLooping(true)
        made:setVolume(.55)
        return made
    end)
    if not ok or not source then self.sources[index]=false;return nil end
    self.sources[index]=source
    return source
end

-- 로비가 매 프레임 부르는 유일한 진입점. 트랙 번호와 재생 여부만 넘기면
-- 나머지(교체·정지·재개)는 여기서 맞춘다.
function LobbyAudio:sync(index,playing)
    local active=self.current and self.sources[self.current] or nil
    if not playing then
        if active and self.playing then pcall(function() active:pause() end) end
        self.playing=false
        return
    end
    if self.current~=index then
        if active then pcall(function() active:stop() end) end
        self.current=index
        self.playing=false
    end
    local source=self:source(index)
    if not source then return end
    if not self.playing then
        pcall(function() source:play() end)
        self.playing=true
    end
end

return LobbyAudio
