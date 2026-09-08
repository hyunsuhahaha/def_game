local game=dofile("scripts/verify_job_master.lua")
local Builder=require("src.construction_worker")
local mode=game.clearcut
local c=mode.construction
c.loads={};c.flyingTrees={};c.contactDust={};c.cooldown=0;c.crackQueue=0
c.stats=Builder.stats(game.characterTraits)
mode.enemies={};game.world.nodes={}
game.player.x,game.player.y=game.world.width/2-500,game.world.height/2
local sounds={}
game.feedback={play=function(_,kind) sounds[kind]=(sounds[kind]or 0)+1 end}
for i=1,10 do
    game.world.nodes[i]={kind="tree",rushTree=true,active=true,x=game.player.x+350+i*65,
        y=game.player.y,rushHp=5,rushMaxHp=5,treeVariant=1}
end
local score=mode.treesFelled
Builder.update(mode,game,.1,true,game.player.x+1200,game.player.y)
assert(#c.loads==1 and c.loads[1].height==c.dropHeight,"hoist anticipation missing")
local stopped=false
for i=1,174 do
    Builder.update(mode,game,1/60,false)
    for _,load in ipairs(c.loads)do if (load.impactPause or 0)>0 then stopped=true end end
end
assert(mode.treesFelled==score+10,"single attack did not clear ten trees in three seconds")
assert(sounds.crane_land==1 and (sounds.axe_wood or 0)>1,"missing landing / sequential cracks")
assert(stopped and #c.flyingTrees==0,"missing first contact pause or lingering airborne trees")
assert(c.crackQueue==0,"impact sound queue leaked")
print("CRANE_ATTACK_FEEL_OK one-shot ten-trees three-seconds hoist landing first-hit-pause sequential-cracks low-flight")
