package.path="./?.lua;./?/init.lua;"..package.path

local Settings=require("src.settings")
local decoded=Settings.decode("musicVolume=.35\nsfxVolume=1.8\nscreenShake=false\nviewPitch=.82\n",false)
assert(decoded.musicVolume==.35 and decoded.sfxVolume==1,"저장된 음량을 읽거나 범위 제한하지 못했다")
assert(decoded.screenShake==false and decoded.viewPitch==.82,"기존 화면 설정과 함께 읽히지 않는다")

love={}
local store=Settings.load(true,false)
assert(type(store.save)=="function","설정 저장 객체에 save 메서드가 연결되지 않았다")
assert(store:save()==true,"메모리 전용 설정 저장이 실패했다")

local volumeLog={}
local function source()
    return{setLooping=function()end,setVolume=function(_,v)volumeLog[#volumeLog+1]=v end,
        play=function()end,pause=function()end,stop=function()end,setPitch=function()end,
        clone=function()return source()end}
end
love={
    sound={newSoundData=function()return{setSample=function()end}end},
    audio={newSource=function()return source()end},
    math={random=function()return .5 end},
}

local LobbyAudio=require("src.lobby_audio")
local music=LobbyAudio.new();music:setVolume(.4);music:source(1)
assert(math.abs(volumeLog[#volumeLog]-.22)<.0001,"새 배경음 소스에 설정 음량이 적용되지 않았다")
music:setVolume(.2)
assert(math.abs(volumeLog[#volumeLog]-.11)<.0001,"이미 캐시된 배경음의 음량이 즉시 바뀌지 않는다")

local Feedback=require("src.feedback")
local feedback=Feedback.new(.25);feedback:play("tree",false)
assert(math.abs(volumeLog[#volumeLog]-.04)<.0001,"효과음 재생 음량에 사용자 배율이 적용되지 않았다")
feedback:setVolume(0);feedback:play("tree",true)
assert(volumeLog[#volumeLog]==0,"효과음 0%가 완전 음소거되지 않는다")

local file=assert(io.open("src/game.lua","rb"));local game=file:read("*a");file:close()
assert(game:find("settingsMusicBox",1,true)and game:find("settingsSfxBox",1,true),"설정 화면에 두 음량 슬라이더가 없다")
assert(game:find("Settings.load",1,true)and game:find("saveSettings",1,true),"음량 설정이 저장 경로에 연결되지 않았다")
print("AUDIO_SETTINGS_OK music=live_cached sfx=master persistence=v1 ui=two_sliders")
