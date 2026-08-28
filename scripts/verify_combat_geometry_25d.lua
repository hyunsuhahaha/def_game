package.path="./?.lua;./?/init.lua;"..package.path
require("scripts.forest_render_fixture")
local Geometry=require("src.combat_geometry")
local Mode=require("src.clearcut_mode")

local target={x=119.9,y=0,def={radius=20}}
assert(Geometry.circleOverlapsTarget(0,0,100,target))
target.x=120.1;assert(not Geometry.circleOverlapsTarget(0,0,100,target))
target.x,target.y=50,29.9;target.def.radius=10
assert(Geometry.sweptCircleOverlapsTarget(0,0,100,0,20,target))
target.y=30.1;assert(not Geometry.sweptCircleOverlapsTarget(0,0,100,0,20,target))
target.x,target.y=109.9,0;target.def.radius=10
assert(Geometry.ellipseOverlapsTarget(0,0,100,50,target))
target.x=110.1;assert(not Geometry.ellipseOverlapsTarget(0,0,100,50,target))
target.x,target.y=100*math.cos(.55),100*math.sin(.55);target.def.radius=12
assert(Geometry.coneOverlapsTarget(0,0,0,120,.45,target),"visible body overlap at the cone edge was missed")
target.x,target.y=100*math.cos(.75),100*math.sin(.75)
assert(not Geometry.coneOverlapsTarget(0,0,0,120,.45,target),"cone hit a body fully outside its edge")

local function gameWith(projectileX)
    local mode=Mode.new();mode.projectiles={{x=projectileX,y=0,vx=0,vy=0,life=1,damage=4,hitRadius=11}}
    local game={player={x=0,y=0},world={nodes={},addParticle=function()end},setNotice=function()end}
    mode:updateProjectiles(0,game);return mode
end
assert(#gameWith(28.9).projectiles==0,"projectile missed visible player overlap")
assert(#gameWith(29.1).projectiles==1,"projectile hit outside player and projectile footprints")
local fast=Mode.new();fast.projectiles={{x=-100,y=0,vx=4000,vy=0,life=1,damage=4,hitRadius=5}}
local fastGame={player={x=0,y=0},world={nodes={},addParticle=function()end},setNotice=function()end}
fast:updateProjectiles(.05,fastGame);assert(#fast.projectiles==0,"fast projectile tunneled through the visible player")

local mode=Mode.new();local enemy={x=119.9,y=0,hp=20,def={radius=20}}
mode.enemies={enemy};local game={world={nodes={},addParticle=function()end}}
mode:damageEnemiesInRadius(0,0,100,3,game);assert(enemy.hp==17)
enemy.x,enemy.hp=120.1,20;mode:damageEnemiesInRadius(0,0,100,3,game);assert(enemy.hp==20)

local flightMode=Mode.new();flightMode.job="fire";flightMode.levels.molotov=1
local airborne={x=0,y=-120,hp=20,def={radius=5}};local underneath={x=0,y=0,hp=20,def={radius=5}}
flightMode.enemies={airborne,underneath};flightMode.molotovs={{x0=-100,y0=0,x1=100,y1=0,t=.49,dur=1,hitSet={}}}
flightMode:updateMolotovImpacts(.02,{world={}})
assert(airborne.hp<20,"flying cigarette missed a monster on its visible arc")
assert(underneath.hp==20,"flying cigarette hit a monster underneath its visible arc")

local fogMode=Mode.new();fogMode.job="fire";fogMode.levels.molotov=1
local fogEdge={x=329.9,y=0,hp=20,def={radius=10}};local fogOutside={x=330.1,y=0,hp=20,def={radius=10}}
fogMode.enemies={fogEdge,fogOutside};fogMode.secondhandSmokeClouds={{x=0,y=0,vx=0,vy=0,age=0,life=2,tick=.25,radiusX=320,radiusY=200}}
fogMode:updateSecondhandSmoke(0,{world={}});assert(fogEdge.hp<20 and fogOutside.hp==20,"fog ellipse and visible monster edge disagree")

local plants=assert(io.open("src/attack_plants.lua","rb")):read("*a")
assert(plants:find('love.graphics.circle("line",tel.x,tel.y,tel.radius)',1,true),"plant warning is manually flattened before 2.5D projection")
assert(not plants:find("scale,scale*.72",1,true),"resin footprint is double-squashed")
local supplement=assert(io.open("src/supplement_art.lua","rb")):read("*a")
assert(supplement:find("function Art.drawGround",1,true) and supplement:find("function Art.drawUpright",1,true),"shared-skill footprint and sprite passes are not separated")
print("COMBAT_GEOMETRY_25D_OK circles=body_edge swept=exact ellipse=body_edge cone=body_edge projectile=visual_sum footprints=ground_projected")
