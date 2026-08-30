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
local result={victory=true,scoreAttack=true,failureReason="score_overcrowded",elapsed=167,wood=1248,trees=386,
    peakTreesPerSecond=42,level=18,highestRegenTier=6,treeAllowance=34,totalTreesSpawned=421,
    treeSpawnRate=5.6,traitEarned=52,traitCurrency=184}

local function capture(w,h,path)
    love.graphics.getDimensions=function()return w,h end
    love.graphics.getWidth=function()return w end
    love.graphics.getHeight=function()return h end
    fixture.reset()
    local iw,ih=background:getDimensions();local scale=math.max(w/iw,h/ih)
    love.graphics.setColor(1,1,1,1);love.graphics.draw(background,(w-iw*scale)/2,(h-ih*scale)/2,0,scale,scale)
    local game={result=result};Mode.new():drawResults(game,fonts)
    fixture.save(path)
end
capture(1280,720,"docs/previews/score-result-draws.json")
capture(960,540,"docs/previews/score-result-compact-draws.json")
print("SCORE_RESULT_CAPTURE_OK 1280x720+960x540 window=none")
