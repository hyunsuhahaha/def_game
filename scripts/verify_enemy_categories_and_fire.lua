package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local ClearcutMode=require("src.clearcut_mode")
local Butts=require("src.cigarette_butts")
local FireArt=require("src.cigarette_butt_art")
local ForestArt=require("src.forest_arcade_art")

local plantCount,animalCount=0,0
for kind,def in pairs(ClearcutMode.enemyDefinitions) do
    assert(def.category=="plant" or def.category=="animal","invalid enemy category: "..kind)
    if def.category=="plant" then plantCount=plantCount+1 else animalCount=animalCount+1 end
end
assert(plantCount>0 and animalCount>0,"enemy taxonomy did not contain both categories")

local mode=ClearcutMode.new()
local particles,ignitions=0,0
local game={world={nodes={},igniteFx=function() ignitions=ignitions+1 end,
    addParticle=function() particles=particles+1 end}}
local plant={kind="vineSprout",def=ClearcutMode.enemyDefinitions.vineSprout,x=100,y=100,hp=100,maxHp=100,seed=.3}
local animal={kind="boar",def=ClearcutMode.enemyDefinitions.boar,x=102,y=100,hp=100,maxHp=100}
mode.enemies={plant,animal}
assert(mode:enemyHasCategory(plant,"plant") and mode:enemyHasCategory(animal,"animal"),
    "shared category query did not match definitions")
assert(mode:igniteEnemy(plant,game,0) and plant.burning,"plant enemy did not ignite")
assert(not mode:igniteEnemy(animal,game,0) and not animal.burning,"animal enemy ignited")
plant.burnTimer=.7
assert(not mode:igniteEnemy(plant,game,0) and plant.burnTimer==.7,"re-ignition stacked or refreshed fire")
plant.burnTimer,plant.fireTickTimer=0,0
for _=1,40 do mode:updateBurningEnemies(.1,game) end
assert(not plant.burning and plant.burnTimer==nil,"plant fire did not extinguish after fixed duration")
assert(plant.hp==60,"plant burn did not deal eight fixed non-stacking ticks")
assert(animal.hp==100 and ignitions==1 and particles==24,"animal was affected by plant burn state")

local radiusMode=ClearcutMode.new()
local nearPlant={kind="turret",def=ClearcutMode.enemyDefinitions.turret,x=0,y=0,hp=100,maxHp=100}
local nearAnimal={kind="squirrel",def=ClearcutMode.enemyDefinitions.squirrel,x=0,y=0,hp=100,maxHp=100}
radiusMode.enemies={nearPlant,nearAnimal}
radiusMode:igniteEnemiesInRadius(0,0,80,game,0)
assert(nearPlant.burning and not nearAnimal.burning,"radius ignition ignored taxonomy")
radiusMode.rainSuppressFire=true;radiusMode:updateBurningEnemies(.1,game)
assert(not nearPlant.burning,"active rain did not extinguish an existing plant fire")

local buttMode=ClearcutMode.new()
local buttPlant={kind="seedPod",def=ClearcutMode.enemyDefinitions.seedPod,x=10,y=10,hp=100,maxHp=100}
buttMode.enemies={buttPlant}
buttMode.cigaretteButts={{x=10,y=10,bornAt=0,expiresAt=7,nextAttemptAt=.1,radius=100,
    angle=0,phase="smolder",attempts=0}}
local random=love.math.random;love.math.random=function() return 0 end
Butts.update(buttMode,.11,game)
assert(#buttMode.emberTransfers==1 and buttMode.emberTransfers[1].targetKind=="enemy",
    "ground cigarette did not target a plant enemy")
Butts.update(buttMode,.7,game)
love.math.random=random
assert(buttPlant.burning,"cigarette ember arrival did not ignite plant enemy")

local wetMode=ClearcutMode.new();wetMode.rainSuppressFire=true
local wetPlant={def=ClearcutMode.enemyDefinitions.hammerBloom,x=0,y=0,hp=100}
assert(not wetMode:igniteEnemy(wetPlant,game,0) and not wetPlant.burning,"rain did not suppress plant ignition")

fixture.reset();fixture.time=.8
local burningVisual={kind="vineSprout",burning=true,burnTimer=1,fireIgnitedAt=0,burnDuration=4,
    x=320,y=360,hp=30,maxHp=42,seed=.2,def=ClearcutMode.enemyDefinitions.vineSprout}
ForestArt.drawBody(burningVisual,.8)
FireArt.drawEnemyFire(burningVisual,.8)
local fireDraws=0
for _,draw in ipairs(fixture.commands) do
    if draw.shader=="assets/shaders/cigarette-ground-fx.glsl" then fireDraws=fireDraws+1 end
end
assert(fireDraws==3,"plant fire did not use authored flame/smoke shader layers")
local capture=os.getenv("ENEMY_FIRE_CAPTURE")
if capture then fixture.save(capture) end

print(("ENEMY_CATEGORIES_FIRE_OK plant=%d animal=%d burn=4s ticks=8 stack=false butt=plant_only fx=%d")
    :format(plantCount,animalCount,fireDraws))
