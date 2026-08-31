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
mode.scoreEquippedWeapons={"cigarette","firework"}
assert(mode:setScoreWeaponSlot(2,game)and mode:scoreWeaponId()=="firework","equipped slot 2 did not select the firework rocket")
assert(not mode:setScoreWeaponSlot(3,game)and mode:scoreWeaponId()=="firework","third score weapon slot still exists")
local x,y,w,h=mode:scoreWeaponSlotRect(1,1280,720)
assert(mode:scoreWeaponSlotAt(x+w/2,y+h/2,1280,720)==1,"clickable weapon slot geometry is disconnected from the HUD")
assert(#Mode.scoreWeaponDefinitions==3 and #notices==2,"weapon inventory or two-slot selection feedback is incomplete")

local calls={}
mode.updateFireAttack=function(_,_,_,forced)calls[#calls+1]=forced and"cigarette"or"evolved";return true end
mode.updateScoreAxeAttack=function()calls[#calls+1]="axe";return true end
mode.updateFireworkAttack=function()calls[#calls+1]="firework";return true end
mode.scoreEquippedWeapons={"cigarette","axe"}
for slot=1,2 do mode.scoreWeaponSlot=slot;assert(mode:updateHeldAxe(0,game,true))end
mode.scoreEquippedWeapons[2]="firework";mode.scoreWeaponSlot=2;assert(mode:updateHeldAxe(0,game,true))
assert(table.concat(calls,",")=="cigarette,axe,firework","selected weapon did not own the click attack path")

local actual=Mode.new();actual.scoreAttack=true;actual.job="fire"
local tree={rushTree=true,active=true,x=100,y=0,rushHp=100,rushMaxHp=100}
local attackGame={
    player={x=0,y=0,facing=1,gather=1.15,axeHolding=false,cancelInteraction=function()end,playAutoAxeSwing=function()end},
    camera={screenToWorld=function()return 100,0 end},
    world={nodes={tree},impactNode=function()end},tools={axe={speed=.8}},setNotice=function()end,
}
-- 도끼 타격은 스윙의 접촉 프레임에서 해결되므로 접촉 시점까지 굴려야 한다.
local function swing(mode,world)
    mode:updateHeldAxe(.7,world,true)
    for _=1,240 do
        if not mode.scoreAxeAction then break end
        mode:updateScoreAxeAction(1/60,world)
    end
end
actual.scoreWeaponSlot=2
swing(actual,attackGame)
assert(tree.rushHp==96 and actual.actionAudit.scoreAxe==1,
    "axe slot did not apply its real direct tree hit")
actual.scoreEquippedWeapons={"cigarette","firework"};actual.scoreWeaponSlot=2;actual.smokerWeaponCooldown=0
assert(actual:updateHeldAxe(1,attackGame,true)and actual.smokerWeaponProjectiles[1].kind=="firework",
    "firework slot did not launch its real projectile")
actual:updateSmokerWeaponProjectiles(2,attackGame)
assert(tree.rushHp<96,"firework projectile did not detonate against its displayed target area")
print("SCORE_WEAPON_SLOTS_OK equipped_slots=2 inventory_weapons=3 attacks=cigarette+axe+firework")
