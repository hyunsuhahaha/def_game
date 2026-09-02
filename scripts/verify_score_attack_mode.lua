package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
love.graphics.rotate=love.graphics.rotate or function()end
love.graphics.getDimensions=function()return 1280,720 end
love.graphics.getWidth=function()return 1280 end
love.graphics.getHeight=function()return 720 end
love.mouse={getPosition=function()return -100,-100 end,isDown=function()return false end}
local heldKeys={}
love.keyboard={isDown=function(...)
    for index=1,select("#",...)do if heldKeys[select(index,...)]then return true end end
    return false
end}

local Game=require("src.game")
local World=require("src.world")
local Player=require("src.player")
local Camera=require("src.camera")
local Traits=require("src.character_traits").new(true)
Traits.data.scoreTutorialSeen=true -- This suite verifies ordinary score runs, not onboarding.
local WoodEconomy=require("src.wood_economy")
local function expectedSpawn(tier,seconds)return .14*1.75^(tier-1)*2^(seconds/20)end

assert(WoodEconomy.researchCoinMultiplier==2,"global research-coin reward multiplier drifted")
for _,mapId in ipairs({"forest","mangrove","madagascar","island"})do
    local inventory={}
    for _,def in ipairs(WoodEconomy.catalog(mapId))do inventory[def.id]=1 end
    local rows,total=WoodEconomy.settlement(mapId,inventory);local expected=0
    for index,def in ipairs(WoodEconomy.catalog(mapId))do
        expected=expected+def.coin*2
        assert(rows[index].coin==def.coin*2,mapId.." lumber did not receive the global 2x research-coin reward")
    end
    assert(total==expected,mapId.." doubled research-coin total is incorrect")
end

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
assert(mode.xp==0 and mode.xpNext==0 and mode.level==1 and mode.pending==0,
    "score mode still initialized an in-run level-up track")
assert(game:grantTestLevels(20)==0 and mode.level==1 and mode.pending==0,
    "developer level grant reopened score-mode upgrades")
