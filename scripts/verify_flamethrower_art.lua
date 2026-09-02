package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
love.mouse={getPosition=function()return 350,0 end}
local Mode=require("src.clearcut_mode")
local Art=require("src.flamethrower_art")

local function game()
    local world={nodes={},playBounds={x=-1000,y=-1000,w=2000,h=2000},billboardQueue={}}
    function world:impactNode(node)node.hitFlash=.2 end
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

stream.nx=-1;stream.ny=0;fixture.reset();Art.drawStream(stream)
local left=fixture.commands[1]
assert(left.args[3]==0 and left.args[4]<0 and left.args[5]>0,
    "left-facing stream must mirror horizontally without turning upside down")
stream.nx=1

stream.visualStyle="torch";local torchFrames={}
for index=0,7 do
    fixture.reset();stream.t=index/16;Art.drawStream(stream)
    local command=fixture.commands[1]
    assert(command and command.file=="assets/effects/smoker-flamethrower-torch-atlas-v1.png","torch atlas draw disappeared")
    torchFrames[(command.quad[1]or 0)..":"..(command.quad[2]or 0)]=true
end
local torchCount=0;for _ in pairs(torchFrames)do torchCount=torchCount+1 end
assert(torchCount==8,"torch runtime did not expose all eight frames")
fixture.reset();Art.drawImpact(20,30,.1,2)
assert(fixture.commands[1]and fixture.commands[1].file=="assets/effects/smoker-flamethrower-torch-impact-atlas-v1.png",
    "tree-contact torch impact atlas disappeared")

local mode=Mode.new();mode.scoreAttack=true;mode.job="fire";mode.permanentTraits.scoreFlameUnlock=1
mode.flameVisualStyle="torch";mode.smokerGroundTime=.1;mode.flameStream=stream;local g=game()
mode.permanentTraits.scoreFlameRange=250;mode.permanentTraits.scoreFlameWidth=56
g.world.nodes={{rushTree=true,active=true,burning=true,x=110,y=0,rushHp=10,rushMaxHp=10}}
mode:updateFlamethrowerAttack(.13,g,true)
assert(mode.flameStream.reach==550 and mode.flameStream.halfWidth==128,
    "max flamethrower research did not extend reach to 550 while preserving its existing width")
assert(g.world.nodes[1].hitFlash==0,"flamethrower left the generic solid tree-hit circle visible")
g.world.nodes={{rushTree=true,active=true,x=110,y=20,flameTorchImpactAt=0,flameTorchImpactPhase=1},
    {rushTree=true,active=true,x=210,y=30,flameTorchImpactAt=0,flameTorchImpactPhase=5}}
mode:queueProjectedOverlay(g,.2)
local queued,impactCount=false,0
for _,entry in ipairs(g.world.billboardQueue)do
    if entry.draw then fixture.reset();entry.draw()
        for _,command in ipairs(fixture.commands)do
            if command.op=="draw"and command.file=="assets/effects/smoker-flamethrower-torch-atlas-v1.png"then queued=true end
            if command.op=="draw"and command.file=="assets/effects/smoker-flamethrower-torch-impact-atlas-v1.png"then impactCount=impactCount+1 end
        end
    end
end
assert(queued,"flamethrower stream did not enter the upright 2.5D billboard pass")
assert(impactCount==2,"torch impact was not queued independently for every damaged tree")
print("FLAMETHROWER_ART_OK styles=classic+torch frames=8 impacts=per-tree generic-circle=off billboard=upright")
