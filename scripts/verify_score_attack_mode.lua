package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
love.graphics.rotate=love.graphics.rotate or function()end
love.graphics.getDimensions=function()return 1280,720 end
love.graphics.getWidth=function()return 1280 end
love.graphics.getHeight=function()return 720 end
love.mouse={getPosition=function()return -100,-100 end,isDown=function()return false end}
love.keyboard={isDown=function()return false end}

local Game=require("src.game")
local World=require("src.world")
local Player=require("src.player")
local Camera=require("src.camera")
local Traits=require("src.character_traits").new(true)
local function expectedSpawn(tier,seconds)return .14*1.75^(tier-1)*2^(seconds/60)end

local loader
for i=1,30 do local name,value=debug.getupvalue(Game.new,i);if name=="loadClearcutSprites"then loader=value;break end end
local sprites=assert(loader)()
local game=setmetatable({characterTraits=Traits,clearcutSprites=sprites,tools={axe={speed=.8}},wood=0},Game)
function game:resetRun()
    self.clearcut=nil;self.result=nil;self.world=World.new()
    self.player=Player.new(1600,1000,self.world.images.workerWalk,self.world.images.workerActions,self.world.images.workerRepair)
    self.camera=Camera.new(1600,1000)
end
function game:setNotice(message)self.notice=message end

game:startClearcutScoreAttack()
local mode=assert(game.clearcut)
assert(game.mode=="playing"and mode.scoreAttack and mode.job=="fire"and mode.stageTimeLimit==math.huge,"score mode still has a visible fixed timer")
local lobbySource=assert(io.open("src/lobby.lua","rb")):read("*a")
local modeSource=assert(io.open("src/clearcut_mode.lua","rb")):read("*a")
assert(not lobbySource:find("SMOKER ONLY",1,true)and not lobbySource:find("흡연자 벌목 기록 실험",1,true),
    "active lobby still presents a smoker/character premise")
assert(not modeSource:find("벌목 기록 · 흡연자",1,true),"score HUD still presents a selected character")
assert(mode.scoreTreeAllowance==12,"fresh score mode did not use the 12-tree base allowance")
assert(game.world.width==2240 and game.world.height==1400,"score mode world was not reduced to 70 percent")
assert(game.world.playBounds.w==1680 and game.world.playBounds.h==980 and game.world.cameraTopReveal==630,
    "score mode playable bounds or camera reveal did not follow the 70-percent map scale")
