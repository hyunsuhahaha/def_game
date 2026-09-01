-- 로비 배경음을 wav 로 내보낸다. 게임과 같은 src/lobby_audio.lua 를 쓰므로
-- 여기서 들은 소리가 로비에서 나는 소리다.
--
--   python scripts/headless_lua.py scripts/export_lobby_audio.lua
--
-- 이 저장소에서 소리는 눈으로 검수할 수 없다. 수치 검사(verify_lobby_audio.lua)는
-- 무음·클리핑·이음매만 잡고, 곡이 괜찮은지는 사람이 이 파일을 들어야 안다.
package.path = "./?.lua;./?/init.lua;" .. package.path

local LobbyAudio = require("src.lobby_audio")
local RATE = LobbyAudio.RATE

local function u32(v) return string.char(v%256,math.floor(v/256)%256,math.floor(v/65536)%256,math.floor(v/16777216)%256) end
local function u16(v) return string.char(v%256,math.floor(v/256)%256) end

local function writeWav(path,buffer,count)
    local body={}
    for i=0,count-1 do
        local sample=math.floor(buffer[i]*32767+.5)
        if sample>32767 then sample=32767 elseif sample<-32768 then sample=-32768 end
        if sample<0 then sample=sample+65536 end
        body[#body+1]=u16(sample)
    end
    local data=table.concat(body)
    local file=assert(io.open(path,"wb"))
    file:write("RIFF",u32(36+#data),"WAVE",
        "fmt ",u32(16),u16(1),u16(1),u32(RATE),u32(RATE*2),u16(2),u16(16),
        "data",u32(#data),data)
    file:close()
end

local names={"forest-day-loop-07","river-line-loop-03","owl-shift-loop-11"}
for index,track in ipairs(LobbyAudio.TRACKS) do
    local buffer,count=LobbyAudio.render(index)
    local path="docs/previews/lobby-"..(track.slug or names[index])..".wav"
    writeWav(path,buffer,count)
    local peak,sum=0,0
    for i=0,count-1 do
        local a=buffer[i]<0 and -buffer[i] or buffer[i]
        if a>peak then peak=a end
        sum=sum+buffer[i]*buffer[i]
    end
    print(string.format("%-22s %5.2fs  %3d BPM  peak %.2f  rms %.3f  %s",
        track.name,count/RATE,track.bpm,peak,math.sqrt(sum/count),path))
end
