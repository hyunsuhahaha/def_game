package.path = "./?.lua;./?/init.lua;" .. package.path

love = {
    mouse = {isDown=function() return false end, getPosition=function() return 300,200 end},
    math = {random=function(a,b) if a and b then return a end if a then return 1 end return .5 end},
    timer = {getTime=function() return 0 end},
    graphics = {}
}

local ClearcutMode=require("src.clearcut_mode")
local mode=ClearcutMode.new()
mode.job="miner"
mode.levels.detector=1
mode.permanentTraits={attackSpeed=1,range=0,area=0,extraTargets=0,treeDamage=0,moveSpeed=1}
local notices={}
local particles=0
local player={x=100,y=100,facing=1,gather=1,setClearcutAction=function(self,p) self.pose=p end,clearClearcutAction=function(self) self.pose=nil end}
local treeA={rushTree=true,active=true,x=160,y=100,rushHp=3,rushMaxHp=3,treeVariant=2}
local treeC={rushTree=true,active=true,x=205,y=100,rushHp=3,rushMaxHp=3,treeVariant=3}
local treeB={rushTree=true,active=true,x=160,y=250,rushHp=3,rushMaxHp=3,treeVariant=1}
local world={
    nodes={treeA,treeC,treeB}, width=1000,height=1000,drops={},images={treeVariants={}},
    impactNode=function() end, addParticle=function() particles=particles+1 end,
    harvestBurst=function(node) node.fallT=.1 end, spawnDrop=function() end
}
local game={
    player=player,world=world,tools={axe={speed=1}},
    camera={screenToWorld=function() return 220,100 end,trauma=0},
    setNotice=function(_,message) notices[#notices+1]=message end
}

-- Scratch damage is tied to the authored contact frame, not a free-running timer.
mode:updateMinerAttack(0,game,true)
assert(treeA.rushHp==3)
mode:updateMinerAttack(.2,game,true)
assert(treeA.rushHp==3,"claw damage happened before the contact frame")
mode:updateMinerAttack(.25,game,true)
assert(treeA.rushHp<3,"claw contact frame did not damage the forward tree")
assert(#mode.minerClawFx==1,"claw contact did not create its directional pixel effect")
assert(mode.minerClawFx[1].x==treeA.x and mode.minerClawFx[1].x~=player.x,"claw effect must originate at the struck point, never the mole")
assert(math.abs(mode.minerClawFx[1].angle)<.001,"rightward claw effect is not aligned to the attack vector")
assert(mode.minerClawFx[1].curveFlip==-1,"rightward claw must be the mirror image of the accepted leftward curve")
assert(#mode.minerClawMarks==1 and mode.minerClawMarks[1].life==6,"claw gouge was not left on the struck surface")
assert(mode:getUpgradeDefinition("detector").name:find("손톱 강화",1,true),"miner claw upgrade is not identified as a job skill")
mode:updateMinerAttack(.3,game,false)
assert(#mode.minerClawFx==0 and #mode.minerClawMarks==1,"contact flash should end while the scratch mark remains")

assert(mode:activateMinerBurrow(game)==true)
assert(mode.minerBurrow and mode.minerBurrow.state=="enter")
mode:updateMinerBurrow(.3,game)
assert(mode.minerBurrow.state=="tunnel")
player.x=180
mode:updateMinerBurrow(.1,game)
assert(treeA.active==false and treeA.uprooted==true,"burrow path did not uproot the crossed tree")
assert(treeC.active==false and treeC.uprooted==true,"all trees over the burrow path must launch automatically")
assert(#mode.thrownTrees==2,"crossed trees were not launched sideways")
local thrown=mode.thrownTrees[1]
assert(math.abs(thrown.vy)>math.abs(thrown.vx),"tree was not launched to the side of travel")
assert(thrown.variant==2,"tree visual variant was not preserved")
assert(mode.thrownTrees[1].vy*mode.thrownTrees[2].vy<0,"successive trees should fan out to alternating sides")

-- Reposition a live tree into the projectile path and verify collision damage.
treeB.x,treeB.y=thrown.x,thrown.y+45
mode:updateThrownTrees(.05,game)
assert(treeB.rushHp<3 or not treeB.active,"flying tree did not damage another tree")

local hp=mode.hp
mode.minerBurrow={state="tunnel"}
mode:damagePlayer(10,game)
assert(mode.hp==hp,"underground mole should ignore surface damage")

print("COIN_MINER_GAMEPLAY_VERIFY_OK")
