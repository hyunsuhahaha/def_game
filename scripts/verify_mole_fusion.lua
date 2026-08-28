package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
love.math.random=function(a,b)if b then return a elseif a then return 1 else return .5 end end
local Mode=require("src.clearcut_mode")
local Fusions=require("src.clearcut_fusions")
local MoleClawArt=require("src.mole_claw_art")
local MoleBurrowArt=require("src.mole_burrow_art")

local function make(fused)
    local mode=Mode.new();mode.job="miner";mode.levels={detector=6,burrow_uproot=6};mode.evolutions.coward_barrage=fused
    mode.permanentTraits={attackSpeed=1,range=0,area=0,extraTargets=0,treeDamage=0,moveSpeed=1}
    local tree={rushTree=true,active=true,x=200,y=215,rushHp=100,rushMaxHp=100,treeVariant=1}
    local enemy={x=190,y=100,hp=100,maxHp=100,visualHit=0,def={radius=20}}
    local nearby={x=210,y=108,hp=100,maxHp=100,visualHit=0,def={radius=16}}
    local outside={x=100,y=280,hp=100,maxHp=100,visualHit=0,def={radius=16}}
    local player={x=100,y=100,facing=1,setClearcutAction=function()end,clearClearcutAction=function()end}
    local world={nodes={tree},impactNode=function()end}
    local game={player=player,world=world,camera={trauma=0}}
    mode.enemies={enemy,nearby,outside};mode.minerBurrow={state="tunnel",t=0,duration=99,lastX=100,lastY=100,
        trackX=100,trackY=100,side=1,launched=0,cowardTimer=0,cowardSequence=0}
    mode:addBurrowTrack(player.x,player.y,0,"entry")
    return mode,game,tree,enemy,nearby,outside
end

local fusion
for _,def in ipairs(Fusions.definitions)do if def.id=="coward_barrage"then fusion=def end end
assert(fusion and fusion.job=="miner" and fusion.needs[1]=="detector" and fusion.needs[2]=="burrow_uproot")
local areaMode,areaGame,_,primary,nearby,outside=make(true)
areaMode:burrowCowardBarrage(areaGame,0,0)
assert(#areaMode.minerClawFx==1,"one barrage strike must create exactly one effect")
assert(primary.hp<100 and nearby.hp<100,"all enemies touched by one barrage effect must take damage")
assert(outside.hp==100,"barrage damaged an enemy outside the visible claw effect")
local mode,game,tree,enemy,nearEnemy=make(false)
assert(Fusions.ready(mode,fusion),"max claw + max burrow did not unlock fusion")
mode.evolutions.coward_barrage=true
mode:updateMinerBurrow(.3,game)
assert(game.player.x==100 and mode.minerBurrow.lastX==100,"stationary test moved the mole")
assert(tree.active and tree.rushHp<100,"outer tree was uprooted instead of clawed / not damaged")
assert(enemy.hp<100,"underground barrage ignored enemies")
assert(nearEnemy.hp<100,"one barrage swipe did not damage every enemy inside its visible area")
assert(#mode.minerClawFx==2 and #mode.minerClawMarks==2,"stationary tunnel did not produce two rapid contacts")
assert(mode.minerClawFx[1].x==enemy.x and mode.minerClawFx[1].x~=game.player.x,"claw originated at mole instead of target")
for _,fx in ipairs(mode.minerClawFx)do
    assert(fx.level==6 and fx.halfWidth==27 and fx.dual,"fusion did not reuse one composite max-rank claw art per strike")
end

fixture.reset();MoleClawArt.draw(mode,game,0)
local draws=0
for _,op in ipairs(fixture.commands)do
    assert(op.op=="draw" and op.file=="assets/fx/mole-claw/mole-claw-swipe-cartoon-pixel-v1.png")
    assert(op.filter=="nearest");draws=draws+1
end
assert(draws==8,"two composite strikes did not render both authored hands for live and persistent frames")
local capture=os.getenv("MOLE_FUSION_CAPTURE")
if capture then
    fixture.reset()
    for _,fx in ipairs(mode.minerClawFx)do fx.life=.07 end -- peak white contact frame for visual QA
    for _,mark in ipairs(mode.burrowTracks)do MoleBurrowArt.draw(mark)end
    MoleClawArt.draw(mode,game,0)
    fixture.save(capture)
end

local plain,plainGame,plainTree,plainEnemy=make(false)
plain:updateMinerBurrow(.3,plainGame)
assert(plainTree.rushHp==100 and plainEnemy.hp==100 and #plain.minerClawFx==0,"barrage ran without fusion")
print("MOLE_FUSION_OK recipe=claw+burrow stationary=true interval=.14 targets=world_contact atlas=nearest")
