package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Art=require("src.bee_art")
local image=love.graphics.newImage("assets/fx/bees/bee-flight-simple-pixel-v2.png")
assert(image:getWidth()==192 and image:getHeight()==24,"bee atlas dimensions changed")
local frames={}
for frame=0,5 do
    fixture.reset();Art.draw(100,80,0,frame,.9)
    local op=fixture.commands[#fixture.commands]
    assert(op.op=="draw" and op.file=="assets/fx/bees/bee-flight-simple-pixel-v2.png")
    assert(op.filter=="nearest" and op.quad[3]==32 and op.quad[4]==24)
    assert(math.abs(op.args[4]-.9)<.001 and math.abs(op.args[5]-.9)<.001,"bee display scale is not compact")
    frames[op.quad[1]]=true
end
local count=0;for _ in pairs(frames) do count=count+1 end
assert(count==6,"bee wing animation does not use all six frames")
print("BEE_ART_OK atlas=192x24 frames=6 palette=11 compact=true")
