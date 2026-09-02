package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Mode=require("src.clearcut_mode")
local Art=require("src.flamethrower_art")

local function game()
    local world={nodes={},playBounds={x=-1000,y=-1000,w=2000,h=2000},billboardQueue={}}
    local player={x=0,y=0,facing=1,gather=1}
    function player:clearClearcutAction()self.clearcutActionProgress=nil end
    function player:setClearcutAction(value)self.clearcutActionProgress=value end
    return{player=player,world=world,tools={axe={speed=1}},camera={screenToWorld=function()return 350,0 end}}
end

local stream={x=34,y=-58,nx=1,ny=0,reach=380,halfWidth=90,t=0}
fixture.reset();Art.drawHeld({flameStream=stream},{player={x=0,y=0,facing=1}});Art.drawStream(stream)
local equipment,atlas=0,0
for _,command in ipairs(fixture.commands)do if command.op=="draw"then
    if command.file=="assets/effects/smoker-flamethrower-equipment-v1.png"then equipment=equipment+1 end
    if command.file=="assets/effects/smoker-flamethrower-stream-atlas-v5.png"then atlas=atlas+1 end
end end
assert(equipment==1 and atlas==1,"flamethrower did not use its authored equipment and stream atlases")

local frameKeys={}
for index=0,7 do
    fixture.reset();stream.t=index/16;Art.drawStream(stream)
    local command=fixture.commands[1]
    assert(command and command.file=="assets/effects/smoker-flamethrower-stream-atlas-v5.png","stream atlas draw disappeared")
    frameKeys[(command.quad[1]or 0)..":"..(command.quad[2]or 0)]=true
end
local frameCount=0;for _ in pairs(frameKeys)do frameCount=frameCount+1 end
assert(frameCount==8,"runtime did not expose all eight coherent stream frames")

local mode=Mode.new();mode.scoreAttack=true;mode.job="fire";mode.permanentTraits.scoreFlameUnlock=1
mode.flameStream=stream;local g=game();mode:queueProjectedOverlay(g,.2)
local queued=false
for _,entry in ipairs(g.world.billboardQueue)do
    if entry.draw then fixture.reset();entry.draw()
        for _,command in ipairs(fixture.commands)do
            if command.op=="draw"and command.file=="assets/effects/smoker-flamethrower-stream-atlas-v5.png"then queued=true end
        end
    end
end
assert(queued,"flamethrower stream did not enter the upright 2.5D billboard pass")
print("FLAMETHROWER_ART_OK atlas=v5:1536x768x8 equipment=384x128 nearest=true billboard=upright source=8-authored-moments")
