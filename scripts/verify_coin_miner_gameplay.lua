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
local treeD={rushTree=true,active=true,x=280,y=100,rushHp=3,rushMaxHp=3,treeVariant=4}
local treeB={rushTree=true,active=true,x=160,y=320,rushHp=3,rushMaxHp=3,treeVariant=1}
local world={
    nodes={treeA,treeC,treeD,treeB}, width=1000,height=1000,drops={},images={treeVariants={}},
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
assert(treeC.rushHp<3,"a nearer tree incorrectly shielded another target inside the visible swipe")
assert(treeD.rushHp<3,"visible forward claw lobe still has no matching damage range")
assert(#mode.minerClawFx==1,"one click spawned one claw effect per target instead of one shared swipe")
assert(mode.minerClawFx[1].x==220 and mode.minerClawFx[1].x~=player.x,"claw effect must remain at the chosen attack point, never the mole")
assert(math.abs(mode.minerClawFx[1].angle)<.001,"rightward claw effect is not aligned to the attack vector")
assert(mode.minerClawFx[1].curveFlip==-1,"rightward claw must be the mirror image of the accepted leftward curve")
assert(#mode.minerClawMarks==1 and mode.minerClawMarks[1].life==6,"one click must leave one shared gouge")
assert(mode:getUpgradeDefinition("detector").name:find("손톱 강화",1,true),"miner claw upgrade is not identified as a job skill")
mode:updateMinerAttack(.3,game,false)
assert(#mode.minerClawFx==0 and #mode.minerClawMarks==1,"contact flash should end while its one scratch mark remains")

-- Continuous movement during the wind-up must carry the original direction
-- with the mole instead of swinging back toward a stale mouse world point.
local moveMode=ClearcutMode.new();moveMode.job="miner";moveMode.levels.detector=1
moveMode.permanentTraits={attackSpeed=1,range=0,area=0,extraTargets=0,treeDamage=0,moveSpeed=1}
local movePlayer={x=100,y=100,facing=1,gather=1,setClearcutAction=function() end,clearClearcutAction=function() end}
local moveTree={rushTree=true,active=true,x=250,y=180,rushHp=10,rushMaxHp=10,treeVariant=1}
local moveGame={player=movePlayer,tools={axe={speed=1}},world={nodes={moveTree},impactNode=function() end},
    camera={screenToWorld=function() return 220,100 end,trauma=0}}
moveMode:updateMinerAttack(0,moveGame,true);moveMode:updateMinerAttack(.2,moveGame,true)
movePlayer.y=180;moveMode:updateMinerAttack(.25,moveGame,true)
assert(moveTree.rushHp<10,"moving during claw wind-up detached the hitbox from the mole")

-- Aiming at the visible upper tree, rather than its root anchor, still hits
-- the vertical body segment and places the contact effect at that height.
local canopyMode=ClearcutMode.new();canopyMode.job="miner";canopyMode.levels.detector=1
canopyMode.permanentTraits={attackSpeed=1,range=0,area=0,extraTargets=0,treeDamage=0,moveSpeed=1}
local canopyPlayer={x=100,y=100,facing=1,gather=1,setClearcutAction=function() end,clearClearcutAction=function() end}
local canopyTree={rushTree=true,active=true,x=160,y=100,rushHp=10,rushMaxHp=10,treeVariant=1}
local canopyGame={player=canopyPlayer,tools={axe={speed=1}},world={nodes={canopyTree},impactNode=function() end},
    camera={screenToWorld=function() return 160,-50 end,trauma=0}}
canopyMode:updateMinerAttack(0,canopyGame,true);canopyMode:updateMinerAttack(.45,canopyGame,true)
assert(canopyTree.rushHp<10,"claw aimed at the visible tree body only checked the root point")
assert(canopyMode.minerClawFx[1].y<canopyTree.y,"tree contact effect was not placed on the actual visible hit height")

-- Max rank uses both hands, but the paired visuals still form exactly one
-- damage envelope and therefore never double the damage.
local maxMode=ClearcutMode.new()
maxMode.job="miner";maxMode.levels.detector=6
maxMode.permanentTraits={attackSpeed=1,range=0,area=0,extraTargets=0,treeDamage=0,moveSpeed=1}
local maxTree={rushTree=true,active=true,x=160,y=100,rushHp=100,rushMaxHp=100,treeVariant=1}
local emptyWorld={nodes={maxTree},impactNode=function() end}
local maxGame={player=player,world=emptyWorld,camera={trauma=0}}
maxMode:applyClawSwipe(260,100,maxGame)
assert(#maxMode.minerClawFx==1 and #maxMode.minerClawMarks==1,"level-six paired claws must remain one composite attack effect")
assert(maxMode.minerClawFx[1].dual==true,"level-six shared effect lost its mirrored second hand")
local singleHitDamage=2+maxMode:power("detector")*.65
assert(math.abs(maxTree.rushHp-(100-singleHitDamage))<.001,"two-hand visual must not apply claw damage twice")

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
