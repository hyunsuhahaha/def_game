-- Visual fixture using the real World, Player, Butts scheduler and art methods.
-- The main branch demonstrates the new immediate first contact and later spread.
local fixture=require("scripts.forest_render_fixture")
local Mode=require("src.clearcut_mode")
local World=require("src.world")
local Player=require("src.player")
local Game=require("src.game")
love.math.random=math.random
local world=World.new();world:useArcadeForest()
world.width,world.height=640,460;world.theme="forest";world.hideBase=true
world.treeVisual.scale=1;world.treeVisual.variantScale={1,1,1,1}
local function tree(x,y,variant) return {x=x,y=y,kind="tree",rushTree=true,active=true,treeVariant=variant} end
local target=tree(442,342,1)
world.nodes={tree(60,190,2),tree(234,162,4),tree(550,166,3),tree(580,434,2),target}
local player=Player.new(135,362,world.images.workerWalk,world.images.workerActions,world.images.workerRepair)
local loader
for i=1,30 do local name,value=debug.getupvalue(Game.new,i);if name=="loadClearcutSprites" then loader=value;break end end
assert(loader);player:setClearcutSprite(loader().fire,"fire")
local mode=Mode.new();mode.job="fire";mode.scoreAttack=true;mode.permanentTraits.scoreCigaretteImpact=1
mode.smoking={phase="loaded",t=1,dur=1};mode.remainingTrees=5
local game={player=player,world=world,setNotice=function() end}
mode:hurlMolotovAt(372,360,game)
for frame=0,44 do
    if frame>0 then
        love.math.random=function() return 0 end
        mode:updateMolotovs(.1,game)
        love.math.random=math.random
    end
    fixture.time=mode.smokerGroundTime;fixture.reset()
    world:draw(player,mode);mode:drawWorldOverlay(game)
    fixture.save("docs/previews/smoker-ground-draws-"..frame..".json")
end
assert(target.burning,"capture never reached ignition")
-- Independent all-failure branch: expired grey butt, never a burning tree.
local failed=Mode.new();failed.job="fire";failed.scoreAttack=true;failed.smoking=mode.smoking
target.burning=nil;target.cigaretteIgnitedAt=nil
target.active=false
failed:hurlMolotovAt(372,360,game)
failed:updateMolotovs(.4,game)
target.active=true
love.math.random=function() return .99 end
failed:updateMolotovs(7.1,game)
love.math.random=math.random
fixture.time=7.5;fixture.reset()
world:draw(player,failed);failed:drawWorldOverlay(game)
fixture.save("docs/previews/smoker-ground-expired.json")
assert(not target.burning and failed.cigaretteButts[1].phase=="cold")
print("SMOKER_GROUND_CAPTURE_OK frames=45 landing=instant expiry_branch=unlit")
