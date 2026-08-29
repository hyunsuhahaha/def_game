package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
love.mouse={getPosition=function()return 240,0 end,isDown=function()return false end}
local Mode=require("src.clearcut_mode")
local Art=require("src.smoker_weapon_art")
local Branches=require("src.clearcut_skill_branches")

local function tree(x,y)
 return{x=x,y=y,rushTree=true,active=true,rushHp=100,rushMaxHp=100}
end
local function game(nodes)
 local world={nodes=nodes or {},playBounds={x=-1000,y=-1000,w=2000,h=2000}}
 function world:impactNode()end;function world:igniteFx()end;function world:addParticle()end
 function world:harvestBurst()end;function world:spawnDrop()end
 local player={x=0,y=0,facing=1,gather=1}
 function player:clearClearcutAction()self.clearcutActionProgress=nil end
 local g={mode="clearcut_upgrade",player=player,world=world,tools={axe={speed=1}},camera={screenToWorld=function(_,x,y)return x,y end}}
 function g:setNotice()end
 return g
end

assert(Branches.triggerLevel("molotov")==6 and #Branches.forSkill("molotov")==2,"max-rank smoker evolution choices missing")
local draft=Mode.new();draft.job="fire";draft.levels.molotov=5;draft.pending=1
draft.choices={draft:getUpgradeDefinition("molotov")};local dg=game({tree(200,0)})
assert(draft:choose(1,dg) and draft.selectionKind=="branch" and draft.branchChoiceSkill=="molotov","molotov level six did not open evolution")
assert(draft:chooseBranch(1,dg) and draft:skillBranch("molotov")=="vape" and dg.mode=="playing","vape evolution could not be chosen")
local fusionDraft=Mode.new();fusionDraft.job="fire";fusionDraft.levels={molotov=5,dry_forest=6};fusionDraft.pending=1
fusionDraft.choices={fusionDraft:getUpgradeDefinition("molotov")};local fdg=game({tree(200,0)})
assert(fusionDraft:choose(1,fdg) and fusionDraft.selectionKind=="branch")
assert(fusionDraft:chooseBranch(2,fdg) and fusionDraft.selectionKind=="fusion","weapon evolution swallowed a ready smoker fusion")

local vape=Mode.new();vape.job="fire";vape.levels.molotov=6;vape.skillBranches.molotov="vape"
local vt=tree(120,-30);local vg=game({vt})
assert(vape:updateFireAttack(0,vg,true) and vape.actionAudit.vapeShot==1 and vape.smokerWeaponProjectiles[1].kind=="vape")
vape:updateSmokerWeaponProjectiles(.16,vg);assert(vt.rushHp<100,"visible vape plume missed its swept tree envelope")
vape.molotovTimer=3;vape:updateFire(.01,vg);assert(#vape.molotovs==1,"max-rank cigarette did not remain as an automatic passive")

local fireworks=Mode.new();fireworks.job="fire";fireworks.levels.molotov=6;fireworks.skillBranches.molotov="fireworks"
local ft=tree(240,0);local fg=game({ft})
assert(fireworks:updateFireAttack(0,fg,true) and fireworks.actionAudit.fireworkShot==1)
fireworks:updateSmokerWeaponProjectiles(1,fg)
assert(ft.rushHp<100,"firework burst did not damage its displayed landing area")
local foundBurst=false;for _,p in ipairs(fireworks.smokerWeaponProjectiles)do if p.kind=="firework_burst"then foundBurst=true end end
assert(foundBurst,"firework flight did not become an animated multicolour burst")

fixture.reset();Art.drawChoice("vape",100,100,.8);Art.drawChoice("fireworks",240,100,.8)
for _,p in ipairs({{kind="vape",x=100,y=240,age=.3,maxLife=.72,angle=0},{kind="firework",x=240,y=240,age=.2,dur=.5,angle=0},{kind="firework_burst",x=390,y=240,age=.45,life=.82}})do Art.drawProjectile(p)end
local equipment,fx=0,0
for _,command in ipairs(fixture.commands)do if command.op=="draw"then
 if command.file=="assets/characters/ingame/smoker-weapon-evolution-equipment-v1.png"then equipment=equipment+1 end
 if command.file=="assets/effects/smoker-weapon-evolution-fx-v1.png"then fx=fx+1 end
end end
assert(equipment==2 and fx==3,"production atlases were not used by choice/projectile draw paths")
local burstDraw=fixture.commands[#fixture.commands]
assert(burstDraw.op=="draw" and math.abs(burstDraw.args[4]-360/192)<.001,"firework visual diameter does not match radius-180 gameplay")
local integrated=Mode.new();integrated.job="fire";integrated.skillBranches.molotov="fireworks"
integrated.smokerWeaponProjectiles={{kind="firework_burst",x=333,y=222,age=.3,life=.82,radius=180}}
local ig=game({});ig.world.billboardQueue={};integrated:queueProjectedOverlay(ig,.3)
local queued=false;for _,entry in ipairs(ig.world.billboardQueue)do if entry.x==333 and entry.y==222 then fixture.reset();entry.draw();queued=true end end
assert(queued and fixture.commands[1],"smoker evolution FX did not enter the upright 2.5D billboard pass")
print("SMOKER_WEAPON_EVOLUTIONS_OK choice=Lv6 vape=swept_pierce fireworks=arc+burst cigarette=passive art=nearest")
