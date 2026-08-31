package.path="./?.lua;./?/init.lua;"..package.path

local fixture=require("scripts.forest_render_fixture")
love.mouse={isDown=function() return false end,getPosition=function() return 1000,0 end}

local ClearcutMode=require("src.clearcut_mode")
local player={x=0,y=0,gather=1,facing=1,setClearcutAction=function() end,clearClearcutAction=function() end}
local game={player=player,tools={axe={speed=1}},camera={trauma=0,screenToWorld=function(_,x,y) return x,y end},world={nodes={}},setNotice=function() end}
local failures={}

local smoker=ClearcutMode.new(); smoker.job="fire"; smoker:startSmoking(game)
smoker:updateFireAttack(smoker.smoking.dur+1,game,false)
if type(smoker.drawSmokerCigarette)~="function" or not smoker:drawSmokerCigarette(game) then failures[#failures+1]="lit cigarette object missing from mouth" end

smoker:hurlMolotovAt(320,0,game)
if #smoker.molotovs~=1 or smoker.molotovs[1].dur<.22 or smoker.molotovs[1].dur>=.34 then failures[#failures+1]="flying cigarette did not receive the faster readable arc" end
smoker.molotovs[1].t=smoker.molotovs[1].dur*.5
fixture.reset()
assert(smoker:drawCigaretteProjectiles(0)==1)
local flightBody
for _,draw in ipairs(fixture.commands) do
    if draw.shader=="assets/shaders/cigarette-butt-burn.glsl" then flightBody=draw end
end
assert(flightBody and flightBody.file=="assets/characters/ingame/smoker-cigarette-butt-pixel-v1.png","flying native-pixel butt missing")
assert(flightBody.filter=="nearest" and math.abs(flightBody.args[4]*256-32)<.01,"flying butt unreadable or blurred")
assert(love.graphics.getShader()==nil,"flight shader leaked")

local developer=ClearcutMode.new(); developer.job="developer"
developer:updateDeveloperAttack(0,game,false)
if math.abs((developer.aimX or 0)-200)>.01 or developer.aimRadius~=55 then failures[#failures+1]="developer telegraph does not match level-0 dash geometry" end
developer:startDash(developer.aimX or 0,developer.aimY or 0,game)
if not developer.dashing or math.abs(developer.dashing.remaining-(developer.aimX or 0))>.01 then failures[#failures+1]="developer actual dash distance differs from telegraph" end
developer.dashing=nil; developer.levels.pile_driving=3; developer.levels.heavy_machinery=3
developer:updateDeveloperAttack(0,game,false)
-- 200 + power(3)*70 = 200 + 2.0*70 = 340; 55 + power(3)*20 = 55 + 2.0*20 = 95 (레벨→파워 곡선 재설계 반영)
if math.abs((developer.aimX or 0)-340)>.01 or developer.aimRadius~=95 then failures[#failures+1]="developer upgraded telegraph geometry is wrong" end

assert(#failures==0,table.concat(failures,"; "))
print("SMOKER_OBJECTS_AND_DEVELOPER_RANGE_OK")

-- Ground persistence, immediate first contact, then delayed probabilistic spread.
local Butts=require("src.cigarette_butts")
local Art=require("src.cigarette_butt_art")
local function tree(x,y) return {kind="tree",rushTree=true,active=true,x=x,y=y or 0,rushHp=3,rushMaxHp=3} end
local function setup(nodes)
    local m=ClearcutMode.new();m.job="fire"
    return m,{player=player,world={nodes=nodes,igniteFx=function() end}}
end
local function throw(m,x,y,target)
    m.molotovs[#m.molotovs+1]={x0=-100,y0=-100,x1=x,y1=y,t=0,dur=.4,radius=90,target=target}
end
local function advance(m,g,seconds,step)
    local left=seconds
    while left>1e-8 do local dt=math.min(step or seconds,left);m:updateMolotovs(dt,g);left=left-dt end
end
local node=tree(50)
local m,g=setup({node});throw(m,0,0)
love.math.random=function() return 0 end
advance(m,g,.4)
assert(#m.molotovs==0 and #m.cigaretteButts==1 and node.burning,"landing did not ignite its nearest target immediately")
assert(#m.cigaretteLandingImpacts==1 and math.abs((m.cigaretteLandingImpacts[1].expiresAt-m.cigaretteLandingImpacts[1].startAt)-.42)<1e-6,
    "landing impact animation missing or mistimed")
local butt=m.cigaretteButts[1]
assert(#m.emberArrivals==1 and m.emberArrivals[1].instant and m.cigaretteHitStop==.03,
    "landing has no immediate authored impact/hit-stop beat")
assert(node.hitFlash>=.22 and node.hitShake>=.08 and math.abs(node.swayVel)>=1.85,
    "immediate ignition has no local tree recoil")

-- Active score mode starts deliberately restrained, then the early permanent
-- research node restores the complete contact package without changing spread.
local lockedTree=tree(50);local locked,lockedGame=setup({lockedTree});locked.scoreAttack=true;throw(locked,0,0)
advance(locked,lockedGame,.4)
assert(not lockedTree.burning and locked.cigaretteHitStop==0 and #locked.emberArrivals==0,
    "fresh score-mode save already has the researched cigarette impact")
advance(locked,lockedGame,.16)
assert(#locked.emberTransfers==1 and not lockedTree.burning,
    "fresh score-mode save lost the slightly delayed visible ember path")
local unlockedTree=tree(50);local unlocked,unlockedGame=setup({unlockedTree});unlocked.scoreAttack=true
unlocked.permanentTraits.scoreCigaretteImpact=1;throw(unlocked,0,0);advance(unlocked,unlockedGame,.4)
assert(unlockedTree.burning and unlocked.cigaretteHitStop==.03 and unlocked.emberArrivals[1].instant,
    "early impact research did not restore the complete landing feedback")

-- The same butt still spreads after the warm-up using the visible spark path.
local spread=tree(45);g.world.nodes[#g.world.nodes+1]=spread
advance(m,g,.14)
assert(butt.attempts==0 and #m.emberTransfers==0,"spread rolled before warm-up")
advance(m,g,.02)
assert(butt.attempts==1 and #m.emberTransfers==1 and not spread.burning,"spread must launch a visible spark first")
local transfer=m.emberTransfers[1]
assert(spread.cigaretteEmber==transfer,"spark did not reserve its target")
advance(m,g,transfer.arrivesAt-m.smokerGroundTime-.001)
assert(not spread.burning,"spread target ignited before spark arrival")
advance(m,g,.002)
assert(spread.burning and spread.burnTimer==0 and spread.spreadDepth==0 and not spread.cigaretteEmber,"spark arrival did not ignite exactly once")
assert(#m.emberTransfers==0,"arrived spread spark was not removed")

-- Failing all rolls still consumes lifetime and leaves brief cold ash.
local failed=tree(45)
local f,fg=setup({});throw(f,0,0)
love.math.random=function() return 1 end
advance(f,fg,.4);fg.world.nodes={failed};advance(f,fg,7,.016)
assert(not failed.burning and f.cigaretteButts[1].attempts>=12,"failure was replaced by guaranteed ignition or retry cadence stayed slow")
assert(f.cigaretteButts[1].phase=="cold" and #f.emberTransfers==0,"expired butt remains hot")
advance(f,fg,1.51)
assert(#f.cigaretteButts==0,"cold litter never cleaned up")

-- Radius, inactive/burning trees, and no-tree rolls.
local outside,inactive,already=tree(91),tree(10),tree(20)
inactive.active=false;already.burning=true
local isolated,ig=setup({outside,inactive,already});throw(isolated,0,0)
local rolls=0;love.math.random=function() rolls=rolls+1;return 0 end
advance(isolated,ig,3)
assert(rolls==0 and #isolated.emberTransfers==0 and not outside.burning,"ineligible tree received an ember")

-- Distance and dry-forest upgrades affect chance, not guaranteed landing ignition.
local function probabilityAt(distance,dry)
    local n=tree(distance);local p,pg=setup({});p.levels.dry_forest=dry;throw(p,0,0)
    love.math.random=function() return .82 end
    advance(p,pg,.4);pg.world.nodes={n};advance(p,pg,.16)
    assert(not n.burning)
    return #p.emberTransfers
end
assert(probabilityAt(0,0)==1 and probabilityAt(90,0)==0 and probabilityAt(90,3)==1,"distance/dry chance tuning not connected")

-- Pending targets are not duplicated across simultaneous butts.
local shared=tree(35);local overlap,og=setup({shared})
throw(overlap,0,0);throw(overlap,1,0);love.math.random=function() return 0 end
advance(overlap,og,.56)
assert(shared.burning and #overlap.emberTransfers==0,"simultaneous landings struck the same target more than once")
shared.active=false
advance(overlap,og,1)
assert(shared.burning and not shared.cigaretteEmber,"immediate target kept a stale ember reservation")

-- Rain cancels in-flight sparks, extinguishes ground butts, and never relights them.
local wetTree=tree(50);local rain,rg=setup({});throw(rain,0,0)
advance(rain,rg,.4);rg.world.nodes={wetTree};advance(rain,rg,.16);assert(#rain.emberTransfers==1)
rain.rainSuppressFire=true;advance(rain,rg,.01)
assert(#rain.emberTransfers==0 and rain.cigaretteButts[1].phase=="wet" and not wetTree.cigaretteEmber)
rain.rainSuppressFire=false;advance(rain,rg,1)
assert(not wetTree.burning,"wet butt relit when rain stopped")
local rainy,rng=setup({tree(0)});rainy.rainSuppressFire=true;throw(rainy,0,0);advance(rainy,rng,.4)
assert(rainy.cigaretteButts[1].phase=="wet","landing in rain did not extinguish")

-- An already burning target cancels an incoming spark without restarting its fire.
local live=tree(40);local race,raceGame=setup({live});throw(race,0,0);advance(race,raceGame,.56)
live.burnTimer=2
advance(race,raceGame,1)
assert(live.burnTimer==2 and not live.cigaretteEmber,"arrival restarted an existing fire")

-- Auto throws release their old flight reservation and use the SAME ground rules.
love.math.random=math.random
local autoTree=tree(80,20);local auto,ag=setup({autoTree})
auto:throwMolotov(ag);assert(autoTree.igniting and #auto.molotovs==1)
advance(auto,ag,auto.molotovs[1].dur)
assert(not autoTree.igniting and autoTree.burning and #auto.cigaretteButts==1,"auto throw lacks immediate landing contact")
-- Fresh drum oil overrides the ordinary tree target. Once that puddle group is
-- already burning, the exact old tree-selection path resumes.
local oilTree=tree(80,20);local oilAuto,oilGame=setup({oilTree})
local freshOil={x=210,y=45,source="drum",spawnedAt=0,lifetime=20,group="drum_auto",ignited=false}
oilAuto.smokerGroundTime=1;oilAuto.oilTrail={freshOil};oilAuto.oilPuddleGroups={drum_auto={ignited=false}}
oilAuto:throwMolotov(oilGame)
assert(oilAuto.molotovs[1].target==freshOil and oilAuto.molotovs[1].x1==freshOil.x and oilAuto.molotovs[1].y1==freshOil.y,
    "automatic cigarette did not prioritize the center of fresh drum oil")
oilAuto.molotovs={};freshOil.igniting=nil;oilAuto.oilTrail[#oilAuto.oilTrail+1]=
    {x=225,y=50,source="drum",spawnedAt=0,lifetime=20,group="drum_auto",ignited=true}
oilAuto:throwMolotov(oilGame)
assert(oilAuto.molotovs[1].target==oilTree and oilTree.igniting,
    "burning drum oil did not restore the original tree targeting")
local barrage,bg=setup({});barrage.levels.molotov=6;bg.setNotice=function() end -- barrage bonus now gates on the new max (6), not the old max (3)
for i=1,3 do barrage:hurlMolotovAt(40,0,bg) end
assert(#barrage.molotovs==5,"barrage throw count changed")
advance(barrage,bg,1)
assert(#barrage.cigaretteButts==5,"barrage bypassed persistent butts")

-- Frame partitioning cannot grant extra probability rolls or change event order.
local function timeline(step)
    local n=tree(40);local tm,tg=setup({n});throw(tm,0,0)
    love.math.random=function() return 0 end
    advance(tm,tg,3,step)
    return tm.cigaretteButts[1].attempts,n.cigaretteIgnitedAt,#tm.emberTransfers
end
local a1,a2,a3=timeline(3);local b1,b2,b3=timeline(.016)
assert(a1==b1 and math.abs(a2-b2)<1e-7 and a3==b3,"ground fire depends on FPS")

-- Stage transition clears reservations and all new transient state.
local resetTree=tree(40);local reset,resetGame=setup({resetTree});throw(reset,0,0);advance(reset,resetGame,.56)
reset.generateForest=function() end;reset.arcanaPool=function() return {} end;reset.openUpgradeChoices=function() end
resetGame.world.width=1000;resetGame.world.height=1000;resetGame.camera={trauma=0};resetGame.setNotice=function() end
reset:advanceStage(resetGame)
assert(#reset.cigaretteButts==0 and #reset.emberTransfers==0 and #reset.emberArrivals==0 and not resetTree.cigaretteEmber,"stage leaked ground fire")

-- Real renderer: body in depth queue, smolder/transfer cues above it, no state mutation.
fixture.reset();local queue={};m:queueWorldActors(queue,0)
local attempts=butt.attempts
for _,item in ipairs(queue) do item.draw() end
m:drawCigaretteGroundEffects()
assert(butt.attempts==attempts and love.graphics.getShader()==nil,"drawing changed gameplay or leaked shader")
local nativeBody,smoke=false,false
for _,draw in ipairs(fixture.commands) do
    if draw.shader=="assets/shaders/cigarette-butt-burn.glsl" then nativeBody=true end
    if draw.shader=="assets/shaders/cigarette-ground-fx.glsl" and draw.uniforms.fxKind==2 then smoke=true end
end
assert(nativeBody and smoke,"persistent butt/smoke not drawn through production paths")
print("SMOKER_GROUND_EMBERS_OK base=delayed research=instant_first+.03_hitstop spread=delayed_chance expiry=7s rain=extinguish fps=independent")

if SMOKER_GROUND_CAPTURE then dofile("scripts/smoker_ground_capture.lua") end
