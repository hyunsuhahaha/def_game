package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Mode=require("src.clearcut_mode")
local Synergies=require("src.clearcut_synergies")
local Branches=require("src.clearcut_skill_branches")
local function tree(x,y,hp)return{x=x,y=y or 0,rushTree=true,active=true,rushHp=hp or 1000,rushMaxHp=hp or 1000}end
local function enemy(x,y)return{x=x,y=y or 0,hp=1000,maxHp=1000}end
local function game(nodes,enemies)
 local g={mode="clearcut_upgrade",player={x=0,y=0,facing=1},camera={trauma=0},world={nodes=nodes or {},
  impactNode=function()end,addParticle=function()end,harvestBurst=function()end,spawnDrop=function()end}}
 function g:setNotice()end;return g
end

-- Every live skill has exactly two authored tags; removed concepts cannot leak back.
local mode=Mode.new()
local seen={}
for _,job in ipairs({"physical","fire","toxic","developer","miner","philosopher"})do
 mode.job=job
 for _,def in ipairs(mode:sandboxSkillList())do assert(#def.tags==2,def.id.." missing synergy tags");seen[def.id]=true end
end
local liveCount=0;for _ in pairs(seen)do liveCount=liveCount+1 end
assert(liveCount==32,"live skill tag audit did not cover every definition: "..liveCount)
assert(not Synergies.skillTags.spore_cloud,"removed spore cloud returned through synergy data")
mode.levels={bat_swarm=1,crow_strike=6,seed_mine=2,thorn_aura=1}
local counts=Synergies.refresh(mode)
assert(counts.wild==2 and counts.growth==2 and counts.momentum==2,"unique-skill trait count is wrong")
assert(mode:synergyTier("wild")==2 and mode:synergyTier("growth")==2)

local ignition=Mode.new();ignition.levels={molotov=1,dry_forest=1,oil_drum=1,straw_bale=1}
assert(Synergies.ignitionChanceMultiplier(ignition)==1.38 and Synergies.ignitionRadiusMultiplier(ignition)==1.32,"ignition tier is display-only")

-- Rank three interrupts the ordinary draft with an unskippable specialization.
local branchMode=Mode.new();branchMode.levels.seed_mine=2;branchMode.choices={branchMode:getUpgradeDefinition("seed_mine")};branchMode.pending=1
local g=game()
assert(branchMode:choose(1,g) and branchMode.selectionKind=="branch" and #branchMode.branchChoices==3)
assert(branchMode:chooseBranch(2,g) and branchMode:skillBranch("seed_mine")=="scatter_mine" and g.mode=="playing")

-- All six branch identities change actual attack geometry/timing, not card copy only.
local e=enemy(0,300)
local heavy=Mode.new();heavy.levels.seed_mine=3;heavy.skillBranches.seed_mine="heavy_mine";heavy.enemies={e};local hg=game({},heavy.enemies);heavy:updateSeedMine(0,hg)
local plain=Mode.new();plain.levels.seed_mine=3;plain.enemies={enemy(0,300)};local pg=game({},plain.enemies);plain:updateSeedMine(0,pg)
assert(heavy.seeds[1].radius>plain.seeds[1].radius*1.4 and heavy.seeds[1].dmg>plain.seeds[1].dmg*1.3)
local scatter=Mode.new();scatter.levels.seed_mine=3;scatter.skillBranches.seed_mine="scatter_mine";scatter.seedTimer=99
scatter.seeds={{x=0,y=0,fuse=0,maxFuse=1,radius=100,dmg=20,branch="scatter_mine"}};scatter.enemies={}
scatter:updateSeedMine(.01,game({},{}));assert(#scatter.seeds==6,"scatter mine did not release six secondary seeds")
local sprout=Mode.new();sprout.levels.seed_mine=3;sprout.skillBranches.seed_mine="sprout_mine";sprout.seedTimer=99
sprout.seeds={{x=0,y=0,fuse=0,maxFuse=1,radius=100,dmg=20,branch="sprout_mine"}};sprout.enemies={}
sprout:updateSeedMine(.01,game({},{}));assert(#sprout.sproutFields==1 and sprout.sproutFields[1].life==4)

local target=enemy(100,0)
local broad=Mode.new();broad.levels.boomerang_axe=3;broad.skillBranches.boomerang_axe="broad_axe";broad.enemies={target};broad:updateBoomerangAxe(0,game({},broad.enemies))
local rapid=Mode.new();rapid.levels.boomerang_axe=3;rapid.skillBranches.boomerang_axe="rapid_return";rapid.enemies={enemy(100,0)};rapid:updateBoomerangAxe(0,game({},rapid.enemies))
assert(broad.boomerangs[1].radius>rapid.boomerangs[1].radius*1.4 and rapid.boomerangs[1].speed>broad.boomerangs[1].speed*1.5)
local ric=Mode.new();ric.levels.boomerang_axe=3;ric.skillBranches.boomerang_axe="ricochet_axe";ric.boomerangTimer=99
local r1,r2=enemy(12,0),enemy(100,80);ric.enemies={r1,r2};ric.boomerangs={{x=0,y=0,dx=1,dy=0,speed=480,traveled=0,maxDist=300,phase="out",hitSet={},dmg=2,radius=24,branch="ricochet_axe",ricochets=0}}
ric:updateBoomerangAxe(.03,game({},ric.enemies));assert(ric.boomerangs[1].ricochets==1 and ric.boomerangs[1].target==r2)

-- Late-game pressure accelerates restoration without changing ordinary tree HP.
local pressure=Mode.new();pressure.stage=4;pressure.level=36;pressure.stageElapsed=480
assert(pressure:forestPressure()>2 and pressure:forestPressure()<=2.65)
local oldHp=tree(0,0,9).rushMaxHp;pressure:forestPressure();assert(oldHp==9)

-- Two-piece waves exist; four-piece builds accelerate them to every seven trees.
local earlyBurst=Mode.new();earlyBurst.level=12;earlyBurst.levels={thorn_aura=1,seed_mine=1};earlyBurst.enemies={}
for i=1,12 do earlyBurst:recordSynergyFell({x=0,y=0})end
assert(#earlyBurst.friendlyGrowthBursts==1,"two-growth breakpoint has no gameplay effect")
local burst=Mode.new();burst.level=30;burst.levels={thorn_aura=1,vine_whip=1,seed_mine=1,forced_growth=1,
 wide_blade=1,shockwave=1,boomerang_axe=1,demolition=1};burst.enemies={}
for i=1,7 do burst:recordSynergyFell({x=0,y=0})end
assert(#burst.friendlyGrowthBursts>=2,"capstone synergies did not schedule clearing waves")

local source=assert(io.open("src/clearcut_mode.lua","rb")):read("*a")
assert(source:find("drawSynergyTooltip",1,true) and source:find("self.synergyBoxes",1,true),"hoverable synergy HUD missing")
assert(source:find("Synergies.previewCount",1,true),"draft cards do not preview synergy count changes")
local dossier=assert(io.open("docs/character_dossier.html","rb")):read("*a")
assert(dossier:find("const SYNERGIES",1,true) and dossier:find("const SYNERGY_TAGS",1,true),"dossier has no synergy reference")
for id in pairs(seen)do assert(dossier:find(id..':[',1,true),"dossier is missing tags for "..id)end
for skill in pairs(Branches.definitions)do assert(dossier:find(skill..':[',1,true),"dossier is missing branch choices for "..skill)end
print("CLEARCUT_SYNERGIES_OK live_tags="..liveCount.." branches=6 hover=cards+HUD ignition=real pressure=2.65 mass_clear=queued")
