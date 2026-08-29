package.path="./?.lua;./?/init.lua;"..package.path

local aimX,held=100,false
love={
    mouse={isDown=function() return held end,getPosition=function() return aimX,0 end},
    math={random=math.random},timer={getTime=function() return 0 end},
    graphics={setLineStyle=function() end,setColor=function() end,setLineWidth=function() end,
        push=function() end,pop=function() end,translate=function() end,rotate=function() end,
        line=function() end,ellipse=function() end,polygon=function() end,print=function() end,
        rectangle=function() end,circle=function() end}
}

local ClearcutMode=require("src.clearcut_mode")
local CharacterTraits=require("src.character_traits")
local CharacterTraitBoard=require("src.character_trait_board")

local player={x=0,y=0,gather=1,facing=1,axeHolding=false,
    setClearcutAction=function(self,p) self.action=p end,
    clearClearcutAction=function(self) self.action=nil end}
local game={player=player,tools={axe={speed=1}},camera={screenToWorld=function(_,x,y) return x,y end}}
local mode=ClearcutMode.new(); mode.job="fire"
local shots,shotTargets=0,{}
mode.hurlMolotovAt=function(_,tx,ty) shots=shots+1;shotTargets[#shotTargets+1]={x=tx,y=ty} end
mode:startSmoking(game)

-- 재장전은 입력 없이 진행되고, 버튼을 놓은 동안 완료된 담배는 준비 상태를 유지해야 한다.
mode:updateFireAttack(mode.smoking.dur+1,game,false)
assert(mode.smoking and mode.smoking.phase=="loaded" and mode.smoking.loaded,"idle smoking did not stay loaded")
assert(shots==0,"reload completion fired while the attack button was released")

-- 클릭은 플릭 모션만 시작하고, 투사체는 손가락이 펴지는 프레임에서 발생한다.
aimX,held=-100,true
assert(mode:updateFireAttack(0,game,true)==false and mode.smoking.phase=="flick","click did not start the flick animation")
aimX=100; player.facing=1 -- moving/aiming right after a left throw was committed
mode:updateFireAttack(mode.smoking.dur*.57,game,true)
assert(player.facing==-1,"throw turned away from its committed target")
assert(shots==0,"shot fired before the fingertip release frame")
assert(mode:updateFireAttack(mode.smoking.dur*.02,game,true)==true,"release frame did not fire")
assert(shots==1 and shotTargets[1].x<0 and player.facing==-1,"shot/facing did not follow the user's left aim")
mode:updateFireAttack(mode.smoking.dur+1,game,true)
assert(mode.smoking and mode.smoking.phase=="reload","next cigarette reload did not start after firing")
mode:updateFireAttack(mode.smoking.dur+1,game,true)
assert(mode.smoking.phase=="loaded" and shots==1,"held reload did not reach the next loaded cigarette")
mode:updateFireAttack(0,game,true)
assert(mode.smoking.phase=="flick","holding the mouse did not automatically start the next throw")
mode:updateFireAttack(mode.smoking.dur*.60,game,true)
assert(shots==2 and shotTargets[2].x>0,"held attack did not fire again toward the current aim after cooldown")
held=false; mode:updateFireAttack(mode.smoking.dur+1,game,false)
local mouthX,_,facing,emberX=mode:smokerMouthPose(game)
assert((emberX-mouthX)*facing>0,"smoker holds the cigarette backwards after repeated fire")

-- The visible smoke ring gets body allowance and swept collision. This target
-- sits outside the old radius and behind the ring's current point, but inside
-- the path that was visibly crossed during this frame.
local ringMode=ClearcutMode.new();ringMode.job="fire"
local ringTarget={x=0,y=48,hp=50}
local outsideRing={x=0,y=49.1,hp=50}
ringMode.enemies={ringTarget,outsideRing};ringMode.smokeRing={x=0,y=0,vx=480,vy=0,radius=20,startRadius=20,maxRadius=20,dmg=10,knockback=100,maxRange=500,traveled=0,hit={}}
ringMode:updateSmokeRing(.1,{world={nodes={}}})
assert(ringTarget.hp==40 and ringTarget.knockTimer>0,"expanded swept smoke-ring hitbox missed a visible crossing")
assert(outsideRing.hp==50,"smoke-ring hit beyond its visible outer puff")
assert(ringMode.smokeRing.hitRadius==49,"upright smoke-ring generous envelope drifted")

-- Use the real movement update order: movement first, then the smoking loop.
local Player=require("src.player")
local walking=setmetatable({x=500,y=500,speed=260,walkClock=0,gather=1,facing=1},Player)
local walkingGame={player=walking,rush={},tools={axe={speed=1}},
    camera={screenToWorld=function(_,x,y) return x,y end}}
local world={width=2000,height=2000,core={x=0,y=0}}
for _,phase in ipairs({"reload","loaded"}) do
    for _,direction in ipairs({-1,1}) do
        local walkingMode=ClearcutMode.new(); walkingMode.job="fire"
        walkingMode.smoking={phase=phase,t=0,dur=10,loaded=phase=="loaded"}
        aimX=walking.x-direction*500
        love.keyboard={isDown=function(key)
            return (direction==-1 and key=="a") or (direction==1 and key=="d")
        end}
        local previousX=walking.x
        walking:update(.016,world,walkingGame)
        walkingMode:updateFireAttack(.016,walkingGame,false)
        assert((walking.x-previousX)*direction>0 and walking.facing==direction,
            "mouse aim overrides walking direction during "..phase)
        love.keyboard.isDown=function() return false end
        walking:update(.016,world,walkingGame)
        walkingMode:updateFireAttack(.016,walkingGame,false)
        assert(walking.facing==direction,"idle smoking turns back toward the cursor")
    end
end

-- 그래프와 정보창은 같은 정식 명칭을 사용해야 한다.
local store=CharacterTraits.new(true)
local board=CharacterTraitBoard.new(store,{}, {})
local node=store:getNodes("physical")[#store:getNodes("physical")]
assert(board:nodeLabel(node)==node.name,"node label and detail title use different names")

print("SMOKER_STATE_AND_TRAIT_LABEL_OK autofire=held reload_cycle=repeat smoke_ring=upright_billboard+generous_swept")
