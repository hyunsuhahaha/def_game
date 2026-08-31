package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Mode=require("src.clearcut_mode")

local mode=Mode.new()
mode.job="fire"
mode.evolutions.oilRoad=true
mode.smokerGroundTime=2
local igniteCalls=0
local game={
    player={x=100,y=120,isMoving=true,facing=1},
    world={igniteFx=function() igniteCalls=igniteCalls+1 end},
}
mode.damageEnemiesInRadius=function(self,x,y,radius,damage)
    self.damageAudit={x=x,y=y,radius=radius,damage=damage}
end

mode:updateOilTrail(.2,game)
game.player.x,game.player.y=148,132
mode:updateOilTrail(.2,game)
assert(#mode.oilTrail==2,"moving smoker did not leave oil")
assert(mode.oilTrail[1].variant==1 and mode.oilTrail[2].variant==2)
assert(mode.oilTrail[2].angle>.2 and mode.oilTrail[2].angle<.3,"trail ignores movement direction")
mode:igniteOilTrail(mode.oilTrail[1],game)
assert(mode.oilTrail[1].ignited and mode.oilTrail[2].ignited,"connected oil did not chain")
assert(igniteCalls==0,"generic explosion FX still masks authored ignition")

fixture.reset()
local queue={}
mode:queueWorldActors(queue,mode.smokerGroundTime)
assert(#queue==6,"oil ground/flame bridge depth entries missing")
table.sort(queue,function(a,b) return a.y<b.y end)
for _,entry in ipairs(queue) do entry.draw() end
local rectangles,polygons,draws=0,0,0
for _,op in ipairs(fixture.commands) do
    if op.op=="rectangle"then rectangles=rectangles+1
    elseif op.op=="polygon"then polygons=polygons+1
    elseif op.op=="draw"then draws=draws+1 end
end
assert(rectangles>=40 and polygons>=60 and draws>=2,
    "oil road did not use dense code-native black pixels with separate authored flame objects")

mode.smokerGroundTime=2.5
game.player.isMoving=false
mode:updateOilTrail(.41,game)
assert(mode.damageAudit and mode.damageAudit.radius==55 and mode.damageAudit.damage==4,"visual rewrite changed oil damage")
mode.smokerGroundTime=7.1
mode:updateOilTrail(.01,game)
assert(#mode.oilTrail==0,"five-second fire lifetime changed")
print("OIL_TRAIL_FX_OK runtime-pixels depth=ground+separate-flame chain=preserved gameplay=preserved")
