package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local World=require("src.world")
local ClearcutMode=require("src.clearcut_mode")

local world=World.new();world:useArcadeForest();world.hideBase=true;world.width,world.height=720,520
world.treeVisual.scale=1;world.treeVisual.variantScale={1,1,1,1}
local tree={kind="tree",rushTree=true,active=true,x=360,y=350,rushHp=8,rushMaxHp=8,treeVariant=1,beehive=true,
    treeEmergence={t=.45,duration=.95,direction=1,source="regrow"}}
world.nodes={tree}
local player={x=100,y=100,introHidden=true}
local mode=ClearcutMode.new()

fixture.reset();world:draw(player,mode)
local treeDraw,castDraw
for _,command in ipairs(fixture.commands)do
    if command.file and command.file:find("broadleaf%-tree%-cartoon%-v3%.png")then treeDraw=command end
    if command.file and command.file:find("regrowth%-cast%-atlas%-v3%.png")then castDraw=command end
end
assert(treeDraw and castDraw,"tree emergence did not combine the approved tree and authored regrowth atlas")
assert(treeDraw.args[4] and treeDraw.args[4]<1 and treeDraw.args[4]>.5,"tree emergence scale is not in its readable rise phase")
world.billboardQueue={};mode:queueProjectedOverlay({world=world,player=player},0)
local function hasHive(queue)for _,entry in ipairs(queue)do if entry.x==tree.x and entry.y==tree.y and math.abs((entry.sortBias or 0)-.08)<.001 then return true end end return false end
assert(not hasHive(world.billboardQueue),"beehive appeared before its tree finished emerging")

world:updateEffects(.6,{player=player})
assert(not tree.treeEmergence,"tree emergence state did not finish")
fixture.reset();world:draw(player,mode)
treeDraw=nil;castDraw=nil
for _,command in ipairs(fixture.commands)do
    if command.file and command.file:find("broadleaf%-tree%-cartoon%-v3%.png")then treeDraw=command end
    if command.file and command.file:find("regrowth%-cast%-atlas%-v3%.png")then castDraw=command end
end
assert(treeDraw and math.abs(treeDraw.args[4]-1)<.001 and not castDraw,"settled tree did not return to its authored scale")
world.billboardQueue={};mode:queueProjectedOverlay({world=world,player=player},0)
assert(hasHive(world.billboardQueue),"beehive did not return after tree emergence")

print("TREE_EMERGENCE_OK duration=.95 atlas=regrowth-v3 scale=.56..1.065 settle=1 beehive=delayed")
