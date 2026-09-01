package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Art=require("src.popping_machine")
local tree=love.graphics.newImage("assets/trees/broadleaf-tree-cartoon-v3.png");tree:setFilter("nearest","nearest")
love.graphics.setColor(.16,.28,.12,1);love.graphics.rectangle("fill",0,0,1280,720)
love.graphics.setColor(.23,.38,.17,1);love.graphics.rectangle("fill",0,355,1280,365)
love.graphics.setColor(.30,.46,.21,1)
for y=375,700,34 do for x=(y%68),1280,76 do love.graphics.rectangle("fill",x,y,19,4)end end
love.graphics.setColor(.12,.22,.10,1);love.graphics.rectangle("fill",0,585,1280,135)
for _,x in ipairs({310,650,1010})do love.graphics.setColor(1,1,1,1);love.graphics.draw(tree,x,610,0,.72,.72,tree:getWidth()/2,tree:getHeight()*.91)end
local mode={poppingMachines={{x=430,y=620,state="heating",heat=1.8,life=2,shake=.08,facing=1,moving=false}},
    puffedRiceShots={{x=735,y=455,spin=1.3}},puffedRiceImpacts={{x=1000,y=462,age=.08,life=.48,angle=-.12}}}
local queue={};Art.queue(mode,queue);table.sort(queue,function(a,b)return(a.anchorY or a.y or 0)<(b.anchorY or b.y or 0)end)
for _,item in ipairs(queue)do item.draw()end
fixture.save("docs/previews/popping-machine-runtime-draws.json")
print("POPPING_MACHINE_CAPTURE_OK window=none")
