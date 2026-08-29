-- Controlled stationary targets, real World/Player/skill update+draw, no HUD/window.
package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local width,height=640,400
love.graphics.getDimensions=function() return width,height end
love.graphics.getWidth=function() return width end;love.graphics.getHeight=function() return height end
love.mouse={getPosition=function() return -100,-100 end,isDown=function() return false end}
love.keyboard={isDown=function() return false end}
local Game=require("src.game")
local World=require("src.world")
local Player=require("src.player")
local Camera=require("src.camera")
local Mode=require("src.clearcut_mode")
local EnemyArt=require("src.forest_arcade_art")
local loader
for i=1,30 do local name,value=debug.getupvalue(Game.new,i);if name=="loadClearcutSprites" then loader=value;break end end
local sprites=assert(loader)()
local traits=require("src.character_traits").new(true)
local ids={"bat_swarm","thorn_aura","crow_strike","vine_whip","boomerang_axe","seed_mine","chain_lightning","all"}
local durations={1.6,1.6,.48,.32,1.6,1.6,.36,1.6}
for case,id in ipairs(ids) do
    if id=="all" then width,height=1280,720 end
    math.randomseed(1701)
    love.math.random=math.random
    local g=setmetatable({characterTraits=traits,clearcutSprites=sprites,tools={axe={speed=.8}},wood=0},Game)
    function g:resetRun()
        self.clearcut=nil;self.world=World.new()
        self.player=Player.new(1600,1000,self.world.images.workerWalk,self.world.images.workerActions,self.world.images.workerRepair)
        self.camera=Camera.new(1600,1000)
    end
    function g:setNotice() end
    g:startClearcut("fire","forest")
    local m,w,p=g.clearcut,g.world,g.player
    m.levels={[id]=3};m.enemies={};m.smoking=nil
    if id=="all" then for i=1,7 do m.levels[ids[i]]=3 end end
    p:clearClearcutAction();p.walkClock=.2
    local px,py=p.x,p.y
    -- Fixed clearing for comparing effects. Canopy is kept at the edges.
    local nodes={}
    for i,offset in ipairs({{-395,-140},{360,-140},{-380,160},{370,180}}) do
        local n=w.nodes[i];n.x,n.y=px+offset[1],py+offset[2];n.beehive=false;n.rushHp=10000;n.rushMaxHp=10000
        nodes[#nodes+1]=n
    end
    if id~="all" then w.nodes=nodes;w.forestScenery.ground={};w.forestScenery.actors={} end
    for _,n in ipairs(w.nodes) do n.beehive=false;n.rushHp=10000;n.rushMaxHp=10000 end
    -- Keep the farthest crow contact in view by giving it a target at the upper right.
    if id=="crow_strike" then w.nodes={} end
    for i,offset in ipairs({{85,5},{178,-64},{240,70},{-175,60}}) do
        local e=m:spawnEnemy(i==2 and "turret" or "boar",px+offset[1],py+offset[2])
        e.hp,e.maxHp,e.visualHit=10000,10000,0;e.visualTime=.2;e.moving=false
    end
    -- RNG controls placement only; production update and collision code are unchanged.
    love.math.random=function(a,b) if b then return a elseif a then return 1 else return .08 end end
    m:updateSupplementSkills(0,g)
    g.camera.x,g.camera.y,g.camera.zoom=px,py-32,.72
    for frame=0,24 do
        local t=frame*durations[case]/24
        if frame>0 then
            -- Simulate at <=60Hz even if the exported panel time step is larger.
            local remain=durations[case]/24
            while remain>1e-8 do
                local dt=math.min(remain,1/60);remain=remain-dt
                for _,e in ipairs(m.enemies) do e.visualHit=math.max(0,(e.visualHit or 0)-dt) end
                m:updateSupplementSkills(dt,g);m:updatePlague(dt,g)
            end
        end
        -- Generic world debris is outside this FX capture; do not accumulate it
        -- while the world simulation is deliberately held stationary.
        w.particles={}
        fixture.time=t;fixture.reset();love.graphics.setShader(nil)
        g.camera:attach();w:draw(p,m);m:drawSupplementSkills(g,t)
        for _,e in ipairs(m.enemies) do EnemyArt.drawHealth(e,t) end
        g.camera:detach()
        fixture.save("docs/previews/supplement-"..id.."-"..frame.."-draws.json")
    end
end
print("SUPPLEMENT_CAPTURE_OK cases=7+combined frames=200 camera=.72 no-window")
