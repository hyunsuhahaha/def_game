package.path="./?.lua;./?/init.lua;"..package.path

love={
    math={random=math.random},
    graphics={getDimensions=function()return 1600,900 end},
    mouse={getPosition=function()return 800,450 end,isDown=function()return false end}
}

local ClearcutMode=require("src.clearcut_mode")

local mode=ClearcutMode.new()
mode.scoreAttack=true
mode.permanentTraits.scoreOilDrum=1
mode.permanentTraits.scoreGrayCat=1
mode.smokerGroundTime=10
local drum={id=1,x=420,y=310,state="settled",hp=8,maxHp=8,angle=0,claimed=false}
mode.oilDrums={drum}
assert(mode:spillOilDrum(drum,"axe"),"settled drum did not spill")
assert(drum.state=="spilled" and #mode.oilTrail==11,"drum spill did not create one continuous eleven-spot puddle")
local group=mode.oilPuddleGroups.drum_1
assert(group and group.radius==105,"drum oil puddle group was not registered")
local earliest,latest=math.huge,-math.huge
for _,spot in ipairs(mode.oilTrail)do
    assert(spot.group=="drum_1" and spot.lifetime==20,"drum oil spot lost its group or lifetime")
    earliest,latest=math.min(earliest,spot.spawnedAt),math.max(latest,spot.spawnedAt)
end
assert(#mode.oilDrumSpills==1 and mode.oilDrumSpills[1].frameDuration==.12,"dedicated drum spill animation was not created")
assert(latest-earliest>=.18,"oil collision points did not follow the visible spill timing")

local game={player={x=500,y=350},world={nodes={}},camera=nil}
local catMode=ClearcutMode.new()
catMode.scoreAttack=true
catMode.permanentTraits.scoreOilDrum=1
catMode.permanentTraits.scoreGrayCat=1
local catDrum={id=2,x=500,y=350,state="settled",hp=8,maxHp=8,angle=0,claimed=false}
catMode.oilDrums={catDrum}
assert(catMode:startGrayOilCat(catDrum,game),"gray cat did not enter from offscreen")
local startedX=catMode.grayOilCat.x
assert(startedX<0 or startedX>1600,"gray cat did not start outside the screen")
for _=1,140 do catMode:updateGrayOilCat(.05,game)end
assert(catDrum.state=="spilled","gray cat did not tip the target drum")
assert(catMode.grayOilCat==nil,"gray cat did not jump out through the opposite screen edge")
assert(#catMode.oilTrail==11,"gray cat tip did not create the same oil spill as an axe hit")

local damageMode=ClearcutMode.new()
damageMode.scoreAttack=true
damageMode.smokerGroundTime=2
local tree={active=true,rushTree=true,x=100,y=100,hp=2}
local damageGame={player={isMoving=false,x=0,y=0},world={nodes={tree}}}
local spot={x=100,y=100,spawnedAt=0,ignited=true,ignitedAt=1,group="drum_3",lifetime=20}
damageMode.oilTrail={spot}
damageMode.oilPuddleGroups={drum_3={x=100,y=100,radius=105,tickTimer=0}}
damageMode.damageEnemiesInRadius=function()end
damageMode.igniteEnemiesInRadius=function()end
damageMode.damageTreeWithSmokerWeapon=function(_,node,amount)node.hp=node.hp-amount;return false end
damageMode:updateOilTrail(.5,damageGame)
assert(tree.hp==1,"ignited drum puddle did not damage a tree in its visible radius")

print("GRAY_OIL_CAT_OK exact-approved-atlas runtime-flow=enter,push,spill,jump oil-spots=11")
