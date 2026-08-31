package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Mode=require("src.clearcut_mode")
local Art=require("src.flamethrower_art")
local bg=love.graphics.newImage("assets/maps/forest-preview-v1.png")
local smoker=love.graphics.newImage("assets/characters/ingame/smoker-atlas-pixel-v2.png")
local tree=love.graphics.newImage("assets/trees/broadleaf-tree-cartoon-v3.png")
local smokerQuad=love.graphics.newQuad(0,0,96,192,smoker:getDimensions())
local bw,bh=bg:getDimensions()

for frame=0,7 do
    fixture.reset();fixture.time=frame/18
    love.graphics.setColor(1,1,1,.86);love.graphics.draw(bg,0,0,0,1280/bw,720/bh)
    love.graphics.setColor(.015,.035,.025,.48);love.graphics.rectangle("fill",0,0,1280,720)
    -- Runtime-scale anchors: a player, targets at the edge, and one target in
    -- front of the stream make coverage and readability reviewable together.
    love.graphics.setColor(0,0,0,.30);love.graphics.ellipse("fill",214,608,34,8)
    love.graphics.setColor(1,1,1,1);love.graphics.draw(tree,660,590,0,.72,.72,tree:getWidth()/2,tree:getHeight()*.91)
    love.graphics.draw(tree,835,515,0,.56,.56,tree:getWidth()/2,tree:getHeight()*.91)
    love.graphics.draw(smoker,smokerQuad,214,610,0,.61,.61,48,190)
    local mode=Mode.new();mode.scoreAttack=true;mode.job="fire";mode.permanentTraits.scoreFlameUnlock=1
    mode.flameStream={x=248,y=552,nx=1,ny=0,reach=430,halfAngle=.84,t=fixture.time}
    Art.drawHeld(mode,{player={x=214,y=610,facing=1}})
    Art.drawStream(mode.flameStream)
    fixture.save("docs/previews/flamethrower-fx-v1-draws-"..frame..".json")
end
print("FLAMETHROWER_FX_V1_CAPTURE_OK frames=8 reach=430 halfAngle=.84 window=none")
