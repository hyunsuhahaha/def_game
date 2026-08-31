package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
love.graphics.getDimensions=function()return 1280,720 end
love.graphics.getWidth=function()return 1280 end
love.graphics.getHeight=function()return 720 end
love.mouse={getPosition=function()return -100,-100 end,isDown=function()return false end}
love.keyboard={isDown=function()return false end}

local Mode=require("src.clearcut_mode")
local mode=Mode.new();mode.scoreAttack=true;mode.job="fire";mode.scoreWeaponSlot=2
local fonts={small=love.graphics.newFont("assets/font-korean-regular.ttf",16),micro=love.graphics.newFont("assets/font-korean-regular.ttf",13)}
mode:drawScoreWeaponSlots(fonts,1280,720)
fixture.save("docs/previews/score-weapon-slots-draws.json")
print("SCORE_WEAPON_SLOTS_CAPTURE_OK 1280x720 selected=axe window=none")
