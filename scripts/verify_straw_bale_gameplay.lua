package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Mode=require("src.clearcut_mode")
local mode=Mode.new();mode.job="fire";mode.levels.straw_bale=1;mode.strawTimer=999;mode.smokerGroundTime=10
mode.strawBales={{x=100,y=120,age=0,ignited=false,variant=0}}
mode.cigaretteButts={}
local spreadCalls,igniteFxCalls=0,0
local game={player={x=0,y=0},world={nodes={{rushTree=true,active=true,burning=true,x=100,y=120,rushHp=1000,rushMaxHp=1000}},igniteFx=function() igniteFxCalls=igniteFxCalls+1 end,impactNode=function() end}}
mode.damageEnemiesInRadius=function(self,x,y,radius,damage)
    self.damageAudit={x=x,y=y,radius=radius,damage=damage}
end
mode.igniteNear=function() spreadCalls=spreadCalls+1 end

-- A burning tree on top of the bale no longer lights it.
mode:updateStrawBales(.1,game)
local bale=mode.strawBales[1]
assert(not bale.primedAt and not bale.ignited,"burning tree still auto-ignites hay")

-- The larger bale accepts a cigarette across its visible top, then keeps the
-- exact half-second anticipation.
mode.cigaretteButts={{x=168,y=120}}
mode:updateStrawBales(.01,game)
assert(bale.primedAt==10 and not bale.ignited,"cigarette did not prime bale")
mode.smokerGroundTime=10.49;mode:updateStrawBales(.48,game)
assert(not bale.ignited,"bale ignited before 0.5 seconds")
mode.smokerGroundTime=10.5;mode:updateStrawBales(.01,game)
assert(bale.ignited and bale.ignitedAt==10.5,"bale did not ignite at 0.5 seconds")
assert(igniteFxCalls==0,"generic tree ignition FX masks authored bale animation")

-- Local DOT stays intact, without invoking any spread path.
mode.smokerGroundTime=10.9;mode:updateStrawBales(.4,game)
local openingGrowth=(.5/5.6)^1.35
local expectedRadius,expectedDamage=150+openingGrowth*70,7+openingGrowth*6
assert(mode.damageAudit and math.abs(mode.damageAudit.radius-expectedRadius)<.001 and mode.damageAudit.radius>150)
assert(math.abs(mode.damageAudit.damage-expectedDamage)<.001)
assert(spreadCalls==0,"hay fire spread to another target")

-- Nearby trees take the burn as direct continuous damage, not an ember hand-off.
local scorched=game.world.nodes[1]
assert(math.abs(scorched.rushHp-(1000-expectedDamage))<.001,"nearby tree did not take straw-bale burn damage")
assert(spreadCalls==0 and igniteFxCalls==0,"straw bale used the ember-transfer path instead of direct damage")

mode.cigaretteButts={}
fixture.reset();local queue={};mode:queueWorldActors(queue,mode.smokerGroundTime)
local found,bodyLarge,continuous=false,false,false
for _,entry in ipairs(queue) do
    entry.draw()
end
for _,op in ipairs(fixture.commands) do
    if op.file=="assets/fx/straw-bale/straw-bale-body-pixel-v4.png" then
        found=true;bodyLarge=op.op=="draw" and op.filter=="nearest" and op.args[4]==.55
    elseif op.file=="assets/fx/straw-bale/straw-bale-atlas-pixel-v3.png" and op.shader=="assets/shaders/straw-bale-fire.glsl" then
        continuous=op.uniforms.fireTime and op.uniforms.fireGrid[1]>=34 and op.uniforms.fireLayer~=nil
    end
end
assert(found,"authored straw-bale atlas was not depth-queued")
assert(bodyLarge,"straw-bale body was not enlarged")
assert(continuous,"continuous-time flame shader was not depth-queued")
if STRAW_CAPTURE then
    bale.x,bale.y=320,310
    local ground=love.graphics.newImage("assets/forest-ground-tile-v1.png")
    for frame=0,17 do
        mode.smokerGroundTime=10.5+frame/30
        fixture.reset();love.graphics.setColor(1,1,1,1)
        love.graphics.draw(ground,0,0,0,640/ground:getWidth(),360/ground:getHeight())
        local frameQueue={};mode:queueWorldActors(frameQueue,mode.smokerGroundTime)
        for _,entry in ipairs(frameQueue) do entry.draw() end
        fixture.save("docs/previews/straw-bale-v4-"..frame.."-draws.json")
    end
end
print("STRAW_BALE_GAMEPLAY_OK cigarette_only delay=0.5 dot=150..220 damage=7..13 spread=none continuous_shader=v4")
