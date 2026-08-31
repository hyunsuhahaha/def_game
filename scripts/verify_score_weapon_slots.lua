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
-- 폭죽은 이제 영구 연구(담배 자동 투척 → 폭죽 해금)로 열린다. 이 검사는 슬롯 조작과
-- 입력 경로를 다루므로 해금은 미리 부여하고, 해금 게이트 자체는
-- scripts/verify_score_weapon_traits.lua가 검사한다.
mode.permanentTraits.scoreRocketUnlock=1
local notices={}
local game={player={axeHolding=false,clearClearcutAction=function()end},setNotice=function(_,message)notices[#notices+1]=message end}
assert(mode:scoreWeaponId()=="cigarette","score mode did not default to cigarette slot")
assert(mode:setScoreWeaponSlot(2,game)and mode:scoreWeaponId()=="axe","slot 2 did not select the axe")
assert(mode:setScoreWeaponSlot(3,game)and mode:scoreWeaponId()=="firework","slot 3 did not select the firework rocket")
assert(not mode:setScoreWeaponSlot(4,game)and mode:scoreWeaponId()=="firework","invalid score weapon slot changed the weapon")
local x,y,w,h=mode:scoreWeaponSlotRect(1,1280,720)
assert(mode:scoreWeaponSlotAt(x+w/2,y+h/2,1280,720)==1,"clickable weapon slot geometry is disconnected from the HUD")
assert(#Mode.scoreWeaponDefinitions==3 and #notices==2,"weapon definitions or selection feedback are incomplete")

local calls={}
mode.updateFireAttack=function(_,_,_,forced)calls[#calls+1]=forced and"cigarette"or"evolved";return true end
mode.updateScoreAxeAttack=function()calls[#calls+1]="axe";return true end
mode.updateFireworkAttack=function()calls[#calls+1]="firework";return true end
for slot=1,3 do mode.scoreWeaponSlot=slot;assert(mode:updateHeldAxe(0,game,true))end
assert(table.concat(calls,",")=="cigarette,axe,firework","selected weapon did not own the click attack path")

local actual=Mode.new();actual.scoreAttack=true;actual.job="fire"
local tree={rushTree=true,active=true,x=100,y=0,rushHp=100,rushMaxHp=100}
local attackGame={
    player={x=0,y=0,facing=1,gather=1.15,axeHolding=false,cancelInteraction=function()end,playAutoAxeSwing=function()end},
    camera={screenToWorld=function()return 100,0 end},
    world={nodes={tree},impactNode=function()end},tools={axe={speed=.8}},setNotice=function()end,
}
actual.scoreWeaponSlot=2
assert(actual:updateHeldAxe(.7,attackGame,true)and tree.rushHp==96 and actual.actionAudit.scoreAxe==1,
    "axe slot did not apply its real direct tree hit")
actual.scoreWeaponSlot=3;actual.smokerWeaponCooldown=0
assert(actual:updateHeldAxe(1,attackGame,true)and actual.smokerWeaponProjectiles[1].kind=="firework",
    "firework slot did not launch its real projectile")
actual:updateSmokerWeaponProjectiles(2,attackGame)
assert(tree.rushHp<96,"firework projectile did not detonate against its displayed target area")
print("SCORE_WEAPON_SLOTS_OK slots=3 input=keyboard+click attacks=cigarette+axe+firework")
