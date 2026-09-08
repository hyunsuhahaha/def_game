local game=dofile("scripts/verify_crane_overview.lua")
local fixture=require("scripts.forest_render_fixture")
local Builder=require("src.construction_worker")
local mode=game.clearcut
mode.enemies={};mode.moleCompanions={};mode.bombMonkeys={};mode.monkeyBombs={}
mode.bombExplosions={};mode.oilDrums={};mode.pizzaOven=nil;mode.poppingMachines={};mode.flameStream=nil
game.world.forestScenery={ground={},actors={}};game.world.forestUnderstory=nil
game.player.x,game.player.y=game.world.width*.23,game.world.height*.65
mode.jobMaster.actor.x,mode.jobMaster.actor.y=game.player.x-160,game.player.y+120
mode.construction.cooldown=0;mode.construction.loads={};mode.construction.flyingTrees={}
game.world.nodes={}
local b=game.world.playBounds
for row=0,5 do for col=0,9 do
    game.world.nodes[#game.world.nodes+1]={kind="tree",rushTree=true,active=true,
        x=b.x+100+col*(b.w-200)/9,y=b.y+100+row*(b.h-200)/5,
        rushHp=5,rushMaxHp=5,treeVariant=col%4+1,work=0,workTime=1}
end end
for i=1,7 do game.world.nodes[#game.world.nodes+1]={kind="tree",rushTree=true,active=true,
    x=game.player.x+320+i*145,y=game.player.y,rushHp=5,rushMaxHp=5,treeVariant=i%4+1,work=0,workTime=1}end
for frame=0,27 do
    Builder.update(mode,game,.08,frame==0,game.player.x+1800,game.player.y)
    game.world:updateEffects(.08,game)
    game.camera:update(0,game.player,game.world)
    fixture.time=frame*.08;fixture.reset()
    game.camera:attach();game.world:draw(game.player,mode);mode:drawHeldSmoker(game,fixture.time);game.camera:detach()
    fixture.save("docs/previews/crane-overview-"..frame..".json")
end
print("CRANE_OVERVIEW_CAPTURE_OK actual-camera actual-map actual-tree-flight 28frames window=none")
