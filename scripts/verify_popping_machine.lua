package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Popper=require("src.popping_machine")
local Traits=require("src.character_traits")

local function tree(x,hp)return{rushTree=true,active=true,x=x,y=0,rushHp=hp,rushMaxHp=hp}end
local source={active=true,burning=true,x=0,y=0}
local trees={tree(120,20),tree(240,20),tree(360,20),tree(480,20),tree(600,20)}
local world={nodes={source,trees[1],trees[2],trees[3],trees[4],trees[5]},width=900,height=600}
function world:impactNode()end
local mode={scoreAttack=true,permanentTraits={scorePopperUnlock=1},poppingMachines={{x=0,y=0,state="cold",heat=0,life=0,recoil=0,shake=0}},puffedRiceShots={},puffedRiceImpacts={},poppingMachineTimer=99,poppingMachineSequence=1,oilTrail={},_popperWorld=world}
function mode:fellTree(node)node.active=false;return true end
local game={world=world,player={x=0,y=0}}
for _=1,260 do Popper.update(mode,.02,game)end
assert(trees[1].rushHp==16 and trees[2].rushHp==16 and trees[3].rushHp==16,"base puffed rice did not damage three consecutive trees")
assert(trees[1].active and trees[2].active and trees[3].active,"base puffed rice incorrectly one-shot a normal tree")
assert(trees[4].rushHp==20,"base puffed rice exceeded its contact count")

mode.permanentTraits.scorePopperDamage=10;mode.permanentTraits.scorePopperBounces=2
mode.poppingMachines[1].state="heating";mode.poppingMachines[1].heat=2.79
for _=1,150 do Popper.update(mode,.02,game)end
for index=1,3 do assert(trees[index].rushHp==2,"upgraded puffed rice failed to revisit surviving tree "..index)end
for index=4,5 do assert(trees[index].rushHp==6,"upgraded puffed rice failed to continue through new tree "..index)end

local store=Traits.new(true);local count=0
for _,node in ipairs(store:getScoreAttackNodes("fire"))do if node.id:match("^fire_score_popper")then count=count+1;assert(node.max==1,"popper node has stacked ranks: "..node.id)end end
assert(count==9,"popper research branch is incomplete")
fixture.reset();Popper.queue(mode,{});Popper.load()
print("POPPING_MACHINE_OK base_damage=4 base_contacts=3 upgraded_damage=14 upgraded_contacts=5 survivor_chain=true nodes=9")
