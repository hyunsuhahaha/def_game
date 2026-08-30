package.path="./?.lua;./?/init.lua;"..package.path
local Mode=require("src.clearcut_mode")

local mode=Mode.new();mode.job="fire";mode.sandbox=true
local seen={}
for _,def in ipairs(mode:sandboxSkillList())do seen[def.id]=true end
assert(seen.molotov and seen.seed_mine and not seen.berserker,"practice skill catalog is not job + shared")

local branches=mode:sandboxBranchList();local foundRoute=false
for _,group in ipairs(branches)do if group.skill=="molotov"then
    assert(group.trigger==3 and #group.choices==2,"smoker rank-three route choices are incomplete")
    foundRoute=true
end end
assert(foundRoute,"locked smoker route is not discoverable in practice")
assert(not mode:sandboxSetBranch("molotov","flame_route"),"smoker route was selectable below level three")
mode:sandboxSetLevel("molotov",99)
assert(mode:sandboxSetBranch("molotov","flame_route") and mode:skillBranch("molotov")=="flame_route","practice did not equip the flame route")
assert(mode:smokerEvolutionId()=="vape","max-rank flame route did not auto-evolve into vape")
mode:sandboxSetLevel("molotov",-1)
assert(mode:skillBranch("molotov")=="flame_route"and not mode:smokerEvolutionId(),"vape remained active below level six or route was lost")
mode:sandboxSetLevel("molotov",-99)
assert(not mode:skillBranch("molotov"),"smoker route remained below its rank-three trigger")

mode:sandboxSetAllSkills(true)
assert(mode:levelOf("molotov")==6 and mode:levelOf("chain_lightning")==6,"max-all did not fill practice skills")
mode:sandboxSetAllSkills(false)
assert(mode:levelOf("molotov")==0 and mode:levelOf("chain_lightning")==0,"practice reset did not clear skills")

local gameSource=assert(io.open("src/game.lua","rb")):read("*a")
assert(gameSource:find("sandboxBranchBoxes",1,true) and gameSource:find("sandboxMaxBox",1,true) and gameSource:find("sandboxPanelScroll",1,true),"practice controls are not wired to the panel")
assert(gameSource:find('UI.button(plusBox.x,plusBox.y,plusBox.w,plusBox.h,"+",level<def.max',1,true),"practice skill plus control is not explicit/enabled")
assert(gameSource:find("sandboxSetLevel(box.id,1,self)",1,true),"practice plus button does not open the real rank-three branch flow")
local sandboxGuard=assert(gameSource:find("if self.clearcut and self.clearcut.sandbox and button==1 and self:sandboxPanelClick(x, y) then return end",1,true))
local endedGuard=assert(gameSource:find("if self.ended then return end",sandboxGuard,true))
assert(sandboxGuard<endedGuard,"practice panel input is blocked by gameplay end/emergence guards")
local dossier=assert(io.open("docs/character_dossier.html","rb")):read("*a")
assert(not dossier:find("시스템 연동",1,true) and not dossier:find("system%-note"),"internal system note is still visible in the dossier")
assert(dossier:find("화염 농축 %[인게임 구현%]")and dossier:find("흡입→압축→원뿔형 풍압",1,true)
    and dossier:find("연습장에서 꽁초 투척",1,true),"dossier does not expose live smoker routes/practice support")
print("SKILL_SANDBOX_OK rows=click-to-level smoker=rank3-route+rank6-auto-evolution shared=rank3 scroll=wheel dossier=clean")
