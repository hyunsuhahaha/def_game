package.path=package.path..";./?.lua;./?/init.lua"
local Camera=require("src.camera")
local Projection=require("src.world_projection")

local width,height,pitch=1280,720,.76
-- A disabled skyview must be bit-for-bit the pre-existing projection formula.
for _,point in ipairs({{0,0},{640,360},{1100,650},{260,185}}) do
    local x,y,scale=Projection.project(point[1],point[2],width,height,pitch,0)
    local groundY=height*.5+(point[2]-height*.5)*pitch
    local depth=math.max(0,math.min(1,groundY/height))
    local expectedScale=.78+(1.12-.78)*depth
    assert(math.abs(x-(width*.5+(point[1]-width*.5)*expectedScale))<1e-8,"default X projection changed")
    assert(math.abs(y-(height*.5+(point[2]-height*.5)*pitch*expectedScale))<1e-8,"default Y projection changed")
    assert(math.abs(scale-expectedScale)<1e-8,"default projection scale changed")
end

local horizon=height*Projection.horizonRatio
local _,farY,farScale=Projection.project(width*.5,0,width,height,pitch,1)
local _,midY,midScale=Projection.project(width*.5,height*.5,width,height,pitch,1)
local _,nearY,nearScale=Projection.project(width*.5,height,width,height,pitch,1)
assert(math.abs(farY-horizon)<.001,"skyview ground does not meet the horizon")
assert(midY>horizon and nearY>midY,"skyview ground depth is not monotonic")
assert(nearY-midY>midY-farY,"distant ground is not compressed toward the horizon")
assert(farScale<midScale and midScale<nearScale,"skyview billboard scale does not follow depth")

for _,flat in ipairs({{188,72},{640,360},{1120,670}}) do
    local sx,sy=Projection.project(flat[1],flat[2],width,height,pitch,1)
    local rx,ry=Projection.unproject(sx,sy,width,height,pitch,1)
    assert(math.abs(rx-flat[1])<.001 and math.abs(ry-flat[2])<.001,"skyview pointer inverse drifted")
end

local camera=Camera.new(300,420)
camera.perspective=true;camera.pitch=pitch
camera:setMode("skyview",.6)
camera:updateMode(.3)
assert(camera.mode=="skyview" and camera.skyviewBlend>0 and camera.skyviewBlend<1,"skyview did not lerp")
camera:updateMode(.3)
assert(math.abs(camera.skyviewBlend-1)<.0001,"skyview did not finish in 0.6 seconds")
camera:setMode("default",.6);camera:updateMode(.6)
assert(camera.skyviewBlend==0,"skyview did not restore the default camera")

local game=assert(io.open("src/game.lua","rb")):read("*a")
local source=assert(io.open("src/world_projection.lua","rb")):read("*a")
assert(game:find("sandboxSkyviewBox",1,true) and game:find('setMode((self.camera.skyviewTarget',1,true),"practice button is missing")
assert(game:find("SkyView.draw(self.camera)",1,true),"sky/horizon layers are not in the render path")
assert(game:find("self.camera:updateMode(dt)",1,true),"camera mode lerp stops during scripted presentation freezes")
assert(source:find("horizonRatio=.285",1,true) and source:find("u^1.22",1,true),"pseudo-perspective horizon curve is missing")
assert(source:find("Projection.overscanX+(skyPad and .76 or 0)",1,true),"skyview ground can leak sky at the side edges")
assert(source:find('"triangles","dynamic"',1,true) and source:find("cache.mesh:setVertices",1,true),"skyview transition reallocates the render canvas every step")
print(string.format("SKYVIEW_OK horizon=%.1f%% transition=.6s projection=render_only billboard=uniform",Projection.horizonRatio*100))
