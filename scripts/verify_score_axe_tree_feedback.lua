package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local World=require("src.world")

local world=World.new()
world.nodes={}
local played={}
local game={player={x=100,y=300},camera={trauma=0},feedback={play=function(_,kind,strong)played[#played+1]={kind,strong}end}}
local node={kind="tree",rushTree=true,active=true,x=210,y=300,rushHp=8,rushMaxHp=8,treeVariant=1}
local impact={kind="axe",x=210,y=235,dir=1}

world:impactNode(node,game,false)
world:updateEffects(.01,game)
assert(world.particles[1]and world.particles[1].y,"ordinary tree impact created a particle without a y coordinate")
world.particles={};game.camera.trauma=0;node.swayVel=0;played={}

world:impactNode(node,game,false,impact)
assert(#world.particles==12,"normal axe hit did not create 8 bark chips and 4 leaves")
for index=1,8 do
    local chip=world.particles[index]
    assert(chip.woodChip and chip.x==impact.x and chip.y==impact.y and chip.vx>0,
        "axe bark chip did not start at blade contact and travel with the swing")
end
assert(node.swayVel>0 and math.abs(game.camera.trauma-.09)<1e-9,
    "normal axe hit lacks directional tree recoil or small camera punch")
assert(played[1][1]=="axe_wood"and played[1][2]==false,"normal axe hit lacks its wood-chop sound")

world.particles={};game.camera.trauma=0;node.rushHp=0
world:impactNode(node,game,true,impact)
local soundCount=#played
world:harvestBurst(node,game,4,"목재",impact)
assert(node.fallDir==1,"axe-felled tree does not fall away from the incoming blade")
assert(game.camera.trauma==.30 and #played==soundCount and played[#played][2]==true,
    "felling hit is not stronger than a normal chop or duplicated its contact sound")
assert(#world.particles>20,"felling hit lacks the larger bark, leaf, and pickup burst")
print("SCORE_AXE_TREE_FEEDBACK_OK contact-chips directional-recoil chop-sound normal-vs-fell fall-direction")
