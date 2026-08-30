package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Mode=require("src.clearcut_mode")
local MoleClawArt=require("src.mole_claw_art")

local mode=Mode.new()
local image=love.graphics.newImage("assets/characters/ingame/coin-miner-mole-atlas-pixel-v3.png")
image:setFilter("nearest","nearest")
local sprite={image=image,scale=.48,nativeFacing=-1,
    walkFeet={380,380,380,380,380,380},actionFeet={380,380,380,380,380,380},
    actionFacing={1,-1,-1,1,1,1},actionScale={1.28,1.48,1.52,1,1,1}}
local fw,fh=image:getWidth()/6,image:getHeight()/2
local frames={walk={},action={}}
for i=0,5 do
    frames.walk[i+1]=love.graphics.newQuad(i*fw,0,fw,fh,image:getDimensions())
    frames.action[i+1]=love.graphics.newQuad(i*fw,fh,fw,fh,image:getDimensions())
end
local companion={x=178,y=275,sprite=sprite,frames=frames,fw=fw,fh=fh,state="attack",facing=1,
    walkClock=1.4,attackT=.34,attackDuration=.62}

fixture.reset()
love.graphics.setColor(.29,.43,.16,1);love.graphics.rectangle("fill",0,0,520,360)
love.graphics.setColor(.19,.29,.11,.7)
for i=1,7 do love.graphics.ellipse("fill",38+i*67,322-(i%2)*9,43,10)end
local tree=love.graphics.newImage("assets/trees/broadleaf-tree-cartoon-v3.png");tree:setFilter("nearest","nearest")
love.graphics.setColor(0,0,0,.34);love.graphics.ellipse("fill",345,286,60,9)
love.graphics.setColor(1,1,1,1);love.graphics.draw(tree,345,285,0,1,1,tree:getWidth()/2,tree:getHeight()*.91)
mode:drawMoleCompanion(companion)
MoleClawArt.spawn(mode,252,245,0,1,-1,24,1,false)
MoleClawArt.draw(mode,{},0)

local output=assert(os.getenv("MOLE_COMPANION_CAPTURE"),"MOLE_COMPANION_CAPTURE is required")
fixture.save(output)
print("MOLE_COMPANION_CAPTURE_OK sprite=mole-v3 scale=.30 contact=claw-v1")
