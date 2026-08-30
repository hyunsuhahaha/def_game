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
local lobby=Lobby.new({},fonts);lobby.time=1.4;lobby:draw()
fixture.save("docs/previews/score-attack-lobby-draws.json")
print("SCORE_ATTACK_LOBBY_CAPTURE_OK 1280x720 window=none")
