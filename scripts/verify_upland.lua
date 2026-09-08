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

local b=world.playBounds
local cells={}
for i=1,180 do
    local x,y=Upland.sampleTree(world,i,1)
    assert(Upland.isTreeZone(world,x,y),"sample outside playable field")
    local key=math.floor((x-b.x)/b.w*4)+math.floor((y-b.y)/b.h*3)*4
    cells[key]=(cells[key]or 0)+1
end
for key=0,11 do assert((cells[key]or 0)>=5,"growth left an artificial empty region")end
game.clearcut.scoreRegenTier=10;game.clearcut.scoreTierFx=nil
local node=world.nodes[1];local x,y=node.x,node.y
assert(game.clearcut:advanceScoreRegenTier(game,false,"world_tree"))
assert(node.x==x and node.y==y,"promotion relocated an existing tree")

local shader=assert(io.open("assets/shaders/upland-ground.glsl","rb")):read("*a")
assert(not shader:lower():find("lake",1,true)and not shader:lower():find("shore",1,true),"upland shader contains lakeside material")
print("UPLAND_OK tier11 fourfold-area full-field-growth existing-roots-preserved")
