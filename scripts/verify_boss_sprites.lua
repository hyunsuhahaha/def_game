package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local ClearcutMode=require("src.clearcut_mode")
local Art=require("src.forest_arcade_art")
local World=require("src.world")
local Player=require("src.player")
local catalog=require("src.forest_arcade_catalog")
local mode=ClearcutMode.new()
mode.remainingTrees=20
local world=World.new()
local oldVariants=world.images.treeVariants
world:useArcadeForest()
assert(world.images.treeVariants~=oldVariants,"approved trees not connected")
local variants=world.images.treeVariants
world.treeVisual.frontBias=82
world:useArcadeForest()
assert(world.images.treeVariants==variants and world.treeVisual.frontBias==0,"repeat setup broke art anchors")
world.treeVisual.scale=1; world.treeVisual.variantScale={1,1,1,1}
world.width,world.height=1280,900; world.theme="forest"; world.hideBase=true
world.nodes={}
-- Use the game's forest generator, then view a central region at native scale.
math.randomseed(20260826)
world.width,world.height=3200,2000
mode:generateForest({world=world},260)
for _,node in ipairs(world.nodes) do
    node.x=node.x-960; node.y=node.y-550
    node.beehive=false -- fixture isolates the changed forest art, not bee FX
end
world.width,world.height=1280,900
local player=Player.new(720,495,world.images.workerWalk,world.images.workerActions,world.images.workerRepair)
local Game=require("src.game")
local loader
for i=1,30 do local name,value=debug.getupvalue(Game.new,i); if name=="loadClearcutSprites" then loader=value;break end end
assert(loader)
player:setClearcutSprite(loader().fire,"fire"); player.isMoving=true; player.walkClock=.2
mode.job="fire"; mode.smoking={phase="loaded",t=1,dur=1}
local kinds={"squirrel","boar","turret","vineSprout","planter","ent","worldtree","reaper"}
for i,kind in ipairs(kinds) do
    local e=mode:spawnEnemy(kind,400+(i%3)*118,245+math.floor((i-1)/3)*230)
    e.moving=true; e.facing=-1; e.seed=i*.3
    local radius,hp=e.def.radius,e.hp
    local pose=Art.pose(e,.35)
    ClearcutMode.drawEnemy(e,.35)
    local draw
    for j=#fixture.commands,1,-1 do if fixture.commands[j].file==catalog[kind].file then draw=fixture.commands[j];break end end
    assert(draw,"runtime sprite draw missing")
    assert(draw.file==catalog[kind].file and draw.filter=="nearest","wrong runtime asset or filtering")
    assert(draw.args[7]==catalog[kind].foot,"foot anchor drift")
    assert(draw.shader=="assets/shaders/forest-arcade-light.glsl","material shader not used")
    assert(e.def.radius==radius and e.hp==hp,"art changed combat values")
    assert(love.graphics.getShader()==nil,"art leaked its shader")
end
local squirrel=mode.enemies[1]
squirrel.facing=-1; assert(Art.pose(squirrel,.2).flip==1)
squirrel.facing=1; assert(Art.pose(squirrel,.2).flip==-1,"squirrel walks backwards")
local game={world=world,player=player,setNotice=function() end,camera={trauma=0}}
local movement=ClearcutMode.new(); movement.remainingTrees=20
local walker=movement:spawnEnemy("squirrel",50,50)
movement:updateEnemies(.1,{player={x=500,y=50}})
assert(walker.facing==1 and walker.moving)
movement:updateEnemies(.1,{player={x=-500,y=50}})
assert(walker.facing==-1 and walker.moving)
local facing=walker.facing
movement.damagePlayer=function() end
movement:updateEnemies(.1,{player={x=walker.x,y=walker.y}})
assert(walker.facing==facing and not walker.moving,"idle changed facing")
assert(walker.visualAttack>0,"contact recoil not connected")
local stationary=movement:spawnEnemy("turret",10,10)
stationary.fireTimer=0
movement:updateEnemies(.1,{player={x=100,y=10}})
assert(stationary.visualAttack>0 and #movement.projectiles==1,"firing recoil not connected")
local queue={}
mode:queueWorldActors(queue,.3)
assert(#queue==8)
for i,e in ipairs(mode.enemies) do assert(queue[i].y==Art.footY(e),"enemy depth differs from feet") end
-- Capture actual production World depth queue + overlay, not a hand-composed picture.
for frame=0,(FOREST_RENDER_CAPTURE and 5 or 0) do
    fixture.time=frame*.1; fixture.reset()
    for _,e in ipairs(mode.enemies) do e.visualTime=frame*.1 end
    player.walkClock=frame*.1
    world:draw(player,mode)
    local bodies={}
    for _,draw in ipairs(fixture.commands) do
        if draw.op=="draw" and draw.file:find("assets/enemies/arcade/",1,true)
            and not draw.file:find("regrowth-prism-rotation",1,true) then bodies[#bodies+1]=draw end
    end
    assert(#bodies==8,"world failed to queue every enemy exactly once")
    for bodyIndex,body in ipairs(fixture.commands) do
        if body.op=="draw" and body.file:find("assets/enemies/arcade/",1,true)
            and not body.file:find("regrowth-prism-rotation",1,true) then
            local enemy
            for _,e in ipairs(mode.enemies) do if catalog[e.kind].file==body.file then enemy=e end end
            for treeIndex,tree in ipairs(fixture.commands) do
                if tree.op=="draw" and tree.file:find("-tree-cartoon-v3.png",1,true) then
                    assert((treeIndex<bodyIndex)==(tree.args[2]<=Art.footY(enemy)),"tree/monster depth order reversed")
                end
            end
        end
    end
    local before=#bodies
    mode:drawWorldOverlay(game)
    bodies={}
    for _,draw in ipairs(fixture.commands) do
        if draw.op=="draw" and draw.file:find("assets/enemies/arcade/",1,true)
            and not draw.file:find("regrowth-prism-rotation",1,true) then bodies[#bodies+1]=draw end
    end
    assert(#bodies==before,"overlay redrew enemy bodies over trees")
    if FOREST_RENDER_CAPTURE then fixture.save("docs/previews/forest-arcade-draws-"..frame..".json") end
end
assert(catalog.planter.file:find("planter%-forest%-atlas%-v4%.png") and catalog.planter.cell==256 and catalog.planter.width==68,"open-core regrowth totem v4 is not wired")
for _,id in ipairs({"forest","mangrove","madagascar","island"}) do
    local spec=assert(catalog["planter_"..id])
    assert(spec.width<=74 and spec.motion==0 and spec.prism and spec.prismRow~=nil,
        "regional planter must keep a stable body and separated rotating prism: "..id)
end
print("FOREST_ARCADE_RUNTIME_OK species=8 trees=4 facing=both depth=shared shader=restored")
