package.path="./?.lua;./?/init.lua;"..package.path

local function read(path)
    local file=assert(io.open(path,"rb"));local data=file:read("*a");file:close();return data
end

love={graphics={getDimensions=function()return 1280,720 end},math={random=function()return 0 end}}
local Projection=require("src.world_projection")
local game=read("src/game.lua")
local settings=read("src/settings.lua")
local frontend=read("src/frontend_ui.lua")
local maps=read("src/clearcut_maps.lua")

assert(settings:find("viewPitch=.76",1,true),"default view tilt no longer matches the approved 2.5D camera")
assert(game:find("function Game:setViewTilt",1,true) and game:find("function Game:enableClearcutPerspective",1,true),"view tilt setting is not connected to the camera")
assert(game:find("Frontend.slider(self.settingsTiltBox",1,true),"settings screen has no view tilt slider")
assert(game:find('Frontend.slider(tiltBox,self:viewTiltAmount()',1,true),"in-game ESC pause menu has no perspective slider")
assert(game:find("self.pauseTiltDragging=true",1,true) and game:find("if self.paused and self.pauseTiltDragging",1,true),"pause perspective slider cannot be dragged")
assert(game:find("if self.paused then",1,true) and game:find("local _,_,_,_,_,_,tiltBox=self:pauseButtons()",1,true),"pause slider wheel input missing")
assert(game:find("settingsTiltDragging",1,true) and game:find("sliderValueAt",1,true),"view tilt slider cannot be dragged")
assert(game:find('key == "left"',1,true) and game:find('key == "right"',1,true),"view tilt keyboard adjustment missing")
assert(frontend:find("function Frontend.slider",1,true),"frontend slider control missing")

local sandboxStart=assert(game:match("function Game:startClearcutSandbox%b()%s*(.-)function Game:sandboxCharacterName"))
assert(sandboxStart:find("self:enableClearcutPerspective()",1,true),"practice yard is not projected")
local regularStart=assert(game:match("function Game:startClearcut%b()%s*(.-)function Game:setNotice"))
assert(regularStart:find("self:enableClearcutPerspective()",1,true),"clearcut maps are not projected")
assert(game:find("local projected=self.clearcut and self.camera.perspective",1,true),"projection leaked outside clearcut maps")

for _,id in ipairs({"forest","mangrove","madagascar","island"}) do
    assert(maps:find('id="'..id..'"',1,true),"missing clearcut map: "..id)
end
local _,topDeep=Projection.project(640,0,1280,720,.72)
local _,topFlat=Projection.project(640,0,1280,720,1)
assert(topDeep>topFlat,"view tilt does not strengthen ground-plane compression")

-- Exercise the real billboard pass at both slider extremes. Upright character,
-- skill and projectile art may change uniform size with depth, never aspect.
local scaleCalls={}
love.graphics.setBlendMode=function()end
love.graphics.push=function()end
love.graphics.pop=function()end
love.graphics.translate=function()end
love.graphics.scale=function(x,y)scaleCalls[#scaleCalls+1]={x,y};assert(math.abs(x-y)<1e-9,"upright billboard aspect ratio was distorted")end
for _,pitch in ipairs({.72,1})do
    local camera={pitch=pitch,renderZoom=1,worldToScreen=function(self,x,y)return Projection.project(x,y,1280,720,self.pitch)end}
    local drawn=false
    Projection.drawBillboards({{x=320,y=210,anchorY=240,draw=function()drawn=true end}},camera)
    assert(drawn,"billboard skill layer was not drawn at pitch "..pitch)
end
assert(#scaleCalls==2,"billboard scale contract was not exercised at both slider extremes")

print("VIEW_TILT_SETTING_OK range=0..100 default=86 pause=drag/wheel/keys maps=4 sandbox=projected scope=clearcut_only billboards=uniform")
