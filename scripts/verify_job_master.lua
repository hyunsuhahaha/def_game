package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
love.graphics.getDimensions=function()return 1280,720 end
love.graphics.getWidth=function()return 1280 end
love.graphics.getHeight=function()return 720 end
love.mouse={isDown=function()return false end,getPosition=function()return 0,0 end}
love.keyboard={isDown=function()return false end}
local Traits=require("src.character_traits")
local Builder=require("src.construction_worker")
local Game=require("src.game")
local World=require("src.world")
local Player=require("src.player")
local Camera=require("src.camera")
local Mode=require("src.clearcut_mode")
local store=Traits.new(true);store.data.scoreTutorialSeen=true
assert(not store:completeJobMaster() and store:activeScoreJob()=="fire")
assert(not store:status("builder_damage"),"construction research unlocked before job mastery")
for _,job in ipairs({"fire","universal"})do
    for _,node in ipairs(store:getScoreAttackNodes(job))do store.data.levels[node.id]=node.max end
end
local last=store:getNode("universal_oven_stack")
store.data.levels[last.id]=last.max-1
assert(not store:completeJobMaster(),"mastery ignored an unfinished facility node")
store.data.currency=1000000;store.data.regenTier=12
assert(store:buy(last.id) and store.data.jobMasterFire,"final node did not persist job mastery")
assert(not store:completeJobMaster(),"mastery repeated")
local saved=Traits.encode(store.data);store.data=Traits.decode(saved)
assert(store.data.jobMasterFire and store:activeScoreJob()=="builder","mastery lost on reload")
for _,node in ipairs(Builder.nodes)do assert(store:getLevel(node.id)==0,"new character did not start fresh")end
assert(store:nextGoal().id=="builder_damage","lobby still offers completed smoker research")
local old=Traits.decode("version=7\ncurrency=42\nregenTier=3\nfire_score_prewarm=2")
assert(not old.jobMasterFire and old.levels.fire_score_prewarm==2 and old.currency==42,"old save migration lost research")

local loader
for i=1,30 do local name,value=debug.getupvalue(Game.new,i);if name=="loadClearcutSprites"then loader=value;break end end
local sprites=assert(loader)()
local function newGame()
    local game=setmetatable({characterTraits=store,clearcutSprites=sprites,tools={axe={speed=.8}},wood=0},Game)
    function game:resetRun()
        self.clearcut=nil;self.result=nil;self.world=World.new()
        self.player=Player.new(1600,1000,self.world.images.workerWalk,self.world.images.workerActions,self.world.images.workerRepair)
        self.camera=Camera.new(1600,1000)
    end
    function game:setNotice(message)self.notice=message end
    game:resetRun();return game
end
local baseline=newGame();local original=Mode.new();original.scoreAttack=true;original.job="fire"
baseline.player:setClearcutSprite(sprites.fire,"fire");original:setup(baseline)
local game=newGame();game:startClearcutScoreAttack(1,false)
local mode=game.clearcut;local operator=game.player
assert(mode.jobMaster.actor~=operator and operator.clearcutJob=="builder","builder did not take player control")
assert(operator.construction==mode.construction and not operator.clearcutSprite,"a human still represents the crane")
for key,value in pairs(original.permanentTraits)do
    assert(mode.permanentTraits[key]==value,"master ability was changed: "..key)
