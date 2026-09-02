package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local width=tonumber(rawget(_G,"DEVELOPER_TOOLS_WIDTH")or os.getenv("DEVELOPER_TOOLS_W"))or 1280
local height=tonumber(rawget(_G,"DEVELOPER_TOOLS_HEIGHT")or os.getenv("DEVELOPER_TOOLS_H"))or 720
love.mouse={getPosition=function()return -100,-100 end}
love.graphics.getWidth=function()return width end
love.graphics.getHeight=function()return height end
love.graphics.clear=function(r,g,b,a)
    love.graphics.setColor(r,g,b,a or 1);love.graphics.rectangle("fill",0,0,width,height)
end

local Game=require("src.game")
local CharacterTraits=require("src.character_traits")
local function font(size)return love.graphics.newFont("assets/font-korean-pixel.ttf",size)end
local traits=CharacterTraits.new(true);traits.data.currency=1000000
local ranks,total=traits:setScoreProgress(80)
local game=setmetatable({
    fonts={title=font(34),heading=font(24),body=font(18),small=font(14)},
    characterTraits=traits,testReturnMode="lobby",testResetArmed=false,
    testMessage=string.format("영구 특성 80%% 프리셋 완료 · 저가 순 %d/%d단계 저장",ranks,total),
},Game)

fixture.reset();game:drawTestOptions()
local layout=game:testOptionLayout(width,height)
assert(#layout.actions==9 and layout.actions[#layout.actions].index==4,"developer trait preset buttons are missing")
local output=assert(rawget(_G,"DEVELOPER_TOOLS_CAPTURE_PATH")or os.getenv("DEVELOPER_TOOLS_CAPTURE"),
    "DEVELOPER_TOOLS_CAPTURE is required")
fixture.save(output)
print("DEVELOPER_TOOLS_CAPTURE_OK "..width.."x"..height.." actions=9")
