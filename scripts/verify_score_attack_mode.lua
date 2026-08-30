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
assert(mode.scoreTreeAllowance==12,"fresh score mode did not use the 12-tree base allowance")
assert(#game.world.nodes==6 and mode:scoreActiveTreeCount()==6 and mode.totalTreesSpawned==6,"score mode did not start with exactly six active trees")
assert(mode.remainingTrees==6 and mode.initialTrees==6 and mode.peakActiveTrees==6,"starting score trees were not included in occupancy metrics")
assert(not mode:checkWorldTreeSpawn(game),"opening score field incorrectly summoned the world tree")
assert(mode.scoreRegenTier==1 and math.abs(mode:scoreTreeSpawnRate()-.14)<.001,"opening forest did not use saved regeneration tier 1")
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
assert(#scorePool==6,"score mode did not expose exactly six operation cards")
for _,def in ipairs(scorePool)do assert(def.scoreOperation and not def.job,"combat skill leaked into the operation draft: "..def.id)end
assert(mode:getUpgradeDefinition("baby_robot").scoreOperation==true,"baby robot is not marked as a score operation")

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
assert(mode.currentTreesPerSecond==5 and math.abs(mode:scoreTreeSpawnRate()-.14)<.001,"recent logging output incorrectly changed tier-based regeneration")

local pending=mode.pending
game.mode="test"
mode:onWood(10,game)
assert(mode.pending==pending+1 and mode.level==2 and mode.scoreWoodEarned==10,"score wood did not feed the normal level-up queue")
mode:rollChoices()
assert(#mode.choices==3,"score level-up did not roll exactly three choices")
for _,choice in ipairs(mode.choices)do assert(choice.id~="forest_expansion","removed forest automation card returned")end
for _,choice in ipairs(mode.choices)do assert(choice.scoreOperation and not choice.job,"score draft offered a combat card: "..choice.id)end
assert(mode.buyScoreAutomation==nil and mode.updateScoreAutomation==nil,"removed automation runtime methods remain")
game.mode="playing"

-- Clearing every active tree advances and immediately persists the regeneration tier;
-- it must not open a card because cards are still earned only through wood XP.
for _,node in ipairs(nodes)do if node.rushTree and node.active and not node.giantTree then node.active=false end end
mode.remainingTrees=0
local pendingBeforeTier=mode.pending
assert(mode:updateScoreTierClear(.31,game),"empty forest did not trigger a regeneration transition")
assert(mode.scoreRegenTier==2 and Traits:getRegenTier()==2 and mode.pending==pendingBeforeTier,"tier clear was not persisted or incorrectly granted a card")
assert(mode:scoreActiveTreeCount()==6 and math.abs(mode:scoreTreeSpawnRate()-(.14*1.45))<.001,"tier 2 did not reseed six trees at the tier rate")

ordinary=mode:scoreActiveTreeCount()
mode.scoreTreeAllowance=ordinary+1
assert(not mode:checkScoreOvercrowding(game),"score mode ended below its tree allowance")
nodes[#nodes+1]={rushTree=true,active=true,giantTree=false}
assert(mode:checkScoreOvercrowding(game)and game.mode=="clearcut_results","reaching the active-tree allowance did not end the run")
assert(game.result.scoreAttack and game.result.victory and game.result.failureReason=="score_overcrowded","score result omitted the overcrowding cause")
assert(game.result.treeAllowance==ordinary+1 and game.result.peakActiveTrees>=ordinary+1 and game.result.peakTreesPerSecond>=5,"score result omitted capacity metrics")
assert(game.result.woodSpent==nil and game.result.automation==nil,"removed automation build leaked into score results")

game:startClearcutScoreAttack()
assert(game.clearcut.scoreRegenTier==2 and math.abs(game.clearcut:scoreTreeSpawnRate()-(.14*1.45))<.001,"next run did not start from the permanently unlocked tier")

Traits.data.regenTier=1
game:startClearcutScoreAttack()
mode=assert(game.clearcut)
local unattendedEnd
for second=1,90 do
    mode.stageElapsed=second
    if mode:updateScoreTreeGrowth(1,game)then unattendedEnd=second;break end
end
assert(unattendedEnd and unattendedEnd>=38 and unattendedEnd<=50,"six-tree unattended run did not end near the tier-1 supply window")

Traits.data.levels.universal_yard=7
Traits.data.levels.universal_robot_start=1
Traits.data.levels.universal_robot_motor=5
for _,id in ipairs({"fire_score_prewarm","fire_score_filter","fire_score_lighter","fire_score_ash","fire_score_drag","fire_score_heat"})do Traits.data.levels[id]=5 end
game:startClearcutScoreAttack()
assert(game.clearcut.scoreTreeAllowance==40,"max permanent yard expansion did not raise the runtime allowance to 40")
assert(game.clearcut.permanentTraits.range==60 and game.clearcut.permanentTraits.area==50 and game.clearcut.permanentTraits.treeDamage==2.5,"score-only permanent smoker research was not applied at runtime")
assert(game.clearcut:levelOf("molotov")==5 and game.clearcut:levelOf("dry_forest")==5 and game.clearcut:levelOf("straw_bale")==5 and game.clearcut:levelOf("smoke_ring")==5 and game.clearcut:levelOf("oil_drum")==5,"former run combat cards did not start at their permanent research levels")
assert(game.clearcut:levelOf("baby_robot")==1 and game.clearcut.permanentTraits.scoreRobotSpeed==.5,"baby robot permanent research was not applied at runtime")
assert(game.clearcut.totalWood==0 and game.clearcut.level==1 and game.clearcut.pending==0,"score run did not start with a clean wood-XP progression")
assert(game.clearcut.smoking and game.clearcut.smoking.dur<.75,"first ignition preparation trait did not shorten the opening load")
local deliveredBefore=game.clearcut.totalWood
local carriedBefore=game.player.wood
game.world.drops={{kind="wood",amount=1,x=game.player.x+300,y=game.player.y,height=0,vx=0,vy=0,vz=0,magnet=false}}
for _=1,300 do game.world:updateHelpers(1/60,game)end
assert(#game.world.helpers==1 and #game.world.drops==0 and game.clearcut.totalWood==deliveredBefore+1,"baby robot did not convert a landed wood drop into wood XP")
assert(game.player.wood==carriedBefore and game.world.helpers[1].carrying==nil,"baby robot incorrectly carried wood back to the player")
game.clearcut.levels.baby_robot=3
game.world:updateHelpers(1/60,game)
assert(#game.world.helpers==2,"baby robot level scaling did not add a second carrier")
print("SCORE_ATTACK_MODE_OK start=6 persistent_regen_tier wood_xp=operations combat=permanent")
