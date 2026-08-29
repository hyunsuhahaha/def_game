-- Headless combat walk using production ClearcutMode attacks/collisions.
-- It measures the same dense forest at opening, early-build and completed-build power.
package.path="./?.lua;./?/init.lua;"..package.path
require("scripts.forest_render_fixture")
local Mode=require("src.clearcut_mode")

local function runScenario(spec)
    math.randomseed(7429);love.math.random=math.random
    local mode=Mode.new();mode.job="physical";mode.sandbox=true;mode.level=spec.level
    mode.stage=spec.stage;mode.stageElapsed=spec.elapsed;mode.elapsed=spec.elapsed
    mode.levels=spec.levels;mode.skillBranches=spec.branches or {};mode.enemies={}
    local player={x=0,y=0,gather=1,axeHolding=false,
        cancelInteraction=function()end,playAutoAxeSwing=function()end}
    local world={nodes={},particles={},drops={},popups={},width=4000,height=3000,
        impactNode=function()end,harvestBurst=function()end,spawnDrop=function()end,
        addParticle=function()end,igniteFx=function()end}
    for gy=-10,10 do for gx=-15,15 do
        world.nodes[#world.nodes+1]={kind="tree",rushTree=true,active=true,x=gx*48,y=gy*48,
            rushHp=6,rushMaxHp=6,treeVariant=1,sterile=false}
    end end
    for i=1,8 do mode.enemies[i]={x=0,y=0,hp=1000000,maxHp=1000000,radius=18,def={category="animal"}}end
    mode.initialTrees=#world.nodes;mode.remainingTrees=#world.nodes
    local game={player=player,world=world,tools={axe={speed=1}},camera={trauma=0,
        screenToWorld=function(_,x,y)return x,y end},setNotice=function()end}
    local dt=1/60;local totemTimer=0
    local totems={}
    for i=1,(spec.totems or 0)do
        local a=(i-1)/math.max(1,spec.totems)*math.pi*2
        totems[i]={x=math.cos(a)*300,y=math.sin(a)*240,worldTreeTotem=true,
            def={name="후반 재생 프리즘",plantRadius=820,plantCount=6,plantInterval=7}}
    end
    for frame=1,spec.seconds*60 do
        local t=frame*dt
        -- A player clears one pocket for five seconds, then moves to the next;
        -- this avoids flattering automatic skills with a stationary whole-map
        -- target while still letting the basic axe finish actual trees.
        local pocket=math.floor((t-.0001)/5)%6
        player.x=-480+pocket*192;player.y=(pocket%2==0) and -150 or 150
        for i,e in ipairs(mode.enemies)do
            local a=i/8*math.pi*2+t*.08;e.x=player.x+math.cos(a)*(120+i*22);e.y=player.y+math.sin(a)*(90+i*18)
        end
        mode.elapsed=spec.elapsed+t;mode.stageElapsed=spec.elapsed+t
        mode:updatePhysicalAttack(dt,game,true)
        mode:updateSupplementSkills(dt,game)
        if #totems>0 then
            totemTimer=totemTimer+dt
            if totemTimer>=7/mode:forestPressure()then
                totemTimer=totemTimer-7/mode:forestPressure()
                for _,totem in ipairs(totems)do mode:plantTreesNear(totem,game)end
            end
        end
    end
    return {name=spec.name,felled=mode.treesFelled,seconds=spec.seconds,rate=mode.treesFelled/spec.seconds,
        remaining=mode.remainingTrees,revived=mode.treesRevived,pressure=mode:forestPressure(),maxMulti=mode.maxMulti}
end

local scenarios={
    {name="opening",level=3,stage=1,elapsed=45,seconds=30,levels={wide_blade=1,boomerang_axe=1}},
    {name="early",level=8,stage=1,elapsed=110,seconds=30,
        levels={wide_blade=1,berserker=1,thorn_aura=1,vine_whip=1,boomerang_axe=1,seed_mine=2}},
    {name="mid",level=19,stage=2,elapsed=260,seconds=30,
        levels={wide_blade=3,berserker=3,thorn_aura=3,vine_whip=3,boomerang_axe=3,seed_mine=3},
        branches={boomerang_axe="broad_axe",seed_mine="scatter_mine"}},
    {name="late",level=43,stage=4,elapsed=500,seconds=30,
        levels={wide_blade=6,berserker=6,forced_growth=6,thorn_aura=6,vine_whip=6,boomerang_axe=6,seed_mine=6},
        branches={boomerang_axe="ricochet_axe",seed_mine="sprout_mine"}},
    {name="late_contested",level=43,stage=4,elapsed=500,seconds=30,totems=4,
        levels={wide_blade=6,berserker=6,forced_growth=6,thorn_aura=6,vine_whip=6,boomerang_axe=6,seed_mine=6},
        branches={boomerang_axe="ricochet_axe",seed_mine="sprout_mine"}},
}
local results={};for _,spec in ipairs(scenarios)do results[#results+1]=runScenario(spec)end
for _,r in ipairs(results)do
    print(string.format("POWER_CURVE %s level=%d",r.name,({opening=3,early=8,mid=19,late=43,late_contested=43})[r.name]))
    print(string.format("  felled=%d revived=%d remaining=%d rate=%.2f/s pressure=%.2f maxMulti=%d",r.felled,r.revived,r.remaining,r.rate,r.pressure,r.maxMulti))
end
local opening,early,mid,late,contested=results[1],results[2],results[3],results[4],results[5]
assert(opening.rate<1.5,"opening build already mass-clears the forest")
assert(early.rate<3.5,"early synergy build reaches payoff too soon")
assert(mid.rate>early.rate*1.45,"midgame has no visible power step")
assert(late.rate>mid.rate*1.55 and late.felled>=360,"completed build lacks late mass-clearing payoff")
assert(contested.revived>=180 and contested.felled>contested.revived*2,"late forest does not visibly refill or completed build cannot overcome it")
print("CLEARCUT_POWER_CURVE_OK opening=restrained early=restrained mid=step late=mass_clear contested=regrowth_vs_clear window=30s trees=651")
