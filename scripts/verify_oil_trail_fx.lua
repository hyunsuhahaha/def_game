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
    world={nodes={},igniteFx=function() igniteCalls=igniteCalls+1 end,addParticle=function()end},
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
mode:updateOilTrail(0,game)
assert(#mode.oilFireLinks==1,"burning oil did not build one readable minimum-spanning fire link")

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
    elseif op.op=="draw"then
        assert(op.file=="assets/fx/oil-trail/oil-fire-object-atlas-pixel-v3.png","oil fire did not use the dedicated v3 object atlas")
        assert(op.filter=="nearest","oil-fire object atlas is not nearest-filtered")
        draws=draws+1
    end
end
assert(rectangles>=40 and polygons>=60 and draws>=2,
    "oil road did not use dense code-native black pixels with separate authored flame objects")

-- Separate drum spills are allowed to meet. Igniting one end must propagate
-- through nearby visible oil, build N-1 links instead of a complete orange net,
-- and make the visible corridor use the same capsule for tree/enemy damage.
local linked=Mode.new();linked.job="fire";linked.smokerGroundTime=3
local function drumSpot(x,group,sequence)
    return{x=x,y=200,spawnedAt=0,lifetime=20,source="drum",group=group,sequence=sequence,
        pixelSeed=sequence,damage=6,hitRadius=32,burnDuration=8,visualScale=1}
end
linked.oilTrail={drumSpot(100,"left",1),drumSpot(180,"left",2),drumSpot(260,"right",3)}
linked.oilPuddleGroups={left={id="left",spots={linked.oilTrail[1],linked.oilTrail[2]}},
    right={id="right",spots={linked.oilTrail[3]}}}
local tree={x=220,y=200,active=true,rushTree=true,hp=20}
local enemy={x=140,y=200,hp=20,radius=12,category="plant"}
linked.enemies={enemy};game.world.nodes={tree}
linked.damageTreeWithSmokerWeapon=function(self,node,damage)node.hp=node.hp-damage;self.linkTreeDamage=damage end
linked.igniteEnemy=function(self,target)target.burning=true;return true end
linked:igniteOilTrail(linked.oilTrail[1],game)
assert(linked.oilTrail[3].ignited,"fire did not cross from one nearby drum spill into another")
linked:updateOilTrail(.41,game)
assert(#linked.oilFireLinks==2,"three connected oil patches did not produce exactly two readable bridges")
assert(linked.linkTreeDamage==1 and tree.hp==19,"oil link visual capsule did not damage its tree corridor")
assert(enemy.hp==14 and enemy.burning,"oil link visual capsule did not continuously damage and ignite its enemy corridor")
linked.enemies={}
fixture.reset();local linkedQueue={};linked:queueWorldActors(linkedQueue,linked.smokerGroundTime)
for _,entry in ipairs(linkedQueue)do entry.draw()end
local linkedFlames=0
for _,op in ipairs(fixture.commands)do if op.op=="draw"and op.file=="assets/fx/oil-trail/oil-fire-object-atlas-pixel-v3.png"then linkedFlames=linkedFlames+1 end end
assert(linkedFlames>=7,"linked drum fire did not fill the corridor with authored v3 flame objects")

mode.smokerGroundTime=2.5
game.player.isMoving=false
mode:updateOilTrail(.41,game)
assert(mode.damageAudit and mode.damageAudit.radius==55 and mode.damageAudit.damage==4,"visual rewrite changed oil damage")
mode.smokerGroundTime=7.1
mode:updateOilTrail(.01,game)
assert(#mode.oilTrail==0,"five-second fire lifetime changed")
print("OIL_TRAIL_FX_OK runtime-pixels fire=v3-3x6 linked-drums=mst corridor=visible+damage")
