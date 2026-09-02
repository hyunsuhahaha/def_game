package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Mode=require("src.clearcut_mode")
local Reward=require("src.boss_reward_pickup")

local mode=Mode.new();mode.hp,mode.maxHp=65,100
local notices={}
local game={mode="playing",player={x=100,y=120,capacity=999,wood=0,stone=0,food=0,ore=0,
        totalCargo=function(self)return self.wood+self.stone+self.food+self.ore end},
    world={drops={{kind="wood",amount=1,x=900,y=700,height=0,vx=0,vy=0,vz=0,magnet=false}},popups={}},runStats={harvested=0},
    addRunXP=function()end,
    setNotice=function(_,text)notices[#notices+1]=text end}
local boss={x=180,y=150,seed=.4,def={name="검증 보스",boss=true,finalBoss=false,reward=0}}
mode:onEnemyDefeated(boss,game)
assert(mode.hp==85,"boss defeat did not restore exactly 20 HP")
assert(#mode.bossMagnetPickups==1 and mode.bossMagnetPickups[1].x==boss.x,"boss magnet did not drop at death point")
assert(#game.world.popups==1 and game.world.popups[1].text=="+20 HP","boss heal feedback missing")
mode:onEnemyDefeated(boss,game)
assert(mode.hp==85 and #mode.bossMagnetPickups==1,"boss reward was granted more than once")

fixture.reset();Reward.draw(mode.bossMagnetPickups[1],.25)
local authored=false
for _,command in ipairs(fixture.commands)do if command.file and command.file:find("boss%-magnet%-pickup%-pixel%-v1%.png")then authored=true end end
assert(authored,"magnet pickup did not render authored sprite")
if BOSS_REWARD_CAPTURE then
    fixture.reset()
    local floor=love.graphics.newImage("assets/forest-ground-tile-v1.png")
    love.graphics.setColor(1,1,1,1);love.graphics.draw(floor,0,0,0,640/floor:getWidth(),360/floor:getHeight())
    local preview={x=320,y=210,phase=.4};Reward.draw(preview,.25)
    fixture.save("docs/previews/boss-magnet-pickup-runtime-v1-draws.json")
end

game.player.x,game.player.y=boss.x,boss.y
Reward.update(mode,game)
local delayedDrop=game.world.drops[1]
assert(#mode.bossMagnetPickups==0 and delayedDrop.magnet and delayedDrop.bossMagnet and delayedDrop.magnetDelay>=.18,
    "magnet pickup did not arm a delayed pull for every world drop")
assert(notices[#notices]:find("자석",1,true),"magnet collection feedback missing")
local World=require("src.world");local startX=delayedDrop.x
World.updateDrops(game.world,.12,game)
assert(delayedDrop.x==startX,"boss magnet pulled drops before its anticipation delay")
for _=1,7 do World.updateDrops(game.world,.1,game) end
assert(delayedDrop.x<startX and delayedDrop.x>game.player.x+30,"boss magnet pull was invisible or teleported the drop")

local originalRandom=love.math.random
love.math.random=function()return .009 end
local woodMode={bossMagnetPickups={}}
assert(Reward.rollWoodMagnet(woodMode,100,120)and woodMode.bossMagnetPickups[1].woodOnly,"one-percent wood magnet did not drop")
love.math.random=function()return .01 end
assert(not Reward.rollWoodMagnet(woodMode,100,120)and#woodMode.bossMagnetPickups==1,"wood magnet probability exceeded one percent")
love.math.random=originalRandom
local woodDrop={kind="wood",x=800,y=500};local stoneDrop={kind="stone",x=700,y=500}
local woodGame={mode="playing",player={x=100,y=120},world={drops={woodDrop,stoneDrop}},setNotice=function()end}
Reward.update(woodMode,woodGame)
assert(woodDrop.magnet and woodDrop.bossMagnet and not stoneDrop.magnet,"wood magnet did not exclusively collect every dropped lumber")

mode.bossMagnetPickups={{x=400,y=400,collected=false}}
local originalGenerate=mode.generateForest;mode.generateForest=function()end;mode.initForestZones=function()end
game.world.width,game.world.height,game.world.nodes,game.world.drops=3200,2000,{},{}
game.world.images={treeVariants={}};game.world.treeVisual={};game.world.clearcutMap="forest";game.world.playBounds={x=0,y=0,w=3200,h=2000}
game.camera={zoom=.8,userZoom=1,x=0,y=0,trauma=0};game.player.x,game.player.y=1600,1000
mode.stage,mode.mapId,mode.permanentTraits=1,"forest",mode.permanentTraits
mode:advanceStage(game)
assert(#mode.bossMagnetPickups==1,"world-tree stage transition deleted its magnet reward")
mode.generateForest=originalGenerate

mode.hp=94
local second={x=220,y=160,def={name="두 번째 검증 보스",boss=true,finalBoss=false,reward=0}}
mode:onEnemyDefeated(second,game)
assert(mode.hp==100 and game.world.popups[#game.world.popups].text=="+6 HP","boss heal did not clamp to max HP")
print("BOSS_DEFEAT_REWARDS_OK heal=20 clamp=max magnet=delay+stagger+accelerate stage_persist once=true atlas=128")
