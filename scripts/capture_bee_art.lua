package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Art=require("src.bee_art")
local grass=love.graphics.newImage("assets/forest-ground-tile-v1.png");grass:setFilter("nearest","nearest")
fixture.reset();love.graphics.push();love.graphics.scale(.72,.72)
local tw,th=grass:getDimensions()
for y=0,520,th do for x=0,900,tw do love.graphics.setColor(1,1,1,1);love.graphics.draw(grass,x,y) end end
for i=1,5 do
    local a=i*1.22
    Art.draw(440+math.cos(a)*(24+i*3),250+math.sin(a)*(18+i),a,7+i,1.30)
end
for i=1,3 do
    local a=i*2.05
    Art.draw(210+math.cos(a)*22,170+math.sin(a)*14,a+math.pi/2,12+i,1.02)
end
love.graphics.pop();fixture.save("docs/previews/bee-runtime-v2-draws.json")
print("BEE_CAPTURE_OK zoom=.72 swarm_scale=1.30 hive_scale=1.02")
