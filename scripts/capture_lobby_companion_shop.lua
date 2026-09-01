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
local traits=Traits.new(true);traits.data.currency=61
for _,id in ipairs({"fire_score_axe_crew","universal_mole_companion","universal_gray_cat"})do traits.data.levels[id]=1 end
traits.data.lobbyItems=SHOP_OPEN and{ball_court=true}or
    {ball_court=true,sand_burrow=true,cat_tower=true,forest_swing=true}
local game={characterTraits=traits};local lobby=Lobby.new({},fonts)
lobby.time=2.2;lobby.timeOfDayOverride=17;lobby:update(.01,game)
Companions.prepareAmenityPreview(lobby.lobbyCompanions,SHOP_AMENITY or"ball")
local remaining=math.max(0,SHOP_PREVIEW_TIME or 0)
while remaining>0 do local dt=math.min(1/30,remaining);Companions.update(lobby.lobbyCompanions,dt);remaining=remaining-dt end
if SHOP_OPEN then lobby.companionShop.open=true end
fixture.reset();lobby:draw(game)
fixture.save(string.format("docs/previews/lobby-companion-shop-draws-%d-%s.json",width,SHOP_OPEN and"store"or"world"))
print(string.format("LOBBY_COMPANION_SHOP_CAPTURE_OK %dx%d open=%s window=none",width,height,tostring(SHOP_OPEN==true)))
