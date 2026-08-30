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
assert(game.mode=="playing"and mode.scoreAttack and mode.job=="fire"and mode.stageTimeLimit==math.huge,"score attack still has a fixed stage time limit")
assert(mode.scorePhase=="survival"and mode.scoreOvertimeBuffer==10 and mode.scoreRequirement==1,"production survival state was not initialized")
assert(#game.world.nodes==0 and mode.remainingTrees==0 and mode.totalTreesSpawned==0,"score attack did not start on empty ground")
assert(not mode:checkWorldTreeSpawn(game),"empty score field incorrectly summoned the world tree")

mode:updateScoreTreeGrowth(1,game)
assert(mode.remainingTrees>0 and mode.totalTreesSpawned>0,"adaptive forest supply did not begin growing trees")
for _,node in ipairs(game.world.nodes)do
    assert(node.active and node.rushTree and node.treeEmergence and node.treeEmergence.source=="score_growth","generated tree is missing growth animation or harvest state")
end

local schedule={1,2,4,8,16,32}
for i,expected in ipairs(schedule)do assert(mode:scoreOvertimeRequirementAt((i-1)*30)==expected,"production requirement schedule is incorrect at tier "..i)end

mode.stageElapsed=1
mode.scoreFellTimes={}
for _=1,3 do mode.scoreFellTimes[#mode.scoreFellTimes+1]=1.5 end
mode.scoreFellHead=1;mode.scoreOvertimeBuffer=5
assert(not mode:updateStageClock(1,game)and mode.currentTreesPerSecond==3 and mode.scoreOvertimeBuffer>5,"production above requirement did not refill the buffer")
local highBuffer=mode.scoreOvertimeBuffer
mode.scoreOvertimeElapsed=30
mode.scoreFellTimes={}
for _=1,1 do mode.scoreFellTimes[#mode.scoreFellTimes+1]=2.5 end
mode.scoreFellHead=1
assert(not mode:updateStageClock(1,game)and mode.scoreRequirement==2 and mode.scoreOvertimeBuffer<highBuffer,"production below requirement did not drain the buffer")
assert(mode:scoreTreeSpawnRate()>=2.3,"automatic forest supply did not stay above the current requirement")

local pending=mode.pending
mode:onWood(999,game)
assert(mode.pending>pending,"production mode no longer allows run-build progression")
if game.mode~="playing"then game.mode="playing"end
mode.pending=0
mode.scoreOvertimeBuffer=.05
mode.scoreFellTimes={};mode.scoreFellHead=1
assert(mode:updateStageClock(.1,game)and game.mode=="clearcut_results"and game.result.scoreAttack and game.result.victory,"empty production buffer did not finish into score results")
assert(game.result.overtimeElapsed>0 and game.result.maxOvertimeRequirement==2 and game.result.peakTreesPerSecond>=3,"score result omitted production metrics")
print("SCORE_ATTACK_MODE_OK lobby=separate smoker=only fixedTime=none buffer=10 requirement=1x2^tier supply=adaptive result=throughput")
