package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local World=require("src.world")
local Art=require("src.cigarette_butt_art")

local node={kind="tree",x=220,y=250,active=true,burning=true,swayAngle=0,swayVel=0}
local world=setmetatable({nodes={node},particles={},treeBreakFx={},popups={},harvestChainTime=0}, {__index=World})
local game={player={x=0,y=0}}
for _=1,100 do
    world:updateEffects(.01,game)
end
assert(not node.burnPulseSerial and not node.burnPulseAge and not node.burnJoltTimer,
    "removed rhythmic combustion pulse state returned")
assert((node.burnDrawOffset or 0)==0,"continuous fire still jolted the whole tree")
assert(#world.particles==0,"continuous fire emitted timer-driven pulse particles")

fixture.reset();fixture.time=.4
node.cigaretteIgnitedAt=0
Art.drawTreeFire(node,.4)
local atlasDraws,shaderDraws,oldPulseDraws=0,0,0
for _,draw in ipairs(fixture.commands) do
    if draw.file=="assets/fx/tree-fire-loop-atlas-pixel-v3.png" then atlasDraws=atlasDraws+1 end
    if draw.file=="assets/fx/tree-fire-pulse-atlas-pixel-v1.png" then oldPulseDraws=oldPulseDraws+1 end
    if draw.shader=="assets/shaders/cigarette-ground-fx.glsl" then shaderDraws=shaderDraws+1 end
end
assert(atlasDraws==2 and shaderDraws==1,"authored fire glow/body and continuous smoke were not drawn")
assert(oldPulseDraws==0,"removed rhythmic pulse atlas is still connected")

fixture.reset()
Art.drawTransfer({x=100,y=200,tx=300,ty=180,startAt=0,duration=.6,treeSpread=true},.12)
local transferDraws=0
for _,draw in ipairs(fixture.commands) do
    if draw.shader=="assets/shaders/cigarette-ground-fx.glsl" then transferDraws=transferDraws+1 end
end
assert(transferDraws>=13,"tree-to-tree spread did not receive the larger directional ember burst")
print(("TREE_FIRE_COMBUSTION_OK rhythm=removed particles=%d loop_atlas=%d spread_draws=%d")
    :format(#world.particles,atlasDraws,transferDraws))
