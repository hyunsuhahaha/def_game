package.path="./?.lua;./?/init.lua;"..package.path
love={math={random=function(a,b) if b then return a elseif a then return 1 else return .99 end end},mouse={isDown=function() return false end,getPosition=function() return 100,0 end},timer={getTime=function() return 0 end}}
local Mode=require("src.clearcut_mode")
local tree={rushTree=true,active=true,x=82,y=0,rushHp=1,rushMaxHp=4,treeVariant=2}
local enemy={x=76,y=2,hp=40,def={radius=12}}
local world={nodes={tree},images={treeVariants={}},impactNode=function() end,addParticle=function() end,
    harvestBurst=function() end,spawnDrop=function() end}
local player={x=0,y=0,gather=1,facing=1,setClearcutAction=function(self,p) self.action=p end,clearClearcutAction=function(self) self.action=nil end}
local game={player=player,tools={axe={speed=1}},camera={trauma=0,screenToWorld=function(_,x,y) return x,y end},world=world,setNotice=function() end}
local mode=Mode.new();mode.job="toxic";mode.hp=40;mode.maxHp=100;mode.remainingTrees=1;mode.initialTrees=1;mode.sandbox=true
mode.levels={fork_feast=1,buffet_fork=2,clean_plate=6,seconds_please=3}
mode.enemies={enemy};mode.checkMilestones=function() end;mode.onWood=function(self,n) self.bonusWood=(self.bonusWood or 0)+n end
mode:updateToxicAttack(0,game,true)
mode:updateToxicAttack(mode.veganAction.dur*.52,game,true)
assert(tree.active and mode.actionAudit.veganFork==0,"fork hit before authored contact frame")
mode:updateToxicAttack(mode.veganAction.dur*.02,game,true)
assert(not tree.active and mode.actionAudit.veganFork==1 and mode.actionAudit.veganConsume==1,"lethal fork did not consume tree exactly once")
assert(#mode.veganForkImpacts>=1 and #mode.veganConsumeFx==1,"fork/chomp visual events missing")
assert(mode.veganHaste>0 and mode.hp>40 and (mode.bonusWood or 0)>0,"clean plate / seconds effects missing")
assert(enemy.hp<40,"fork hitbox missed enemy inside the visible strike lane")
assert(#mode.plagued==0 and not tree.plagueMarked and not enemy.plagueMarked,"vegan fork still applies poison")
local source=assert(io.open("src/clearcut_mode.lua","rb")):read("*a")
assert(not source:find("toxic_rain",1,true) and not source:find("updateToxicRain",1,true),"removed vegan poison skill remains in runtime")
print("VEGAN_FORK_GAMEPLAY_OK contact=.53 consume=lethal poison=removed skills=4 fusion=ready")
