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
assert(math.abs(math.abs(drum.angle)-math.pi*.5)<1e-9 and not drum.hasSpillFx,"original drum did not remain as the separately toppled prop")
assert(latest-earliest>=.18,"oil collision points did not follow the visible spill timing")

local upgraded=ClearcutMode.new()
upgraded.scoreAttack=true
upgraded.permanentTraits.scoreOilDrum=1
upgraded.permanentTraits.scoreOilRadius=54
upgraded.permanentTraits.scoreOilDuration=9
upgraded.permanentTraits.scoreOilDamage=3
upgraded.smokerGroundTime=4
local upgradedDrum={id=8,x=300,y=300,state="settled",hp=8,maxHp=8,angle=0}
assert(upgraded:spillOilDrum(upgradedDrum,"axe"),"upgraded drum did not spill")
assert(upgraded.oilPuddleGroups.drum_8.radius==159,"oil radius upgrade did not change collision radius")
assert(upgraded.oilDrumSpills[1].lifetime==29 and math.abs(upgraded.oilDrumSpills[1].scale-159/105)<1e-9,
    "oil radius/duration upgrades did not change the visible spill")
assert(upgraded.oilTrail[1].damage==7 and upgraded.oilPuddleGroups.drum_8.damage==4,
    "oil damage upgrade did not change enemy and tree damage")

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
for _=1,220 do catMode:updateGrayOilCat(.05,game)end
assert(catDrum.state=="spilled","gray cat did not tip the target drum")
assert(catMode.grayOilCat==nil,"gray cat did not jump out through the opposite screen edge")
assert(#catMode.oilTrail==11,"gray cat tip did not create the same oil spill as an axe hit")

local random=love.math.random
local noCat=ClearcutMode.new();noCat.scoreAttack=true;noCat.oilDrumTimer=999
noCat.permanentTraits.scoreOilDrum=1;noCat.permanentTraits.scoreGrayCat=1
noCat.oilDrums={{id=10,x=500,y=350,state="settled",hp=8,maxHp=8,claimed=false}}
love.math.random=function()return .99 end
noCat:updateOilDrums(.1,game)
assert(noCat.grayOilCat==nil and noCat.oilDrums[1].claimed,"base cat unlock incorrectly guaranteed an immediate response")
local trainedCat=ClearcutMode.new();trainedCat.scoreAttack=true;trainedCat.oilDrumTimer=999
trainedCat.permanentTraits.scoreOilDrum=1;trainedCat.permanentTraits.scoreGrayCat=1
trainedCat.permanentTraits.scoreGrayCatChance=.6;trainedCat.permanentTraits.scoreGrayCatDelay=1.35
trainedCat.oilDrums={{id=11,x=500,y=350,state="settled",hp=8,maxHp=8,claimed=false}}
love.math.random=function()return .5 end
trainedCat:updateOilDrums(.1,game)
assert(trainedCat.grayOilCat==nil and trainedCat.oilDrums[1].catDelay>.7,"trained cat skipped its remaining dispatch delay")
trainedCat:updateOilDrums(.8,game)
assert(trainedCat.grayOilCat~=nil,"trained cat chance/delay upgrades did not dispatch the cat")
love.math.random=random

local damageMode=ClearcutMode.new()
damageMode.scoreAttack=true
damageMode.smokerGroundTime=2
local tree={active=true,rushTree=true,x=100,y=100,hp=2}
local damageGame={player={isMoving=false,x=0,y=0},world={nodes={tree}}}
local spot={x=100,y=100,spawnedAt=0,ignited=true,ignitedAt=1,group="drum_3",lifetime=20}
damageMode.oilTrail={spot}
damageMode.oilPuddleGroups={drum_3={x=100,y=100,radius=105,tickTimer=0}}
damageMode.oilDrumSpills={{group="drum_3",ignited=false}}
damageMode.damageEnemiesInRadius=function()end
damageMode.igniteEnemiesInRadius=function()end
damageMode.damageTreeWithSmokerWeapon=function(_,node,amount)node.hp=node.hp-amount;return false end
damageMode:updateOilTrail(.5,damageGame)
assert(tree.hp==1,"ignited drum puddle did not damage a tree in its visible radius")
assert(damageMode.oilDrumSpills[1].ignited and damageMode.oilDrumSpills[1].ignitedAge==.5,
    "drum puddle did not enable the independent fire overlay")
damageMode.oilTrail={}
damageMode:updateOilTrail(.1,damageGame)
assert(not damageMode.oilDrumSpills[1].ignited,"expired oil fire did not switch back to the ground-oil atlas")

local drawCount=0
love.graphics.newImage=function()return{setFilter=function()end,getDimensions=function()return 1024,400 end}end
love.graphics.newQuad=function()return{}end
love.graphics.setColor=function()end
love.graphics.draw=function()drawCount=drawCount+1 end
local art=ClearcutMode.OilDrumSpillArt
art.drawGround({x=100,y=100,age=2,lifetime=20,radius=105,scale=1})
assert(drawCount==1,"ground oil was not rendered as one independent layer")
drawCount=0
art.drawFire({x=100,y=100,age=2,lifetime=20,radius=105,ignited=true,ignitedAge=.5})
local baseFireDraws=drawCount
drawCount=0
art.drawFire({x=100,y=100,age=2,lifetime=20,radius=159,ignited=true,ignitedAge=.5})
assert(baseFireDraws>1 and drawCount>baseFireDraws,
    "independent fire overlay did not add coverage when the oil radius increased")

print("GRAY_OIL_CAT_OK exact-approved-atlas runtime-flow=enter,push,spill,jump oil-spots=11")
