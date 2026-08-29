package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
-- Map-density captures do not inspect the rotation of tiny bee/particle primitives.
love.graphics.rotate=love.graphics.rotate or function() end
local width,height=1280,720
love.graphics.getDimensions=function() return width,height end
love.graphics.getWidth=function() return width end;love.graphics.getHeight=function() return height end
love.mouse={getPosition=function() return -100,-100 end,isDown=function() return false end}
love.keyboard={isDown=function() return false end}
local Maps=require("src.clearcut_maps")
local Life=require("src.biome_life")
local BiomeEnemies=require("src.biome_enemies")
local Art=require("src.forest_arcade_art")
local Select=require("src.clearcut_map_select")
local Mode=require("src.clearcut_mode")
local World=require("src.world")
local Player=require("src.player")
local Camera=require("src.camera")
local Game=require("src.game")
local traits=require("src.character_traits").new(true)
local loader
for i=1,30 do local name,value=debug.getupvalue(Game.new,i);if name=="loadClearcutSprites" then loader=value;break end end
local sprites=assert(loader)()
local fonts={}
for name,size in pairs({micro=12,small=14,body=17,heading=21,big=28,title=36,display=48}) do fonts[name]=love.graphics.newFont("assets/font-korean-regular.ttf",size) end
local function newGame()
    local g=setmetatable({characterTraits=traits,clearcutSprites=sprites,fonts=fonts,tools={axe={speed=.8}},wood=0},Game)
    function g:resetRun()
        self.clearcut=nil;self.world=World.new()
        self.player=Player.new(1600,1000,self.world.images.workerWalk,self.world.images.workerActions,self.world.images.workerRepair)
        self.camera=Camera.new(1600,1000)
    end
    function g:setNotice(message) self.notice=message end
    return g
