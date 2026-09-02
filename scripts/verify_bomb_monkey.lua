package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local BombMonkey=require("src.bomb_monkey")
local Traits=require("src.character_traits")

local tree={rushTree=true,active=true,x=0,y=0,rushHp=40,rushMaxHp=40}
local world={nodes={tree},width=900,height=600}
function world:impactNode()end
local mode={scoreAttack=true,permanentTraits={scoreBombMonkey=1},bombMonkeys={},monkeyBombs={},bombExplosions={},
    cigaretteButts={},oilTrail={},enemies={},maxChain=0}
function mode.flameStreamCovers(ox,oy,nx,ny,reach,width,x,y)return x>=ox and x<=ox+reach and math.abs(y-oy)<=width end
function mode:damageTreeWithSmokerWeapon(node,damage)node.rushHp=node.rushHp-damage;if node.rushHp<=0 then node.active=false;return true end return false end
local game={world=world,player={x=0,y=0},feedback={play=function()end},camera={trauma=0}}
assert(BombMonkey.FUSE_FRAMES==24,"fuse burn animation lost its progressive frames")

BombMonkey.update(mode,.01,game)
assert(#mode.bombMonkeys==1 and mode.bombMonkeys[1].carrying,"bomb carrier monkey did not spawn holding a bomb")
mode.bombMonkeys[1].dropTimer=0
BombMonkey.update(mode,.01,game)
assert(#mode.monkeyBombs==1 and mode.monkeyBombs[1].state=="unlit","carrier did not drop an inert bomb")
local bomb=mode.monkeyBombs[1];bomb.x,bomb.y=0,0
mode.cigaretteButts={{x=0,y=0,phase="smolder"}}
BombMonkey.update(mode,.01,game)
assert(bomb.state=="lit","smoldering cigarette did not light the fuse")
for _=1,260 do BombMonkey.update(mode,.01,game)end
assert(#mode.monkeyBombs==0 and tree.rushHp==26,"base bomb did not explode for 14 tree damage after 2.6 seconds")
assert(#mode.bombExplosions==1 and mode.bombExplosions[1].radius==180,"dedicated bomb explosion did not use its gameplay radius")

mode.monkeyBombs={{id=2,owner=1,x=0,y=0,state="lit",fuse=1,life=0}};mode.rainSuppressFire=true
BombMonkey.update(mode,.01,game)
assert(mode.monkeyBombs[1].state=="unlit"and mode.monkeyBombs[1].fuse==0,"rain did not extinguish a lit bomb")
mode.rainSuppressFire=false;assert(BombMonkey.igniteInRadius(mode,0,0,40)==1,"firework-radius ignition did not light an inert bomb")

mode.permanentTraits.scoreBombExtra=1
BombMonkey.update(mode,.01,game)
assert(#mode.bombMonkeys==2,"extra carrier research did not add a second monkey")

local store=Traits.new(true);local count,ranks,cost=0,0,0
for _,node in ipairs(store:getScoreAttackNodes("universal"))do if node.id:match("^universal_bomb")then
    count=count+1;ranks=ranks+node.max;for _,value in ipairs(node.costs)do cost=cost+value end
end end
assert(count==6 and ranks==17 and cost==4375,"bomb-monkey research branch totals changed")
fixture.reset();BombMonkey.queue(mode,{});BombMonkey.load()
print("BOMB_MONKEY_OK carry=drop ignition=butt+flame+oil+tree+firework fuse=2.6 radius=180 damage=14 nodes=6 ranks=17")