assert(mode.xpNext==5,"score mode did not start with the fast five-wood first upgrade")
assert(#game.world.nodes==6 and mode:scoreActiveTreeCount()==6 and mode.totalTreesSpawned==6,"score mode did not start with exactly six active trees")
assert(mode.remainingTrees==6 and mode.initialTrees==6 and mode.peakActiveTrees==6,"starting score trees were not included in occupancy metrics")
assert(not mode:checkWorldTreeSpawn(game),"opening score field incorrectly summoned the world tree")
assert(mode.scoreRegenTier==1 and math.abs(mode:scoreTreeSpawnRate()-.14)<.001,"opening forest did not use saved regeneration tier 1")
assert(mode:scoreTimePressureMultiplier()==1,"time pressure was not neutral at run start")
assert(mode:scoreTreeHealth(7)==7,"tier 1 altered ordinary tree health")
mode.currentTreesPerSecond=0

local openingTrees=#game.world.nodes
mode:updateScoreTreeGrowth(8,game)
assert(mode:scoreActiveTreeCount()>openingTrees and mode.totalTreesSpawned>openingTrees,"tier-based forest supply did not grow beyond the six opening trees")
for i=openingTrees+1,#game.world.nodes do local node=game.world.nodes[i]
    assert(node.active and node.rushTree and node.treeEmergence and node.treeEmergence.source=="score_growth","generated tree is missing its growth animation or harvest state")
end

mode:checkMilestones(game)
assert(#mode.enemies==0 and next(mode.milestoneFired)==nil,"score mode fired normal destruction milestone waves")
mode.stageElapsed=44
mode:updateTimeSpawner(44,game)
assert(#mode.enemies==0,"score mode spawned monsters during the 45-second opening grace")
mode.stageElapsed=45
mode:updateTimeSpawner(1.1,game)
assert(#mode.enemies==1,"score mode did not introduce exactly one sparse monster after the grace")
mode.scoreEnemyTimer=0
mode:updateTimeSpawner(.1,game)
assert(#mode.enemies==1,"score mode exceeded its opening one-monster cap")
local berserkBefore,vinesBefore,disasterBefore=mode.berserkTimer,mode.vinePlantTimer,mode.disasterTimer
mode:updateBerserk(999,game);mode:updateVinePlants(999,game);mode:updateDisasters(999,game)
assert(mode.berserkTimer==berserkBefore and mode.vinePlantTimer==vinesBefore and mode.disasterTimer==disasterBefore,"normal-stage threat systems remained active in score mode")

local scorePool=mode:upgradePool()
assert(#scorePool==10,"score mode did not expose six operation and four combat cards")
for _,def in ipairs(scorePool)do assert(def.scoreOperation and not def.job,"combat skill leaked into the operation draft: "..def.id)end
assert(mode:getUpgradeDefinition("baby_robot").scoreOperation==true,"baby robot is not marked as a score operation")
-- 전투 카드는 전부 무기 중립 수치다. 무기별 카드를 두면 다른 무기를 든 판에서
-- 죽은 카드가 되고, 무기를 추가할 때마다 카드도 같이 늘려야 한다.
for _,id in ipairs({"score_attack_speed","score_weapon_damage","score_weapon_area","score_weapon_range"})do
    assert(mode:getUpgradeDefinition(id).scoreOperation==true,"score combat card is not active: "..id)
end
for _,id in ipairs({"score_extra_butts","score_ignition_radius","score_burn_speed"})do
    assert(mode:getUpgradeDefinition(id)==nil,"weapon-specific combat card is back in the run draft: "..id)
end
mode.scoreInitialSmokingStarted=true;mode.levels.score_attack_speed=0;mode:startSmoking(game);local baseSmokingDuration=mode.smoking.dur
mode.levels.score_attack_speed=3;mode:startSmoking(game)
assert(mode.smoking.dur<baseSmokingDuration,"attack-speed card did not shorten the real smoking reload")
local Ops=require("src.score_operations")
mode.levels.score_weapon_damage=2;mode.levels.score_weapon_area=2;mode.levels.score_weapon_range=3
assert(math.abs(Ops.attackSpeedMultiplier(mode)-1.54)<1e-9 and Ops.weaponDamage(mode)==2 and
    Ops.weaponArea(mode)==36 and Ops.weaponRange(mode)==120,"score combat card values are stale")
mode:hurlMolotovAt(game.player.x+240,game.player.y,game)
assert(#mode.molotovs==1 and mode.molotovs[1].radius==126,"weapon area card did not widen the real cigarette ignition radius")
mode.molotovs={};mode.levels.score_attack_speed=0;mode.levels.score_weapon_damage=0
mode.levels.score_weapon_area=0;mode.levels.score_weapon_range=0

local nodes=game.world.nodes
nodes[#nodes+1]={rushTree=true,active=false}
nodes[#nodes+1]={rushTree=true,active=true,giantTree=true}
nodes[#nodes+1]={active=true,kind="plant"}
local ordinary=mode:scoreActiveTreeCount()
assert(ordinary>=1 and ordinary==mode.remainingTrees,"tree capacity count included inactive, giant, or non-tree nodes")

mode.stageElapsed=90
mode.scoreFellTimes={}
for _=1,5 do mode.scoreFellTimes[#mode.scoreFellTimes+1]=90 end
mode.scoreFellHead=1
mode:scoreProductionRate()
assert(mode.currentTreesPerSecond==5 and math.abs(mode:scoreTreeSpawnRate()-expectedSpawn(1,90))<.001,"elapsed-time pressure did not raise regeneration independently of recent logging output")
assert(math.abs(mode:scoreTimePressureMultiplier()-2^1.5)<.001,"time pressure did not double every 60 seconds")

local pending=mode.pending
game.mode="test"
mode:onWood(5,game)
assert(mode.pending==pending+1 and mode.level==2 and mode.xpNext==8 and mode.scoreWoodEarned==5,"score wood did not use the fast 5/8 opening level curve")
mode:rollChoices()
assert(#mode.choices==3,"score level-up did not roll exactly three choices")
for _,choice in ipairs(mode.choices)do assert(choice.id~="forest_expansion","removed forest automation card returned")end
for _,choice in ipairs(mode.choices)do assert(choice.scoreOperation and not choice.job,"score draft offered a combat card: "..choice.id)end
assert(mode.buyScoreAutomation==nil and mode.updateScoreAutomation==nil,"removed automation runtime methods remain")
game.mode="playing"

-- Clearing every active tree persists the tier immediately, then holds the world for
-- the authored transition before six trees rise in a staggered sequence.
for _,node in ipairs(nodes)do if node.rushTree and node.active and not node.giantTree then node.active=false end end
mode.remainingTrees=0
local pendingBeforeTier=mode.pending
assert(mode:updateScoreTierClear(.31,game),"empty forest did not trigger a regeneration transition")
assert(mode.scoreRegenTier==2 and Traits:getRegenTier()==2 and mode.pending==pendingBeforeTier,"tier clear was not persisted or incorrectly granted a card")
assert(mode.scoreTierFx and not mode.scoreTierFx.spawned and mode:scoreActiveTreeCount()==0,"tier effect did not hold the empty field before regrowth")
mode:updateScoreTierClear(.37,game)
assert(mode:scoreActiveTreeCount()==0,"tier trees appeared before the visual impact beat")
mode:updateScoreTierClear(.02,game)
assert(mode.scoreTierFx and mode.scoreTierFx.spawned and mode:scoreActiveTreeCount()==6,"tier effect did not reseed six trees on its impact beat")
local emergenceIndex=0
for _,node in ipairs(nodes)do if node.rushTree and node.active and not node.giantTree then
    emergenceIndex=emergenceIndex+1
    assert(node.treeEmergence and node.treeEmergence.source=="tier_up","tier tree is missing its dedicated emergence animation")
    assert(math.abs(node.treeEmergence.t+(emergenceIndex-1)*.065)<.001,"tier trees do not use staggered emergence timing")
end end
mode:updateScoreTierClear(.47,game)
assert(not mode.scoreTierFx and math.abs(mode:scoreTreeSpawnRate()-expectedSpawn(2,90))<.001,"tier transition did not preserve elapsed-time pressure at the new rate")
assert(mode:scoreTreeHealth(7)==7,"tier 2 tree HP rose before the regeneration pressure became visible")

ordinary=mode:scoreActiveTreeCount()
mode.scoreTreeAllowance=ordinary+1
assert(not mode:checkScoreOvercrowding(game),"score mode ended below its tree allowance")
nodes[#nodes+1]={rushTree=true,active=true,giantTree=false}
assert(mode:checkScoreOvercrowding(game)and game.mode=="clearcut_results","reaching the active-tree allowance did not end the run")
assert(game.result.scoreAttack and game.result.victory and game.result.failureReason=="score_overcrowded","score result omitted the overcrowding cause")
assert(game.result.treeAllowance==ordinary+1 and game.result.peakActiveTrees>=ordinary+1 and game.result.peakTreesPerSecond>=5,"score result omitted capacity metrics")
assert(game.result.woodSpent==nil and game.result.automation==nil,"removed automation build leaked into score results")

game:startClearcutScoreAttack()
assert(game.clearcut.scoreRegenTier==2 and math.abs(game.clearcut:scoreTreeSpawnRate()-(.14*1.75))<.001,"next run did not start from the permanently unlocked tier")

game.clearcut.scoreRegenTier=6
assert(math.abs(game.clearcut:scoreTreeSpawnRate()-(.14*1.75^5))<.001,"late regeneration curve is not supply-led")
assert(game.clearcut:scoreTreeHealth(7)==8,"late tree HP curve is missing its restrained increase")
assert(game.clearcut:scoreTreeSpawnRate()/.14>9 and game.clearcut:scoreTreeHealth(7)/7<1.2,"difficulty did not prioritize regeneration over tree HP")

Traits.data.regenTier=1
game:startClearcutScoreAttack()
mode=assert(game.clearcut)
local unattendedEnd
for second=1,90 do
    mode.stageElapsed=second
    if mode:updateScoreTreeGrowth(1,game)then unattendedEnd=second;break end
end
assert(unattendedEnd and unattendedEnd>=18 and unattendedEnd<=26 and mode.scoreCollapseActive,
    "a losing tier-1 run did not trigger forest collapse and end quickly")

Traits.data.levels.universal_yard=7
Traits.data.levels.universal_robot_start=1
Traits.data.levels.universal_robot_motor=5
Traits.data.levels.universal_mole_companion=1
Traits.data.levels.universal_mole_damage=3;Traits.data.levels.universal_mole_speed=3
Traits.data.levels.universal_mole_attack_speed=3;Traits.data.levels.universal_mole_claw=2
Traits.data.levels.universal_mole_dual=1;Traits.data.levels.universal_mole_extra=2
for _,id in ipairs({"fire_score_prewarm","fire_score_filter","fire_score_lighter","fire_score_spark","fire_score_launch","fire_score_ash","fire_score_drag","fire_score_heat"})do Traits.data.levels[id]=5 end
Traits.data.levels.fire_score_stock=1
game:startClearcutScoreAttack()
assert(game.clearcut.scoreTreeAllowance==40,"max permanent yard expansion did not raise the runtime allowance to 40")
assert(game.clearcut.permanentTraits.range==80 and game.clearcut.permanentTraits.area==60 and game.clearcut.permanentTraits.extraFires==1,"score-only permanent smoker traits were not applied at runtime")
assert(game.clearcut.permanentTraits.attackSpeed==1.2 and game.clearcut.permanentTraits.burnSpeed==1.3 and game.clearcut.permanentTraits.cigaretteProjectileSpeed==1.35,"score-only pacing traits were not applied at runtime")
assert(game.clearcut:levelOf("molotov")==0 and game.clearcut:levelOf("dry_forest")==0 and game.clearcut:levelOf("straw_bale")==0 and game.clearcut:levelOf("smoke_ring")==0 and game.clearcut:levelOf("oil_drum")==0,"permanent traits still injected whole in-game skill levels")
assert(game.clearcut:levelOf("baby_robot")==1 and game.clearcut.permanentTraits.scoreRobotSpeed==.5,"baby robot permanent research was not applied at runtime")
assert(game.clearcut.moleCompanion and game.clearcut.permanentTraits.scoreMoleCompanion==1,"mole companion hire node was not applied at runtime")
assert(#game.clearcut.moleCompanions==3,"two additional companion nodes did not deploy three moles")
local mole=game.clearcut.moleCompanion
assert(mole.damage==5 and math.abs(mole.speed-292.5)<1e-9 and mole.attackDuration<.46 and
    mole.clawLevel==5 and mole.attackReach==140 and mole.dualClaw,"split mole damage, movement, attack-speed and claw upgrades were not applied")
local claimed={}
for _,companion in ipairs(game.clearcut.moleCompanions)do
    local target=game.clearcut:findMoleCompanionTree(companion,game)
    assert(target and not claimed[target],"additional mole companions did not split up across distinct trees")
    claimed[target]=true
end
local moleTree
for _,node in ipairs(game.world.nodes)do if node.rushTree and node.active and not node.giantTree then moleTree=node;break end end
assert(moleTree,"mole companion test has no active tree")
mole.x,mole.y=moleTree.x-96,moleTree.y
mole.target=moleTree;mole.state="seek"
local moleHp=moleTree.rushHp
game.clearcut:updateOneMoleCompanion(mole,.01,game)
assert(mole.state=="attack"and mole.facing==1,"mole companion did not independently acquire and face a tree")
game.clearcut:updateOneMoleCompanion(mole,.25,game)
assert((not moleTree.active)or moleTree.rushHp<moleHp,"mole companion claw contact frame did not damage its target tree")
assert(#game.clearcut.minerClawFx==1,"mole companion did not produce one authored claw contact effect")
assert(game.clearcut.minerClawFx[1].level==5 and game.clearcut.minerClawFx[1].dual,
    "max-rank mole companion did not use the large two-handed claw effect")
assert(game.clearcut.totalWood==0 and game.clearcut.level==1 and game.clearcut.pending==0,"score run did not start with a clean wood-XP progression")
assert(game.clearcut.smoking and game.clearcut.smoking.dur<.75,"first ignition preparation trait did not shorten the opening load")
game.clearcut:hurlMolotovAt(game.player.x+600,game.player.y,game)
assert(#game.clearcut.molotovs==2 and game.clearcut.molotovs[1].approachDur<.5,"projectile-speed/additional-butt traits are not live")
game.clearcut.molotovs={}
local deliveredBefore=game.clearcut.totalWood
local carriedBefore=game.player.wood
game.world:updateHelpers(0,game)
local idleRobot=game.world.helpers[1]
idleRobot.x,idleRobot.y=game.player.x+700,game.player.y+500
game.world.drops={}
game.world:updateHelpers(1,game)
assert(idleRobot.x==game.player.x+700 and idleRobot.y==game.player.y+500,"score robot still follows the player while idle")
game.world.drops={{kind="wood",amount=1,x=game.player.x+1800,y=game.player.y+500,height=0,vx=0,vy=0,vz=0,magnet=false}}
local beforeDispatchX=idleRobot.x
game.world:updateHelpers(1,game)
assert(idleRobot.target==game.world.drops[1] and idleRobot.x>beforeDispatchX,"score robot did not dispatch to map-wide wood")
for _=1,900 do game.world:updateHelpers(1/60,game)end
assert(#game.world.helpers==1 and #game.world.drops==0 and game.clearcut.totalWood==deliveredBefore+1,"baby robot did not convert a landed wood drop into wood XP")
assert(game.player.wood==carriedBefore and game.world.helpers[1].carrying==nil,"baby robot incorrectly carried wood back to the player")
game.clearcut.levels.baby_robot=3
game.world:updateHelpers(1/60,game)
assert(#game.world.helpers==2,"baby robot level scaling did not add a second carrier")
local r1,r2=game.world.helpers[1],game.world.helpers[2]
game.world.drops={{kind="wood",amount=1,x=r1.x+900,y=r1.y,height=0},{kind="wood",amount=1,x=r1.x-900,y=r1.y,height=0}}
r1.target,r2.target=nil,nil
game.world:updateHelpers(1/60,game)
assert(r1.target and r2.target and r1.target~=r2.target,"multiple score robots were dispatched to the same wood")

-- Tree variants become distinct lumber and are paid only by the animated result settlement.
local settleMode=require("src.clearcut_mode").new();settleMode.scoreAttack=true;settleMode.sandbox=true;settleMode.mapId="forest";settleMode.job="fire"
local speciesTree={active=true,rushTree=true,treeVariant=3,x=game.player.x+20,y=game.player.y,rushHp=0}
settleMode:fellTree(speciesTree,game)
assert(settleMode.lumberInventory.birch==1,"felled tree variant did not enter its species lumber inventory")
settleMode.lumberInventory={broadleaf=2,birch=3};settleMode.treesFelled=5;settleMode.initialTrees=6
settleMode.scoreStartingRegenTier=1;settleMode.scoreRegenTier=1;settleMode.scoreHighestRegenTier=1
game.result=nil;game.ended=false;game.achievements=nil
local coinsBefore=Traits.data.currency
settleMode:finish(game,true)
assert(#game.result.lumberRows==2 and game.result.lumberCoinTotal==8,"species lumber did not retain its distinct coin values")
assert(Traits.data.currency==coinsBefore and game.result.traitEarned==0,"result coins were granted before the visible settlement")
settleMode:updateResults(.35,game);settleMode:updateResults(.15,game)
assert(game.result.traitEarned>0 and game.result.traitEarned<8,"sequential settlement did not begin one unit at a time")
settleMode:completeResultSettlement(game)
assert(Traits.data.currency==coinsBefore+8 and game.result.traitEarned==8 and settleMode.resultSettlement.complete,"skipping result settlement lost or duplicated coins")
local completedVisualTime=settleMode.resultSettlement.elapsed
settleMode.resultSettlement.bursts={{t=.44,dur=.48,rowIndex=1,seed=1}}
settleMode:updateResults(.12,game)
assert(settleMode.resultSettlement.elapsed>completedVisualTime and #settleMode.resultSettlement.bursts==0,"completed settlement froze its coin animation clock or final transfer burst")
print("SCORE_ATTACK_MODE_OK start=6 persistent_regen_tier wood_xp=operations combat=permanent")
