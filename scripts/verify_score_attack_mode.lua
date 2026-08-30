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
assert(#game.world.nodes==0 and mode:scoreActiveTreeCount()==0 and mode.totalTreesSpawned==0,"score mode did not start on empty ground")
assert(not mode:checkWorldTreeSpawn(game),"empty score field incorrectly summoned the world tree")
assert(math.abs(mode:scoreTreeSpawnRate()-.16)<.001,"opening forest supply was not reduced to the new low rate")

mode:updateScoreTreeGrowth(7,game)
assert(mode:scoreActiveTreeCount()>0 and mode.totalTreesSpawned>0,"adaptive forest supply did not begin growing trees")
for _,node in ipairs(game.world.nodes)do
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

local sample=game.world.nodes[1];local baseHp=sample.scoreBaseHp;sample.rushHp=math.max(1,math.floor(sample.rushMaxHp/2))
mode.levels.forest_expansion=2
mode:syncScoreTreeHealth(game)
assert(mode:scoreForestDensityMultiplier()==1.5 and sample.rushMaxHp==math.ceil(baseHp*1.5),"forest expansion did not scale supply and tree health proportionally")
assert(sample.rushHp/sample.rushMaxHp>.35 and sample.rushHp/sample.rushMaxHp<.7,"forest expansion did not preserve existing damage ratio")
mode.levels.forest_expansion=0;mode:syncScoreTreeHealth(game)
assert(#mode:upgradePool()==0,"random level-up cards remained enabled in score mode")
mode.scoreAttack=false
for _,def in ipairs(mode:upgradePool())do assert(def.id~="forest_expansion","score-only forest expansion leaked into normal stages")end
mode.scoreAttack=true

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
assert(mode.currentTreesPerSecond==5 and mode:scoreTreeSpawnRate()>=5.4,"adaptive supply did not follow recent logging output")

local pending=mode.pending
mode:onWood(999,game)
assert(mode.pending==pending and mode.xp==0 and mode.scoreWoodEarned==999,"score wood still opened random level-up cards")
local beforeFlights=#mode.molotovs
assert(mode:buyScoreAutomation("butt_launcher",game),"automatic butt launcher purchase failed")
assert(mode:buyScoreAutomation("straw_feeder",game)and mode:levelOf("straw_bale")==1,"straw automation did not activate the existing authored system")
assert(mode:buyScoreAutomation("oil_pump",game)and mode:levelOf("oil_drum")==1,"oil automation did not activate the existing authored system")
assert(mode:buyScoreAutomation("forest_contract",game)and mode:levelOf("forest_expansion")==1,"forest contract did not activate supply and durability scaling")
sample.x,sample.y=game.player.x+120,game.player.y;sample.active,sample.burning,sample.igniting=true,nil,nil
mode.scoreAutomationTimer=0;mode:updateScoreAutomation(.1,game)
assert(#mode.molotovs>beforeFlights,"automatic butt launcher did not fire an authored cigarette projectile")

mode.scoreTreeAllowance=ordinary+1
assert(not mode:checkScoreOvercrowding(game),"score mode ended below its tree allowance")
nodes[#nodes+1]={rushTree=true,active=true,giantTree=false}
assert(mode:checkScoreOvercrowding(game)and game.mode=="clearcut_results","reaching the active-tree allowance did not end the run")
assert(game.result.scoreAttack and game.result.victory and game.result.failureReason=="score_overcrowded","score result omitted the overcrowding cause")
assert(game.result.treeAllowance==ordinary+1 and game.result.peakActiveTrees>=ordinary+1 and game.result.peakTreesPerSecond>=5,"score result omitted capacity metrics")
assert(game.result.woodSpent>0 and game.result.wood>=game.result.woodSpent,"score result omitted earned-versus-invested wood")
assert(game.result.automation.butt_launcher==1 and game.result.automation.forest_contract==1,"score result omitted the purchased automation build")

game:startClearcutScoreAttack()
mode=assert(game.clearcut)
local unattendedEnd
for second=1,90 do
    mode.stageElapsed=second
    if mode:updateScoreTreeGrowth(1,game)then unattendedEnd=second;break end
end
assert(unattendedEnd and unattendedEnd>=55 and unattendedEnd<=80,"fresh unattended run did not reflect the reduced opening forest supply")

Traits.data.levels.universal_yard=7
for _,id in ipairs({"fire_score_filter","fire_score_lighter","fire_score_ash","fire_score_drag","fire_score_heat"})do Traits.data.levels[id]=5 end
game:startClearcutScoreAttack()
assert(game.clearcut.scoreTreeAllowance==40,"max permanent yard expansion did not raise the runtime allowance to 40")
assert(game.clearcut.permanentTraits.range==60 and game.clearcut.permanentTraits.area==50 and game.clearcut.permanentTraits.treeDamage==2.5,"score-only permanent smoker research was not applied at runtime")
print("SCORE_ATTACK_MODE_OK start=empty loss=tree_capacity base=12 supply=adaptive permanent=yard result=occupancy")
