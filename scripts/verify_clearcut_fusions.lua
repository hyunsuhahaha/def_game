package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
love.math.random=function(a,b) if b then return a elseif a then return 1 else return .99 end end
love.mouse={getPosition=function() return -1,-1 end,isDown=function() return false end}
love.graphics.getDimensions=function() return 1280,720 end
local Mode=require("src.clearcut_mode")
local Fusions=require("src.clearcut_fusions")
local Game=require("src.game")
local function tree(x,hp,active)
    return {kind="tree",rushTree=true,x=x,y=0,active=active~=false,rushHp=hp or 20,rushMaxHp=hp or 20}
end
local function setup(job,nodes)
    local mode=Mode.new();mode.job=job;mode.remainingTrees=100;mode.initialTrees=100
    mode.checkMilestones=function() end
    local game={mode="playing",clearcut=mode,wood=0,player={x=-500,y=0},tools={axe={speed=1}},camera={trauma=0},
        setNotice=function(self,text) self.notice=text end,
        world={nodes=nodes or {},impactNode=function() end,addParticle=function() end,spawnDrop=function() end,
            harvestBurst=function(_,node) node.fallDir=-1 end,igniteFx=function() end,toxicPulseFx=function() end}}
    return mode,game
end
local function maxIngredients(mode,def)
    for _,id in ipairs(def.needs) do mode.levels[id]=mode:getUpgradeDefinition(id).max end
end
local fonts={}
for id,size in pairs({small=14,body=17,heading=21,big=28,title=36}) do
    fonts[id]=love.graphics.newFont("assets/font-korean-"..((id=="small" or id=="body") and "regular" or "bold")..".ttf",size)
end

