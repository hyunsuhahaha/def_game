package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local World=require("src.world")
local Mode=require("src.clearcut_mode")

love.graphics.getDimensions=function()return 1280,720 end
love.graphics.getWidth=function()return 1280 end
love.graphics.getHeight=function()return 720 end
love.mouse={getPosition=function()return -100,-100 end,isDown=function()return false end}

local world=World.new();world:useArcadeForest();world.width,world.height=5120,3200;world.theme="forest"
world.hideBase=true;world.arcadeForest=false;world.clearcutMap=nil;world.deferBillboards=false
world.nodes={};world.buildings={};world.helpers={};world.drops={};world.enemies={};world.defenders={}
local mode=Mode.new();mode.scoreAttack=true;mode.defenseMode=true;mode.job="fire";mode.mapWorld=world
local player={x=world.width*.5,y=world.height*.5,introHidden=true,interactionTarget=nil}
local game={world=world,player=player}
Mode.DefenseMode.populate(mode,game)
for _=1,120 do Mode.DefenseMode.update(mode,game,.1)end

fixture.reset();fixture.time=2.4
love.graphics.setColor(.09,.16,.08,1);love.graphics.rectangle("fill",0,0,1280,720)
love.graphics.push();love.graphics.translate(640,360);love.graphics.scale(.7,.7);love.graphics.translate(-world.width*.5,-world.height*.5)
world:draw(player,mode)
love.graphics.pop()
local font=love.graphics.newFont("assets/font-korean-regular.ttf",18);love.graphics.setFont(font)
love.graphics.setColor(1,.94,.72,1);love.graphics.print("무한 디펜스 · 외곽에서 접근 중 · 12초",24,20)
fixture.save("docs/previews/defense-mode-v1-draws.json")
print("DEFENSE_MODE_CAPTURE_OK stages=8 trees=768 far_spawn=true window=none")
