package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Art=require("src.bomb_monkey")
local tree=love.graphics.newImage("assets/trees/broadleaf-tree-cartoon-v3.png");tree:setFilter("nearest","nearest")
love.graphics.setColor(.16,.28,.12,1);love.graphics.rectangle("fill",0,0,1280,720)
love.graphics.setColor(.23,.38,.17,1);love.graphics.rectangle("fill",0,355,1280,365)
love.graphics.setColor(.30,.46,.21,1)
for y=375,700,34 do for x=(y%68),1280,76 do love.graphics.rectangle("fill",x,y,19,4)end end
for _,x in ipairs({250,650,1040})do love.graphics.setColor(1,1,1,1);love.graphics.draw(tree,x,610,0,.72,.72,tree:getWidth()/2,tree:getHeight()*.91)end
local mode={permanentTraits={scoreBombFuse=0},bombMonkeys={{x=390,y=620,life=2.4,facing=1,moving=true,carrying=true}},
    monkeyBombs={{x=650,y=625,state="unlit",fuse=0,life=1},{x=820,y=625,state="lit",fuse=.7,life=1.4},{x=990,y=625,state="lit",fuse=2.1,life=2.1}},
    bombExplosions={{x=1110,y=600,age=.27,life=.78,radius=180}}}
local queue={};Art.queue(mode,queue);table.sort(queue,function(a,b)return(a.anchorY or a.y or 0)<(b.anchorY or b.y or 0)end)
for _,item in ipairs(queue)do item.draw()end
fixture.save("docs/previews/bomb-monkey-runtime-draws.json")
print("BOMB_MONKEY_CAPTURE_OK window=none")