end
local totalTrees=0
for _,def in ipairs(Maps.catalog) do
    math.randomseed(20260826)
    local g=newGame();g:startClearcut("fire",def.id)
    local m,w=g.clearcut,g.world
    assert(g.mode=="playing" and w.clearcutMap==def.id and m.mapId==def.id)
    assert(m.regrowGrace==35 and m.regrowInterval==12 and m.timeSpawnTimer==35)
    local zoneCores=0
    for _,enemy in ipairs(m.enemies) do
        if enemy.zoneCoreId then
            zoneCores=zoneCores+1
            assert(Maps.canPlant(w,enemy.x,enemy.y),def.id.." zone core spawned outside walkable forest")
        end
    end
    assert(zoneCores>=1 and #m.forestZones==6,def.id.." zone cores missing")
    assert(m.berserkTimer==170 and m.vinePlantTimer==60 and m.disasterTimer==150)
    assert(#w.nodes==def.trees and m.remainingTrees==def.trees,def.id.." target underfilled: "..#w.nodes)
    if def.id~="beginner" then
        assert(w.playBounds.w<w.width or w.playBounds.h<w.height,"stage 1 starts at final map footprint")
    end
    local edgeX,edgeY=Maps.constrain(w,-99999,99999,75)
    assert(Maps.insidePlayable(w,edgeX,edgeY,75),def.id.." movement escaped stage bounds")
    g.camera:update(10,{x=99999,y=-99999},w)
    local viewL,viewT,viewR,viewB=g.camera:visibleBounds()
    assert(viewL>=w.playBounds.x-.01 and viewT>=w.playBounds.y-.01
        and viewR<=w.playBounds.x+w.playBounds.w+.01 and viewB<=w.playBounds.y+w.playBounds.h+.01,
        def.id.." camera escaped stage bounds")
    assert(not w.overviewBounds,def.id.." playable map unexpectedly fixed the camera")
    local followStartY=w.height/2;g.camera.x,g.camera.y=w.width/2,followStartY
    g.camera:update(.75,{x=w.width/2,y=followStartY+math.min(620,w.playBounds.h*.25)},w)
    assert(g.camera.y>followStartY+80,def.id.." vertical movement did not move the camera")
    g.camera.x,g.camera.y=w.width/2,w.height/2
    local speciesCounts={}
    for _,node in ipairs(w.nodes) do
        assert(Maps.canPlant(w,node.x,node.y),def.id.." tree in water")
        node.beehive=false
        speciesCounts[node.treeVariant]=(speciesCounts[node.treeVariant] or 0)+1
    end
    if def.id~="forest" and def.id~="beginner" then
        local paths={}
        for i=1,3 do
            assert((speciesCounts[i] or 0)>=3,def.id.." missing tree species "..i)
            local path=w.images.treeVariants[i].path
            assert(not paths[path],"size variation passed off as different plant species");paths[path]=true
        end
        print("BIOME_SPECIES",def.id,speciesCounts[1],speciesCounts[2],speciesCounts[3])
    end
    for _,list in ipairs({w.forestScenery.ground,w.forestScenery.actors}) do
        for _,p in ipairs(list) do assert(Maps.canPlant(w,p.x,p.y),"prop in water") end
    end
    local environment=w.biomeLife
    local counts={}
    for _,p in ipairs(environment.items) do counts[p.kind]=(counts[p.kind] or 0)+1;assert(not p.hp and not p.reward,"ambient entered combat") end
    if def.id=="forest" or def.id=="beginner" or def.id=="greatforest" then assert(#environment.items==0)
    elseif def.id=="mangrove" then assert(counts.crab==22 and not counts.parrot,"wrong regional wildlife")
    elseif def.id=="madagascar" then assert(counts.lemur>=2 and counts.traveller>=6)
    else assert(counts.parrot==12 and counts.crab==28) end
    math.randomseed(173);local expected=math.random();math.randomseed(173)
    Life.generate(w,1);assert(math.random()==expected,"ambient consumes combat RNG")
    for i,p in ipairs(w.biomeLife.items) do local q=environment.items[i];assert(p.x==q.x and p.y==q.y and p.phase==q.phase) end
    for tick=1,60 do
        Life.update(w,.1)
        for _,p in ipairs(w.biomeLife.items) do
            if not p.air then assert(Maps.islandDistance(p.x,p.y,w.width,w.height)<1 or def.id~="island","ambient walks into sea") end
        end
    end
    totalTrees=totalTrees+#w.nodes
    -- Both scripted waves and the timer/elite paths use the same regional table.
    m.enemies={};m:spawnWave({squirrel=2,boar=1,turret=1},g)
    assert(#m.enemies==3,"stage 1 milestone wave was not reduced")
    local seen={}
    for _,e in ipairs(m.enemies) do
        seen[e.kind]=true
        assert(e.kind~="squirrel" and e.kind~="boar" and e.kind~="turret" or def.id=="forest" or def.id=="beginner" or def.id=="greatforest")
        if e.kind=="crocodile" then
            assert(Maps.channelDistance(e.x,e.y,w.width,w.height)<0,"croc must emerge from water")
            assert((e.x-g.player.x)^2+(e.y-g.player.y)^2>=260^2,"croc projected onto player")
        end
        local pose=Art.pose(e,0);assert(pose.spec.file)
            if def.id~="forest" and def.id~="beginner" and def.id~="greatforest" and e.kind~="vineSprout" then
            e.facing=-1;assert(Art.pose(e,0).sx<0);e.facing=1;assert(Art.pose(e,0).sx>0)
        end
    end
    if def.id=="mangrove" then assert(seen.crocodile and seen.marshCrab)
    elseif def.id=="madagascar" then assert(seen.angryLemur)
    elseif def.id=="island" then assert(seen.shoreCrab) end
    m.enemies={};m.elapsed=30;m.timeSpawnTimer=0;m:updateTimeSpawner(.01,g)
    assert(#m.enemies==1 and m.timeSpawnTimer==24,"opening time-attack spawn pacing regressed")
    for _,e in ipairs(m.enemies) do assert(e.kind==BiomeEnemies.resolve(def.id,e.kind)) end
    m.enemies={};m.elapsed=100;m.timeSpawnTimer=0;m:updateTimeSpawner(.01,g)
    assert(#m.enemies==1 and m.timeSpawnTimer==20,"mid-opening time-attack spawn pacing regressed")
    local disasterTimer=m.disasterTimer;m.stage=1;m:updateDisasters(20,g)
    assert(m.disasterState=="idle" and m.disasterTimer==disasterTimer,"stage 1 disaster was not locked")
    m.enemies={};m.eliteTimer=0;m:updateEliteTimer(.01,g)
    assert(#m.enemies==1 and m.enemies[1].elite)
    m.enemies={}
    if def.tree then assert(w.images.treeVariants[1].path:find(def.tree,1,true)) end
    if def.id=="island" then
        assert(Maps.island.radiusX*Maps.island.radiusY>=4*650*330,"island land area was not expanded")
        assert(def.trees==65 and Maps.treeTarget(def.id,2)==145,"island opening progression lost")
        local minX,minY,maxX,maxY=w.width,w.height,0,0
        for _,n in ipairs(w.nodes) do minX=math.min(minX,n.x);maxX=math.max(maxX,n.x);minY=math.min(minY,n.y);maxY=math.max(maxY,n.y) end
        assert(maxX-minX>900 and maxY-minY>450,"island opening collapsed into one clearing")
        for _,p in ipairs(w.biomeLife.items) do
            if p.kind=="crab" then local d=Maps.islandDistance(p.homeX,p.homeY,w.width,w.height);assert(d>.90 and d<.98,"beach crab left on old shoreline") end
        end
        Maps.configureStage(w,4);g.camera.zoom=w.stageZoom
        for _,size in ipairs({{960,540},{1280,720},{1920,1080},{2560,1080}}) do
            width,height=unpack(size)
            g.camera.x,g.camera.y=w.width/2,w.height/2
            g.camera.renderX,g.camera.renderY=g.camera.x,g.camera.y
            local beforeY=g.camera.y
            g.camera:update(.35,{x=w.width/2,y=w.height/2+420},w)
            assert(g.camera.y>beforeY,"island stage 4 camera no longer follows vertical movement")
            for a=0,math.pi*2,.025 do
                local radius=1+.065*math.sin(a*3+.4)+.035*math.cos(a*5)
                local x,y=w.width/2+Maps.island.radiusX*radius*math.cos(a),w.height/2+Maps.island.radiusY*radius*math.sin(a)
                local cx,cy=Maps.constrain(w,x*4-w.width,y*4-w.height,18)
                assert(Maps.islandDistance(cx,cy,w.width,w.height)<=1-18/Maps.island.radiusY+.00001)
            end
            local zoom=g.camera.zoom;g:wheelmoved(0,1);assert(g.camera.zoom==zoom)
            love.keyboard.isDown=function(key) return key=="lctrl" end
            g:wheelmoved(0,1)
            assert(g.camera.zoom>zoom and g.camera.renderZoom==g.camera.zoom,"Ctrl+wheel did not zoom projected world")
            g:wheelmoved(0,-1)
            assert(math.abs(g.camera.zoom-zoom)<.00001,string.format("projected zoom did not return to its base level %.6f != %.6f",g.camera.zoom,zoom))
            love.keyboard.isDown=function() return false end
            local cx,cy=g.camera:screenToWorld(width/2,height/2)
            assert(math.abs(cx-g.camera.renderX)<.001 and math.abs(cy-g.camera.renderY)<.001)
        end
        Maps.configureStage(w,1);g.camera.zoom=w.stageZoom
        width,height=1280,720;g.camera:update(0,g.player,w)
        for _,kind in ipairs({"squirrel","boar","turret","ent","worldtree","reaper"}) do
            local e=m:spawnEnemy(kind,-400,9000)
            assert(Maps.islandDistance(e.x,e.y,w.width,w.height)<1,"enemy/boss spawns at sea")
        end
        m.enemies={}
        local px,py=Maps.constrain(w,99999,w.height/2,18);g.player.x,g.player.y=px,py
        love.keyboard.isDown=function(key) return key=="d" end
        g.player:update(1,w,g);assert(Maps.islandDistance(g.player.x,g.player.y,w.width,w.height)<1)
        love.keyboard.isDown=function() return false end
        m.dashing={dx=1,dy=0,angle=0,remaining=10000,width=45,hitSet={}}
        m:updateDash(.1,g);assert(Maps.islandDistance(g.player.x,g.player.y,w.width,w.height)<1,"dash escapes sea boundary")
        m.dashing=nil;m.dashTrail={}
    end
    if MAP_CAPTURE then
        -- Let transient FX from the boundary tests expire before the starting view.
        m.traitFx:update(10)
        g.player.x,g.player.y=w.width/2,w.height/2;g.player:clearClearcutAction()
        g.player.isMoving=true;g.player.walkClock=.2;m.smoking={phase="loaded",t=1,dur=1}
        m.enemies={}
        for i,kind in ipairs({"squirrel","boar","turret"}) do
            local x,y=g.player.x-160+i*90,g.player.y+80
            if def.id=="mangrove" and kind=="boar" then x,y=g.player.x-340,g.player.y+280 end
            local e=m:spawnEnemy(kind,x,y);e.visualTime=.2
        end
        -- Capture the real starting clearing, not a hand-placed forest opening.
        g.camera.x,g.camera.y=g.player.x,g.player.y;g.camera:update(0,g.player,w)
        fixture.time=.2;fixture.reset();g.camera:attach();w:draw(g.player,m);m:drawWorldOverlay(g);g.camera:detach()
        fixture.save("docs/previews/map-"..def.id.."-draws.json")
        if def.id~="forest" then
            for frame=1,5 do
                Life.update(w,.22);fixture.time=.2+frame*.22
                fixture.reset();g.camera:attach();w:draw(g.player,m);m:drawWorldOverlay(g);g.camera:detach()
                fixture.save("docs/previews/map-"..def.id.."-motion-"..frame.."-draws.json")
            end
        end
    end
    -- Retry keeps biome, subsequent stages keep biome and correct targets.
    g:startClearcut("fire");assert(g.clearcut.mapId==def.id and g.world.clearcutMap==def.id,"retry loses map")
    local openingW,openingH,openingZoom=g.world.playBounds.w,g.world.playBounds.h,g.world.stageZoom
    g.clearcut:advanceStage(g)
    assert(g.clearcut.stage==2 and #g.world.nodes==Maps.treeTarget(def.id,2),def.id.." stage target lost")
    if def.id~="beginner" then
        assert(g.world.playBounds.w>openingW and g.world.playBounds.h>openingH and g.world.stageZoom<openingZoom,
            def.id.." stage 2 did not expand the playable footprint")
    end
    for stage=3,5 do
        g.world.nodes={};g.clearcut.stage=stage;Maps.configureStage(g.world,stage)
        g.clearcut:generateForest(g,Maps.treeTarget(def.id,stage))
        assert(#g.world.nodes==Maps.treeTarget(def.id,stage),def.id.." stage "..stage.." underfilled "..#g.world.nodes)
        if MAP_CAPTURE and stage==4 and def.id~="beginner" then
            g.player.x,g.player.y=g.world.width/2,g.world.height/2
            g.camera.x,g.camera.y,g.camera.zoom=g.player.x,g.player.y,g.world.stageZoom
            fixture.time=.2;fixture.reset();g.camera:attach();g.world:draw(g.player,g.clearcut);g.clearcut:drawWorldOverlay(g);g.camera:detach()
            fixture.save("docs/previews/map-"..def.id.."-stage4-draws.json")
        end
    end
    if def.id~="forest" and def.id~="beginner" and def.id~="greatforest" then
        for _,seed in ipairs({17,83,421}) do
            math.randomseed(seed);g.world.nodes={};g.clearcut.stage=1
            g.clearcut:generateForest(g,Maps.treeTarget(def.id,1))
            local kinds={}
            for _,node in ipairs(g.world.nodes) do kinds[node.treeVariant]=true end
            assert(#g.world.nodes==def.trees and kinds[1] and kinds[2] and kinds[3],"seed lost biome variety/target")
        end
    end
end
-- Regional attacks: real mode update dispatch, committed direction, one swept hit,
-- a dodgeable warning and a recovery period at both normal and long frame rates.
for _,case in ipairs({{map="mangrove",kind="crocodile"},{map="madagascar",kind="angryLemur"}}) do
    for _,dt in ipairs({1/60,.12}) do
        local g=newGame();g:startClearcut("fire",case.map)
        local m=g.clearcut;local hits=0
        function m:damagePlayer(amount) assert(amount>0);hits=hits+1 end
        local e=m:spawnEnemy(case.kind,0,0)
        e.x,e.y=g.player.x-125,g.player.y;e.seed=0;e.biomeTimer=0
        m:updateEnemies(.01,g)
        assert(e.biomeState=="warn" and hits==0 and Art.pose(e).frame==7)
        local dx,dy=e.attackDX,e.attackDY
        fixture.reset();BiomeEnemies.drawWarning(e);assert(#fixture.commands>=3)
        while e.biomeState=="warn" do m:updateEnemies(.01,g);assert(hits==0,"damage before lunge") end
        assert(e.biomeState=="lunge")
        while e.biomeState=="lunge" do
            m:updateEnemies(dt,g)
            assert(e.attackDX==dx and e.attackDY==dy,"lunge homed after warning")
        end
        assert(hits==1 and e.biomeState=="recover" and e.hopHeight==0,"swept contact/recovery")
        m:updateEnemies(.2,g);assert(hits==1,"repeated contact hit during recovery")
        -- Re-run from a warning, then sidestep outside its locked path.
        e.x,e.y=g.player.x-125,g.player.y;e.biomeState="stalk";e.biomeTimer=0;hits=0
        m:updateEnemies(.01,g);assert(e.biomeState=="warn")
        g.player.y=g.player.y+140
        while e.biomeState~="recover" do m:updateEnemies(.01,g) end
        assert(hits==0,"sidestep did not evade committed lunge")
    end
    if MAP_CAPTURE then
        local g=newGame();g:startClearcut("fire",case.map)
        local m,w=g.clearcut,g.world
        local e=m:spawnEnemy(case.kind,0,0)
        e.x,e.y=g.player.x-125,g.player.y;e.seed=0;e.biomeTimer=0
        g.camera.x,g.camera.y,g.camera.zoom=g.player.x-20,g.player.y-45,1.6
        g.camera.shakeScale=0
        for _,node in ipairs(w.nodes) do node.beehive=false end
        m:updateEnemies(.01,g)
        for frame=0,14 do
            fixture.time=frame*.1
            fixture.reset();g.camera:attach();w:draw(g.player,m);m:drawWorldOverlay(g);g.camera:detach()
            fixture.save("docs/previews/biome-action-"..case.kind.."-"..frame.."-draws.json")
            m:updateEnemies(.1,g)
        end
    end
end
print("BIOME_COMBAT_OK waves=regional timer=regional elite=regional windup=visible swept=one_hit sidestep=ok facing=ok")
-- Selection flow handles every actual job (including later additions).
for i,c in ipairs(Mode.characters) do
    traits:markStorySeen(c.id)
    local g=newGame();g:chooseClearcutCharacter(i)
    assert(g.mode=="clearcut_map_select" and g.pendingClearcutCharacter==c.id)
    Game.keypressed(g,"escape");assert(g.mode=="clearcut_select")
    g:chooseClearcutCharacter(i);Game.keypressed(g,"4");Game.keypressed(g,"return")
    assert(g.mode=="clearcut_briefing" and g.selectedClearcutMap=="island")
    Game.keypressed(g,"return")
    assert(g.mode=="playing" and g.clearcut.job==c.id and g.clearcut.mapId=="island")
end
do
    local g=newGame();g:chooseClearcutCharacter(1);Game.keypressed(g,"6")
    assert(g.clearcutMapFocus==6,"sixth map numeric shortcut missing")
    Game.keypressed(g,"up");Game.keypressed(g,"up");Game.keypressed(g,"up")
    assert(g.selectedClearcutStage==4,"map-select stage keyboard control missing")
    Game.keypressed(g,"return")
    assert(g.mode=="clearcut_briefing" and g.selectedClearcutMap=="greatforest","great forest briefing was not selectable")
    Game.keypressed(g,"return")
    assert(g.clearcut.stage==4 and g.selectedClearcutStage==4,"selected stage was not passed into gameplay")
    assert(#g.world.nodes==Maps.treeTarget("greatforest",4) and g.clearcut.stageTimeLimit==Maps.stageTimeLimit("greatforest",4),"selected stage objective/time mismatch")
    assert(g.world.playBounds.w==7200 and g.world.playBounds.h==4600,"selected final stage footprint mismatch")
    g:startClearcut("physical");assert(g.clearcut.stage==4,"retry lost selected starting stage")
end
for _,size in ipairs({{960,540},{1280,720},{1920,1080}}) do
    width,height=unpack(size)
    local g=newGame();g:chooseClearcutCharacter(1)
    fixture.reset();Select.draw(g)
    assert(#g.clearcutStageBoxes==4,"stage selector did not render four entries")
    local stageBox=g.clearcutStageBoxes[3].box
    assert(stageBox.x>=0 and stageBox.x+stageBox.w<=width and stageBox.y>=0 and stageBox.y+stageBox.h<=height,"stage selector escaped viewport")
    Game.mousepressed(g,stageBox.x+stageBox.w/2,stageBox.y+stageBox.h/2,1)
    assert(g.selectedClearcutStage==3 and g.mode=="clearcut_map_select","stage selector mouse input changed screens")
    for i=1,#Maps.catalog do
        Select.focus(g,i,true)
        local found
        for _,b in ipairs(Select.boxes(width,height,g))do if b.index==i then found=b break end end
        assert(found and found.x>=0 and found.x+found.w<=width and found.y>=0 and found.y+found.h<=height-40,"focused globe marker not visible")
        assert(Select.at(found.x+found.w/2,found.y+found.h/2,g)==i,"globe marker hit mismatch")
    end
    Select.focus(g,3,true);local hidden=0
    local globe=require("src.stage_select_globe")
    local routes=globe.routes(g,width,height);assert(#routes==5,"globe route count mismatch")
    for _,leg in ipairs(routes)do assert(#leg.points==20 and leg.from~=leg.to,"globe dotted route malformed")end
    for _,m in ipairs(globe.markers(g,width,height))do
        assert(m.r>=23,"landmark hit area regressed")
        if not m.visible then hidden=hidden+1;assert(Select.at(m.x,m.y,g)~=m.index,"back-side globe marker accepted input")end
    end
    assert(hidden>=1,"globe test did not place any marker on back hemisphere")
    local l=globe.layout(width,height);local z=globe.stateFor(g).zoom
    assert(globe.wheelmoved(g,l.cx,l.cy,1,width,height),"wheel over globe was ignored")
    globe.update(g,.25);assert(globe.stateFor(g).zoom>z and globe.stateFor(g).zoom<=1.15,"globe zoom-in failed")
    assert(not globe.wheelmoved(g,width-2,height-2,1,width,height),"wheel outside globe changed zoom")
    -- A drag can cross a complete longitude without selecting a marker.
    Select.focus(g,1,true);l=globe.layout(width,height);local before=globe.stateFor(g).yaw
    Game.mousepressed(g,l.cx,l.cy,1);Game.mousemoved(g,l.cx+l.r*4.06,l.cy,l.r*4.06,0);Game.mousereleased(g,l.cx+l.r*4.06,l.cy,1)
    assert(g.mode=="clearcut_map_select" and math.abs(math.cos(globe.stateFor(g).yaw-before))>.99,"360 globe drag failed or selected accidentally")
    -- A stationary click on a visible stage marker selects it immediately.
    Select.focus(g,2,true);local marker
    for _,b in ipairs(Select.boxes(width,height,g))do if b.index==2 then marker=b break end end
    Game.mousepressed(g,marker.x+marker.w/2,marker.y+marker.h/2,1);Game.mousereleased(g,marker.x+marker.w/2,marker.y+marker.h/2,1)
    assert(g.mode=="clearcut_briefing" and g.selectedClearcutMap=="mangrove","biome briefing was skipped")
    if MAP_UI_CAPTURE then
        fixture.reset();Select.draw(g)
        fixture.save("docs/previews/map-select-"..width.."-draws.json")
    end
end
-- Stage entry is a frozen cinematic: no combat clock or enemy simulation runs
-- while the quiet clearing, worker arrival and wildlife scatter are playing.
local Intro=require("src.clearcut_intro")
do
    local file=assert(io.open("src/clearcut_intro.lua","rb"));local source=file:read("*a");file:close()
    assert(not source:find("작전 개시",1,true)and not source:find("전투 시작",1,true)and not source:find("작업 시작",1,true),"start combat copy returned")
end
for _,def in ipairs(Maps.catalog)do
    local g=newGame();g:startClearcut("physical",def.id)
    local intro=g.clearcut.intro;assert(intro and g.player.introHidden and #intro.birds==14,def.id.." intro missing")
    assert(g.camera.renderX==g.camera.x and g.camera.renderY==g.camera.y and g.camera.renderZoom==g.camera.zoom,def.id.." intro camera render pose was not initialized")
    local minDepth,maxDepth=9,0;for _,bird in ipairs(intro.birds)do minDepth=math.min(minDepth,bird.depth);maxDepth=math.max(maxDepth,bird.depth)end
    assert(minDepth<.7 and maxDepth>1.5,"intro depth bands missing")
    local elapsed,time=g.clearcut.elapsed,g.time;local enemy=g.clearcut.enemies[1];local ex,ey=enemy and enemy.x,enemy and enemy.y
    Intro.update(g,.8);assert(g.clearcut.elapsed==elapsed and g.time==time and g.player.introHidden,"intro advanced gameplay")
    assert(g.camera.renderX==g.camera.x and g.camera.renderY==g.camera.y and g.camera.renderZoom==g.camera.zoom,def.id.." authored intro camera stopped reaching the renderer")
    Intro.update(g,.9);assert(g.clearcut.intro and not g.player.introHidden and g.player.isMoving,"worker did not enter")
    local flying=0;for _,bird in ipairs(g.clearcut.intro.birds)do if bird.flying then flying=flying+1 end end
    assert(flying>=4,"birds did not scatter")
    assert(#g.clearcut.intro.debris>=20,"authored canopy debris did not burst")
    local swaying=0;for _,node in ipairs(g.world.nodes)do if math.abs(node.swayAngle or 0)>.001 then swaying=swaying+1 end end
    assert(swaying>0,"canopy did not react to flock launch")
    if def.id~="forest" and def.id~="beginner" and def.id~="greatforest" then
        local startled=0;for _,p in ipairs(g.world.biomeLife.items)do if p.startle then startled=startled+1 end end
        assert(startled>0,def.id.." wildlife ignored arrival")
    end
    if enemy then assert(enemy.x==ex and enemy.y==ey,"enemy moved during intro")end
    fixture.reset();Intro.drawWorldBack(g);Intro.drawWorldFront(g);Intro.drawScreen(g)
    local birdDraw,debrisDraw=false,false;for _,cmd in ipairs(fixture.commands)do
        if cmd.file=="assets/fx/stage-intro/stage-intro-birds-atlas-pixel-v2.png" then birdDraw=true end
        if cmd.file=="assets/fx/stage-intro/stage-intro-debris-atlas-pixel-v2.png" then debrisDraw=true end
    end
    assert(birdDraw and debrisDraw,"intro v2 authored atlases not rendered")
    while Intro.active(g)do Intro.update(g,.25)end
    assert(not g.player.introHidden and not g.player.isMoving and g.clearcut.elapsed==0,"intro completion state invalid")
    assert(g.camera.renderX==g.camera.x and g.camera.renderY==g.camera.y and g.camera.renderZoom==g.camera.zoom,"intro camera did not hand back a synchronized pose")
    g.clearcut:update(.1,g);assert(g.clearcut.elapsed>.09,"gameplay did not start after intro")
end
local skipGame=newGame();skipGame:startClearcut("physical","forest");Game.keypressed(skipGame,"space")
assert(not Intro.active(skipGame) and skipGame.clearcut.elapsed==0,"intro skip started combat early")
local clickGame=newGame();clickGame:startClearcut("physical","forest");Game.mousepressed(clickGame,10,10,1)
assert(not Intro.active(clickGame) and clickGame.clearcut.elapsed==0,"mouse intro skip started combat early")
print("CLEARCUT_INTRO_V2_OK maps=6 quiet=frozen flock=14_clustered depth=3 debris=authored canopy=sway camera=impact wildlife=startled skip=space/click")
print("CLEARCUT_MAPS_OK maps="..#Maps.catalog.." first_stage_trees="..totalTrees.." stages=1..5 pacing=opening_locked jobs="..#Mode.characters.." sea=bounded camera=all_sides retry=kept keyboard=ok mouse=ok")
