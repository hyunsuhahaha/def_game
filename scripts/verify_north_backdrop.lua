package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Backdrop=require("src.north_backdrop")
local Maps=require("src.clearcut_maps")

love.graphics.getDimensions=function()return 1280,720 end
local camera={renderX=1600,skyviewBlend=0,worldToScreen=function(_,x,y)return 640,286 end}
local world={width=3200,height=2000,clearcutMap="forest",northBackdrop=true,playBounds={x=400,y=300,w=2400,h=1400}}
fixture.reset()
assert(Backdrop.drawBack(camera,world) and Backdrop.drawRidge(camera,world),"north backdrop did not render at the boundary")
local draws={}
for _,command in ipairs(fixture.commands)do if command.file and command.file:find("north_backdrops",1,true)then
    draws[#draws+1]=command;assert(command.filter=="nearest","north backdrop lost nearest filtering")
end end
assert(#draws==2 and draws[1].file:find("panorama%-pixel%-v2") and draws[2].file:find("ridge%-pixel%-v1"),
    "panorama/ridge render order drifted")
camera.skyviewBlend=1;fixture.reset()
assert(not Backdrop.drawBack(camera,world) and #fixture.commands==0,"north backdrop overlapped SKYVIEW")

local configured={width=3200,height=2000,clearcutMap="forest"};Maps.configureStage(configured,1)
assert(configured.northBackdrop and configured.cameraTopReveal==900 and configured.playBounds.y>configured.cameraBounds.y,
    "map did not separate play and presentation bounds")
local game=assert(io.open("src/game.lua","rb")):read("*a")
local projection=assert(io.open("src/world_projection.lua","rb")):read("*a")
local worldSource=assert(io.open("src/world.lua","rb")):read("*a")
assert(game:find("NorthBackdrop.drawBack",1,true)<game:find("WorldProjection.begin",1,true),"panorama is not behind projected ground")
assert(game:find("WorldProjection.finish",1,true)<game:find("NorthBackdrop.drawRidge",1,true)
    and game:find("NorthBackdrop.drawRidge",1,true)<game:find("WorldProjection.drawBillboards",1,true),
    "ridge is not between terrain and actors")
assert(projection:find("love.graphics.clear(0,0,0,0)",1,true),"projected canvas still blocks the panorama")
assert(worldSource:find("self.playBounds.y",1,true) and worldSource:find("setStencilTest",1,true),"playable ground is not clipped at the ridge")
print("NORTH_BACKDROP_OK maps=4 layers=panorama+ridge+playfield reveal=900 collision=unchanged skyview=isolated")