-- Exercise the last real upgrade selection, not only a direct flag assignment.
for _,def in ipairs(Fusions.definitions) do
    local m,g=setup(def.job or "fire")
    maxIngredients(m,def)
    local last=def.needs[2];m.levels[last]=m.levels[last]-1
    assert(not m:checkEvolutions(g),def.id.." unlocked early")
    m.pending=1;m.choices={m:getUpgradeDefinition(last)};g.mode="clearcut_upgrade"
    assert(m:choose(1,g))
    assert(g.mode=="clearcut_upgrade" and m.selectionKind=="fusion" and m.fusionChoice.id==def.id,def.id.." acquisition screen missing")
    assert(not m.evolutions[def.id] and m.pending==0,"fusion granted before confirmation / charged extra level")
    m:checkEvolutions(g);assert(m.fusionChoice.id==def.id,"recheck lost acquisition")
    m.totalWood=100
    assert(not m:choose("reroll",g) and not m:choose("banish",g) and not m:choose("special",g) and not m:choose(2,g))
    fixture.reset();m:drawSelection(g,fonts)
    local box=assert(m.choiceBoxes[1]);assert(m:choiceAt(box.x+5,box.y+5)==1)
    assert(box.x>=0 and box.y+box.h<=720,"acquisition card clipped")
    local text="";for _,op in ipairs(fixture.commands) do text=text..(op.text or "") end
    assert(text:find(def.name,1,true) and text:find("MAX",1,true) and text:find(def.desc,1,true),"card omits requirements/effect")
    if FUSION_CAPTURE then fixture.save("docs/previews/fusion-"..def.id.."-draws.json") end
    fixture.time=(fixture.time or 0)+1 -- clear the post-reveal input lock before simulating the real click/keypress
    if def.id=="wildfire" then Game.keypressed(g,"return")
    elseif def.id=="newtown" then Game.mousepressed(g,box.x+5,box.y+5,1)
    else assert(m:choose(1,g)) end
    assert(m.evolutions[def.id] and g.mode=="playing" and m.pending==0,def.id.." was not acquired")
    assert(not m:checkEvolutions(g) and not m:choose(1,g),"fusion can be acquired twice")
    assert(#Fusions.activeNames(m)==1,"HUD omits acquired fusion")
    if def.job then
        local wrong,wg=setup(def.job=="fire" and "physical" or "fire");maxIngredients(wrong,def)
        assert(not Fusions.ready(wrong,def),"wrong-job fusion unlocked")
    end
end

-- Smallest supported window uses the same UI layout and screen-space hit boxes.
local small,sg=setup("fire");maxIngredients(small,Fusions.definitions[1]);small:checkEvolutions(sg)
love.graphics.getDimensions=function() return 960,540 end
fixture.reset();small:drawSelection(sg,fonts)
local smallBox=small.choiceBoxes[1]
assert(smallBox.x+smallBox.w<=960 and smallBox.y+smallBox.h<=540)
assert(small:choiceAt(smallBox.x+smallBox.w/2,smallBox.y+smallBox.h/2)==1,"scaled click misses acquisition")
if FUSION_CAPTURE then fixture.save("docs/previews/fusion-wildfire-small-draws.json") end
love.graphics.getDimensions=function() return 1280,720 end

-- Independently completed recipes are queued and guaranteed without consuming XP.
local m,g=setup("fire")
m.levels={molotov=m:getUpgradeDefinition("molotov").max,dry_forest=m:getUpgradeDefinition("dry_forest").max,
    straw_bale=m:getUpgradeDefinition("straw_bale").max,oil_drum=m:getUpgradeDefinition("oil_drum").max};m.pending=2
assert(m:checkEvolutions(g) and m.fusionChoice.id=="wildfire")
assert(m:choose(1,g) and m.fusionChoice.id=="oilRoad" and m.pending==2)
assert(m:choose(1,g) and m.selectionKind=="upgrade" and m.pending==2 and #m.choices>0)
assert(m.evolutions.wildfire and m.evolutions.oilRoad)
fixture.reset();m:drawHUD(g,fonts)
local hud="";for _,op in ipairs(fixture.commands) do hud=hud..(op.text or "") end
assert(hud:find("산불",1,true) and hud:find("기름을 실수로 붓다",1,true),"HUD omits acquired fusions")
fixture.reset();Fusions.drawProgress(m,fonts)
if FUSION_CAPTURE then fixture.save("docs/previews/fusion-progress-draws.json") end

-- Chest reward is separate from pending XP. Banish cannot sneak through a chest.
local chest,cg=setup("fire");chest.pending=2;chest.levels={molotov=chest:getUpgradeDefinition("molotov").max,dry_forest=chest:getUpgradeDefinition("dry_forest").max-1}
chest.banishArmed=true;chest:openChest(cg)
assert(not chest.banishArmed and chest.chestPending)
chest.choices={chest:getUpgradeDefinition("dry_forest")}
assert(chest:choose(1,cg) and chest.selectionKind=="fusion" and chest.pending==2)
assert(chest:choose(1,cg) and chest.pending==2 and chest.selectionKind=="upgrade")
-- A ready fusion cannot consume a newly collected chest or overwrite another modal.
local deferred,dfg=setup("fire");local moloMax,dryMax=deferred:getUpgradeDefinition("molotov").max,deferred:getUpgradeDefinition("dry_forest").max
deferred.levels={molotov=moloMax,dry_forest=dryMax}
deferred:openChest(dfg);assert(deferred.selectionKind=="fusion")
assert(deferred:choose(1,dfg) and deferred.chestPending and #deferred.choices>0)
local nearby,ng=setup("fire");ng.player.x=0
nearby.chests={{x=0,y=0},{x=0,y=0}}
nearby:updateChests(.01,ng)
assert(nearby.chests[1].collected and not nearby.chests[2].collected,"second chest overwrote first reward")
nearby:updateChests(.01,ng);assert(not nearby.chests[2].collected,"chest collected behind modal")
local all,ag=setup("physical")
for _,def in ipairs(all:upgradePool()) do all.levels[def.id]=def.max end
all.pending=1;all:openUpgradeChoices(ag)
assert(all.selectionKind=="fusion" and all.fusionChoice.id=="frenzy");all:choose(1,ag)
assert(all.choices[1].recovery and all.pending==1,"all-max run deadlocked")
all.hp=50;assert(all:choose(1,ag) and all.hp==70 and ag.mode=="playing" and all.pending==0)
local banned,bg=setup("physical")
banned.choices={banned:getUpgradeDefinition("wide_blade")};banned.totalWood=100;banned.banishArmed=true
for _,def in ipairs(banned:upgradePool()) do if def.id~="wide_blade" then banned.banished[def.id]=true end end
assert(banned:choose(1,bg) and banned.choices[1].recovery,"empty banish pool deadlocked")

-- Requirement levels come from upgrade definitions, not a second hardcoded max.
local dynamic,dyg=setup("fire");maxIngredients(dynamic,Fusions.definitions[1])
local secondId=Fusions.definitions[1].needs[2]
local ingredient=dynamic:getUpgradeDefinition(secondId);local oldMax=ingredient.max
ingredient.max=4;dynamic.levels[secondId]=3
assert(not Fusions.ready(dynamic,Fusions.definitions[1]))
dynamic.levels[secondId]=4;assert(Fusions.ready(dynamic,Fusions.definitions[1]));ingredient.max=oldMax

-- Real effects: wildfire keeps ground landing, strengthens spreading only after fire.
local fire,fg=setup("fire",{tree(0),tree(180)})
fire.levels={molotov=3,dry_forest=3};fire.evolutions.wildfire=true;fire.molotovTimer=-100
fire:updateFire(3,fg);assert(#fire.molotovs==1,"wildfire extra projectile missing")
fire:updateMolotovs(2,fg);assert(#fire.cigaretteButts==1 and not fg.world.nodes[1].burning,"fusion bypassed smolder stage")
local function spread(fused)
    local a,b=tree(0),tree(170);a.burning=true;a.burnTimer=0
    local mode,game=setup("fire",{a,b});mode.evolutions.wildfire=fused
    love.math.random=function() return 0 end
    mode:updateFire(.1,game)
    love.math.random=function(a,b) if b then return a elseif a then return 1 else return .99 end end
    return b.burning
end
assert(not spread(false) and spread(true),"wildfire spread range unchanged")

-- Eternal Return is a persistent field: it keeps ticking and catches late entrants.
local pTree,pLate=tree(0,30),tree(260,30)
local philosopher,pg=setup("philosopher",{pTree,pLate});philosopher.evolutions.eternal_return=true
philosopher.levels={footnote=philosopher:getUpgradeDefinition("footnote").max,saliva_gland=philosopher:getUpgradeDefinition("saliva_gland").max}
philosopher.aimRadius=70;philosopher:spawnEternalField(0,0,pg)
assert(#philosopher.eternalFields==1 and pTree.rushHp==30,"eternal field did not persist before its tick")
philosopher:updateEternalFields(.01,pg)
assert(pTree.rushHp<30 and pTree.plagueMarked and pLate.rushHp==30,"eternal field first tick/radius wrong")
pLate.x=40;philosopher:updateEternalFields(.6,pg)
assert(pLate.rushHp<30 and pLate.plagueMarked,"late entrant ignored by eternal field")

-- Revival fusion launches three authored chorus packets and damages only on arrival.
local r1,r2,r3=tree(0,40),tree(70,40),tree(140,40)
local revival,rg=setup("philosopher",{r1,r2,r3});revival.evolutions.revival_chorus=true
revival.levels={monologue=revival:getUpgradeDefinition("monologue").max,revival_meeting=revival:getUpgradeDefinition("revival_meeting").max}
assert(revival:activateRevival(rg));revival:updateRevival(.01,rg)
assert(#revival.revivalChorusShots==3 and r1.rushHp==40,"revival chorus skipped its travel phase")
revival:updateRevival(1,rg)
assert(#revival.revivalChorusShots==0 and #revival.revivalChorusImpacts>=3 and r1.rushHp<40,"revival chorus arrival did not hit")

-- Both fusion effects render from authored nearest-filter atlases, not runtime circles.
local FusionArt=require("src.philosopher_fusion_art")
fixture.reset();local queue={};FusionArt.queue(philosopher,queue);for _,item in ipairs(queue) do item.draw() end
revival.revivalChorusShots={{sx=0,sy=0,tx=100,ty=0,t=.2,dur=.5,radius=56}};FusionArt.draw(revival)
local artFiles="";for _,op in ipairs(fixture.commands) do artFiles=artFiles..(op.file or "") end
assert(artFiles:find("eternal%-return%-field%-atlas") and artFiles:find("revival%-chorus%-atlas"),"philosopher fusion atlases not rendered")

local function frenzy(streak,enabled)
    local p,q=tree(0,10),tree(130,10)
    local mode,game=setup("physical",{p,q});mode.streak=streak;mode.evolutions.frenzy=enabled
    mode.levels={berserker=3,shockwave=3};mode.enemies={{x=130,y=0,hp=100}}
    mode:hitTree(p,game)
    return q.rushHp,mode.enemies[1].hp,#mode.traitFx.events
end
assert(frenzy(8,true)==10 and frenzy(9,false)==10,"frenzy active without threshold/fusion")
local hp,enemyHp,fx=frenzy(9,true);assert(hp==7 and enemyHp==88 and fx==1,"frenzy lacks tree/enemy shockwave")

local n1,n2=tree(120,1,false),tree(300)
local dev,dg2=setup("developer",{n1,n2});dg2.player.x=0
dev.evolutions.newtown=true;dev.dashing={dx=1,dy=0,angle=0,remaining=0,width=55,hitSet={}}
dev:updateDash(.01,dg2)
assert(n1.sterile and not n2.sterile,"newtown footprint wrong")

-- Stage transition keeps acquired fusions, clears transient combat state only.
all.generateForest=function() end
ag.camera={trauma=0};ag.world.width=1000;ag.world.height=1000
all:advanceStage(ag)
assert(all.evolutions.frenzy,"stage reset erased fusions")

-- Existing upgrade/arcana cards still run through the scaled wrapper. Their
-- legacy stencil decorations are not rasterized by this interaction check.
love.graphics.stencil=function(fn) fn() end
love.graphics.setStencilTest=function() end
love.graphics.polygon=function() end
love.graphics.rotate=function() end
for _,job in ipairs({"physical","fire","toxic","developer"}) do
    local ui,ug=setup(job);ui:openUpgradeChoices(ug)
    love.graphics.getDimensions=function() return 960,540 end
    fixture.reset();ui:drawSelection(ug,fonts)
    for i,box in ipairs(ui.choiceBoxes) do
        assert(box.y+box.h<=540 and ui:choiceAt(box.x+box.w/2,box.y+box.h/2)==i,"scaled upgrade hit box wrong")
    end
    assert(ui.rerollBox.y+ui.rerollBox.h<=540,"scaled reroll clipped")
    ui.selectionKind="arcana";ui:rollArcanaChoices();ui:drawSelection(ug,fonts)
    assert(#ui.choiceBoxes==3 and not ui.rerollBox,"arcana inherited stale upgrade controls")
end
print("CLEARCUT_FUSIONS_OK recipes="..#Fusions.definitions.." acquisition=guaranteed multi=queued chest=separate persistent=verified chorus=verified")
