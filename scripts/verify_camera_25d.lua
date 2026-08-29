package.path="./?.lua;./?/init.lua;"..package.path
local viewportW,viewportH=1280,720
love={graphics={getDimensions=function()return viewportW,viewportH end},math={random=function(a,b)return 0 end}}
local Camera=require("src.camera")
local Projection=require("src.world_projection")
local cam=Camera.new(500,400)
cam.renderX,cam.renderY,cam.renderZoom,cam.roll,cam.pitch=500,400,1.2,.013,.76
cam.perspective=true
local wx0,wy0=742,533
local sx,sy,perspective=cam:worldToScreen(wx0,wy0)
local wx,wy=cam:screenToWorld(sx,sy)
assert(math.abs(wx-wx0)<.001 and math.abs(wy-wy0)<.001,"2.5D projection input inverse drifted")
cam.shakeX,cam.shakeY=3,-2
local shakenX,shakenY=cam:worldToScreen(cam.renderX,cam.renderY)
local expectedX,expectedY=Projection.project(640+cam.shakeX,360+cam.shakeY,1280,720,cam.pitch)
assert(math.abs(shakenX-expectedX)<.001 and math.abs(shakenY-expectedY)<.001,"billboard shake diverged from projected ground")
local centerWorldX,centerWorldY=cam:screenToWorld(shakenX,shakenY)
assert(math.abs(centerWorldX-cam.renderX)<.001 and math.abs(centerWorldY-cam.renderY)<.001,"shared shake broke pointer inverse")
cam.shakeX,cam.shakeY=0,0
local calm=Camera.new(500,400)
calm.zoom,calm.renderZoom,calm.pitch,calm.perspective=.84,.84,.76,true
calm.trauma=1
calm:impulse(120,-80,.08,.08)
calm:update(1/60,{x=560,y=420},{width=3200,height=2200,playBounds={x=0,y=0,w=3200,h=2200}})
assert(calm.shakeX==0 and calm.shakeY==0,"2.5D procedural shake still moves the whole screen")
assert(calm.roll==0,"2.5D roll still rocks the projected world")
assert(math.abs(calm.renderX-calm.x)<=1.501 and math.abs(calm.renderY-calm.y)<=1.001,"2.5D inertia exceeds the calm envelope")
assert(math.abs(calm.renderZoom-calm.zoom)<=.0076,"2.5D zoom kick exceeds the calm envelope")
local topScale=Projection.factor(0,720,.76)
local bottomScale=Projection.factor(720,720,.76)
assert(topScale<.9 and bottomScale>1.05 and bottomScale>topScale,"perspective scale range drifted")
local ax=cam:worldToScreen(400,260)
local bx=cam:worldToScreen(600,260)
local cx=cam:worldToScreen(400,650)
local dx=cam:worldToScreen(600,650)
assert(dx-cx>bx-ax,"distant X spacing is not narrower than foreground spacing")
local left,top,right,bottom=cam:visibleBounds()
assert(left<right and top<bottom,"projected visible bounds invalid")
-- Portrait windows expose the projection's asymmetric vertical footprint:
-- considerably more world is visible above the camera than below it. Camera
-- clamping must use four independent extents or the player can leave the view.
viewportW,viewportH=1095,1384
local portrait=Camera.new(1600,1000)
portrait.zoom,portrait.renderZoom,portrait.roll,portrait.pitch=0.84,0.84,0,.76
portrait.perspective=true
local bounds={width=3200,height=2000,playBounds={x=400,y=300,w=2400,h=1400}}
local target={x=1600,y=1000}
for index,position in ipairs({{1600,1000},{2780,1000},{420,1000},{1600,1680},{1600,320}}) do
    target.x,target.y=position[1],position[2]
    for _=1,180 do portrait:update(1/60,target,bounds) end
    local playerX,playerY=portrait:worldToScreen(target.x,target.y)
    assert(playerX>=55.9 and playerX<=viewportW-55.9 and playerY>=115.9 and playerY<=viewportH-47.9,
        string.format("camera lost player in portrait view at %.1f,%.1f -> %.1f,%.1f",target.x,target.y,playerX,playerY))
    if index==1 then
        assert(math.abs(playerX-viewportW*.5)<.1 and math.abs(playerY-viewportH*.5)<.1,
            "portrait camera no longer centers an unconstrained player")
    end
end
local game=assert(io.open("src/game.lua","rb")):read("*a")
local projection=assert(io.open("src/world_projection.lua","rb")):read("*a")
assert(game:find("WorldProjection.begin",1,true) and game:find("WorldProjection.finish",1,true),"world projection render pass missing")
assert(not game:find("CameraDepthArt",1,true),"screen-space foreground layer returned")
assert(not projection:find("backdrop",1,true),"separate backdrop image returned")
assert(projection:find("canvas",1,true) and projection:find("mesh",1,true),"terrain and actors do not share one projection")
assert(projection:find('canvas:setFilter("linear","nearest",8)',1,true),"projected ground minification can shimmer while moving")
assert(projection:find("love.graphics.scale(uniform,uniform)",1,true),"billboard sprite aspect ratio is not uniform")
assert(game:find("WorldProjection.finish(self.camera)",1,true)<game:find("WorldProjection.drawBillboards",1,true),"billboards are drawn before projected ground")
local world=assert(io.open("src/world.lua","rb")):read("*a")
assert(world:find("self.billboardQueue",1,true) and world:find("item.ground",1,true),"ground and billboard passes are not separated")
assert(game:find("self.camera.userZoom=userZoom",1,true) and game:find("self.camera.renderZoom=self.camera.zoom",1,true),"Ctrl+wheel 2.5D zoom missing")
print(string.format("CAMERA_25D_OK pitch=.76 inverse=exact scale=%.2f..%.2f shake=off roll=off recoil=1.5x1 billboards=uniform",topScale,bottomScale))