assert(#game.world.nodes==6 and mode:scoreActiveTreeCount()==6 and mode.totalTreesSpawned==6,"score mode did not start with exactly six active trees")
assert(mode.remainingTrees==6 and mode.initialTrees==6 and mode.peakActiveTrees==6,"starting score trees were not included in occupancy metrics")
assert(not mode:checkWorldTreeSpawn(game),"opening score field incorrectly summoned the world tree")
assert(mode.scoreRegenTier==1 and math.abs(mode:scoreTreeSpawnRate()-.14)<.001,"opening forest did not use saved regeneration tier 1")
assert(mode:scoreTimePressureMultiplier()==1,"time pressure was not neutral at run start")
assert(mode:scoreTreeHealth(7)==7,"tier 1 altered ordinary tree health")
local fonts={big=love.graphics.newFont(30),micro=love.graphics.newFont(11),small=love.graphics.newFont(14),body=love.graphics.newFont(18),display=love.graphics.newFont(34)}
fixture.reset();mode:drawHUD(game,fonts)
local lockedAmmoIcons=0
for _,command in ipairs(fixture.commands)do
    assert(command.op~="text"or not command.text:find("SPACE",1,true),"locked dash leaked a SPACE hint into the score HUD")
    if command.op=="ellipse"and command.args[1]>1200 then lockedAmmoIcons=lockedAmmoIcons+1 end
end
assert(lockedAmmoIcons>0,"locking dash also hid the smoker ammo HUD")
assert(not mode:activateSmokerDash(game),"smoker dashed before buying the research node")
mode.permanentTraits.scoreDashUnlock=1
fixture.reset();mode:drawHUD(game,fonts)
if os.getenv("DASH_HUD_CAPTURE")then fixture.save(os.getenv("DASH_HUD_CAPTURE"))end
local dashPixels=0
for _,command in ipairs(fixture.commands)do
    assert(command.op~="text"or(not command.text:find("SPACE",1,true)and not command.text:find("대시",1,true)),
        "dash HUD used a text prompt instead of the bottom icon")
    if command.op=="rectangle"and command.args[2]>650 and command.color[1]==.55 and command.color[2]==.9 then dashPixels=dashPixels+1 end
end
assert(dashPixels>0,"unlocked dash did not draw its ready icon at the bottom of the HUD")
heldKeys.d=true
local dashStartX=game.player.x
assert(mode:activateSmokerDash(game),"unlocked smoker dash did not start")
mode:updateSmokerDash(.25,game)
assert(not mode.smokerDash and game.player.x>dashStartX+180 and mode.smokerDashCooldown>0,
    "smoker dash did not travel its full distance or start cooldown")
assert(not mode:activateSmokerDash(game),"smoker dash ignored its cooldown")
mode.smokerDashCooldown=0
mode.permanentTraits.scoreDashDistance=130
assert(mode:activateSmokerDash(game)and mode.smokerDash.remaining==320,
    "dash-distance research did not extend the runtime dash from 190 to 320")
mode:updateSmokerDash(.4,game)
heldKeys.d=nil
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
assert(#mode.enemies==0,"score mode spawned a roaming monster after the opening grace")
mode.stageElapsed=600
mode:updateTimeSpawner(600,game)
assert(#mode.enemies==0,"score mode spawned a roaming monster during a long run")
local berserkBefore,vinesBefore=mode.berserkTimer,mode.vinePlantTimer
mode:updateBerserk(999,game);mode:updateVinePlants(999,game)
assert(mode.berserkTimer==berserkBefore and mode.vinePlantTimer==vinesBefore,"normal-stage threat systems remained active in score mode")
-- 재해는 통째로 꺼져 있었으나 이제 비만 돈다. 비는 피해를 주지 않고 불만 끊으므로
-- 위협 시스템이 아니라 무기 독점을 푸는 장치다. 지속·상세는 verify_score_rain.lua.
mode:updateDisasters(1,game)
assert(mode.disasterType==nil or mode.disasterType=="rain","기록 모드에 비 이외의 재해가 들어왔다")
assert(mode.scoreRainReady,"기록 모드 재해가 캠페인 경로로 흘렀다")

local scorePool=mode:upgradePool()
assert(#scorePool==0,"score mode still exposes in-run upgrade choices")
assert(mode:getUpgradeDefinition("baby_robot").scoreOperation==true,"baby robot is not marked as a score operation")
-- 보존된 정의는 일반 작전/샌드박스 복구용일 뿐 활성 기록 모드 후보에는 들어가지 않는다.
for _,id in ipairs({"score_attack_speed","score_weapon_damage","score_weapon_area","score_weapon_range"})do
    assert(mode:getUpgradeDefinition(id).scoreOperation==true,"preserved score card definition disappeared: "..id)
end
for _,id in ipairs({"score_extra_butts","score_ignition_radius","score_burn_speed"})do
    assert(mode:getUpgradeDefinition(id)==nil,"weapon-specific combat card is back in the run draft: "..id)
end
local hpBefore=mode.hp
game.mode="playing"
mode:damagePlayer(9999,game)
assert(mode.hp==hpBefore and not mode.dead and game.mode=="playing","score mode still has player HP damage or death")

-- 과거 테스트/저장 상태가 선택 대기열을 들고 있어도 기록 모드는 즉시 폐기한다.
local maxed=require("src.clearcut_mode").new();maxed.scoreAttack=true;maxed.job="fire"
maxed.pending,maxed.xp,maxed.level,maxed.totalWood,maxed.scoreWoodEarned=7,4,31,0,0
game.mode="playing"
maxed:openUpgradeChoices(game)
assert(game.mode=="playing"and maxed.pending==0 and #maxed.choices==0,"stale score draft still opened a level-up screen")
maxed:onWood(100,game)
assert(maxed.level==31 and maxed.pending==0 and maxed.xp==0 and maxed.totalWood==100 and maxed.scoreWoodEarned==100,
    "disabled score draft generated prompts or stopped counting wood")
maxed.choices={{id="yard_management"}};maxed.pending=2;game.mode="clearcut_upgrade"
assert(maxed:openUpgradeChoices(game)==false and game.mode=="playing"and maxed.pending==0 and #maxed.choices==0,
    "score mode did not force-close a legacy upgrade screen")
local chestWood=maxed.totalWood
assert(maxed:openChest(game)==false and game.mode=="playing"and maxed.totalWood==chestWood+40 and #maxed.choices==0,
    "score chest reopened an upgrade/fusion selection instead of becoming score wood")
maxed.levels.molotov,maxed.levels.dry_forest=6,6
assert(not maxed:checkEvolutions(game)and maxed:openBranchChoice("molotov",game)==false and game.mode=="playing",
    "score mode still opened a branch or fusion choice through a legacy skill state")
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
mode.stageElapsed=20
assert(mode.SCORE_TIME_DOUBLING_SECONDS==20 and math.abs(mode:scoreTimePressureMultiplier()-2)<.001,
    "time pressure did not double every 20 seconds")
mode.stageElapsed=60
assert(math.abs(mode:scoreTimePressureMultiplier()-8)<.001,
    "one-minute time pressure is not eight times the starting rate")
mode.stageElapsed=90

game.mode="test"
mode:onWood(5,game)
assert(mode.pending==0 and mode.level==1 and mode.xp==0 and mode.xpNext==0 and mode.scoreWoodEarned==5,
    "score wood still generated XP or a level-up prompt")
mode:rollChoices()
assert(#mode.choices==0,"score mode rolled choices after in-run upgrades were disabled")
assert(mode.buyScoreAutomation==nil and mode.updateScoreAutomation==nil,"removed automation runtime methods remain")
game.mode="playing"

-- Clearing every active tree persists the tier immediately, then holds the world for
-- the authored transition before six trees rise in a staggered sequence.
for _,node in ipairs(nodes)do if node.rushTree and node.active and not node.giantTree then node.active=false end end
mode.remainingTrees=0
local abandonedWorldTree={scoreWorldTree=true,hp=50};mode.scoreWorldTree=abandonedWorldTree
mode.enemies[#mode.enemies+1]=abandonedWorldTree
local pendingBeforeTier=mode.pending
assert(mode:updateScoreTierClear(.31,game),"empty forest did not trigger a regeneration transition")
assert(mode.scoreRegenTier==2 and Traits:getRegenTier()==2 and mode.pending==pendingBeforeTier,"tier clear was not persisted or incorrectly granted a card")
assert(mode.stageElapsed==0 and mode.scoreWorldTreeTimer==mode.ScoreWorldTree.INTERVAL,
    "empty-forest tier up did not reset stage time and world-tree survival timer")
assert(not mode.scoreWorldTree and mode.enemies[#mode.enemies]~=abandonedWorldTree,
    "empty-forest tier up left a world tree that could grant a duplicate tier")
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
assert(not mode.scoreTierFx and math.abs(mode:scoreTreeSpawnRate()-expectedSpawn(2,0))<.001,
    "tier transition did not restart elapsed-time pressure at the new tier")
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

game:openScoreTierSelect()
assert(game.mode=="score_tier_select"and game.scoreTierChoice==2 and game.scoreTierMax==2,
    "score entry did not default the selector to the highest cleared regeneration tier")
game:setScoreTierChoice(1);game:startClearcutScoreAttack(game.scoreTierChoice)
assert(game.clearcut.scoreStartingRegenTier==1 and game.clearcut.scoreRegenTier==1 and Traits:getRegenTier()==2,
    "choosing an earlier start tier changed the unlocked tier or started at the wrong difficulty")
game:retryClearcut()
assert(game.clearcut.scoreStartingRegenTier==1,"retry did not preserve the selected starting regeneration tier")
game:startClearcutScoreAttack()
assert(game.clearcut.scoreRegenTier==2,"direct score start no longer defaults to the highest unlocked tier")

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

for _,id in ipairs({"universal_yard","fire_score_yard_2","universal_yard_3","fire_score_yard_4",
    "universal_yard_5","fire_score_yard_6","fire_score_yard_7"})do Traits.data.levels[id]=1 end
for _,id in ipairs({"fire_score_capacity_4","universal_capacity_5","fire_score_capacity_6",
    "universal_capacity_7","fire_score_capacity_8","universal_capacity_9"})do Traits.data.levels[id]=1 end
Traits.data.levels.universal_veteran_yard=4
for _,id in ipairs({"universal_stride","fire_score_stride_2","universal_stride_3","fire_score_stride_4"})do Traits.data.levels[id]=1 end
for _,id in ipairs({"fire_score_view_1","universal_view_2","fire_score_view_3","universal_view_4"})do Traits.data.levels[id]=1 end
Traits.data.levels.universal_robot_start=1
Traits.data.levels.universal_robot_motor=5
Traits.data.levels.universal_mole_companion=1
Traits.data.levels.universal_mole_damage=3;Traits.data.levels.universal_mole_speed=3
Traits.data.levels.universal_mole_attack_speed=3;Traits.data.levels.universal_mole_claw=2
Traits.data.levels.universal_mole_dual=1;Traits.data.levels.universal_mole_extra=2
Traits.data.levels.universal_mole_burrow=1;Traits.data.levels.universal_mole_burrow_speed=3
Traits.data.levels.universal_mole_burrow_damage=3;Traits.data.levels.universal_mole_burrow_cooldown=3
for _,id in ipairs({"fire_score_prewarm","fire_score_filter","fire_score_lighter","fire_score_spark","fire_score_launch","fire_score_ash","fire_score_drag","fire_score_heat"})do Traits.data.levels[id]=5 end
Traits.data.levels.fire_score_stock=1
game:startClearcutScoreAttack()
assert(game.clearcut.scoreTreeAllowance==100,"max permanent forest-capacity research did not raise the runtime allowance to 100")
assert(math.abs(game.world.clearcutMapScale-.875)<1e-9 and game.world.width==2800,
    "distributed yard nodes did not expand the actual score map")
assert(math.abs(game.clearcut.baseSpeed-396.8)<1e-9,"distributed movement nodes did not preserve +24% runtime speed")
assert(math.abs(game.camera.zoom-(.84/1.1))<1e-9,"distributed view nodes did not expand the runtime camera view")
assert(game.clearcut.permanentTraits.range==80 and game.clearcut.permanentTraits.area==60 and game.clearcut.permanentTraits.extraFires==1,"score-only permanent smoker traits were not applied at runtime")
assert(game.clearcut.permanentTraits.attackSpeed==1.2 and game.clearcut.permanentTraits.burnSpeed==1.3 and game.clearcut.permanentTraits.cigaretteProjectileSpeed==1.35,"score-only pacing traits were not applied at runtime")
assert(game.clearcut:levelOf("molotov")==0 and game.clearcut:levelOf("dry_forest")==0 and game.clearcut:levelOf("straw_bale")==0 and game.clearcut:levelOf("smoke_ring")==0 and game.clearcut:levelOf("oil_drum")==0,"permanent traits still injected whole in-game skill levels")
assert(game.clearcut:levelOf("baby_robot")==1 and game.clearcut.permanentTraits.scoreRobotSpeed==.5,"baby robot permanent research was not applied at runtime")
assert(game.clearcut.moleCompanion and game.clearcut.permanentTraits.scoreMoleCompanion==1,"mole companion hire node was not applied at runtime")
assert(#game.clearcut.moleCompanions==3,"two additional companion nodes did not deploy three moles")
local mole=game.clearcut.moleCompanion
assert(mole.damage==5 and math.abs(mole.speed-292.5)<1e-9 and mole.attackDuration<.46 and
    mole.clawLevel==5 and mole.attackReach==140 and mole.dualClaw,"split mole damage, movement, attack-speed and claw upgrades were not applied")
assert(game.clearcut.permanentTraits.scoreMoleBurrow==1 and
    math.abs(game.clearcut.permanentTraits.scoreMoleBurrowSpeed-.36)<1e-9 and
    game.clearcut.permanentTraits.scoreMoleBurrowDamage==6 and game.clearcut.permanentTraits.scoreMoleBurrowCooldown==4.5,
    "mole burrow unlock and upgrades did not reach score runtime")
local claimed={}
local claimedTargets={}
for _,companion in ipairs(game.clearcut.moleCompanions)do
    local target=game.clearcut:findMoleCompanionTree(companion,game)
    assert(target and not claimed[target],"additional mole companions did not split up across distinct trees")
    for _,other in ipairs(claimedTargets)do
        local dx,dy=target.x-other.x,target.y-other.y
        assert(dx*dx+dy*dy>=240^2,"companions chose separate trees in the same crowded cluster")
    end
    claimed[target]=true
    claimedTargets[#claimedTargets+1]=target
end
local first,second=game.clearcut.moleCompanions[1],game.clearcut.moleCompanions[2]
local firstX,firstY,secondX,secondY,secondKind=first.x,first.y,second.x,second.y,second.kind
second.kind="lumberjack"
first.x,first.y,second.x,second.y=800,700,800,700
game.clearcut:separateMoleCompanions(game)
local splitX,splitY=first.x-second.x,first.y-second.y
assert(splitX*splitX+splitY*splitY>=80^2,"overlapping companions were not separated")
first.x,first.y,second.x,second.y,second.kind=firstX,firstY,secondX,secondY,secondKind
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
-- 큰 수관 표식은 시각 크기일 뿐 살아 있는 벌목 대상이다. 이것만 남아도 두더지가
-- 옆에서 멈추지 않고 찾아가 실제 피해를 줘야 한다.
local ordinaryNodes=game.world.nodes
local landmark={kind="tree",rushTree=true,active=true,giantTree=true,x=mole.x+96,y=mole.y,
    rushHp=50,rushMaxHp=50,treeVariant=1,respawn=math.huge}
game.world.nodes={landmark};mole.state,mole.target,mole.attackT,mole.struck="seek",nil,0,false
assert(game.clearcut:findMoleCompanionTree(mole,game)==landmark,"mole ignored a live giant-canopy tree")
game.clearcut:updateOneMoleCompanion(mole,.01,game)
game.clearcut:updateOneMoleCompanion(mole,.25,game)
assert(landmark.rushHp<50,"mole stood beside a giant-canopy tree without chopping it")
-- 공격 방향은 예외 없이 360도다. 상하좌우와 네 대각선에서 실제로 접근한 뒤
-- 같은 원형 사거리 판정으로 발톱 피해까지 들어가는지 모두 검사한다.
local centerX,centerY=game.world.width*.5,game.world.height*.5
for direction=0,7 do
    local angle=direction*math.pi/4
    local directionalTree={kind="tree",rushTree=true,active=true,x=centerX+math.cos(angle)*300,
        y=centerY+math.sin(angle)*300,rushHp=50,rushMaxHp=50,treeVariant=1,respawn=math.huge}
    game.world.nodes={directionalTree}
    mole.x,mole.y,mole.state,mole.target=centerX,centerY,"seek",nil
    mole.burrowCooldown=999
    for _=1,120 do game.clearcut:updateOneMoleCompanion(mole,.02,game)end
    assert(directionalTree.rushHp<50,"mole failed to attack direction "..direction)
end
-- 기존 플레이어 땅굴의 경로 자국·접촉·뿌리 투척을 두더지 AI가 가까운 나무를
-- 연속으로 찾아가며 사용한다.
local uprootTree={kind="tree",rushTree=true,active=true,x=centerX+170,y=centerY,
    rushHp=1,rushMaxHp=1,treeVariant=1,respawn=math.huge}
local tunnelTree={kind="tree",rushTree=true,active=true,x=centerX+340,y=centerY,
    rushHp=40,rushMaxHp=40,treeVariant=1,respawn=math.huge}
game.world.nodes={uprootTree,tunnelTree}
mole.x,mole.y,mole.state,mole.target=centerX,centerY,"seek",nil
mole.burrowCooldown=0;mole.burrowHit={}
local thrownBefore=#game.clearcut.thrownTrees
for _=1,100 do
    game.clearcut:updateOneMoleCompanion(mole,.02,game)
    if not uprootTree.active and tunnelTree.rushHp<40 then break end
end
assert(not uprootTree.active and uprootTree.uprooted and #game.clearcut.thrownTrees>thrownBefore,
    "mole AI burrow did not reuse the existing zero-HP tree launch")
assert(tunnelTree.rushHp<40 and mole.x>centerX+200,
    "mole AI burrow did not travel quickly through nearby trees and damage its path")
assert(#game.clearcut.burrowTracks>0,"mole AI burrow did not reuse the authored underground trail")
game.world.nodes=ordinaryNodes;mole.state,mole.target="seek",nil
mole.burrowCooldown=0
assert(game.clearcut.totalWood==0 and game.clearcut.level==1 and game.clearcut.xpNext==0 and game.clearcut.pending==0,
    "score run did not start with its in-run progression disabled")
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
assert(#game.world.helpers==1 and #game.world.drops==0 and game.clearcut.totalWood==deliveredBefore+1,"baby robot did not convert a landed wood drop into score wood")
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
assert(settleMode.lumberInventoryByTier[1].birch==1,"felled tree did not remember the regeneration tier where it was earned")
settleMode.lumberInventory={broadleaf=2,birch=3};settleMode.treesFelled=5;settleMode.initialTrees=6
settleMode.lumberInventoryByTier={[1]={broadleaf=2,birch=3}}
settleMode.scoreStartingRegenTier=1;settleMode.scoreRegenTier=1;settleMode.scoreHighestRegenTier=1
game.result=nil;game.ended=false;game.achievements=nil
local coinsBefore=Traits.data.currency
settleMode:finish(game,true)
assert(#game.result.lumberRows==2 and game.result.lumberRows[1].coin==2 and game.result.lumberRows[2].coin==4 and game.result.lumberCoinTotal==16,
    "research-coin settlement did not double every species value")
assert(Traits.data.currency==coinsBefore and game.result.traitEarned==0,"result coins were granted before the visible settlement")
settleMode:updateResults(.35,game);settleMode:updateResults(.15,game)
assert(game.result.traitEarned>0 and game.result.traitEarned<16,"sequential settlement did not begin one unit at a time")
settleMode:completeResultSettlement(game)
assert(Traits.data.currency==coinsBefore+16 and game.result.traitEarned==16 and settleMode.resultSettlement.complete,"skipping result settlement lost or duplicated doubled coins")
local completedVisualTime=settleMode.resultSettlement.elapsed
settleMode.resultSettlement.bursts={{t=.44,dur=.48,rowIndex=1,seed=1}}
settleMode:updateResults(.12,game)
assert(settleMode.resultSettlement.elapsed>completedVisualTime and #settleMode.resultSettlement.bursts==0,"completed settlement froze its coin animation clock or final transfer burst")

-- 대량 목재는 한 개씩 수백 번 세지 않고 묶음 단위로 정산해 몇 초 안에 끝낸다.
local bulkMode=require("src.clearcut_mode").new();bulkMode.scoreAttack=true;bulkMode.mapId="forest"
bulkMode.lumberInventory={broadleaf=130,pine=110,birch=125,maple=132};bulkMode.treesFelled=497
bulkMode.lumberInventoryByTier={[1]=bulkMode.lumberInventory}
bulkMode.scoreStartingRegenTier=1;bulkMode.scoreRegenTier=1;bulkMode.scoreHighestRegenTier=1
game.result=nil;game.ended=false
local bulkCoinsBefore=Traits.data.currency
bulkMode:finish(game,true)
local bulkExpected=130*2+110*2+125*4+132*4
for _=1,240 do bulkMode:updateResults(1/60,game)end
assert(bulkMode.resultSettlement.complete and game.result.traitEarned==bulkExpected and Traits.data.currency==bulkCoinsBefore+bulkExpected,
    "bulk lumber settlement did not finish within four seconds or lost coins")
-- 실측 공급량 증가와 합쳐 판당 총수입이 단계마다 약 2.6배가 되도록, 목재 단가는
-- 획득 당시 재생 단계마다 1.44배씩 오른다.
assert(math.abs(WoodEconomy.tierMultiplier(1)-1)<1e-9,"1단계 배수가 1이 아니다 - 초반 밸런스가 바뀐다")
assert(math.abs(WoodEconomy.tierMultiplier(6)-1.44^5)<1e-9,"6단계 목재 배수가 기하급수로 오르지 않는다")
assert(math.abs(WoodEconomy.tierMultiplier(8)-1.44^7)<1e-9,"8단계 목재 배수가 실측 1.6만 목표와 맞지 않는다")
assert(math.abs(WoodEconomy.tierMultiplier(10)-1.44^9)<1e-9,"10단계 목재 배수가 기하급수로 오르지 않는다")
local plainRows,plainTotal=WoodEconomy.settlement("forest",{broadleaf=10},1,1)
local richRows,richTotal,richMul=WoodEconomy.settlement("forest",{broadleaf=10},10,10)
assert(richTotal>plainTotal and math.abs(richMul-WoodEconomy.tierMultiplier(10))<.06,"높은 단계에서 목재 수입이 오르지 않는다")
local rowSum=0
for _,row in ipairs(richRows)do rowSum=rowSum+row.count*row.coin end
assert(rowSum==richTotal,"행 단가 합계와 총액이 어긋난다 - 정산 연출이 총액과 맞지 않는다")
assert(#richRows==#plainRows+1 and richRows[#richRows].bonus,"재생 단계 보너스가 별도 행으로 보이지 않는다")
-- 배수를 개당 코인에 곱하면 정수 반올림에 먹혀 2단계 수입이 1단계와 같아졌다.
local _,t1=WoodEconomy.settlement("forest",{broadleaf=100},1,1)
local _,t2=WoodEconomy.settlement("forest",{broadleaf=100},2,2)
assert(t2>t1,"2단계 수입이 1단계와 같다 - 배수가 반올림에 먹히고 있다")

-- 시작 단계를 가격에 섞지 않는다. 같은 8단계 목재는 1단계에서 밀고 올라왔든
-- 8단계에서 시작했든 같은 금액이고, 일찍 번 목재는 나중 단계 가격으로 소급되지 않는다.
local _,pushedTier8=WoodEconomy.settlementByTier("forest",{[8]={broadleaf=100}},8)
local _,startedTier8=WoodEconomy.settlement("forest",{broadleaf=100},8,8)
assert(pushedTier8==startedTier8,"같은 8단계 목재가 시작 단계에 따라 다른 가격을 받는다")
local _,mixedTotal=WoodEconomy.settlementByTier("forest",{[1]={broadleaf=100},[8]={broadleaf=100}},8)
assert(mixedTotal==t1+startedTier8,"초반에 번 목재가 최고 도달 단계 가격으로 소급 정산됐다")

print("SCORE_ATTACK_MODE_OK start=6 persistent_regen_tier run_upgrades=disabled combat=permanent companions=spaced")
