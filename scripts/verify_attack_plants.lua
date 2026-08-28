package.path="./?.lua;./?/init.lua;"..package.path
local Plants=require("src.attack_plants")
local game={player={x=120,y=0}}
local expected={thornHunter="telegraph",hammerBloom="telegraph",seedPod="projectile",bambooCannon="projectile",resinSprayer="projectile"}
for kind,def in pairs(Plants.definitions) do
    local mode={projectiles={},bossTelegraphs={},resinPuddles={},rootedTimer=0}
    local e={kind=kind,def=def,x=0,y=0,seed=0,dmgMul=1,plantTimer=0}
    assert(Plants.update(e,.01,mode,game) and e.plantState=="windup",kind.." did not enter windup")
    Plants.update(e,1,mode,game)
    local output=(#mode.bossTelegraphs>0 and "telegraph") or (#mode.projectiles>0 and "projectile")
    assert(output==expected[kind],kind.." wrong attack output")
    if kind=="seedPod" then assert(#mode.projectiles==5,"seed pod must fire five seeds") end
    if kind=="thornHunter" then assert(#mode.bossTelegraphs==3,"thorn hunter must chain three eruptions") end
end
local mode={resinPuddles={},rootedTimer=0}
assert(Plants.onProjectileExpired(mode,{kind="resinBlob",x=4,y=5,targetX=7,targetY=8}))
assert(#mode.resinPuddles==1 and mode.resinPuddles[1].x==7,"resin landing missing")
print("ATTACK_PLANTS_GAMEPLAY_OK species=5 thorn=3 seed=5 resin=sticky")
