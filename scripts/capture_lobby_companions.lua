package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Lobby=require("src.lobby")
local Traits=require("src.character_traits")
local Companions=require("src.lobby_companions")

local finalWidth,finalHeight=CAPTURE_W or 1280,CAPTURE_H or 720
local width,height=LOBBY_RESIZE_FROM_W or finalWidth,LOBBY_RESIZE_FROM_H or finalHeight
love.graphics.getDimensions=function()return width,height end
love.graphics.getWidth=function()return width end
love.graphics.getHeight=function()return height end
love.mouse={getPosition=function()return -100,-100 end,isDown=function()return false end}

local fonts={}
for name,size in pairs({micro=12,small=14,body=17,heading=21,big=28,title=36,display=48})do
    fonts[name]=love.graphics.newFont("assets/font-korean-regular.ttf",size)
end
local traits=Traits.new(true)
local previewLevels=LOBBY_DEPTH_PREVIEW and{
    fire_score_axe_crew=1,fire_score_rocket_crew=1,fire_score_popper_unlock=1,
}or LOBBY_SCALE_MODE and{
    fire_score_axe_crew=1,universal_mole_companion=1,universal_gray_cat=1,
}or{
    fire_score_axe_crew=1,fire_score_rocket_crew=1,fire_score_popper_unlock=1,
    fire_score_popper_extra=1,universal_veteran_crew=1,
    universal_mole_companion=1,universal_mole_extra=2,universal_gray_cat=1,
}
for id,value in pairs(previewLevels)do traits.data.levels[id]=value end
traits.data.currency=1240
local game={characterTraits=traits}
local lobby=Lobby.new({},fonts)
lobby.time=2.2;lobby.timeOfDayOverride=LOBBY_HOUR or 12
lobby:update(.01,game)
if LOBBY_RESIZE_FROM_W or LOBBY_RESIZE_FROM_H then
    width,height=finalWidth,finalHeight
    lobby:update(.01,game)
end
if LOBBY_DEPTH_PREVIEW then
    assert(Companions.prepareDepthPreview(lobby.lobbyCompanions))
elseif LOBBY_SCALE_MODE then
    assert(Companions.prepareScalePreview(lobby.lobbyCompanions,LOBBY_SCALE_MODE=="sleep"))
elseif LOBBY_INTERACTION_KIND then
    for _,actor in ipairs(lobby.lobbyCompanions.animals)do actor.state="idle"end
    assert(Companions.prepareInteractionPreview(lobby.lobbyCompanions,LOBBY_INTERACTION_KIND),
        "interaction preview unavailable: "..tostring(LOBBY_INTERACTION_KIND))
elseif not LOBBY_NATURAL_LAYOUT then Companions.preparePreview(lobby.lobbyCompanions)end
local previewTime=math.max(0,LOBBY_PREVIEW_TIME or 0)
local elapsed=0
while elapsed<previewTime do
    local dt=math.min(1/30,previewTime-elapsed)
    Companions.update(lobby.lobbyCompanions,dt);elapsed=elapsed+dt
end
lobby.backgroundParallax=math.max(-1,math.min(1,LOBBY_PARALLAX or 0))
fixture.reset();lobby:draw(game)
local hour=math.floor(LOBBY_HOUR or 12)
local frameSuffix=LOBBY_PREVIEW_FRAME~=nil and string.format("-f%02d",LOBBY_PREVIEW_FRAME)or""
local interactionSuffix=LOBBY_INTERACTION_KIND and("-"..LOBBY_INTERACTION_KIND)or""
local scaleSuffix=LOBBY_SCALE_MODE and("-scale_"..LOBBY_SCALE_MODE)or""
local depthSuffix=LOBBY_DEPTH_PREVIEW and"-depth"or""
local parallax=math.floor((LOBBY_PARALLAX or 0)*100)
local parallaxSuffix=LOBBY_PARALLAX and string.format("-p%+04d",parallax)or""
local resizeSuffix=(LOBBY_RESIZE_FROM_W or LOBBY_RESIZE_FROM_H)and"-resized"or""
fixture.save(string.format("docs/previews/lobby-companions-draws-%d-h%02d%s%s%s%s%s%s.json",
    width,hour,interactionSuffix,scaleSuffix,depthSuffix,parallaxSuffix,frameSuffix,resizeSuffix))
print(string.format("LOBBY_COMPANIONS_CAPTURE_OK %dx%d hour=%02d animals=%d window=none",
    width,height,hour,#lobby.lobbyCompanions.animals))
