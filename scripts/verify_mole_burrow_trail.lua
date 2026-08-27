package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
love.mouse={isDown=function() return false end,getPosition=function() return 0,0 end}
local Mode=require("src.clearcut_mode")
local mode=Mode.new();mode.job="miner";mode.permanentTraits.area=0
local player={x=100,y=100,facing=1,setClearcutAction=function() end,clearClearcutAction=function() end}
local game={player=player,world={nodes={}},setNotice=function() end}
assert(mode:activateMinerBurrow(game));assert(#mode.burrowTracks==1 and mode.burrowTracks[1].kind=="entry")
mode:updateMinerBurrow(.3,game);assert(mode.minerBurrow.state=="tunnel")
player.x,player.y=210,125;mode:updateMinerBurrow(.1,game)
assert(#mode.burrowTracks>=5,"moving underground did not stamp a continuous trail")
for i=3,#mode.burrowTracks do
    local a,b=mode.burrowTracks[i-1],mode.burrowTracks[i]
    if not a.kind and not b.kind then
        local dx,dy=a.x-b.x,a.y-b.y;assert(dx*dx+dy*dy<=23*23,"trail stamps have a visible gap")
    end
end
fixture.reset();local queue={};mode:queueWorldActors(queue,0)
for _,entry in ipairs(queue) do entry.draw() end
local draws=0
for _,op in ipairs(fixture.commands) do
    if op.file=="assets/fx/mole-burrow/mole-burrow-trail-atlas-pixel-v1.png" then
        draws=draws+1;assert(op.op=="draw" and op.filter=="nearest")
    end
end
assert(draws==#mode.burrowTracks,"not every track mark reached the ground queue")
mode:updateBurrowTracks(15.1);assert(mode.burrowTracks[1].life<3,"trail did not reach fade phase")
mode:updateBurrowTracks(3);assert(#mode.burrowTracks==0,"trail did not expire")
print("MOLE_BURROW_TRAIL_OK spacing=22 lifetime=18 depth=ground atlas=v1")
