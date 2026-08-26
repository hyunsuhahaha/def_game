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
