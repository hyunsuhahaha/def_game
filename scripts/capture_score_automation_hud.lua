package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Mode=require("src.clearcut_mode")
local width,height=1280,720
love.graphics.getDimensions=function()return width,height end
love.graphics.getWidth=function()return width end;love.graphics.getHeight=function()return height end
local mouseX,mouseY=1040,660
love.mouse={getPosition=function()return mouseX,mouseY end,isDown=function()return false end}
local function font(path,size)return{path=path,size=size,getHeight=function()return size end,getWidth=function(_,s)return #tostring(s)*size*.52 end}end
local regular="assets/font-korean-regular.ttf"
local fonts={micro=font(regular,12),small=font(regular,14)}
local mode=Mode.new();mode.scoreAttack=true;mode.totalWood=86
mode.scoreAutomation={butt_launcher=2,straw_feeder=1,oil_pump=0,forest_contract=0}
fixture.reset();mode:drawScoreAutomationHUD({},fonts)
fixture.save("docs/previews/score-automation-hud-draws.json")
print("SCORE_AUTOMATION_HUD_CAPTURE_OK icons=4 hover=tooltip background=none window=none")
