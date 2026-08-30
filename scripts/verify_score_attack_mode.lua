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
assert(game.mode=="playing"and mode.scoreAttack and mode.job=="fire"and mode.stageTimeLimit==600,"score attack did not start as a ten-minute smoker run")
assert(#game.world.nodes==0 and mode.remainingTrees==0 and mode.totalTreesSpawned==0,"score attack did not start on empty ground")
assert(not mode:checkWorldTreeSpawn(game),"empty score field incorrectly summoned the world tree")

mode:updateScoreTreeGrowth(4,game)
assert(#game.world.nodes==2 and mode.remainingTrees==2 and mode.totalTreesSpawned==2,"tree generation rate did not grow two trees over four seconds")
for _,node in ipairs(game.world.nodes)do
    assert(node.active and node.rushTree and node.treeEmergence and node.treeEmergence.source=="score_growth","generated tree is missing growth animation or harvest state")
end

local recycled=game.world.nodes[1];recycled.active=false;mode.remainingTrees=mode.remainingTrees-1
local slots=#game.world.nodes;mode.treeSpawnAccumulator=1
mode:updateScoreTreeGrowth(0,game)
assert(#game.world.nodes==slots and recycled.active and mode.totalTreesSpawned==3,"felled tree slot was not safely recycled for continuous growth")

mode.stageElapsed=599.9
assert(mode:updateStageClock(.2,game)and game.mode=="clearcut_results"and game.result.scoreAttack and game.result.victory,"ten-minute score run did not finish into score results")
assert(game.result.totalTreesSpawned==3 and game.result.treeSpawnRate==.55,"score result omitted generation metrics")
print("SCORE_ATTACK_MODE_OK lobby=separate smoker=only duration=600s initialTrees=0 growth=.55/s result=throughput")
