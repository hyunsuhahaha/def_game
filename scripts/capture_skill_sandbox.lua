package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Game=require("src.game")
local Mode=require("src.clearcut_mode")

local width,height=1280,720
love.graphics.getDimensions=function()return width,height end
love.graphics.getWidth=function()return width end;love.graphics.getHeight=function()return height end
love.mouse={getPosition=function()return 100,100 end,isDown=function()return false end}
local function font(path,size)return{path=path,size=size,getHeight=function()return size end,getWidth=function(_,s)return #tostring(s)*size*.52 end}end
local regular="assets/font-korean-regular.ttf";local bold="assets/font-korean-bold.ttf"
local mode=Mode.new();mode.job="fire";mode.sandbox=true;mode:sandboxSetLevel("molotov",6);mode:sandboxSetBranch("molotov","flame_route")
local game=setmetatable({clearcut=mode,camera={skyviewTarget=0},fonts={micro=font(regular,12),small=font(regular,14),body=font(regular,18),heading=font(bold,20)}},{__index=Game})
fixture.reset();game:drawSandboxPanel();fixture.save("docs/previews/skill-sandbox-v2-draws.json")
print("SKILL_SANDBOX_CAPTURE_OK character=smoker vape=selected window=none")
