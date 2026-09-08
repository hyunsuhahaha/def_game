local game=dofile("scripts/verify_job_master.lua")
local fixture=require("scripts.forest_render_fixture")
local Builder=require("src.construction_worker")
local mode=game.clearcut
-- Exercise the actual World queue with the two characters and the new art.
game.world.width,game.world.height=1280,900
game.world.playBounds={x=0,y=0,w=1280,h=900};game.world.northBackdrop=false
game.world.forestScenery={ground={},actors={}};game.world.forestUnderstory=nil
mode.moleCompanions={};mode.oilDrums={};mode.bombMonkeys={};mode.monkeyBombs={};mode.bombExplosions={}
mode.pizzaOven=nil;mode.poppingMachines={};mode.enemies={};mode.flameStream=nil
game.player.x,game.player.y=500,560
mode.jobMaster.actor.x,mode.jobMaster.actor.y=760,590
mode.jobMaster.actor.isMoving=false;mode.jobMaster.actor.clearcutActionProgress=nil
mode.jobMaster.actor.scoreAxeEquipped=false;mode.scoreActiveWeapon="cigarette"
mode.construction.towerX,mode.construction.towerY=360,650
mode.construction.stats=Builder.stats(game.characterTraits)
mode.construction.loads={};mode.construction.cooldown=0
game.world.nodes={}
for _,spot in ipairs({{690,570},{930,620},{1080,470},{185,600},{880,820}})do
    game.world.nodes[#game.world.nodes+1]={kind="tree",rushTree=true,active=true,x=spot[1],y=spot[2],
        rushHp=100000,rushMaxHp=100000,treeVariant=1,work=0,workTime=1}
end
for frame=0,7 do
    if frame==0 then Builder.update(mode,game,.05,true,1100,560)
    else Builder.update(mode,game,.1,false,1100,560)end
    fixture.time=frame*.1;fixture.reset()
    game.world:draw(game.player,mode)
    mode:drawHeldSmoker(game,fixture.time)
    local found,masterBody,operatorBody=0,false,false
    for _,op in ipairs(fixture.commands)do
        if op.file and op.file:find("assets/construction/",1,true)then found=found+1;assert(op.filter=="nearest")end
        if op.file and op.file:find("smoker-atlas-pixel-v3",1,true)then masterBody=true end
        if op.file and op.file:find("developer-atlas-pixel-v2",1,true)then operatorBody=true end
    end
    assert(found>=3 and masterBody and operatorBody,"runtime did not render crane, material and both workers")
    fixture.save("docs/previews/job-master-runtime-"..frame..".json")
end
local fonts={small=love.graphics.newFont(14)}
local board=require("src.character_trait_board").new(game.characterTraits,fonts,game.clearcutSprites)
fixture.reset();board:draw();fixture.save("docs/previews/job-master-research.json")
print("JOB_MASTER_CAPTURE_OK real-world-queue two-workers crane pipe nearest research window=none")
