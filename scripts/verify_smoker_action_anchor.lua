package.path="./?.lua;./?/init.lua;"..package.path

love={mouse={isDown=function() return false end,getPosition=function() return 0,0 end},math={random=math.random},timer={getTime=function() return 0 end}}
local ClearcutMode=require("src.clearcut_mode")
local mode=ClearcutMode.new(); mode.job="fire"; mode.smoking={phase="reload",t=.4,dur=1}
local player={x=100,y=100,facing=1,clearcutActionProgress=.2,clearcutFrameWidth=96,
    clearcutSprite={scale=.61,actionFeet={190,190,190,190,190,190}}}
local game={player=player}

local mouthX,mouthY,facing,tipX=mode:smokerMouthPose(game)
local expectedX=100+(68-48)*.61
local expectedY=100+(30-190)*.61
assert(math.abs(mouthX-expectedX)<.01 and math.abs(mouthY-expectedY)<.01,"smoking action cigarette still uses the idle mouth anchor")
assert(facing==1 and math.abs(tipX-(mouthX+16))<.01,"smoking action cigarette tip is not attached to its object")

player.facing=-1
local leftX,leftY,leftFacing,leftTip=mode:smokerMouthPose(game)
assert(math.abs(leftX-(100-(68-48)*.61))<.01 and leftY==mouthY,"left smoking pose did not mirror the action anchor")
assert(leftFacing==-1 and math.abs(leftTip-(leftX-16))<.01,"left smoking cigarette points backwards")

print("SMOKER_ACTION_ANCHOR_OK")

-- Exercise the production metadata and actual renderer, not just facing math.
local Player=require("src.player")
local Game=require("src.game")
local loadSprites
for index=1,30 do
    local name,value=debug.getupvalue(Game.new,index)
    if not name then break end
    if name=="loadClearcutSprites" then loadSprites=value; break end
end
assert(loadSprites,"production sprite loader missing")
local drawn
local activeShader = {existing=true}
local previousShader = activeShader
local sentTime
love.graphics={
    newImage=function() return {setFilter=function() end} end,
    newQuad=function(...) return {...} end,
    newShader=function() return {send=function(_,name,value)
        assert(name=="emberTime" or name=="smokeTime" or name=="smokeFacing")
        sentTime=value
    end} end,
    getShader=function() return activeShader end,
    setShader=function(value) activeShader=value end,
    setColor=function() end,ellipse=function() end,
    draw=function(...) drawn={...} end
}
local sprite=loadSprites().fire
local p=setmetatable({x=100,y=100,facing=1,walkClock=0,isMoving=false,
    clearcutSprite=sprite,clearcutFrameWidth=96,
    clearcutFrames={walk={1,2,3,4,5,6},action={7,8,9,10,11,12}}},Player)
game.player=p
local sourceFacing={-1,-1,-1,-1,1,1}
for _,direction in ipairs({-1,1}) do
    p.facing=direction
    for frame=1,6 do
        p:setClearcutAction((frame-.5)/6)
        p:draw()
        assert(drawn[6]*sourceFacing[frame]*direction>0,"smoking body turns away from aim")
        local mx,my,face,tip=mode:smokerMouthPose(game)
        local anchor=sprite.actionMouth[frame]
        assert(math.abs(mx-(p.x+(anchor[1]-48)*drawn[6]))<.001,"mouth uses a different flip than body")
        assert(math.abs(my-(drawn[4]+(anchor[2]-190)*drawn[7]))<.001,"mouth detached vertically")
        assert(face==direction and (tip-mx)*direction>0,"ember points behind the face")
    end
    p:clearClearcutAction(); p.isMoving=true
    for frame=1,6 do
        p.walkClock=frame-1+.25
        p:draw()
        local mx,my=mode:smokerMouthPose(game)
        local anchor=sprite.walkMouth[frame]
        assert(math.abs(mx-(p.x+(anchor[1]-48)*drawn[6]))<.001,"walking cigarette detached horizontally")
        assert(math.abs(my-(drawn[4]+(anchor[2]-190)*drawn[7]))<.001,"walking smoke ignores bob")
    end
    p.isMoving=false
end
mode.job="fire"
love.graphics.rectangle=function() error("duplicate cigarette drawn over atlas") end
assert(mode:drawSmokerCigarette(game),"production cigarette not recognized")
assert(drawn[1]==sprite.cigarette.image,"cigarette must use its detailed equipment sprite")
local equipmentScale=sprite.cigarette.length/(sprite.cigarette.tipX-sprite.cigarette.mouthX)
assert(math.abs(drawn[5])==equipmentScale and drawn[6]==equipmentScale,
    "equipment pixels must keep their aspect ratio")
assert(activeShader==previousShader and sentTime~=nil,"ember shader leaked into world rendering")
local mx,_,face,tip=mode:smokerMouthPose(game)
assert(math.abs(tip-mx-sprite.cigarette.length*face)<.001,"smoke is not at the enlarged cigarette tip")
require("src.cigarette_sprite").drawSmoke(sprite.cigarette,tip,100,face,1)
assert(activeShader==previousShader,"smoke shader leaked into world rendering")
assert(drawn[5]*sprite.cigarette.width==60 and drawn[6]*sprite.cigarette.height==120,
    "smoke must be three times its original width and height")
assert(drawn[2]+30==tip and drawn[3]+120==100,"smoke emitter detached from cigarette tip")
print("SMOKER_FRAME_FACING_AND_ATTACHMENTS_OK")