end
assert(#mode.moleCompanions==#original.moleCompanions,"master lost its existing companions")
assert(mode.jobMaster.actor.speed==original.baseSpeed and mode.jobMaster.actor.gather==baseline.player.gather,
    "master movement or attack speed was weakened")
assert(mode.construction.stats.damage==900 and mode.construction.stats.payload==1)
local Board=require("src.character_trait_board")
local board=Board.new(store,{},sprites)
assert(#board:nodesFor("all")==#Builder.nodes,"builder research not reachable on board")
assert(store:buy("builder_damage") and store:getLevel("builder_damage")==1)
game:retryClearcut();mode=game.clearcut;operator=game.player
assert(mode.construction.stats.damage==1200 and mode.jobMaster,"retry lost builder growth or master")

-- Real Player input moves the machine itself, not an invisible remote worker.
local keyboard=love.keyboard.isDown
local ox,oy=operator.x,operator.y
for _,key in ipairs({"w","a","s","d"})do
    operator.x,operator.y=ox,oy
    love.keyboard.isDown=function(...)for _,k in ipairs({...})do if k==key then return true end end return false end
    operator:update(.1,game.world,game)
    Builder.update(mode,game,0,false,ox+800,oy)
    local dx,dy=operator.x-ox,operator.y-oy
    assert((key=="w" and dy<0)or(key=="s" and dy>0)or(key=="a" and dx<0)or(key=="d" and dx>0),"crane WASD failed: "..key)
    assert(mode.construction.towerX==operator.x and mode.construction.towerY==operator.y,"crane detached from input position")
end
love.keyboard.isDown=keyboard;operator.x,operator.y=ox,oy
assert(operator.cameraOffsetY==-250 and operator.movementMargin==160,"large crane framing/boundary clearance missing")

-- Full update: autonomous original weapon attacks without mouse input, while
-- the operator remains untouched and the shared forest is updated just once.
local master=mode.jobMaster.actor
local tree={kind="tree",rushTree=true,active=true,x=master.x+180,y=master.y,rushHp=10000,rushMaxHp=10000,treeVariant=1}
game.world.nodes={tree};mode.remainingTrees=1;mode.treeSpawnAccumulator=0
local x,y=operator.x,operator.y
for _=1,40 do mode:update(.02,game)end
assert(tree.rushHp<10000,"master did not automatically attack using the full runtime")
assert(game.player==operator and operator.x==x and operator.y==y,"master hijacked operator movement")
assert(master.scoreAxeEquipped~=true and mode.flameStream,"master did not use its unlocked flamethrower")

-- All directions, high-speed swept contacts, no repeated damage and no
-- damage while the load is still hanging in the air.
for direction=0,7 do
    local a=direction*math.pi/4;local nx,ny=math.cos(a),math.sin(a)
    operator.x,operator.y=game.world.width/2,game.world.height/2
    local near={kind="tree",rushTree=true,active=true,x=operator.x+nx*320,y=operator.y+ny*320,rushHp=10000,rushMaxHp=10000,treeVariant=1}
    local far={kind="tree",rushTree=true,active=true,x=operator.x+nx*540,y=operator.y+ny*540,rushHp=10000,rushMaxHp=10000,treeVariant=1}
    local missed={kind="tree",rushTree=true,active=true,x=near.x-ny*130,y=near.y+nx*130,rushHp=10000,rushMaxHp=10000,treeVariant=1}
    game.world.nodes={near,far,missed};mode.enemies={}
    mode.construction.loads={};mode.construction.cooldown=0
    Builder.update(mode,game,.2,true,operator.x+nx*600,operator.y+ny*600)
    assert(near.rushHp==10000 and far.rushHp==10000,"airborne material damaged trees")
    Builder.update(mode,game,.8,false)
    assert(near.rushHp==8800 and far.rushHp==8800,"material failed continuous collision direction "..direction)
    assert(missed.rushHp==10000,"material hit outside its visible radius")
    Builder.update(mode,game,.01,false)
    assert(near.rushHp==8800,"one material damaged the same tree twice")
    Builder.update(mode,game,10,false)
    assert(#mode.construction.loads==0,"material leaked after reaching its range or boundary")
end
operator.x,operator.y=game.world.width/2,game.world.height/2
local boss={x=operator.x+320,y=operator.y,hp=20000,scoreWorldTree=true,def={radius=50}}
game.world.nodes={};mode.enemies={boss};mode.construction.cooldown=0
Builder.update(mode,game,1,true,operator.x+600,operator.y)
assert(boss.hp==18800,"construction material cannot damage world tree")
for _,node in ipairs(Builder.nodes)do store.data.levels[node.id]=node.max end
local stats=Builder.stats(store)
assert(stats.damage==4800 and stats.payload==3 and stats.boss==3 and stats.radius==82,
    "construction capstones do not affect real attack stats")
print("JOB_MASTER_OK save+migration final-node fresh-builder full-smoker-runtime all-directions ground-contact sweep once-per-load boss cleanup")
return game
