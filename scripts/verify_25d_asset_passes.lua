package.path="./?.lua;./?/init.lua;"..package.path
require("scripts.forest_render_fixture")

local Mode=require("src.clearcut_mode")
local mode=Mode.new()
mode.job="fire"
mode.smoking={phase="reload",t=.4,dur=1,fired=false}
mode.smokeRing={x=130,y=180}
mode.secondhandSmokeClouds={{x=150,y=170,age=.2,life=2}}
mode.minerClawFx={{x=80,y=210,angle=0,level=6,curveFlip=1,life=.2,maxLife=.3}}
mode.minerClawMarks={{x=80,y=210,angle=0,level=6,curveFlip=1,life=2,maxLife=3}}
mode.bees={{x=170,y=190}}
mode.molotovs={{x=190,y=175}}
mode.chests={{x=210,y=205,collected=false}}
mode.projectiles={{x=230,y=180,kind="thorn",color={1,1,1,1}}}
mode.bossTelegraphs={{x=250,y=210,phase="active",rootQuake=true}}
mode.enemies={{x=270,y=195,kind="squirrel"}}
mode.cigaretteButts={{x=115,y=215,phase="smolder",bornAt=0}}
mode.emberTransfers={{x=120,y=210,tx=155,ty=190,startAt=0,duration=1}}

local player={x=120,y=220,facing=1,clearcutSprite={walkMouth={}}}
local game={player=player,world={billboardQueue={},nodes={{x=300,y=240,rushTree=true,active=true,beehive=true}},images={treeVariants={}}}}
mode:queueProjectedOverlay(game,1)

local queue=game.world.billboardQueue
assert(#queue>=15,"representative upright assets were not queued")
for i,item in ipairs(queue) do
    assert(item.ground~=true,"upright overlay leaked into the projected ground pass at "..i)
    assert(type(item.x)=="number" and type(item.anchorY)=="number" and type(item.draw)=="function","invalid billboard entry at "..i)
end

local source=assert(io.open("src/clearcut_mode.lua","rb")):read("*a")
for _,token in ipairs({
    "MoleClawArt.queue(self,queue)","SecondhandSmokeArt.queue(self,queue)",
    "self:drawHeldSmoker(game,t)","drawBeeBody", "AttackPlants.drawProjectile",
    "if not projected then self:drawCigaretteProjectiles(t) end",
    "if not projected then self:drawCigaretteGroundEffects() end"
}) do assert(source:find(token,1,true),"missing 2.5D pass guard: "..token) end
assert(source:find("ground=true,draw=function() CigaretteButtArt.drawGround",1,true),"cigarette body no longer follows the ground plane")
assert(source:find("ground=true,draw=function() MoleBurrowArt.draw",1,true),"burrow trail no longer follows the ground plane")
assert(source:find("ground=true,draw=function() OilTrailArt.drawGround",1,true),"oil trail no longer follows the ground plane")

local projection=assert(io.open("src/world_projection.lua","rb")):read("*a")
assert(projection:find("item.sortBias or 0",1,true),"billboard attachments cannot sort after their actor")
assert(source:find("hiveChance,hiveCap,hiveCount=.022,6,0",1,true),"beehives are not capped at the reduced density")
assert(source:find("node.y+.08,node.y",1,true),"beehive has no stable sort bias over its host tree")
print("ASSET_PASSES_25D_OK ground=burrow+butt+oil+puddles upright=claw+cigarette+reload+smoke+bee+projectiles+props+threats")
