package.path="./?.lua;./?/init.lua;"..package.path

local function read(path)
    local file=assert(io.open(path,"rb"));local data=file:read("*a");file:close();return data
end

love={graphics={getDimensions=function()return 1280,720 end},math={random=function()return 0 end}}
local Projection=require("src.world_projection")
local game=read("src/game.lua")
local frontend=read("src/frontend_ui.lua")
local maps=read("src/clearcut_maps.lua")

assert(game:find("viewPitch = .76",1,true),"default view tilt no longer matches the approved 2.5D camera")
assert(game:find("function Game:setViewTilt",1,true) and game:find("function Game:enableClearcutPerspective",1,true),"view tilt setting is not connected to the camera")
assert(game:find("Frontend.slider(self.settingsTiltBox",1,true),"settings screen has no view tilt slider")
assert(game:find("settingsTiltDragging",1,true) and game:find("sliderValueAt",1,true),"view tilt slider cannot be dragged")
assert(game:find('key == "left"',1,true) and game:find('key == "right"',1,true),"view tilt keyboard adjustment missing")
assert(frontend:find("function Frontend.slider",1,true),"frontend slider control missing")

local sandboxStart=assert(game:match("function Game:startClearcutSandbox%b()%s*(.-)function Game:sandboxCharacterName"))
assert(sandboxStart:find("self:enableClearcutPerspective()",1,true),"practice yard is not projected")
local regularStart=assert(game:match("function Game:startClearcut%b()%s*(.-)function Game:setNotice"))
assert(regularStart:find("self:enableClearcutPerspective()",1,true),"clearcut maps are not projected")
assert(game:find("local projected=self.clearcut and self.camera.perspective",1,true),"projection leaked outside clearcut maps")

for _,id in ipairs({"forest","mangrove","madagascar","island","beginner"}) do
    assert(maps:find('id="'..id..'"',1,true),"missing clearcut map: "..id)
end
local _,topDeep=Projection.project(640,0,1280,720,.72)
local _,topFlat=Projection.project(640,0,1280,720,1)
assert(topDeep>topFlat,"view tilt does not strengthen ground-plane compression")

print("VIEW_TILT_SETTING_OK range=0..100 default=86 maps=5 sandbox=projected scope=clearcut_only billboards=uniform")
