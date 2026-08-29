package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
love.mouse={isDown=function()return false end,getPosition=function()return 0,0 end}

local Understory=require("src.forest_understory")
local Scenery=require("src.forest_scenery")
local BiomeLife=require("src.biome_life")
local Maps=require("src.clearcut_maps")
local Butts=require("src.cigarette_butts")
local ClearcutMode=require("src.clearcut_mode")

local world={width=3200,height=2000,clearcutMap="forest",northBackdrop=true,nodes={},
    playBounds={x=400,y=300,w=2400,h=1400},addLeafParticle=function()end}
local grass=Understory.generate(world,1)
assert(#grass.patches>0,"playfield grass disappeared")
for _,patch in ipairs(grass.patches)do
    local margin=Maps.groundPlantMargins
    assert(patch.x>=world.playBounds.x+margin.left and patch.x<=world.playBounds.x+world.playBounds.w-margin.right,
        "grass escaped the horizontal playfield")
    assert(patch.y>=world.playBounds.y+margin.top and patch.y<=world.playBounds.y+world.playBounds.h-margin.bottom,
        "grass spawned in the panorama")
end

Scenery.generate(world,1)
for _,list in ipairs({world.forestScenery.ground,world.forestScenery.actors})do for _,prop in ipairs(list)do
    assert(Maps.canPlant(world,prop.x,prop.y),"scenery prop escaped playable terrain")
    if prop.kind=="fern" then
        assert(Maps.insideGroundPlants(world,prop.x,prop.y,{left=135,right=135,top=220,bottom=120}),
            "scenery fern escaped its safe ground inset")
    end
end end

local lifeWorld={width=3200,height=2000,clearcutMap="madagascar",nodes={},
    playBounds={x=400,y=300,w=2400,h=1400}}
local life=BiomeLife.generate(lifeWorld,1)
for _,item in ipairs(life.items)do
    assert(Maps.insideSpawnTerrain(lifeWorld,item.x,item.y,28),"ambient wildlife spawned in panorama")
    if BiomeLife.catalog[item.kind].plant then
        assert(Maps.insideGroundPlants(lifeWorld,item.x,item.y),"ambient plant escaped the safe ground inset")
    end
end
life.items[#life.items+1]={kind="lemur",x=1600,y=world.playBounds.y-80,homeX=1600,homeY=0,phase=0,facing=1,scale=1}
local lifeQueue={};BiomeLife.queue(lifeWorld,lifeQueue,nil)
assert(#lifeQueue==#life.items-1,"render safety allowed off-terrain wildlife into panorama")

local rooted=ClearcutMode.new();rooted.mapId="forest";rooted.mapWorld=world;rooted.mapPlayer={x=1600,y=1000}
local plant=assert(rooted:spawnEnemy("vineSprout",world.playBounds.x-400,world.playBounds.y-400))
assert(Maps.insideGroundPlants(world,plant.x,plant.y),"rooted attack plant remained on the panorama/edge")

local player={x=1600,y=430,facing=1}
local game={player=player,world=world,camera={trauma=0},setNotice=function()end}
local mode=ClearcutMode.new();mode.job="fire"
mode:hurlMolotovAt(1680,40,game)
local flight=assert(mode.molotovs[1])
assert(flight.fallsOffMap and math.abs(flight.y1-world.playBounds.y-2)<.01,
    "north throw did not stop its ground arc at the ridge")
local _,edgeY=Butts.flightPosition(flight,flight.approachDur)
local _,fallY=Butts.flightPosition(flight,flight.approachDur+flight.fallDuration*.8)
assert(math.abs(edgeY-flight.y1)<.01 and fallY>flight.y1+1500,
    "cigarette did not visibly fall below the ridge")
mode:updateMolotovs(flight.dur+.01,game)
assert(#mode.molotovs==0 and #mode.cigaretteButts==0,
    "off-map cigarette landed on an invisible floor")

local groundMode=ClearcutMode.new();groundMode.job="fire"
groundMode:hurlMolotovAt(1700,700,game)
groundMode:updateMolotovs(groundMode.molotovs[1].dur+.01,game)
assert(#groundMode.cigaretteButts==1,"ordinary in-map cigarette no longer lands")

print(("NORTH_BOUNDARY_OBJECTS_OK grass=%d plants=inset panorama=empty cigarette=falls_until_hidden ground=unchanged")
    :format(#grass.patches))
