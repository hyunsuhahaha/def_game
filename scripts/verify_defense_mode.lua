package.path="./?.lua;./?/init.lua;"..package.path
local Defense=require("src.defense_mode")
local world={width=2240,height=1400,nodes={}}
local mode={remainingTrees=0,treesFelled=0}
local game={world=world,player={x=0,y=0},result=nil}
function mode:finish(target,victory)target.result={victory=victory,failureReason=self.failureReason}end

assert(Defense.visibleStages==4 and Defense.treeCount()==384,"opening defense density drifted")
assert(Defense.speed>=40 and Defense.spawnInterval<=1.25,"defense pressure is no longer at least twice as fast and tightly spaced")
Defense.populate(mode,game)
local radii,counts,hp={},{0,0,0,0},{}
for _,node in ipairs(world.nodes)do
    counts[node.defenseStage]=counts[node.defenseStage]+1
    local radius=math.sqrt((node.x-Defense.centerX(world))^2+(node.y-Defense.centerY(world))^2)
    radii[node.defenseStage]=radii[node.defenseStage]or radius
    assert(math.abs(radius-radii[node.defenseStage])<.01,"one stage is not one circular ring")
    if node.treeVariant==1 then hp[node.defenseStage]=node.rushMaxHp end
end
for stage=1,4 do
    assert(counts[stage]==Defense.treesPerStage,"stage ring population is incorrect")
    if stage==1 then assert(hp[stage]==24,"stage 1 health is not doubled")end
    if stage>1 then assert(hp[stage]>hp[stage-1],"stage health did not increase")end
end
local first=world.nodes[1];local before=math.sqrt((first.x-Defense.centerX(world))^2+(first.y-Defense.centerY(world))^2)
Defense.update(mode,game,1)
local after=math.sqrt((first.x-Defense.centerX(world))^2+(first.y-Defense.centerY(world))^2)
assert(math.abs((before-after)-Defense.speed)<.01,"stage ring did not advance inward")
assert(first.swayAngle==0 and first.swayVel==0,"defense movement added per-tree sway effects")

-- Stage 5 must arrive on time even while every tree from stages 1..4 is alive.
Defense.update(mode,game,Defense.spawnInterval-1)
assert(mode.defenseNextStage==6 and #world.nodes==480 and mode.remainingTrees==480,"stage 5 waited for an earlier ring clear")
local stage5Hp
for _,node in ipairs(world.nodes)do if node.defenseStage==5 and node.treeVariant==1 then stage5Hp=node.rushMaxHp end end
assert(stage5Hp and stage5Hp>hp[4],"stage 5 did not receive increased tree health")

first.x,first.y=Defense.centerX(world)+Defense.coreRadius-1,Defense.centerY(world)
Defense.update(mode,game,.01)
assert(game.result and game.result.victory==false and mode.failureReason=="defense_core_breached","core breach did not end the run")

local fixture=require("scripts.forest_render_fixture")
love.graphics.rotate=love.graphics.rotate or function()end
love.graphics.getDimensions=function()return 1280,720 end
love.graphics.getWidth=function()return 1280 end;love.graphics.getHeight=function()return 720 end
love.mouse={getPosition=function()return -100,-100 end,isDown=function()return false end}
love.keyboard={isDown=function()return false end}
local Game=require("src.game");local World=require("src.world");local Player=require("src.player");local Camera=require("src.camera")
local Traits=require("src.character_traits").new(true)
local loader;for index=1,30 do local name,value=debug.getupvalue(Game.new,index);if name=="loadClearcutSprites"then loader=value;break end end
local runtime=setmetatable({characterTraits=Traits,clearcutSprites=assert(loader)(),tools={axe={speed=.8}},wood=0},Game)
function runtime:resetRun()
    self.clearcut=nil;self.result=nil;self.world=World.new()
    self.player=Player.new(1600,1000,self.world.images.workerWalk,self.world.images.workerActions,self.world.images.workerRepair)
    self.camera=Camera.new(1600,1000)
end
function runtime:setNotice(message)self.notice=message end
runtime:startClearcutDefense()
assert(runtime.mode=="playing"and runtime.clearcut.defenseMode and runtime.clearcut.scoreAttack,"lobby defense start path did not create the active mode")
assert(runtime.clearcut.remainingTrees==384 and runtime.clearcut.defenseNextStage==5,"runtime defense setup did not create dense stages 1..4")
assert(runtime.world.width==5120 and runtime.world.height==3200,"defense mode did not expand the world")
assert(runtime.world.playBounds.w==3840 and runtime.world.playBounds.h==2240,"defense playable field did not expand with the world")
assert(Defense.spawnRadius>1280/2/.84,"defense stages are not born beyond the opening camera edge")
local killTarget=runtime.world.nodes[1]
local dropsBefore=#runtime.world.drops
local popupsBefore=#runtime.world.popups
local felledBefore=runtime.clearcut.treesFelled
assert(runtime.clearcut:fellTree(killTarget,runtime),"defense tree kill failed")
assert(#runtime.world.drops==dropsBefore,"defense tree created a wood drop")
assert(#runtime.world.popups==popupsBefore,"defense tree created a wood reward popup")
assert(killTarget.fallT==0,"defense tree lost its fall animation")
assert(runtime.clearcut.totalWood==felledBefore+1 and runtime.clearcut.scoreWoodEarned==felledBefore+1,"defense currency is not the tree kill count")
local fonts={};for name,size in pairs({micro=12,small=14,big=28,heading=21,title=36,display=48})do fonts[name]=love.graphics.newFont("assets/font-korean-regular.ttf",size)end
fixture.reset();runtime.clearcut:drawHUD(runtime,fonts)
assert(#fixture.commands>0,"defense HUD draw path produced no output")
local lobbySource=assert(io.open("src/lobby.lua","rb")):read("*a")
assert(lobbySource:find('{label="디펜스",key="D",action="defense"}',1,true),"lobby defense entry is missing")
print("defense mode verification passed")
