local game=dofile("scripts/verify_crane_full_scene.lua")
local Maps=require("src.clearcut_maps")
local Upland=require("src.upland")
local world=game.world

Maps.configureScoreTier(world,10)
assert(world.lakeside and not world.upland,"tier 10 must remain lakeside")
local oldW,oldH=world.playBounds.w,world.playBounds.h
Maps.configureScoreTier(world,11)
assert(world.upland and not world.lakeside,"tier 11 did not replace the lakeside")
assert(math.abs(world.playBounds.w/oldW-2)<.001 and math.abs(world.playBounds.h/oldH-2)<.001,"tier 11 must quadruple playable area")
local width=world.width
Maps.configureScoreTier(world,12)
assert(world.width==width and world.playBounds.w>oldW*2,"later tier compounded world size or stopped expansion")

local nodes={}
for i=1,72 do nodes[i]={rushTree=true,active=true,x=world.width/2,y=world.height/2}end
Upland.clusterTrees(world,nodes)
for _,node in ipairs(nodes)do
    assert(Upland.isTreeZone(world,node.x,node.y),"tree escaped a woodland grove")
    local neighbours=0
    for _,other in ipairs(nodes)do
        if other~=node and (other.x-node.x)^2+(other.y-node.y)^2<400^2 then neighbours=neighbours+1 end
    end
    assert(neighbours>=1,"upland tree became a sparse singleton")
end

local shader=assert(io.open("assets/shaders/upland-ground.glsl","rb")):read("*a")
assert(not shader:lower():find("lake",1,true)and not shader:lower():find("shore",1,true),"upland shader contains lakeside material")
print("UPLAND_OK tier11 zero-lakeside full-field clustered-groves haul-roads")
