package.path="./?.lua;./?/init.lua;"..package.path
love={graphics={getDimensions=function()return 1280,720 end},math={random=function(a,b)return 0 end}}
local Camera=require("src.camera")
local cam=Camera.new(500,400)
cam.renderX,cam.renderY,cam.renderZoom,cam.roll,cam.pitch=500,400,1.2,.013,.84
local wx0,wy0=742,533
local dx,dy=wx0-cam.renderX,wy0-cam.renderY
local c,s=math.cos(cam.roll),math.sin(cam.roll)
local sx=640+(dx*c-dy*cam.pitch*s)*cam.renderZoom
local sy=360+(dx*s+dy*cam.pitch*c)*cam.renderZoom
local wx,wy=cam:screenToWorld(sx,sy)
assert(math.abs(wx-wx0)<.001 and math.abs(wy-wy0)<.001,"2.5D projection input inverse drifted")
local left,top,right,bottom=cam:visibleBounds()
assert(bottom-top>720/cam.renderZoom,"pitched camera did not widen vertical world bounds")
local game=assert(io.open("src/game.lua","rb")):read("*a")
local depth=assert(io.open("src/camera_depth_art.lua","rb")):read("*a")
assert(game:find("self.camera.pitch=.84",1,true),"clearcut 2.5D pitch missing")
assert(depth:find("overhead crown",1,true) and depth:find("h*.62",1,true),"three-plane foreground depth missing")
print("CAMERA_25D_OK pitch=.84 inverse=exact planes=ground+actors+foreground")
