local game=dofile("scripts/verify_job_master.lua")
local fixture=require("scripts.forest_render_fixture")
local Projection=require("src.world_projection")
game:startClearcutScoreAttack(8,false)
game.runType="clearcut"
local Game=require("src.game")
for i=1,30 do local name,value=debug.getupvalue(Game.new,i);if name=="makeFonts"then game.fonts=value();break end end
love.graphics.clear=function(r,g,b,a)
    love.graphics.setColor(r,g,b,a or 1);love.graphics.rectangle("fill",0,0,love.graphics.getDimensions())
end
-- Only the GPU canvas transport is replaced. Game:draw, world draw, all
-- combat overlays, real projection maths, billboard sorting and HUD run intact.
local firstGround
local clip,stencilClip,stencilEnabled
love.graphics.setScissor=function(x,y,w,h)clip=x and {x,y,w,h}or nil end
love.graphics.stencil=function(fn)
    local rectangle=love.graphics.rectangle
    love.graphics.rectangle=function(_,x,y,w,h)
        local sx,sy=game.camera:worldToScreen(x,y)
        local ex,ey=game.camera:worldToScreen(x+w,y+h)
        stencilClip={sx,sy,ex-sx,ey-sy}
    end
    fn();love.graphics.rectangle=rectangle
end
love.graphics.setStencilTest=function(test)stencilEnabled=test~=nil end
for _,name in ipairs({"draw","rectangle","ellipse","circle","line","polygon","print","printf"})do
    local original=love.graphics[name]
    love.graphics[name]=function(...)
        local first=#fixture.commands+1;original(...)
        for i=first,#fixture.commands do fixture.commands[i].clip=clip or(stencilEnabled and stencilClip or nil)end
    end
end
Projection.begin=function()firstGround=#fixture.commands+1;return love.graphics.getDimensions()end
Projection.finish=function(camera)
    local _,h=love.graphics.getDimensions();local pitch=camera.pitch
    for i=firstGround,#fixture.commands do
        local op=fixture.commands[i];local a=op.args
        if op.op=="draw"then
            a[2]=h*.5+(a[2]-h*.5)*pitch;a[5]=(a[5]or a[4]or 1)*pitch
        elseif op.op=="rectangle"or op.op=="ellipse"then
            a[2]=h*.5+(a[2]-h*.5)*pitch;a[4]=a[4]*pitch
        elseif op.op=="line"or op.op=="polygon"then
            for j=2,#a,2 do a[j]=h*.5+(a[j]-h*.5)*pitch end
        end
    end
end
local mode=game.clearcut
local master=mode.jobMaster.actor
-- Durable target for automatic fire; retain every real companion/facility
-- and the generated terrain, rather than removing the scenario under test.
local tree={kind="tree",rushTree=true,active=true,x=master.x+240,y=master.y,
    rushHp=1000000,rushMaxHp=1000000,treeVariant=1,work=0,workTime=1}
game.world.nodes[#game.world.nodes+1]=tree
mode.remainingTrees=mode.remainingTrees+1
for _=1,12 do mode:update(.02,game);game.world:updateEffects(.02,game)end
assert(mode.flameStream,"full-scene master did not fire")
fixture.reset();game:draw()
local flame,equipment,crane=0,0,0
for _,op in ipairs(fixture.commands)do
    if op.file=="assets/effects/smoker-flamethrower-stream-atlas-v5.png"then flame=flame+1 end
    if op.file=="assets/effects/smoker-flamethrower-equipment-v1.png"then equipment=equipment+1 end
    if op.file=="assets/construction/tower-crane-pixel-v2.png"then crane=crane+1 end
end
assert(flame==1,"Game:draw loses the master's actual flamethrower stream in crane view")
assert(equipment==1 and crane==1,"full scene missing or duplicating equipment/crane")
assert(game.camera.perspective and game.camera.pitch<1,"crane must retain perspective")
local b=game.world.playBounds
local left,top=game.camera:worldToScreen(b.x,b.y)
local right,bottom=game.camera:worldToScreen(b.x+b.w,b.y+b.h)
assert(left>=0 and right<=1280 and top>=0 and bottom<=720,"playable map clipped")
assert(right-left>=1280*.80,"playable map is still a small floating rectangle")
assert(#mode.moleCompanions>0 and mode.pizzaOven and #mode.bombMonkeys>0,"full-scene verification disabled existing automation")
fixture.save("docs/previews/crane-full-scene.json")
print("CRANE_FULL_SCENE_OK Game.draw flame=1 equipment=1 crane=1 perspective companions+facilities-on HUD-on")
return game
