package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
love.mouse={getPosition=function()return -100,-100 end}

local Mode=require("src.clearcut_mode")
local background=love.graphics.newImage("assets/lobby-forest-field-hq-pixel-v2.png")
background:setFilter("nearest","nearest")
local fonts={}
for name,size in pairs({micro=12,small=14,body=17,heading=21,big=28,title=36,display=48})do
    fonts[name]=love.graphics.newFont("assets/font-korean-regular.ttf",size)
end
local rows={
    {id="broadleaf",name="활엽수 목재",count=74,remaining=21,converted=53,coin=1,color={.72,.45,.20}},
    {id="pine",name="소나무 목재",count=74,remaining=74,converted=0,coin=1,color={.56,.42,.20}},
    {id="birch",name="자작나무 목재",count=38,remaining=38,converted=0,coin=2,color={.86,.80,.63}},
}
local result={victory=true,scoreAttack=true,failureReason="score_overcrowded",elapsed=167,wood=1248,trees=386,
    peakTreesPerSecond=42,level=18,highestRegenTier=6,treeAllowance=34,totalTreesSpawned=421,
    treeSpawnRate=5.6,traitEarned=53,traitCurrency=184,lumberRows=rows,lumberCoinTotal=224}

local function capture(w,h,path)
    love.graphics.getDimensions=function()return w,h end
    love.graphics.getWidth=function()return w end
    love.graphics.getHeight=function()return h end
    fixture.reset()
    local iw,ih=background:getDimensions();local scale=math.max(w/iw,h/ih)
    love.graphics.setColor(1,1,1,1);love.graphics.draw(background,(w-iw*scale)/2,(h-ih*scale)/2,0,scale,scale)
    local mode=Mode.new();mode.resultSettlement={rows=rows,rowIndex=1,elapsed=2.15,converted=53,total=224,complete=false,
        bursts={{t=.26,dur=.48,rowIndex=1,seed=4}}}
    local game={result=result};mode:drawResults(game,fonts)
    fixture.save(path)
end
capture(1280,720,"docs/previews/score-result-draws.json")
capture(960,540,"docs/previews/score-result-compact-draws.json")
print("SCORE_RESULT_CAPTURE_OK 1280x720+960x540 window=none")
