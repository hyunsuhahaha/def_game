package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Lobby=require("src.lobby")
love.graphics.getDimensions=function()return 1280,720 end
love.graphics.getWidth=function()return 1280 end
love.graphics.getHeight=function()return 720 end
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
local lobby=Lobby.new({},fonts);lobby.time=1.4;lobby:draw(game)
fixture.save("docs/previews/score-attack-lobby-draws.json")
print("SCORE_ATTACK_LOBBY_CAPTURE_OK 1280x720 progress=shown window=none")
