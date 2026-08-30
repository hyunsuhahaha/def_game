package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local World=require("src.world")
local Art=require("src.cigarette_butt_art")

local node={kind="tree",x=220,y=250,active=true,burning=true,swayAngle=0,swayVel=0}
local world=setmetatable({nodes={node},particles={},treeBreakFx={},popups={},harvestChainTime=0}, {__index=World})
local game={player={x=0,y=0}}
local pulses,jolted=0,false
for _=1,100 do
    world:updateEffects(.01,game)
    pulses=math.max(pulses,node.burnPulseSerial or 0)
    jolted=jolted or math.abs(node.burnDrawOffset or 0)>=1
end
assert(pulses>=3 and pulses<=7,"burn pulse cadence escaped irregular 0.15..0.35s rhythm: "..pulses)
assert(jolted,"combustion beat did not produce the short 1..2 pixel tree response")
assert(#world.particles>=2,"combustion beat did not emit lateral embers")

fixture.reset();fixture.time=.4
node.burnPulseAge=.11;node.burnDrawOffset=2;node.cigaretteIgnitedAt=0
Art.drawTreeFire(node,.4)
local atlasDraws,shaderDraws=0,0
for _,draw in ipairs(fixture.commands) do
    if draw.file=="assets/fx/tree-fire-pulse-atlas-pixel-v1.png" then atlasDraws=atlasDraws+1 end
    if draw.shader=="assets/shaders/cigarette-ground-fx.glsl" then shaderDraws=shaderDraws+1 end
end
assert(atlasDraws==1 and shaderDraws==4,"tree fire pulse was not layered over the continuous authored flame/smoke")

fixture.reset()
Art.drawTransfer({x=100,y=200,tx=300,ty=180,startAt=0,duration=.6,treeSpread=true},.12)
local transferDraws=0
for _,draw in ipairs(fixture.commands) do
    if draw.shader=="assets/shaders/cigarette-ground-fx.glsl" then transferDraws=transferDraws+1 end
end
assert(transferDraws>=13,"tree-to-tree spread did not receive the larger directional ember burst")
print(("TREE_FIRE_COMBUSTION_OK pulses=%d particles=%d pulse_atlas=%d spread_draws=%d")
    :format(pulses,#world.particles,atlasDraws,transferDraws))
