package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Lobby=require("src.lobby")
local captureW,captureH=CAPTURE_W or 1280,CAPTURE_H or 720
love.graphics.getDimensions=function()return captureW,captureH end
love.graphics.getWidth=function()return captureW end
love.graphics.getHeight=function()return captureH end
love.mouse={getPosition=function()return -100,-100 end,isDown=function()return false end}
fixture.reset();fixture.time=1.4
local fonts={}
for name,size in pairs({micro=12,small=14,body=17,heading=21,big=28,title=36,display=48})do fonts[name]=love.graphics.newFont("assets/font-korean-regular.ttf",size)end
-- 진행 상황판은 저장 데이터를 읽으므로, 빈 로비만 그리면 검수에서 보이지 않는다.
-- 어느 정도 진행한 상태를 만들어 실제로 표시되는 화면을 잡는다.
local Traits=require("src.character_traits")
local Achievements=require("src.achievements")
local traits=Traits.new(true);traits.data.currency=1240;traits:unlockRegenTier(8)
traits.data.levels.fire_score_prewarm=2
local achievements=Achievements.new(true)
achievements:recordRun({scoreAttack=true,trees=412,maxChain=9,stage=1,highestRegenTier=8,lumberCoinTotal=980})
achievements.data.stats.total_trees=12847;achievements.data.stats.runs=63
local game={characterTraits=traits,achievements=achievements}
local lobby=Lobby.new({},fonts);lobby.time=1.4;lobby.timeOfDayOverride=LOBBY_HOUR
lobby.audioTrack=LOBBY_TRACK or 1
if LOBBY_CD_ANGLE~=nil then lobby.audioCd.angle=LOBBY_CD_ANGLE end
lobby:draw(game)
local suffix=captureW==1280 and "" or "-"..captureW
if LOBBY_HOUR~=nil then suffix=suffix..string.format("-h%02d",math.floor(LOBBY_HOUR))end
if LOBBY_TRACK~=nil then suffix=suffix..string.format("-track%d",math.floor(LOBBY_TRACK))end
fixture.save("docs/previews/score-attack-lobby-draws"..suffix..".json")
print(string.format("SCORE_ATTACK_LOBBY_CAPTURE_OK %dx%d progress=shown window=none",captureW,captureH))
