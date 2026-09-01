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
for index=1,30 do
    local name,value=debug.getupvalue(Game.new,index)
    if name=="loadClearcutSprites"then loader=value;break end
end
local sprites=assert(loader)()
local function font(path,size)return{path=path,size=size,getHeight=function()return size end,getWidth=function(_,text)return #tostring(text)*size*.52 end}end
local regular,bold="assets/font-korean-regular.ttf","assets/font-korean-bold.ttf"
local game=setmetatable({characterTraits=Traits,clearcutSprites=sprites,tools={axe={speed=.8}},wood=0,
    fonts={micro=font(regular,12),small=font(regular,14),body=font(regular,17),heading=font(bold,21)}},Game)
function game:resetRun()
    self.clearcut=nil;self.result=nil;self.world=World.new()
    self.player=Player.new(1600,1000,self.world.images.workerWalk,self.world.images.workerActions,self.world.images.workerRepair)
    self.camera=Camera.new(1600,1000)
end
function game:setNotice(message)self.notice=message end

game:startClearcutSandbox("fire")
local mode=assert(game.clearcut)
assert(game.mode=="playing"and mode.scoreAttack and mode.scorePractice and mode.sandbox,
    "practice does not run on the current score-mode ruleset")
assert(mode.job=="fire"and mode.mapId=="forest"and mode.stage==1,
    "practice did not use the active smoker forest loadout")
assert(mode.stageTimeLimit==math.huge and mode:stageTimeRemaining()==math.huge,
    "practice retained a time limit")
assert(mode.scoreRegenTier==1 and mode:scoreTreeSpawnRate()==3,
    "practice spawn rate still depends on the saved regeneration tier")
assert(mode:scoreDynamicTreeCap()==math.huge,"practice retained the active-tree hard cap")
assert(mode.xp==0 and mode.xpNext==0 and mode.pending==0 and #mode:upgradePool()==0,
    "practice reopened the removed in-run level-up system")
assert(mode.scoreActiveWeapon==mode:scoreRangedWeaponId(),"practice did not initialize the current weapon progression")

local opening=mode:scoreActiveTreeCount()
mode:updateScoreTreeGrowth(2,game)
assert(mode:scoreActiveTreeCount()>opening and mode.totalTreesSpawned>opening,
    "practice did not continuously generate trees")
mode.scoreTreeAllowance=1
assert(not mode:checkScoreOvercrowding(game)and not game.result,
    "practice still ended from tree overcrowding")
local tier=mode.scoreRegenTier
for _,node in ipairs(game.world.nodes)do if node.rushTree then node.active=false end end
mode.remainingTrees=0
assert(not mode:updateScoreTierClear(10,game)and mode.scoreRegenTier==tier,
    "empty practice field still advanced the regeneration tier")
mode.scoreWorldTreeTimer=0
mode:updateScoreWorldTree(100,game)
assert(not mode.scoreWorldTree,"practice still spawned the timed world tree")
mode.elapsed,mode.stageElapsed=9999,9999
assert(not mode:updateStageClock(10,game)and not game.result,
    "practice still ended from elapsed time or the score hard cap")

game:drawSandboxPanel()
assert(game.sandboxTraitBox and #game.sandboxRateBoxes==3 and game.sandboxTreeBox and game.sandboxMobBox,
    "current practice controls were not drawn")
local fast=game.sandboxRateBoxes[3]
assert(game:sandboxPanelClick(fast.x+2,fast.y+2)and mode:scoreTreeSpawnRate()==8,
    "practice tree-rate control did not update the live generator")

local savedMole=Traits:getLevel("universal_mole_companion")
game.scorePracticeMaxed=true
game:startClearcutSandbox("fire")
mode=game.clearcut
assert((mode.permanentTraits.scoreMoleCompanion or 0)>0 and(mode.permanentTraits.scoreFlameUnlock or 0)>0,
    "temporary max profile did not activate current permanent traits")
assert(Traits:getLevel("universal_mole_companion")==savedMole,
    "temporary max profile modified the real saved traits")
assert(mode:scoreTreeSpawnRate()==8,"practice restart lost the selected tree generation rate")

local source=assert(io.open("src/game.lua","rb")):read("*a")
assert(source:find("scorePractice = true",1,true)and source:find("practicePermanentTraits",1,true),
    "lobby practice entry is not wired to the current score practice mode")
assert(source:find("임시 전체 만렙",1,true)and source:find("나무 25그루 즉시 생성",1,true),
    "practice panel is missing current-mode test controls")
print("SKILL_SANDBOX_OK mode=current-score trees=infinite timer=none overcrowding=none worldtree=none traits=owned-or-temp-max")
