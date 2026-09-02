package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Popper=require("src.popping_machine")
local Traits=require("src.character_traits")

local function tree(x,hp)return{rushTree=true,active=true,x=x,y=0,rushHp=hp,rushMaxHp=hp}end
local source={active=true,burning=true,x=0,y=0}
local trees={tree(120,20),tree(240,20),tree(360,20),tree(480,20),tree(600,20)}
local world={nodes={source,trees[1],trees[2],trees[3],trees[4],trees[5]},width=900,height=600}
function world:impactNode()end
local mode={scoreAttack=true,permanentTraits={scorePopperUnlock=1},poppingMachines={},puffedRiceShots={},puffedRiceImpacts={},poppingMachineSequence=0,oilTrail={},cigaretteButts={},_popperWorld=world}
function mode:fellTree(node)node.active=false;return true end
local game={world=world,player={x=0,y=0}}
Popper.update(mode,.01,game)
assert(#mode.poppingMachines==1 and mode.poppingMachines[1].state=="cooldown","persistent monkey cart did not spawn in the map")
local cart,id=mode.poppingMachines[1],mode.poppingMachines[1].id
cart.x,cart.y,cart.state,cart.cooldown=0,0,"ready",0
for _=1,260 do Popper.update(mode,.02,game)end
source.burning=false
assert(trees[1].rushHp==13 and trees[2].rushHp==13 and trees[3].rushHp==13 and trees[4].rushHp==13,"base puffed rice did not damage four consecutive trees")
assert(trees[1].active and trees[2].active and trees[3].active and trees[4].active,"base puffed rice incorrectly one-shot a normal tree")
assert(trees[5].rushHp==20,"base puffed rice exceeded its contact count")

-- A shot whose target was felled by another weapon must retarget even when the
-- next living tree is outside the normal bounce radius.
local vanished,farTree=tree(0,20),tree(900,20);vanished.active=false
local retargetWorld={nodes={vanished,farTree},width=1200,height=600}
function retargetWorld:impactNode()end
local retargetMode={scoreAttack=true,permanentTraits={scorePopperUnlock=1},
    poppingMachines={{x=0,y=0,state="cooldown",cooldown=100,life=0,facing=1}},poppingMachineSequence=1,
    puffedRiceShots={{x=0,y=0,fromX=0,fromY=0,target=vanished,t=0,dur=.3,used={},contacts=0,maxContacts=3,damage=4,spin=0}},
    puffedRiceImpacts={},oilTrail={},cigaretteButts={}}
function retargetMode:fellTree(node)node.active=false;return true end
Popper.update(retargetMode,.01,{world=retargetWorld,player={x=0,y=0}})
assert(#retargetMode.puffedRiceShots==1 and retargetMode.puffedRiceShots[1].target==farTree,
    "puffed rice vanished instead of retargeting after its target disappeared")

mode.permanentTraits.scorePopperDamage=10;mode.permanentTraits.scorePopperBounces=2
cart.x,cart.y,cart.state,cart.heat=0,0,"heating",2.19
for _=1,150 do Popper.update(mode,.02,game)end
for index=1,4 do assert(trees[index].rushHp==-4,"upgraded puffed rice failed to revisit surviving tree "..index)end
assert(trees[5].rushHp==3,"upgraded puffed rice failed to continue through a new tree")

for _=1,3000 do Popper.update(mode,.02,game)end
assert(#mode.poppingMachines==1 and mode.poppingMachines[1].id==id,"monkey cart left or respawned after its old lifetime")
cart=mode.poppingMachines[1];cart.x,cart.y,cart.state,cart.cooldown=0,0,"ready",0
mode.cigaretteButts={{x=0,y=0,phase="smolder"}};Popper.update(mode,.01,game)
assert(cart.state=="heating","smoldering cigarette butt did not ignite the ready cart")
cart.state,cart.heat="ready",0;mode.cigaretteButts={};mode.oilTrail={{x=0,y=0,ignited=true}};Popper.update(mode,.01,game)
assert(cart.state=="heating","burning oil did not ignite the ready cart")
cart.state,cart.heat="ready",0;mode.oilTrail={};mode.flameStream={x=-100,y=0,nx=1,ny=0,reach=220,halfWidth=45}
function mode.flameStreamCovers(x,y,nx,ny,reach,halfWidth,px,py)return px>=x and px<=x+reach and math.abs(py-y)<=halfWidth end
Popper.update(mode,.01,game);assert(cart.state=="heating","flamethrower did not ignite the ready cart")
cart.state,cart.heat="cooldown",0;cart.cooldown=5
assert(Popper.igniteInRadius(mode,0,0,10)==1 and cart.state=="heating",
    "firework direct hit did not ignite the popping cart")
cart.state,mode.rainSuppressFire="ready",true
assert(Popper.igniteInRadius(mode,0,0,10)==0 and cart.state=="ready",
    "rain did not block firework ignition on the popping cart")
mode.rainSuppressFire=false
mode.flameStream=nil;mode.permanentTraits.scorePopperExtra=1;Popper.update(mode,.01,game)
assert(#mode.poppingMachines==2,"extra permanent monkey cart did not remain on the map")

local store=Traits.new(true);local count,ranks,cost,multi,damage,bounces,heat=0,0,0,0,0,0,0
for _,node in ipairs(store:getScoreAttackNodes("fire"))do if node.id:match("^fire_score_popper")then
    count=count+1;ranks=ranks+node.max;if node.max>1 then multi=multi+1 end
    for _,value in ipairs(node.costs)do cost=cost+value end
    if node.effect=="scorePopperDamage"then damage=damage+node.value*node.max end
    if node.effect=="scorePopperBounces"then bounces=bounces+node.value*node.max end
    if node.effect=="scorePopperHeat"then heat=heat+node.value*node.max end
end end
assert(count==9 and ranks==16 and cost==2320,"popper research branch totals changed")
assert(multi==5 and damage==10 and bounces==2 and math.abs(heat-.7)<.001,"popper upgrades are not distributed multi-rank nodes")
fixture.reset();Popper.queue(mode,{});Popper.load()
print("POPPING_MACHINE_OK persistent=true monkey_cart=true cooldown=7 ignition=butt+flame+oil+tree+firework base_damage=7 base_contacts=4 upgraded_damage=17 upgraded_contacts=6 survivor_chain=true nodes=9 ranks=16 distributed=true")
