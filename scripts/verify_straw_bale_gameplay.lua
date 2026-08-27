package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Mode=require("src.clearcut_mode")
local mode=Mode.new();mode.job="fire";mode.levels.straw_bale=1;mode.strawTimer=999;mode.smokerGroundTime=10
mode.strawBales={{x=100,y=120,age=0,ignited=false,variant=0}}
mode.cigaretteButts={}
local spreadCalls,igniteFxCalls=0,0
local game={player={x=0,y=0},world={nodes={{rushTree=true,active=true,burning=true,x=100,y=120}},igniteFx=function() igniteFxCalls=igniteFxCalls+1 end}}
mode.damageEnemiesInRadius=function(self,x,y,radius,damage)
    self.damageAudit={x=x,y=y,radius=radius,damage=damage}
end
mode.igniteNear=function() spreadCalls=spreadCalls+1 end

-- A burning tree on top of the bale no longer lights it.
mode:updateStrawBales(.1,game)
local bale=mode.strawBales[1]
assert(not bale.primedAt and not bale.ignited,"burning tree still auto-ignites hay")

-- Only a landed cigarette begins the exact half-second anticipation.
mode.cigaretteButts={{x=112,y=122}}
mode:updateStrawBales(.01,game)
assert(bale.primedAt==10 and not bale.ignited,"cigarette did not prime bale")
mode.smokerGroundTime=10.49;mode:updateStrawBales(.48,game)
assert(not bale.ignited,"bale ignited before 0.5 seconds")
mode.smokerGroundTime=10.5;mode:updateStrawBales(.01,game)
assert(bale.ignited and bale.ignitedAt==10.5,"bale did not ignite at 0.5 seconds")
assert(igniteFxCalls==0,"generic tree ignition FX masks authored bale animation")

-- Local DOT stays intact, without invoking any spread path.
mode.smokerGroundTime=10.9;mode:updateStrawBales(.4,game)
assert(mode.damageAudit and mode.damageAudit.radius==60 and mode.damageAudit.damage==4)
assert(spreadCalls==0,"hay fire spread to another target")

mode.cigaretteButts={}
fixture.reset();local queue={};mode:queueWorldActors(queue,mode.smokerGroundTime)
local found=false
for _,entry in ipairs(queue) do
    entry.draw()
end
for _,op in ipairs(fixture.commands) do
    if op.file=="assets/fx/straw-bale/straw-bale-atlas-pixel-v3.png" then
        found=true;assert(op.op=="draw" and op.filter=="nearest")
    end
end
assert(found,"authored straw-bale atlas was not depth-queued")
print("STRAW_BALE_GAMEPLAY_OK cigarette_only delay=0.5 dot=60x4 spread=none atlas=v3")
