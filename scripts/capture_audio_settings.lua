package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Game=require("src.game")
local Lobby=require("src.lobby")
local width,height=CAPTURE_W or 960,CAPTURE_H or 540
love.graphics.getDimensions=function()return width,height end
love.graphics.getWidth=function()return width end
love.graphics.getHeight=function()return height end
love.mouse={getPosition=function()return -100,-100 end,isDown=function()return false end}
local fonts={}
for name,size in pairs({micro=12,small=14,body=17,heading=21,big=28,title=36,display=48})do
    fonts[name]=love.graphics.newFont("assets/font-korean-regular.ttf",size)
end
local game=setmetatable({fonts=fonts,settings={fullscreen=false,screenShake=true,viewPitch=.76,
    musicVolume=.98,sfxVolume=.80}}, {__index=Game})
game.lobby=Lobby.new({},fonts);game.lobby.time=1.4;game.lobby.timeOfDayOverride=22
fixture.reset();fixture.time=1.4;game:drawSettings()
local suffix=width==1280 and ""or"-"..width
fixture.save("docs/previews/audio-settings-v1"..suffix.."-draws.json")
print(string.format("AUDIO_SETTINGS_CAPTURE_OK %dx%d window=none",width,height))
