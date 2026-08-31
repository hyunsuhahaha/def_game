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
assert(drum.state=="spilled" and #mode.oilTrail==16,"drum spill did not create sixteen randomized oil stains")
local group=mode.oilPuddleGroups.drum_1
assert(group and group.radius==180,"drum oil splash base radius was not widened")
local earliest,latest=math.huge,-math.huge
local positions={}
for _,spot in ipairs(mode.oilTrail)do
    assert(spot.group=="drum_1" and spot.lifetime==20,"drum oil spot lost its group or lifetime")
    assert(spot.pixelSeed and spot.visualScale and spot.hitRadius and not spot.hiddenGround,
        "drum oil stain is not a visible code-native pixel patch")
    positions[math.floor(spot.x)..":"..math.floor(spot.y)]=true
    earliest,latest=math.min(earliest,spot.spawnedAt),math.max(latest,spot.spawnedAt)
end
local unique=0;for _ in pairs(positions)do unique=unique+1 end
assert(unique>=14,"oil stains collapsed into a repeated fixed picture")
assert(#mode.oilDrumSpills==1 and mode.oilDrumSpills[1].frameDuration==.085,"code-native airborne splash was not created")
assert(math.abs(math.abs(drum.angle)-math.pi*.5)<1e-9 and not drum.hasSpillFx,"original drum did not remain as the separately toppled prop")
assert(latest-earliest>=.35,"oil collision points did not follow the visible splash timing")

local upgraded=ClearcutMode.new()
upgraded.scoreAttack=true
upgraded.permanentTraits.scoreOilDrum=1
upgraded.permanentTraits.scoreOilRadius=150
upgraded.permanentTraits.scoreOilSplashCount=12
upgraded.permanentTraits.scoreOilPatchScale=.32
upgraded.permanentTraits.scoreOilDuration=12
upgraded.permanentTraits.scoreOilIgnitionRadius=64
upgraded.permanentTraits.scoreOilBurnDuration=6
upgraded.permanentTraits.scoreOilDamage=5
upgraded.smokerGroundTime=4
local upgradedDrum={id=8,x=300,y=300,state="settled",hp=8,maxHp=8,angle=0}
assert(upgraded:spillOilDrum(upgradedDrum,"axe"),"upgraded drum did not spill")
assert(upgraded.oilPuddleGroups.drum_8.radius==330 and #upgraded.oilTrail==28,
    "oil range/count upgrades did not widen and densify the spill")
assert(upgraded.oilDrumSpills[1].lifetime==32 and upgraded.oilTrail[1].visualScale>=.95,
    "oil duration/patch-size upgrades did not change the generated stains")
assert(upgraded.oilTrail[1].damage==9 and upgraded.oilPuddleGroups.drum_8.damage==6,
    "oil damage upgrade did not change enemy and tree damage")

local ignitionMode=ClearcutMode.new()
ignitionMode.scoreAttack=true
ignitionMode.smokerGroundTime=2
ignitionMode.permanentTraits.scoreOilIgnitionRadius=64
ignitionMode.permanentTraits.scoreOilBurnDuration=6
ignitionMode.cigaretteButts={{x=205,y=100}}
ignitionMode.oilTrail={{x=100,y=100,spawnedAt=0,source="drum",group="drum_ignition",lifetime=20}}
ignitionMode.oilPuddleGroups={drum_ignition={x=100,y=100,radius=105,tickTimer=0}}
ignitionMode.damageEnemiesInRadius=function()end
ignitionMode.igniteEnemiesInRadius=function()end
ignitionMode.damageTreeWithSmokerWeapon=function()return false end
local ignitionGame={player={isMoving=false,x=0,y=0},world={nodes={}}}
ignitionMode:updateOilTrail(.1,ignitionGame)
assert(ignitionMode.oilTrail[1]and ignitionMode.oilTrail[1].ignited,
    "oil ignition-radius upgrade did not reach a cigarette outside the base 70-unit radius")
ignitionMode.smokerGroundTime=7.2
ignitionMode:updateOilTrail(.1,ignitionGame)
assert(#ignitionMode.oilTrail==1,"oil burn-duration upgrade still stopped at the base five seconds")
ignitionMode.smokerGroundTime=11.6
ignitionMode:updateOilTrail(.1,ignitionGame)
assert(#ignitionMode.oilTrail==1,"upgraded oil fire ended before its 11-second duration")
ignitionMode.smokerGroundTime=13.2
ignitionMode:updateOilTrail(.1,ignitionGame)
assert(#ignitionMode.oilTrail==0,"upgraded oil fire outlived its 11-second duration")

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

local cancelMode=ClearcutMode.new()
cancelMode.scoreAttack=true
cancelMode.permanentTraits.scoreOilDrum=1
cancelMode.permanentTraits.scoreGrayCat=1
local cancelDrum={id=3,x=560,y=350,state="settled",hp=8,maxHp=8,angle=0,claimed=false}
cancelMode.oilDrums={cancelDrum}
assert(cancelMode:startGrayOilCat(cancelDrum,game),"gray cat cancel fixture did not dispatch")
assert(cancelMode:hitOilDrum(cancelDrum,8,game),"player axe did not break the cat-targeted drum")
assert(cancelMode.grayOilCat==nil,"player-broken drum still left the gray cat flying through the field")

for _=1,220 do catMode:updateGrayOilCat(.05,game)end
assert(catDrum.state=="spilled","gray cat did not tip the target drum")
assert(catMode.grayOilCat==nil,"gray cat did not jump out through the opposite screen edge")
assert(#catMode.oilTrail==16,"gray cat tip did not create the same oil spill as an axe hit")

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
trainedCat.permanentTraits.scoreGrayCatSpeed=.8;trainedCat.permanentTraits.scoreGrayCatExitSpeed=1
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

local rectangles,polygons,draws=0,0,0
love.graphics.setColor=function()end
love.graphics.rectangle=function()rectangles=rectangles+1 end
love.graphics.polygon=function()polygons=polygons+1 end
love.graphics.newImage=function()return{setFilter=function()end,getDimensions=function()return 768,256 end}end
love.graphics.newQuad=function()return{}end
love.graphics.draw=function()draws=draws+1 end
local trailArt=require("src.oil_trail_art")
local generated={x=100,y=100,spawnedAt=0,lifetime=20,pixelSeed=41,sequence=1,
    visualScale=1.1,stretchX=1.3,stretchY=.8,pixelChunks=24,ignited=false}
trailArt.drawGround(generated,2)
assert(rectangles>=20 and polygons>=30,"ground oil lacks dense scanline volume and stepped pixel texture")
generated.ignited,generated.ignitedAt,generated.burnDuration=true,1,8
trailArt.drawFlame(generated,2)
assert(draws>=1,"ignition did not add an independent authored flame object above the black pixels")

print("GRAY_OIL_CAT_OK facing=correct runtime-flow=enter,push,spill,jump oil-spots=16..28 code-native-pixels=true")
