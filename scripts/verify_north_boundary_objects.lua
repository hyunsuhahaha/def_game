package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
love.mouse={isDown=function()return false end,getPosition=function()return 0,0 end}

local Understory=require("src.forest_understory")
local Butts=require("src.cigarette_butts")
local ClearcutMode=require("src.clearcut_mode")

local world={width=3200,height=2000,clearcutMap="forest",northBackdrop=true,nodes={},
    playBounds={x=400,y=300,w=2400,h=1400},addLeafParticle=function()end}
local grass=Understory.generate(world,1)
assert(#grass.patches>0,"playfield grass disappeared")
for _,patch in ipairs(grass.patches)do
    assert(patch.x>=world.playBounds.x+48 and patch.x<=world.playBounds.x+world.playBounds.w-48,
        "grass escaped the horizontal playfield")
    assert(patch.y>=world.playBounds.y+72 and patch.y<=world.playBounds.y+world.playBounds.h-36,
        "grass spawned in the panorama")
end

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

print(("NORTH_BOUNDARY_OBJECTS_OK grass=%d panorama=empty cigarette=falls_until_hidden ground=unchanged")
    :format(#grass.patches))
