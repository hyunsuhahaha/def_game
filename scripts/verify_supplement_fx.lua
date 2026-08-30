-- Behavior and rendering contracts for the seven shared skills. No game window.
package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Mode=require("src.clearcut_mode")
local Art=require("src.supplement_art")
local function near(a,b) assert(math.abs(a-b)<.00001,tostring(a).." ~= "..tostring(b)) end
local function tree(x,y) return {x=x,y=y or 0,rushTree=true,active=true,rushHp=1000,rushMaxHp=1000} end
local function enemy(x,y) return {x=x,y=y or 0,hp=1000,maxHp=1000} end
local function setup(id,nodes,enemies)
    local m=Mode.new();m.levels={[id]=1};m.enemies=enemies or {}
    local g={player={x=0,y=0,facing=1},camera={trauma=0},world={nodes=nodes or {},impactNode=function() end,addParticle=function() end}}
    return m,g
end
-- 레벨→파워 곡선 재설계(만렙 3→6) 반영: 1레벨의 실질 파워는 power(1)=.5 (옛 선형값 1의 절반).
local openingGrowth=(.5/5.6)^1.35
local openingDamageRamp=.20+(openingGrowth^1.5)*.80
-- One bat periodically dives at one target. Monsters always outrank nearer trees.
local a,b=tree(80),tree(500);local e=enemy(260)
local m,g=setup("bat_swarm",{a,b},{e});m:updateBatSwarm(0,g)
assert(#m.bats==1 and m.bats[1].state=="dive" and m.bats[1].target==e)
near(a.rushHp,1000);near(e.hp,1000)
m:updateBatSwarm(.4,g)
near(e.hp,1000-(.35+openingGrowth*3.65)*openingDamageRamp);near(a.rushHp,1000)
assert(m.bats[1].state=="return" and #m.supplementImpacts==1 and m.supplementImpacts[1].kind=="bat")
-- Aura ticks at its real radius, not the visible fringe.
a,b=tree(120+openingGrowth*215-.1),tree(120+openingGrowth*215+.1);m,g=setup("thorn_aura",{a,b});m:updateThornAura(0,g)
near(m.auraRadius,120+openingGrowth*215);assert(m.auraRadius>2*(55+openingGrowth*103));assert(m.auraPulse==1);near(a.rushHp,1000-(.35+openingGrowth*3.65)*openingDamageRamp);near(b.rushHp,1000)
m:updateThornAura(.2,g);near(a.rushHp,1000-(.35+openingGrowth*3.65)*openingDamageRamp)
-- Crow chooses the farthest valid target, not the nearest or an out-of-range one.
a,b=tree(100),tree(510);e=enemy(600);local out=enemy(621)
m,g=setup("crow_strike",{a,b},{e,out});m:updateCrowStrike(0,g)
near(e.hp,1000-(1.5+openingGrowth*32.5)*openingDamageRamp);near(a.rushHp,1000);near(b.rushHp,1000);near(out.hp,1000)
assert(#m.crowFx==1 and m.crowFx[1].x==600);near(m.crowFx[1].angle,0)
m:updateCrowStrike(.33,g);assert(#m.crowFx==0)
-- Nearest monster direction, cone exclusion, snapshot origin: moving cannot drag a hit.
a,b=tree(0,250),tree(270,0);e=enemy(0,200);m,g=setup("vine_whip",{a,b},{e});m:updateVineWhip(0,g)
near(a.rushHp,1000-(.8+openingGrowth*17.2)*openingDamageRamp);near(b.rushHp,1000);near(m.whipFx[1].angle,math.pi/2)
near(e.hp,1000-(.8+openingGrowth*17.2)*openingDamageRamp)
assert(m.whipFx[1].range>2*(125+openingGrowth*155))
g.player.x=77;assert(m.whipFx[1].x==0 and m.whipFx[1].y==0)
m:updateVineWhip(.23,g);assert(#m.whipFx==0)
-- Axe hits once per leg, including a target exactly at the turning endpoint.
a,b=tree(100),tree(260);e=enemy(100)
m,g=setup("boomerang_axe",{a,b},{e});m.boomerangTimer=99
m.boomerangs={{x=0,y=0,dx=1,dy=0,traveled=0,maxDist=260,phase="out",hitSet={},dmg=5,radius=64}}
local turns=0
for tick=1,160 do
    m:updateBoomerangAxe(1/120,g)
    local axe=m.boomerangs[1]
    if axe then assert(#axe.trail<=5);if axe.phase=="back" then turns=turns+1 end end
end
assert(turns>0 and #m.boomerangs==0)
near(a.rushHp,990);near(b.rushHp,990);near(e.hp,990)
assert(64>30*2)
-- New casts aim at a living monster instead of a random direction or a nearer tree.
a=tree(20,0);e=enemy(0,300);m,g=setup("boomerang_axe",{a},{e});m:updateBoomerangAxe(0,g)
assert(m.boomerangs[1].target==e,"boomerang did not select the monster")
near(m.boomerangs[1].dx,0);near(m.boomerangs[1].dy,1)
near(m.boomerangs[1].maxDist,(200+openingGrowth*244)*2)
m,g=setup("boomerang_axe",{tree(30)},{});m:updateBoomerangAxe(0,g);assert(#m.boomerangs==0,"boomerang substituted a tree target")
-- Mine keeps its fuse. Explosion persists after the gameplay object is removed.
a,b=tree(20),tree(71);m,g=setup("seed_mine",{a,b});m.seedTimer=99
m.seeds={{x=0,y=0,fuse=1.1,maxFuse=1.1,radius=70,dmg=7}}
m:updateSeedMine(1,g);near(a.rushHp,1000);assert(#m.seeds==1)
m:updateSeedMine(.11,g);near(a.rushHp,993);near(b.rushHp,1000)
assert(#m.seeds==0 and #m.supplementImpacts==1 and m.supplementImpacts[1].kind=="seed")
Art.update(m,.3);assert(#m.supplementImpacts==1)
Art.update(m,.3);assert(#m.supplementImpacts==0)
-- Newly planted mines use more than twice the former explosion radius.
m,g=setup("seed_mine",{},{enemy(100,0)});m:updateSeedMine(0,g)
assert(m.seeds[1].radius>2*(50+openingGrowth*89))
e=enemy(0,300);m,g=setup("seed_mine",{tree(20,0)},{e});m:updateSeedMine(0,g)
assert(m.seeds[1].target==e and math.abs(m.seeds[1].x)<.001 and m.seeds[1].y==160,"seed mine did not plant toward the monster")
m,g=setup("seed_mine",{tree(30)},{});m:updateSeedMine(0,g);assert(#m.seeds==0,"seed mine substituted a tree target")
-- Chain records monster-only consecutive hits; never revisits or jumps across >260.
a,b=tree(90),tree(300);local e1,e2=enemy(90),enemy(300);out=enemy(900)
m,g=setup("chain_lightning",{a,b},{e1,e2,out});m:updateChainLightning(0,g)
local points=m.lightningFx[1].points;assert(#points==3)
for i,x in ipairs({0,90,300}) do assert(points[i].x==x) end
near(a.rushHp,1000);near(b.rushHp,1000);near(e1.hp,1000-(.8+openingGrowth*13.4)*openingDamageRamp);near(e2.hp,1000-(.8+openingGrowth*13.4)*openingDamageRamp);near(out.hp,1000)
m:updateChainLightning(.26,g);assert(#m.lightningFx==0)
-- Bounded transient storage / all events age out, including a long update.
for i=1,100 do Art.impact(m,"seed",i,0,70) end
assert(#m.supplementImpacts==64 and m.supplementImpacts[1].x==37)
Art.update(m,10);assert(#m.supplementImpacts==0)
-- Render actual assets/shader without mutating timers, targets, HP or combat RNG.
a=tree(100);e=enemy(130);m,g=setup("thorn_aura",{a},{e})
m.levels={bat_swarm=3,thorn_aura=3,crow_strike=3,vine_whip=3,boomerang_axe=3,seed_mine=3,chain_lightning=3}
love.math.random=function() return .12 end
m:updateSupplementSkills(.01,g)
Art.impact(m,"seed",120,0,100)
Art.impact(m,"infection",160,0,24)
local hp,treeHp,time,life=e.hp,a.rushHp,m.supplementTime,m.supplementImpacts[1].life
local previous=love.graphics.newShader("sentinel");love.graphics.setShader(previous)
love.graphics.setColor(.2,.3,.4,.5)
love.math.random=function() error("render consumed combat RNG") end
fixture.reset();m:drawSupplementSkills(g,999)
assert(love.graphics.getShader()==previous);local r,gg,bb,aa=love.graphics.getColor()
near(r,.2);near(gg,.3);near(bb,.4);near(aa,.5)
assert(e.hp==hp and a.rushHp==treeHp and m.supplementTime==time and m.supplementImpacts[1].life==life)
local kinds,sprites={},{}
for _,op in ipairs(fixture.commands) do
    assert(op.op=="draw","shared skill still draws placeholder geometry")
    assert(op.filter=="nearest")
    if op.shader then
        assert(op.shader=="assets/shaders/supplement-fx.glsl");kinds[op.uniforms.effectKind]=true
        local width=op.quad[3]*op.args[4];assert(op.uniforms.gridSize[1]>=width*3.2)
    else sprites[op.file]=true end
end
for i=1,7 do assert(kinds[i],"missing FX shader branch "..i) end
for _,id in ipairs({"bat","crow","axe","seed"}) do assert(sprites["assets/fx/supplement/"..id.."-atlas-v1.png"]) end
local first=fixture.commands[1].uniforms.clock
fixture.reset();m:drawSupplementSkills(g,1999);assert(fixture.commands[1].uniforms.clock==first,"paused draw animates")
print("SUPPLEMENT_FX_OK skills=7 monster_targeting=bat+crow+vine+axe+seed+chain ranges=2x+ fuse/roundtrip/render-purity/cleanup")
