package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Mode=require("src.clearcut_mode")
local GraduateMonkeyArt=require("src.graduate_monkey_art")

local mode=Mode.new()
local moleImage=love.graphics.newImage("assets/characters/ingame/coin-miner-mole-atlas-pixel-v3.png")
moleImage:setFilter("nearest","nearest")
local fw,fh=moleImage:getWidth()/6,moleImage:getHeight()/2
local moleFrames={walk={},action={}}
for i=0,5 do
    moleFrames.walk[i+1]=love.graphics.newQuad(i*fw,0,fw,fh,moleImage:getDimensions())
    moleFrames.action[i+1]=love.graphics.newQuad(i*fw,fh,fw,fh,moleImage:getDimensions())
end
local moleSprite={image=moleImage,nativeFacing=-1,walkFeet={380,380,380,380,380,380},
    actionFeet={380,380,380,380,380,380}}
local monkeySprite,monkeyFrames,monkeyW,monkeyH=GraduateMonkeyArt.sprite()

local feast={feastT=18,feastPower=1,feastFxClock=1.24,state="walk",facing=1,walkClock=.2,attackT=0}
local mole={x=165,y=264,sprite=moleSprite,frames=moleFrames,fw=fw,fh=fh}
local monkey={x=355,y=264,sprite=monkeySprite,frames=monkeyFrames,fw=monkeyW,fh=monkeyH,
    drawScale=.34,kind="lumberjack",prop="axe"}
for key,value in pairs(feast)do mole[key]=value;monkey[key]=value end

fixture.reset()
love.graphics.setColor(.34,.48,.20,1);love.graphics.rectangle("fill",0,0,520,320)
love.graphics.setColor(.22,.34,.12,.72)
for i=1,7 do love.graphics.ellipse("fill",34+i*66,275-(i%2)*5,44,9)end
mode:drawMoleCompanion(mole)
mode:drawMoleCompanion(monkey)

local output=assert(os.getenv("PIZZA_FEAST_CAPTURE"),"PIZZA_FEAST_CAPTURE is required")
fixture.save(output)
print("PIZZA_FEAST_CAPTURE_OK actors=mole+graduate_monkey buff=persistent scale=1.14 aura=yellow")
