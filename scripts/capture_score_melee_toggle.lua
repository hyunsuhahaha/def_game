package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Mode=require("src.clearcut_mode")

local width,height=1280,720
love.graphics.getDimensions=function()return width,height end
love.graphics.getWidth=function()return width end
love.graphics.getHeight=function()return height end
local font=love.graphics.newFont("assets/font-korean-bold.ttf",12)
local fonts={micro=font,small=font}
local mode=Mode.new();mode.scoreAttack=true;mode.job="fire"

fixture.reset();mode.scoreMeleeEnabled=true;mode:drawScoreMeleeToggle(fonts,width,height)
fixture.save("docs/previews/score-melee-toggle-on-v1-draws.json")
fixture.reset();mode.scoreMeleeEnabled=false;mode:drawScoreMeleeToggle(fonts,width,height)
fixture.save("docs/previews/score-melee-toggle-off-v1-draws.json")
print("SCORE_MELEE_TOGGLE_CAPTURE_OK states=on+off scale=1280x720 window=none")
