package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
love.graphics.rotate=love.graphics.rotate or function()end
love.graphics.getDimensions=function()return 1280,720 end
love.graphics.getWidth=function()return 1280 end
love.graphics.getHeight=function()return 720 end
love.mouse={getPosition=function()return 640,360 end,isDown=function()return false end}
love.keyboard={isDown=function()return false end}

local Mode=require("src.clearcut_mode")
local mode=Mode.new();mode.scoreAttack=true;mode.job="fire"
assert(mode.setScoreWeaponSlot==nil and mode.scoreWeaponSlotAt==nil and mode.drawScoreWeaponSlots==nil,
    "manual score weapon slots are still active")
assert(mode:scoreRangedWeaponId()=="cigarette","locked ranged context did not default to the cigarette")

local aimX=110
local tree={rushTree=true,active=true,x=110,y=0,rushHp=100,rushMaxHp=100}
local farTree={rushTree=true,active=true,x=600,y=0,rushHp=100,rushMaxHp=100}
local game={
    player={x=0,y=0,facing=1,gather=1.15,axeHolding=false,cancelInteraction=function()end,playAutoAxeSwing=function()end},
    camera={screenToWorld=function()return aimX,0 end},
    world={nodes={tree,farTree},impactNode=function()end},tools={axe={speed=.8}},setNotice=function()end,
}

-- Clicking the nearby tree claims the input for the authored axe swing.
mode:updateHeldAxe(.7,game,true)
assert(mode.scoreActiveWeapon=="axe"and mode.scoreAxeAction,"nearby tree click did not select the melee weapon")
for _=1,240 do
    if not mode.scoreAxeAction then break end
    mode:updateScoreAxeAction(1/60,game)
end
assert(tree.rushHp==96 and mode.actionAudit.scoreAxe==1,
    "contextual axe did not apply its real contact-frame hit")

-- A cigarette flick that has started owns the action until its release frame,
-- even if the aim enters axe range before the next update.
local throwLock=Mode.new();throwLock.scoreAttack=true;throwLock.job="fire"
throwLock.smoking={phase="loaded",t=0,dur=1,loaded=true,fired=false}
local thrown=0
throwLock.hurlMolotovAt=function()thrown=thrown+1 end
aimX=600
throwLock:updateHeldAxe(0,game,true)
assert(throwLock.smoking.phase=="flick"and throwLock.scoreActiveWeapon=="cigarette",
    "far click did not begin the cigarette flick")
aimX=110
throwLock:updateHeldAxe(1,game,true)
assert(thrown==1 and not throwLock.scoreAxeAction and throwLock.scoreActiveWeapon=="cigarette",
    "entering axe range interrupted a cigarette flick that had already started")
throwLock:updateHeldAxe(0,game,true)
assert(throwLock.scoreActiveWeapon=="axe"and throwLock.scoreAxeAction,
    "axe did not take over after the committed cigarette motion finished")

-- Merely standing near a tree does not steal a ranged click aimed elsewhere.
mode.permanentTraits.scoreRocketUnlock=1
mode.smokerWeaponCooldown=0;aimX=600
assert(mode:updateHeldAxe(1,game,true)and mode.scoreActiveWeapon=="firework",
    "unlocked far click did not automatically select the firework")

-- 실제 게임 루프는 heldOverride 없이 부르고 각 무기가 직접 마우스를 읽는다.
-- 폭죽만 이 규약을 어겨 nil을 "안 누름"으로 읽는 바람에 아무리 클릭해도 발사가
-- 되지 않았다. 오버라이드 없는 경로를 그대로 한 번 더 검사한다.
mode.smokerWeaponProjectiles={}
mode.smokerWeaponCooldown=0
love.mouse.isDown=function(button)return button==1 end
assert(mode:updateHeldAxe(1,game),"real held-mouse loop did not fire the firework")
assert(mode.smokerWeaponProjectiles[1]and mode.smokerWeaponProjectiles[1].kind=="firework",
    "real held-mouse loop launched no firework projectile")
love.mouse.isDown=function()return false end
mode.smokerWeaponProjectiles={}
mode.smokerWeaponCooldown=0
assert(mode:updateHeldAxe(1,game,true),"re-arm shot for the burst path failed")
assert(mode.smokerWeaponProjectiles[1]and mode.smokerWeaponProjectiles[1].kind=="firework",
    "contextual ranged attack did not launch the real firework projectile")
mode:updateSmokerWeaponProjectiles(2,game)
assert(farTree.rushHp<100,"contextual firework did not detonate against its target area")

local burst
for _,projectile in ipairs(mode.smokerWeaponProjectiles)do
    if projectile.kind=="firework_burst"then burst=projectile;break end
end
assert(burst,"contextual firework did not retain its authored burst for rendering")
fixture.reset();game.world.billboardQueue={}
mode:queueProjectedOverlay(game,0)
local burstActor
for _,actor in ipairs(game.world.billboardQueue)do
    if actor.x==burst.x and actor.y==burst.y and(actor.sortBias or 0)>90000 then burstActor=actor;break end
end
assert(burstActor,"contextual firework burst was not queued above the dense world canopy")
burstActor.draw()
local drewExistingBurst=false
for _,command in ipairs(fixture.commands)do
    if command.op=="draw"and command.file=="assets/effects/smoker-firework-burst-v2.png"then
        drewExistingBurst=true;break
    end
end
assert(drewExistingBurst,"contextual firework did not draw the existing 30-frame burst effect")
print("SCORE_CONTEXT_WEAPONS_OK near=axe far=cigarette->firework slots=removed burst=existing30fps")
