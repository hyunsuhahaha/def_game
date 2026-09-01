package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Lobby=require("src.lobby")
local Traits=require("src.character_traits")
local Companions=require("src.lobby_companions")

local width,height=CAPTURE_W or 1280,CAPTURE_H or 720
love.graphics.getDimensions=function()return width,height end
love.graphics.getWidth=function()return width end
love.graphics.getHeight=function()return height end
love.mouse={getPosition=function()return -100,-100 end,isDown=function()return false end}

local fonts={}
for name,size in pairs({micro=12,small=14,body=17,heading=21,big=28,title=36,display=48})do
    fonts[name]=love.graphics.newFont("assets/font-korean-regular.ttf",size)
end
local traits=Traits.new(true)
for id,value in pairs({
    fire_score_axe_crew=1,fire_score_rocket_crew=1,fire_score_popper_unlock=1,
    fire_score_popper_extra=1,universal_veteran_crew=1,
    universal_mole_companion=1,universal_mole_extra=2,universal_gray_cat=1,
})do traits.data.levels[id]=value end
traits.data.currency=1240
local game={characterTraits=traits}
local lobby=Lobby.new({},fonts)
lobby.time=2.2;lobby.timeOfDayOverride=LOBBY_HOUR or 12
lobby:update(.01,game)
Companions.preparePreview(lobby.lobbyCompanions)
local previewTime=math.max(0,LOBBY_PREVIEW_TIME or 0)
local elapsed=0
while elapsed<previewTime do
    local dt=math.min(1/30,previewTime-elapsed)
    Companions.update(lobby.lobbyCompanions,dt);elapsed=elapsed+dt
end
fixture.reset();lobby:draw(game)
local hour=math.floor(LOBBY_HOUR or 12)
local frameSuffix=LOBBY_PREVIEW_FRAME~=nil and string.format("-f%02d",LOBBY_PREVIEW_FRAME)or""
fixture.save(string.format("docs/previews/lobby-companions-draws-%d-h%02d%s.json",width,hour,frameSuffix))
print(string.format("LOBBY_COMPANIONS_CAPTURE_OK %dx%d hour=%02d animals=%d window=none",
    width,height,hour,#lobby.lobbyCompanions.animals))
