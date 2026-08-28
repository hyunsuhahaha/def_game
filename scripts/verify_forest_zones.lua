package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Zones=require("src.forest_zones")
local world={width=300,height=200,nodes={}}
for row=0,1 do for col=0,2 do
    world.nodes[#world.nodes+1]={rushTree=true,active=true,x=50+col*100,y=50+row*100}
end end
local mode={mapWorld=world,zonesSecured=0}
mode.forestZones=Zones.build(world,world.nodes)
assert(#mode.forestZones==6)
for id,z in ipairs(mode.forestZones) do assert(z.initial==1 and z.active==1 and z.coreAlive and not z.secured,id) end
local coreX,coreY=Zones.corePosition(world,mode.forestZones[1],world.nodes,function(_,x,y)return x<100 and y<100 end)
assert(coreX<100 and coreY<100,"core position ignored walkable terrain")
local node=world.nodes[1];node.active=false
assert(not Zones.refresh(mode,1),"living core must prevent securing")
local zone=Zones.coreDestroyed(mode,1)
assert(zone.secured and mode.zonesSecured==1,"core down + empty zone must secure")
assert(not Zones.canRegrow(mode,node),"secured zone regrew")
local secured,total=Zones.status(mode);assert(secured==1 and total==6)
assert(not (secured==total),"final objective opened before every zone was secured")
assert(#Zones.candidates(mode,mode.forestZones[2])==0)
local fonts={micro=love.graphics.newFont("assets/font-korean-regular.ttf",12),small=love.graphics.newFont("assets/font-korean-regular.ttf",14)}
for _,width in ipairs({960,1280}) do
    fixture.reset();Zones.drawHUD(mode,fonts,width,96)
    local rectangles,texts=0,0
    for _,op in ipairs(fixture.commands) do
        assert(op.op=="rectangle" or op.op=="text","zone HUD used a world-effect primitive")
        if op.op=="rectangle" then
            rectangles=rectangles+1
            assert(op.args[1]>=0 and op.args[1]+op.args[3]<=width,"zone HUD overflow")
        else texts=texts+1 end
    end
    assert(rectangles==6 and texts==6,"zone HUD lost one of six minimal states")
end
local capture=os.getenv("FOREST_ZONE_CAPTURE");if capture then fixture.save(capture) end
print("FOREST_ZONES_OK grid=3x2 core_gate=true secured=permanent regen=local")
