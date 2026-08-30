package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Art=require("src.cigarette_butt_art")

fixture.reset();fixture.time=tonumber(os.getenv("TREE_FIRE_CAPTURE_TIME"))or 1.2
love.graphics.setColor(.28,.41,.15,1);love.graphics.rectangle("fill",0,0,760,430)
for i=1,11 do
    love.graphics.setColor(.20+.015*(i%3),.31,.11,.48)
    love.graphics.ellipse("fill",20+i*68,396-(i%2)*8,48,11)
end
local tree=love.graphics.newImage("assets/trees/broadleaf-tree-cartoon-v3.png");tree:setFilter("nearest","nearest")
local x=380
local node={x=x,y=360,burning=true,cigaretteIgnitedAt=0}
love.graphics.setColor(0,0,0,.28);love.graphics.ellipse("fill",x,367,76,12)
love.graphics.setColor(1,1,1,1);love.graphics.draw(tree,x,360,0,1,1,tree:getWidth()/2,tree:getHeight()*.91)
Art.drawTreeFire(node,fixture.time)

local output=assert(os.getenv("TREE_FIRE_CAPTURE"),"TREE_FIRE_CAPTURE is required")
fixture.save(output)
print("TREE_FIRE_CAPTURE_OK tree=1 loop=authored sparks=pixel smoke=continuous")
