package.path="./?.lua;./?/init.lua;"..package.path

local drawCalls, rotations, trackBlocks = 0, {}, 0
love={
    mouse={isDown=function() return false end,getPosition=function() return 0,0 end},
    math={random=math.random},timer={getTime=function() return .25 end},
    graphics={setLineStyle=function() end,setColor=function() end,setLineWidth=function() end,
        push=function() end,pop=function() end,translate=function() end,
        rotate=function(angle) rotations[#rotations+1]=angle end,
        line=function() end,ellipse=function() end,polygon=function() end,
        print=function() end,rectangle=function() trackBlocks=trackBlocks+1 end,circle=function() end,
        draw=function() drawCalls=drawCalls+1 end}
}

local ClearcutMode=require("src.clearcut_mode")
local image={getDimensions=function() return 192,140 end}
local game={
    player={x=100,y=100,facing=1}, tools={axe={speed=1}},
    camera={trauma=0,screenToWorld=function(_,x,y) return x,y end},
    world={nodes={}}, clearcutMachineryImage=image, setNotice=function() end
}
local mode=ClearcutMode.new(); mode.job="developer"
mode:startDash(20,180,game)
assert(mode.dashing and game.player.facing==-1,"developer machinery did not follow the aimed direction")
assert(mode:drawDeveloperMachinery(game,.25) and drawCalls==1,"developer machinery sprite was not drawn during dash")
assert(#rotations==1 and math.abs(rotations[1]-mode.dashing.angle)<.0001,"machinery rendering ignored dash angle")
mode.dashTrail={{x=100,y=100,dx=mode.dashing.dx,dy=mode.dashing.dy,angle=mode.dashing.angle,width=55,life=.3,maxLife=.42}}
mode:drawWorldOverlay(game)
assert(drawCalls==2 and trackBlocks>=14,"pixel machinery overlay or crawler-track blocks are missing")
print("DEVELOPER_MACHINERY_OK")
