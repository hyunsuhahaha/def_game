-- Behavior and rendering contracts for the eight shared skills. No game window.
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
-- Orbit pose is the collision pose; no distant hit or new damage schedule.
-- 레벨→파워 곡선 재설계(만렙 3→6) 반영: 1레벨의 실질 파워는 power(1)=.5 (옛 선형값 1의 절반).
local a,b=tree(82,-14),tree(500)
local m,g=setup("bat_swarm",{a,b});m:updateBatSwarm(0,g)
assert(#m.bats==2);near(a.rushHp,998.7);near(b.rushHp,1000)
near(m.bats[2].x,82);near(m.bats[2].y,-14)
m:updateBatSwarm(.1,g);near(a.rushHp,998.7)
-- Aura ticks at its real radius, not the visible fringe.
a,b=tree(59),tree(60);m,g=setup("thorn_aura",{a,b});m:updateThornAura(0,g)
assert(m.auraRadius==59 and m.auraPulse==1);near(a.rushHp,998.5);near(b.rushHp,1000)
m:updateThornAura(.2,g);near(a.rushHp,998.5)
-- Crow chooses the farthest valid target, not the nearest or an out-of-range one.
a,b=tree(100),tree(510);local e,out=enemy(600),enemy(621)
m,g=setup("crow_strike",{a,b},{e,out});m:updateCrowStrike(0,g)
near(e.hp,987.25);near(a.rushHp,1000);near(b.rushHp,1000);near(out.hp,995.75) -- splash only
assert(#m.crowFx==1 and m.crowFx[1].x==600);near(m.crowFx[1].angle,0)
m:updateCrowStrike(.33,g);assert(#m.crowFx==0)
-- Nearest direction, cone exclusion, snapshot origin: moving cannot drag a hit.
a,b=tree(0,60),tree(100,0);m,g=setup("vine_whip",{a,b});m:updateVineWhip(0,g)
near(a.rushHp,994.75);near(b.rushHp,1000);near(m.whipFx[1].angle,math.pi/2)
g.player.x=77;assert(m.whipFx[1].x==0 and m.whipFx[1].y==0)
m:updateVineWhip(.23,g);assert(#m.whipFx==0)
-- Axe hits once per leg, including a target exactly at the turning endpoint.
a,b=tree(100),tree(260);e=enemy(100)
m,g=setup("boomerang_axe",{a,b},{e});m.boomerangTimer=99
m.boomerangs={{x=0,y=0,dx=1,dy=0,traveled=0,maxDist=260,phase="out",hitSet={},dmg=5}}
local turns=0
for tick=1,160 do
    m:updateBoomerangAxe(1/120,g)
    local axe=m.boomerangs[1]
    if axe then assert(#axe.trail<=5);if axe.phase=="back" then turns=turns+1 end end
end
assert(turns>0 and #m.boomerangs==0)
near(a.rushHp,990);near(b.rushHp,990);near(e.hp,990)
-- Mine keeps its fuse. Explosion persists after the gameplay object is removed.
a,b=tree(20),tree(71);m,g=setup("seed_mine",{a,b});m.seedTimer=99
m.seeds={{x=0,y=0,fuse=1.1,maxFuse=1.1,radius=70,dmg=7}}
m:updateSeedMine(1,g);near(a.rushHp,1000);assert(#m.seeds==1)
m:updateSeedMine(.11,g);near(a.rushHp,993);near(b.rushHp,1000)
assert(#m.seeds==0 and #m.supplementImpacts==1 and m.supplementImpacts[1].kind=="seed")
Art.update(m,.3);assert(#m.supplementImpacts==1)
Art.update(m,.3);assert(#m.supplementImpacts==0)
-- Chain records actual consecutive hits; never revisits or jumps across >260.
a,b=tree(90),tree(300);e,out=enemy(500),enemy(900)
m,g=setup("chain_lightning",{a,b},{e,out});m:updateChainLightning(0,g)
local points=m.lightningFx[1].points;assert(#points==4)
for i,x in ipairs({0,90,300,500}) do assert(points[i].x==x) end
near(a.rushHp,996);near(b.rushHp,996);near(e.hp,996);near(out.hp,1000)
m:updateChainLightning(.26,g);assert(#m.lightningFx==0)
-- Spores reuse the existing infection queue; no direct damage or duplicate DOT.
a,b=tree(110),tree(165);e=enemy(120)
m,g=setup("spore_cloud",{a,b},{e});m:updateSporeCloud(0,g)
assert(#m.plagued==2 and a.plagueMarked and e.plagueMarked and not b.plagueMarked)
near(a.rushHp,1000);near(e.hp,1000);assert(#m.supplementImpacts==2)
m.spore.hitTimer=0;m:updateSporeCloud(0,g);assert(#m.plagued==2)
m:updatePlague(.01,g);near(a.rushHp,997.5);near(e.hp,997.5)
m:updatePlague(.3,g);near(e.hp,997.5)
m:updatePlague(.31,g);near(e.hp,995)
-- Bounded transient storage / all events age out, including a long update.
for i=1,100 do Art.impact(m,"seed",i,0,70) end
assert(#m.supplementImpacts==64 and m.supplementImpacts[1].x==37)
Art.update(m,10);assert(#m.supplementImpacts==0)
-- Render actual assets/shader without mutating timers, targets, HP or combat RNG.
a=tree(100);e=enemy(130);m,g=setup("thorn_aura",{a},{e})
m.levels={bat_swarm=3,thorn_aura=3,crow_strike=3,vine_whip=3,boomerang_axe=3,seed_mine=3,chain_lightning=3,spore_cloud=3}
love.math.random=function() return .12 end
m:updateSupplementSkills(.01,g)
Art.impact(m,"seed",120,0,100)
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
print("SUPPLEMENT_FX_OK skills=8 targeting/fuse/DOT/roundtrip/render-purity/cleanup")
