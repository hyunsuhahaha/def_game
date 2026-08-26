package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Scenery=require("src.forest_scenery")
local Mode=require("src.clearcut_mode")
local World=require("src.world")
local Player=require("src.player")
local Game=require("src.game")
local world=World.new();world:useArcadeForest()
world.theme="forest";world.hideBase=true;world.width=3200;world.height=2000;world.nodes={}
world.treeVisual.scale=1;world.treeVisual.variantScale={1,1,1,1}
local mode=Mode.new();mode.job="fire"
mode.permanentTraits=require("src.character_traits").new(true):effects("fire")
math.randomseed(20260826)
mode:generateForest({world=world},260)
assert(#world.nodes==260 and mode.initialTrees==260 and mode.remainingTrees==260,"scenery changed forest objective")
local data=assert(world.forestScenery)
local kinds={};local total=0
for _,list in ipairs({data.ground,data.actors}) do
    for _,prop in ipairs(list) do
        assert(not Scenery.isOpen(prop.x,prop.y,3200,2000),"scenery blocks open-route centers")
        assert(prop.x>0 and prop.x<3200 and prop.y>0 and prop.y<2000)
        kinds[prop.kind]=(kinds[prop.kind] or 0)+1;total=total+1
    end
end
for _,kind in ipairs({"rock","fern","leaves","log"}) do assert((kinds[kind] or 0)>=5,"missing scenery: "..kind) end
assert(total<350,"unbounded dressing density")
for _,node in ipairs(world.nodes) do
    assert(not Scenery.isOpen(node.x,node.y,3200,2000),"tree occupied reserved path")
    assert(not Scenery.isSceneryPocket(node.x,node.y,3200,2000),"canopy occupied scenery landmark")
end
local first=data
math.randomseed(1984);local expected=math.random();math.randomseed(1984)
local again=Scenery.generate(world,1)
assert(math.random()==expected,"decor generation consumed combat random stream")
for _,key in ipairs({"ground","actors"}) do
    assert(#first[key]==#again[key],"non-deterministic prop count")
    for i,p in ipairs(first[key]) do local q=again[key][i];assert(p.x==q.x and p.y==q.y and p.kind==q.kind and p.scale==q.scale) end
end
Scenery.generate(world,2);assert(world.forestScenery~=again and world.forestScenery.stage==2,"stage scenery not replaced")
world.forestScenery=again

-- Production queue and actual assets, no new gameplay targets or collision bodies.
local queue={};Scenery.queue(world,queue,{x=-1000,y=-1000})
assert(#queue==#again.actors)
fixture.reset();Scenery.drawGround(world)
local groundDraws=#fixture.commands
assert(groundDraws==#again.ground)
for i,entry in ipairs(queue) do assert(entry.y==again.actors[i].y);entry.draw() end
for _,op in ipairs(fixture.commands) do
    assert(op.op=="draw" and op.file:find("assets/scenery/forest/",1,true) and op.filter=="nearest")
end
local prop=again.actors[1]
local fadeQueue={};Scenery.queue({forestScenery={actors={prop}}},fadeQueue,{x=prop.x,y=prop.y-10})
fixture.reset();fadeQueue[1].draw();assert(fixture.commands[1].color[4]==.48,"prop hides player feet")
local newImage=love.graphics.newImage
love.graphics.newImage=function() error("scenery reloaded an image during drawing") end
Scenery.drawGround(world);for _,entry in ipairs(queue) do entry.draw() end
love.graphics.newImage=newImage

if SCENERY_CAPTURE then
    local loader
    for i=1,30 do local name,value=debug.getupvalue(Game.new,i);if name=="loadClearcutSprites" then loader=value;break end end
    local player=Player.new(800,500,world.images.workerWalk,world.images.workerActions,world.images.workerRepair)
    player:setClearcutSprite(assert(loader)().fire,"fire");player.isMoving=true;player.walkClock=.2
    mode.smoking={phase="loaded",t=1,dur=1}
    local views={{"ridge",0,0},{"woodland",800,500},{"hollow",0,1000},{"dry",1600,750}}
    for _,node in ipairs(world.nodes) do node.beehive=false end
    for _,view in ipairs(views) do
        local name,ox,oy=unpack(view)
        for _,node in ipairs(world.nodes) do node.x=node.x-ox;node.y=node.y-oy end
        for _,list in ipairs({again.ground,again.actors}) do for _,p in ipairs(list) do p.x=p.x-ox;p.y=p.y-oy end end
        world.width,world.height=1600,1000
        mode.enemies={}
        for i,kind in ipairs({"squirrel","boar","turret"}) do
            local e=mode:spawnEnemy(kind,700+i*95,580+(i%2)*60);e.facing=-1;e.visualTime=.2
        end
        local game={world=world,player=player,camera={trauma=0},setNotice=function() end}
        fixture.time=.2;fixture.reset();world:draw(player,mode);mode:drawWorldOverlay(game)
        fixture.save("docs/previews/forest-scenery-"..name.."-draws.json")
        if name=="woodland" then
            world.forestScenery=nil
            fixture.reset();world:draw(player,mode);mode:drawWorldOverlay(game)
            fixture.save("docs/previews/forest-scenery-without-draws.json")
            world.forestScenery=again
        end
        for _,node in ipairs(world.nodes) do node.x=node.x+ox;node.y=node.y+oy end
        for _,list in ipairs({again.ground,again.actors}) do for _,p in ipairs(list) do p.x=p.x+ox;p.y=p.y+oy end end
        world.width,world.height=3200,2000
    end
end
-- Reserved scenery pockets must not silently lower later-stage objectives.
math.randomseed(733)
for stage=1,5 do
    local nextMode=Mode.new();nextMode.stage=stage
    local nextWorld={width=3200,height=2000,nodes={},images={treeVariants={{},{},{},{}}}}
    local target=260+(stage-1)*45
    nextMode:generateForest({world=nextWorld},target)
    assert(#nextWorld.nodes==target,"stage "..stage.." lost trees to decoration")
end
print("FOREST_SCENERY_OK trees=260 props="..total.." rock="..kinds.rock.." fern="..kinds.fern.." leaves="..kinds.leaves.." log="..kinds.log.." rng=isolated routes=open depth=shared")
