package.path = "./?.lua;./?/init.lua;" .. package.path

local font = {getHeight=function() return 16 end}
local image = {getDimensions=function() return 1536,1024 end, getWidth=function() return 1536 end, getHeight=function() return 1024 end}
local mouseX,mouseY,mouseDown=-1,-1,false
love = {
    math={random=math.random}, filesystem={}, mouse={getPosition=function() return mouseX,mouseY end,isDown=function() return mouseDown end},
    graphics={
        getDimensions=function() return 1600,900 end, setColor=function() end, rectangle=function() end,
        setFont=function() end, print=function() end, printf=function() end, draw=function() end,
        line=function() end, circle=function() end, ellipse=function() end, polygon=function() end,
        setLineWidth=function() end, push=function() end, pop=function() end,
        translate=function() end, rotate=function() end, setScissor=function() end,
        newQuad=function() return {} end
    }
}

local CharacterTraits = require("src.character_traits")
local ClearcutMode = require("src.clearcut_mode")
local Lobby = require("src.lobby")
local CharacterTraitBoard = require("src.character_trait_board")

local lobby = setmetatable({
    scoreAttackBox={x=0,y=0,w=100,h=50},
    traitsBox={x=110,y=0,w=100,h=50},
    settingsBox={x=220,y=0,w=100,h=50}
}, Lobby)
assert(lobby:keypressed("return") == "score_attack" and lobby:keypressed("m")=="score_attack" and lobby:keypressed("c") == nil, "active lobby did not intentionally disable campaign shortcuts")
assert(lobby:mousepressed(20,20,1)=="score_attack" and lobby:mousepressed(130,20,1) == "character_traits", "score-attack lobby navigation is not wired")
lobby.audioTrack=1;lobby.audioPlaying=false;lobby:keypressed("]")
assert(lobby.audioTrack==2 and lobby.audioPlaying,"lobby audio track shortcut failed")
lobby:keypressed("r")
assert(not lobby.audioPlaying,"lobby audio playback shortcut failed")

local store = CharacterTraits.new(true)
assert(store:getRegenTier()==1 and store:unlockRegenTier(3) and store:getRegenTier()==3 and not store:unlockRegenTier(2),"persistent regeneration tier did not advance monotonically")
-- 연구 비용 상승률. 판당 수입이 지수로 커지는데 노드 가격이 고정값이라 후반 트리가
-- 녹던 문제를 막는다. 이미 산 기록 모드 랭크 수만큼 배율이 붙는다.
do
    local esc=CharacterTraits.new(true)
    local node=esc:getNode("universal_robot_start")
    local base=node.costs[1]
    assert(esc:ownedScoreRanks()==0,"a fresh store already counted owned score ranks")
    assert(esc:nodeCost(node,0)==base,"the very first research node must cost its authored price")

    -- 보존된 캐릭터 트리는 다른 경제라 상승률을 받지 않는다.
    local archived=esc:getNode("physical_quota")
    assert(not archived.scoreMode and esc:nodeCost(archived,0)==archived.costs[1],
        "archived character research picked up the score-mode escalation")

    esc.data.levels.universal_robot_start=1
    esc.data.levels.universal_mole_companion=1
    esc._scoreRanks=nil
    assert(esc:ownedScoreRanks()==2,"owned score ranks were miscounted")
    local k=CharacterTraits.RESEARCH_ESCALATION
    local expected=math.max(1,math.floor(node.costs[1]*k^2+.5))
    assert(esc:nodeCost(node,0)==expected,
        "escalation did not apply owned-rank scaling, got "..esc:nodeCost(node,0).." want "..expected)
    assert(k>1,"research escalation must actually escalate")

    -- 재생 단계 제한 노드는 해당 단계의 한 판 수입대에 직접 맞춘 고정 가격이다.
    -- 전역 보유 랭크 배율까지 다시 곱하면 가격이 이중으로 뛴다.
    local gated=esc:getNode("universal_veteran_crew")
    assert(gated.requiresTier==8 and esc:nodeCost(gated,0)==16000,
        "tier-gated research did not keep its authored stage price")
    local targeted=esc:getNode("fire_score_flame_unlock")
    assert(targeted.targetTier==8 and esc:nodeCost(targeted,0)==16000,
        "stage-targeted weapon research picked up the global rank multiplier")

    -- 어느 시점에서든 후보 전체에 같은 배율이 걸리므로 "가장 싼 것부터"의 순서는
    -- 손으로 적어 둔 가격 순서와 항상 같아야 한다. 순서가 바뀌면 nextGoal 이 흔들린다.
    local ordered=CharacterTraits.new(true)
    ordered.data.levels.universal_robot_start=1
    ordered.data.levels.universal_mole_companion=1
    ordered.data.levels.universal_oil_drum=1
    ordered._scoreRanks=nil
    local previousAuthored,previousScaled
    for _,id in ipairs({"universal_oil_duration","universal_oil_interval","universal_gray_cat"})do
        local candidate=ordered:getNode(id)
        local authored,scaled=candidate.costs[1],ordered:nodeCost(candidate,0)
        if previousAuthored then
            assert((authored>previousAuthored)==(scaled>previousScaled),
                "escalation reordered which node is cheapest: "..id)
        end
        previousAuthored,previousScaled=authored,scaled
    end

    -- 트리 끝의 노드는 시작 노드보다 확실히 비싸야 한다. 이게 안 되면 녹는다.
    local full=CharacterTraits.new(true)
    local ranks=0
    for _,job in ipairs({"fire","universal"})do
        for _,scoreNode in ipairs(full:getScoreAttackNodes(job))do ranks=ranks+scoreNode.max end
    end
    full._scoreRanks=nil
    local endMultiplier=k^ranks
    assert(endMultiplier>=8,"the tree-wide escalation is too flat to stop late nodes melting: "..endMultiplier)
    assert(endMultiplier<=20,"the tree-wide escalation turned the tail into a wall: "..endMultiplier)
end

local moleUpgradeStore=CharacterTraits.new(true)
moleUpgradeStore.data.currency=500000
moleUpgradeStore.data.levels.universal_robot_start=1
assert(moleUpgradeStore:buy("universal_mole_companion")and not moleUpgradeStore:buy("universal_mole_companion"),"mole hire root was not a one-rank node")
assert(moleUpgradeStore:buy("universal_oil_drum")and moleUpgradeStore:buy("universal_gray_cat"),"gray oil-cat research chain was not purchasable")
for _,spec in ipairs({{"universal_oil_interval",3},{"universal_oil_radius",5},{"universal_oil_splash_count",4},
    {"universal_oil_patch_scale",4},{"universal_oil_radius_2",4},{"universal_oil_radius_3",3},
    {"universal_oil_splash_count_2",4},{"universal_oil_ignition_radius",4},{"universal_oil_duration",4},
    {"universal_oil_burn_duration",4},{"universal_oil_damage",5},{"universal_gray_cat_chance",3},
    {"universal_gray_cat_delay",3},{"universal_gray_cat_speed",4},{"universal_gray_cat_exit_speed",4}})do
    for rank=1,spec[2]do assert(moleUpgradeStore:buy(spec[1]),spec[1].." rank "..rank.." was not purchasable")end
end
for _,spec in ipairs({{"universal_mole_damage",3},{"universal_mole_speed",3},{"universal_mole_attack_speed",3},
    {"universal_mole_claw",2},{"universal_mole_dual",1},{"universal_mole_extra",2},{"universal_mole_burrow",1},
    {"universal_mole_burrow_speed",3},{"universal_mole_burrow_damage",3},{"universal_mole_burrow_cooldown",3}})do
    for rank=1,spec[2]do assert(moleUpgradeStore:buy(spec[1]),spec[1].." rank "..rank.." was not purchasable")end
end
local moleEffects=moleUpgradeStore:scoreAttackEffects()
assert(moleEffects.scoreMoleCompanion==1 and moleEffects.scoreMoleDamage==3 and math.abs(moleEffects.scoreMoleSpeed-.30)<1e-9 and
    math.abs(moleEffects.scoreMoleAttackSpeed-.36)<1e-9 and moleEffects.scoreMoleClawTier==2 and moleEffects.scoreMoleDualClaw==1 and
    moleEffects.scoreMoleExtraCompanions==2 and moleEffects.scoreMoleBurrow==1 and
    math.abs(moleEffects.scoreMoleBurrowSpeed-.36)<1e-9 and moleEffects.scoreMoleBurrowDamage==6 and
    moleEffects.scoreMoleBurrowCooldown==4.5,"split mole research nodes did not accumulate independently")
assert(moleEffects.scoreOilDrum==1 and moleEffects.scoreGrayCat==1,"gray oil-cat research effects were not accumulated")
assert(moleEffects.scoreOilDrumInterval==6 and moleEffects.scoreOilRadius==590 and moleEffects.scoreOilSplashCount==32 and
    math.abs(moleEffects.scoreOilPatchScale-.32)<1e-9 and moleEffects.scoreOilIgnitionRadius==64 and
    moleEffects.scoreOilDuration==12 and moleEffects.scoreOilBurnDuration==6 and moleEffects.scoreOilDamage==5 and
    math.abs(moleEffects.scoreGrayCatChance-.6)<1e-9 and math.abs(moleEffects.scoreGrayCatDelay-1.35)<1e-9 and
    math.abs(moleEffects.scoreGrayCatSpeed-.8)<1e-9 and moleEffects.scoreGrayCatExitSpeed==1,
    "split oil drum and gray cat upgrades did not accumulate")
local roundTrip=CharacterTraits.decode(CharacterTraits.encode(store.data))
assert(roundTrip.regenTier==3,"persistent regeneration tier did not survive save encoding")
local migrated=CharacterTraits.decode("fire_score_filter=6\nfire_score_lighter=6\nfire_score_ash=6\nfire_score_drag=6\nfire_score_heat=6\n")
assert(migrated.levels.fire_score_filter==6 and migrated.levels.fire_score_heat==6 and migrated.levels.fire_score_spark==0 and migrated.levels.fire_score_stock==0,
    "legacy score research ranks were not preserved as granular traits")
local migratedMole=CharacterTraits.decode("universal_mole_companion=6\n")
assert(migratedMole.levels.universal_mole_companion==1 and migratedMole.levels.universal_mole_damage==3 and
    migratedMole.levels.universal_mole_claw==2 and migratedMole.levels.universal_mole_dual==1 and
    migratedMole.levels.universal_mole_extra==1,"legacy six-rank mole purchase was not migrated into the split graph")
local migratedGrowth=CharacterTraits.decode("universal_yard=7\nuniversal_stride=4\n")
for _,id in ipairs({"universal_yard","fire_score_yard_2","universal_yard_3","fire_score_yard_4",
    "universal_yard_5","fire_score_yard_6","fire_score_yard_7"})do
    assert(migratedGrowth.levels[id]==1,"legacy yard rank was not migrated into split nodes: "..id)
end
for _,id in ipairs({"universal_stride","fire_score_stride_2","universal_stride_3","fire_score_stride_4"})do
    assert(migratedGrowth.levels[id]==1,"legacy movement rank was not migrated into split nodes: "..id)
end
local migratedFlame=CharacterTraits.decode("fire_score_flame_damage=5\nfire_score_flame_range=5\nfire_score_flame_width=4\nfire_score_flame_ignite=4\n")
for _,baseAndMax in ipairs({{"fire_score_flame_damage",5},{"fire_score_flame_range",5},{"fire_score_flame_width",4},{"fire_score_flame_ignite",4}})do
    for rank=1,baseAndMax[2]do
        local id=baseAndMax[1]..(rank==1 and ""or"_"..rank)
        assert(migratedFlame.levels[id]==1,"legacy flamethrower rank was not migrated into split nodes: "..id)
    end
end
store.data.currency = 300
local blocked = store:buy("physical_axe")
assert(not blocked, "dependent character trait unlocked before its prerequisite")
assert(store:buy("physical_quota"), "first character trait purchase failed")
assert(store:buy("physical_axe"), "dependent character trait purchase failed")
local physical = store:effects("physical")
local smoker = store:effects("fire")
assert(physical.attackSpeed > 1 and physical.range == 14, "logger traits did not produce runtime effects")
assert(smoker.attackSpeed == 1 and smoker.range == 0, "logger traits leaked into another character")
for _,id in ipairs({"universal_yard","fire_score_yard_2","universal_yard_3","fire_score_yard_4",
    "universal_yard_5","fire_score_yard_6","fire_score_yard_7"})do store.data.levels[id]=1 end
for _,id in ipairs({"fire_score_capacity_4","universal_capacity_5","fire_score_capacity_6",
    "universal_capacity_7","fire_score_capacity_8","universal_capacity_9"})do store.data.levels[id]=1 end
store.data.levels.universal_veteran_yard=4
for _,id in ipairs({"universal_stride","fire_score_stride_2","universal_stride_3","fire_score_stride_4"})do store.data.levels[id]=1 end
for _,id in ipairs({"fire_score_view_1","universal_view_2","fire_score_view_3","universal_view_4"})do store.data.levels[id]=1 end
store.data.levels.universal_robot_start=1
store.data.levels.universal_robot_motor=5
store.data.levels.universal_oil_drum=1
store.data.levels.universal_gray_cat=1
store.data.levels.universal_oil_interval=3;store.data.levels.universal_oil_radius=5
store.data.levels.universal_oil_splash_count=4;store.data.levels.universal_oil_patch_scale=4
store.data.levels.universal_oil_radius_2=4;store.data.levels.universal_oil_radius_3=3
store.data.levels.universal_oil_splash_count_2=4
store.data.levels.universal_oil_ignition_radius=4;store.data.levels.universal_oil_duration=4
store.data.levels.universal_oil_burn_duration=4;store.data.levels.universal_oil_damage=5
store.data.levels.universal_gray_cat_chance=3;store.data.levels.universal_gray_cat_delay=3
store.data.levels.universal_gray_cat_speed=4;store.data.levels.universal_gray_cat_exit_speed=4
store.data.levels.universal_mole_companion=1
store.data.levels.universal_mole_damage=3;store.data.levels.universal_mole_speed=3
store.data.levels.universal_mole_attack_speed=3;store.data.levels.universal_mole_claw=2
store.data.levels.universal_mole_dual=1;store.data.levels.universal_mole_extra=2
store.data.levels.universal_mole_burrow=1;store.data.levels.universal_mole_burrow_speed=3
store.data.levels.universal_mole_burrow_damage=3;store.data.levels.universal_mole_burrow_cooldown=3
local splitGrowth=store:scoreAttackEffects()
assert(splitGrowth.scoreYardExpansion==7,"split logging-yard expansion did not reach seven nodes")
assert(splitGrowth.scoreTreeAllowance==60,"forest-capacity research did not reach the 100-tree runtime target")
local allowanceCost=0
for _,id in ipairs({"universal_yard","fire_score_yard_2","universal_yard_3","fire_score_yard_4",
    "universal_yard_5","fire_score_yard_6","fire_score_yard_7","universal_veteran_yard",
    "fire_score_capacity_4","universal_capacity_5","fire_score_capacity_6","universal_capacity_7",
    "fire_score_capacity_8","universal_capacity_9"})do
    local node=store:getNode(id);for _,cost in ipairs(node.costs)do allowanceCost=allowanceCost+cost end
end
assert(allowanceCost==100258,"forest-capacity research base cost drifted away from about 100,000 coins")
assert(math.abs(splitGrowth.moveSpeed-1.24)<1e-9,"split movement upgrades did not preserve +24% total speed")
assert(math.abs(splitGrowth.scoreViewExpansion-.10)<1e-9,"split camera-view upgrades did not reach +10% total view")
for _,id in ipairs({"universal_stride","fire_score_stride_2","universal_stride_3","fire_score_stride_4",
    "fire_score_view_1","universal_view_2","fire_score_view_3","universal_view_4",
    "universal_yard","fire_score_yard_2","universal_yard_3","fire_score_yard_4",
    "universal_yard_5","fire_score_yard_6","fire_score_yard_7"})do
    assert(store:getNode(id).max==1,id.." merged distributed progression back into a multi-rank node")
end
for _,id in ipairs({"fire_score_prewarm","fire_score_filter","fire_score_lighter","fire_score_spark","fire_score_launch","fire_score_ash","fire_score_drag","fire_score_heat"})do store.data.levels[id]=5 end
store.data.levels.fire_score_stock=1
local scoreSmoker=store:effects("fire")
assert(scoreSmoker.scoreRange==80 and scoreSmoker.scoreArea==60,"score-mode permanent smoker geometry was not subdivided correctly")
-- 확산은 런타임이 기준 연소시간 3.6초를 곱해 "옮겨붙는 기대 그루 수"로 쓴다.
-- 5레벨 .235 → 만렙(6) .282, 즉 (.12+.282)*3.6 = 1.45그루로 임계점 1.00을 넘긴다.
assert(math.abs(scoreSmoker.scoreIgnitionChance-.06)<1e-9 and math.abs(scoreSmoker.scoreSpreadChance-.235)<1e-9,"score-mode ignition traits were not separated")
assert(math.abs(scoreSmoker.scoreAttackSpeed-.20)<1e-9 and math.abs(scoreSmoker.scoreProjectileSpeed-.35)<1e-9 and math.abs(scoreSmoker.scoreBurnSpeed-.30)<1e-9 and scoreSmoker.scoreExtraFires==1,"score-mode permanent smoker pacing was not subdivided correctly")
local earlySmoking=CharacterTraits.new(true)
earlySmoking.data.currency=50000
assert(earlySmoking:buy("fire_score_prewarm"),"smoker root purchase failed")
assert(earlySmoking:getNode("fire_score_dash_unlock").desc:find("SPACE",1,true)==nil,
    "locked dash node reveals the control before purchase")
assert(earlySmoking:getNode("fire_score_alwayssmoke").costs[1]==70,
    "always-smoking node cost is not 70 research coins")
assert(earlySmoking:getNode("fire_score_impact")==nil,"removed cigarette-impact research remains on the board")
assert(earlySmoking:buy("fire_score_alwayssmoke"),"always-smoking node is not purchasable directly after the root")
assert(earlySmoking:scoreAttackEffects().scoreAlwaysSmoking==1,"early always-smoking purchase did not reach score runtime effects")
assert(earlySmoking:buy("fire_score_dash_unlock"),"dash unlock is not purchasable beside always-smoking")
assert(earlySmoking:scoreAttackEffects().scoreDashUnlock==1,"dash purchase did not reach score runtime effects")
assert(not earlySmoking:buy("fire_score_dash_distance"),"dash-distance node unlocked before the fifth-step rocket gate")
earlySmoking.data.levels.fire_score_rocket_unlock=1
assert(earlySmoking:buy("fire_score_dash_distance")and earlySmoking:scoreAttackEffects().scoreDashDistance==130,
    "fifth-step dash-distance node was not purchasable or did not reach runtime effects")
local activeScore=store:scoreAttackEffects()
assert(activeScore.scoreInitialIgnitionReduction==.4,"score-mode opening ignition trait is not active")
assert(activeScore.scoreStartingBabyRobot==1 and activeScore.scoreRobotSpeed==.5,"score-mode baby robot permanent research is not active")
assert(activeScore.scoreMoleCompanion==1 and activeScore.scoreMoleDamage==3 and activeScore.scoreMoleExtraCompanions==2 and
    activeScore.scoreMoleBurrow==1 and activeScore.scoreMoleBurrowDamage==6,
    "split score-mode mole companion upgrades are not active")
assert(activeScore.scoreOilDrum==1 and activeScore.scoreOilIgnitionRadius==64 and activeScore.scoreOilBurnDuration==6 and activeScore.scoreGrayCat==1,
    "oil drum ignition upgrades or gray oil-cat permanent research are not active")
local linkedOilMode=ClearcutMode.new()
linkedOilMode.scoreAttack=true
linkedOilMode.permanentTraits=activeScore
linkedOilMode.smokerGroundTime=0
local linkedDrum={id=77,x=400,y=300,state="settled",hp=8,maxHp=8,angle=0}
assert(linkedOilMode:spillOilDrum(linkedDrum,"axe"),"lobby oil research did not reach the runtime spill path")
local linkedGroup=assert(linkedOilMode.oilPuddleGroups.drum_77,"runtime did not register the lobby-upgraded oil group")
local linkedSpill=assert(linkedOilMode.oilDrumSpills[1],"runtime did not create the lobby-upgraded visible oil spill")
assert(linkedGroup.radius==770 and #linkedOilMode.oilTrail==48 and linkedOilMode.oilTrail[1].visualScale>=.95,
    "lobby oil range/count/patch ranks did not enlarge the generated stain geometry")
assert(linkedSpill.lifetime==32 and linkedGroup.damage==6 and linkedOilMode.oilTrail[1].damage==9,
    "lobby oil duration or damage ranks did not reach the runtime puddle")
assert(activeScore.scoreStartingWood==nil and activeScore.scoreAutomationDiscount==nil,"removed score automation traits still affect runtime")

-- 담배 탄약 관리 갈래. 이 세 노드는 startSmoking에 상수로 박혀 있던 세 벽
-- (개비 재장전 하한 0.75초, 보루 재장전 하한 2.4초, 보루 크기 20개비)을 각각 연다.
-- 하한에도 배수를 걸지 않으면 2~3단계부터 노드가 아무 일도 하지 않으므로,
-- 여기서는 "하한에 걸린 상태"를 일부러 만들어 그 하한이 실제로 내려가는지 본다.
local ammoStore=CharacterTraits.new(true)
ammoStore.data.currency=400000
assert(ammoStore:buy("fire_score_prewarm"),"smoker root purchase failed for the ammo branch")
for _=1,5 do assert(ammoStore:buy("fire_score_reload"),"butt reload rank purchase failed") end
for _=1,5 do assert(ammoStore:buy("fire_score_carton_size"),"carton size rank purchase failed") end
for _=1,4 do assert(ammoStore:buy("fire_score_carton_reload"),"carton reload rank purchase failed") end
local ammo=ammoStore:scoreAttackEffects()
assert(math.abs(ammo.scoreReloadSpeed-.40)<1e-9 and ammo.scoreCartonSize==30 and math.abs(ammo.scoreCartonReload-.48)<1e-9,
    "cigarette ammo research did not reach score runtime effects")

local ammoMode=ClearcutMode.new()
ammoMode.scoreAttack=true
ammoMode.permanentTraits=ammo
ammoMode.permanentTraits.attackSpeed=1
local ammoGame={tools={axe={speed=1}},player={gather=1,setClearcutAction=function()end,clearClearcutAction=function()end}}
ammoMode.cartonAmmo=nil
-- 루트(`최초 흡연 준비시간 감소`)의 일회성 개시 보너스는 첫 흡연에만 붙는다.
-- 여기서는 정상 상태의 재장전 길이를 재야 하므로 그 일회성 분기를 미리 소진시킨다.
ammoMode.scoreInitialSmokingStarted=true
ammoMode:startSmoking(ammoGame)
-- 보루 크기: 기본 20 + 6*5 = 50개비. 긴 재장전이 2.5배 드물어진다.
assert(ammoMode.cartonSize==50 and ammoMode.cartonAmmo==50,"carton size research did not enlarge the runtime magazine")
-- 개비 재장전: 1.25/1.40 = 0.893초. 하한 .75/1.40 = 0.536초보다 크므로 나눗셈 쪽이 이긴다.
assert(math.abs(ammoMode.smoking.dur-1.25/1.4)<1e-9,"butt reload research did not shorten the runtime reload")
-- 공격속도를 크게 올려 하한에 걸리게 만든다. 하한에도 배수가 걸려야 0.75가 아니라 0.536이 나온다.
ammoMode.permanentTraits.attackSpeed=8
ammoMode:startSmoking(ammoGame)
assert(math.abs(ammoMode.smoking.dur-.75/1.4)<1e-9,"butt reload research did not lower the reload floor")
-- 보루 교체: 탄약을 다 쓴 상태. 하한 2.4/1.48 = 1.622초.
ammoMode.cartonAmmo=0
ammoMode:startSmoking(ammoGame)
assert(ammoMode.smoking.newCarton and math.abs(ammoMode.smoking.dur-2.4/1.48)<1e-9,
    "carton reload research did not lower the long-reload floor")

-- 자동 투척 주기. 손이 도끼·폭죽으로 넘어간 뒤의 담배 화력은 오직 이 간격으로만 자란다.
local throwStore=CharacterTraits.new(true)
throwStore.data.currency=400000
throwStore.data.levels.fire_score_prewarm=throwStore:getNode("fire_score_prewarm").max
throwStore.data.levels.fire_score_alwayssmoke=1
throwStore.data.levels.fire_score_autothrow=1
throwStore.data.levels.fire_score_filter=throwStore:getNode("fire_score_filter").max
throwStore.data.levels.fire_score_spark=throwStore:getNode("fire_score_spark").max
for _=1,4 do
    local bought,reason=throwStore:buy("fire_score_autothrow_rate")
    assert(bought,"auto-throw rate rank purchase failed: "..tostring(reason))
end
local throwEffects=throwStore:scoreAttackEffects()
assert(math.abs(throwEffects.scoreAutoThrowRate-.36)<1e-9,"auto-throw rate research did not reach score runtime effects")
assert(math.abs(2.6/(1+throwEffects.scoreAutoThrowRate)-2.6/1.36)<1e-9,"auto-throw interval formula drifted from the runtime")

-- 추가 꽁초는 자동 투척에도 그대로 실린다. 1단계에서 멈춰 있던 상한을 2단계로 연다.
assert(store:getNode("fire_score_stock").max==2,"extra-butt research is still capped at a single rank")

-- 무기 졸업 사슬. 도끼 -> 폭죽 -> 화염방사기 순으로 손이 넘어가고, 넘긴 무기는
-- 졸업 원숭이가 이어받는다. 손에 드는 무기는 항상 마지막 해금 하나뿐이어야 한다.
local gradStore=CharacterTraits.new(true)
local gradMode=ClearcutMode.new()
gradMode.scoreAttack=true
gradMode.permanentTraits=gradStore:scoreAttackEffects()
assert(gradMode:scoreRangedWeaponId()=="cigarette","score mode did not start on the cigarette")
gradMode.permanentTraits.scoreRocketUnlock=1
assert(gradMode:scoreRangedWeaponId()=="firework","rocket unlock did not take over the ranged hand")
gradMode.permanentTraits.scoreFlameUnlock=1
assert(gradMode:scoreRangedWeaponId()=="flamethrower","flamethrower unlock did not take over the ranged hand")

-- 폭죽 원숭이는 폭죽 갈래 수치를 물려받아야 한다. 도끼 갈래 수치를 그대로 쓰면
-- 사거리 104짜리 근접 원숭이가 폭죽을 들고 서 있게 된다.
local crewMode=ClearcutMode.new()
crewMode.scoreAttack=true
crewMode.permanentTraits=gradStore:scoreAttackEffects()
crewMode.permanentTraits.scoreAxeCrew=1
crewMode.permanentTraits.scoreRocketCrew=1
crewMode.permanentTraits.scoreRocketDamage=4
crewMode.savedMonkeyWeapons={}
if (crewMode.permanentTraits.scoreAxeCrew or 0)>0 then crewMode.savedMonkeyWeapons[#crewMode.savedMonkeyWeapons+1]="axe" end
if (crewMode.permanentTraits.scoreRocketCrew or 0)>0 then crewMode.savedMonkeyWeapons[#crewMode.savedMonkeyWeapons+1]="firework" end
assert(crewMode.savedMonkeyWeapons[1]=="axe" and crewMode.savedMonkeyWeapons[2]=="firework",
    "graduating both weapons did not hand them to two separate monkeys")
local fireworkMonkey={kind="lumberjack",prop="firework"}
crewMode:configureGraduateMonkeyWeapon(fireworkMonkey)
local axeMonkey={kind="lumberjack",prop="axe"}
crewMode:configureGraduateMonkeyWeapon(axeMonkey)
assert(fireworkMonkey.attackReach>axeMonkey.attackReach and fireworkMonkey.damage==6,
    "firework monkey did not inherit the rocket branch numbers")

-- 화염방사기는 멀어질수록 벌어지는 부채꼴이 아니라 폭이 일정한 전방 기둥이다.
local stream=ClearcutMode.flameStreamCovers
assert(stream(0,0,1,0,250,72,200,0),"flame stream missed its center line")
assert(stream(0,0,1,0,250,72,200,70),"flame stream missed its authored edge")
assert(not stream(0,0,1,0,250,72,300,0),"flame stream reached past its range")
assert(not stream(0,0,1,0,250,72,-20,0),"flame stream burned behind the nozzle")
assert(not stream(0,0,1,0,250,72,200,90),"flame stream widened like a cone")
assert(stream(0,0,1,0,250,128,200,118),"thickness research did not widen the column")

-- 점화가 한 번도 성공하지 않아도 직접 피해는 매 틱 독립적으로 들어가야 한다.
-- 점화 확률 0으로 이걸 확인한다. (예전에는 rainSuppressFire 로 점화를 껐는데,
-- 이제 비는 화염방사기를 통째로 멎게 하므로 그 수단은 쓸 수 없다 —
-- 비 중 화염 차단은 verify_score_rain.lua 가 본다.)
local flameMode=ClearcutMode.new();flameMode.scoreAttack=true;flameMode.flameVisualStyle="torch"
flameMode.permanentTraits.scoreFlameUnlock=1;flameMode.permanentTraits.scoreFlameIgnite=-99
local flameTree={rushTree=true,active=true,x=120,y=-30,rushHp=100,rushMaxHp=100,burning=false}
local flameTree2={rushTree=true,active=true,x=220,y=0,rushHp=100,rushMaxHp=100,burning=false}
local flameWorld={nodes={flameTree,flameTree2}}
function flameWorld:impactNode()end
local flamePlayer={x=0,y=0,facing=1,gather=1}
function flamePlayer:setClearcutAction(value)self.clearcutActionProgress=value end
function flamePlayer:clearClearcutAction()self.clearcutActionProgress=nil end
local flameGame={player=flamePlayer,world=flameWorld,tools={axe={speed=1}},camera={screenToWorld=function()return 300,0 end}}
assert(flameMode:updateFlamethrowerAttack(.13,flameGame,true),"first continuous flame tick missed")
assert(flameTree.flameTorchImpactAt~=nil and flameTree2.flameTorchImpactAt~=nil,
    "torch impact was not attached independently to every damaged tree")
local afterFirstTick=flameTree.rushHp
assert(flameMode:updateFlamethrowerAttack(.13,flameGame,true),"second continuous flame tick missed")
assert(flameTree.rushHp<afterFirstTick and not flameTree.burning,
    "direct flame damage stopped when ignition was unavailable")

-- 반면 비가 오면 직접 피해까지 함께 멎는다. 화염방사기는 전부가 화염이다.
flameMode.rainSuppressFire=true
local beforeRain=flameTree.rushHp
assert(flameMode:updateFlamethrowerAttack(.13,flameGame,true)==false,"비가 오는데 화염방사기가 판정을 냈다")
assert(flameTree.rushHp==beforeRain,"비가 오는데 화염방사기 직접 피해가 들어갔다")
assert(flameMode.flameStream==nil,"비가 오는데 화염 기둥이 남아 있다")
-- 불 갈래 33 = 담배 9 + 탄약 관리 3(개비 재장전·보루 용량·보루 교체) + 공용 나무 피해 1
-- + 도끼 4 + 도끼 상위 3(충격파·연속 벌목·나무꾼 고용) + 후반 해금 3(상시 흡연·자동 투척·폭죽)
-- + 자동 투척 주기 1 + 폭죽 5. 탄약 관리 갈래는 startSmoking의 세 상수(개비 재장전 하한,
-- 보루 재장전 하한, 보루 크기 20)를 각각 여는 노드이며 폭죽 시각 특성 3개가 추가된다.
-- 이동·시야·작업 구역과 화염방사기 강화 단계는 한 노드의 다단계가 아니라 기존 장비
-- 갈래 사이에 놓인 별도 1레벨 노드다. 대시 해금·거리 2개, 초·후반 목재 흡수 범위 2개와 뻥튀기 9개,
-- 꽁초 즉시 타격을 기본 동작으로 옮겨 fire 78이고, universal은 기존 59를 유지한다.
assert(#store:getScoreAttackNodes("fire")==78 and #store:getScoreAttackNodes("universal")==59,
    "active research board did not expose the distributed one-rank nodes")
local pickupStore=CharacterTraits.new(true)
pickupStore.data.levels.fire_score_pickup_1=3
pickupStore.data.levels.fire_score_pickup_2=3
assert(pickupStore:scoreAttackEffects().pickupRadius==405,
    "early and late wood pull-range nodes did not accumulate into score runtime pickup radius")
local rocketNodeCount,rocketRanks,rocketCost=0,0,0
local flameNodeCount,flameCost,flameRange=0,0,0
for _,node in ipairs(store:getScoreAttackNodes("fire"))do
    if node.id:match("^fire_score_rocket")then
        rocketNodeCount=rocketNodeCount+1;rocketRanks=rocketRanks+node.max
        for _,cost in ipairs(node.costs)do rocketCost=rocketCost+cost end
    end
    if node.id:match("^fire_score_flame_damage")or node.id:match("^fire_score_flame_range")or
        node.id:match("^fire_score_flame_width")or node.id:match("^fire_score_flame_ignite")then
        flameNodeCount=flameNodeCount+1;flameCost=flameCost+node.costs[1]
        if node.effect=="scoreFlameRange"then flameRange=flameRange+node.value end
        assert(node.max==1 and #node.costs==1,"flamethrower upgrade still contains stacked ranks: "..node.id)
    end
end
assert(rocketNodeCount==10 and rocketRanks==29 and rocketCost==59000,
    "firework stage pricing changed its node count, rank count, or total cost")
assert(store:getNode("fire_score_rocket_unlock").targetTier==5 and
    store:getNode("fire_score_rocket_finale").targetTier==7 and
    store:getNode("fire_score_rocket_crew").targetTier==7,
    "firework progression is not documented across regeneration tiers 5-7")
assert(flameNodeCount==18 and flameCost==784000,"flamethrower split changed its rank count or total cost")
assert(store:getNode("fire_score_flame_unlock").targetTier==8 and
    store:getNode("fire_score_flame_damage_5").targetTier==10,
    "flamethrower progression is not documented from regeneration tier 8 onward")
assert(flameRange==250,"maxed flamethrower research does not extend reach from 250 to 500")
local popperUnlock=store:getNode("fire_score_popper_unlock")
assert(#popperUnlock.requires==1 and popperUnlock.requires[1][1]=="universal_mole_dual" and popperUnlock.requires[1][2]==1,
    "monkey popping cart is not attached directly below the mole branch")
for _, job in ipairs({"physical","fire","toxic","developer"}) do
    assert(#store:getNodes(job) >= 30, job .. " character graph has too few trait nodes")
end

local encoded = CharacterTraits.encode(store.data)
local decoded = CharacterTraits.decode(encoded)
assert(decoded.currency == store.data.currency and decoded.levels.physical_quota == 1 and decoded.levels.physical_axe == 1, "character trait save roundtrip failed")

local mode = ClearcutMode.new()
mode.job, mode.treesFelled, mode.kills, mode.level = "physical", 100, 4, 8
mode.permanentTraits = physical
local before = store.data.currency
local game = {characterTraits=store, result=nil}
mode:finish(game, true)
assert(game.mode == "clearcut_results" and game.result.traitEarned > 0, "run did not award character trait currency")
assert(store.data.currency == before + game.result.traitEarned, "awarded character trait currency was not stored")
local after = store.data.currency
mode:finish(game, true)
assert(store.data.currency == after, "character trait currency was awarded twice for one run")

local fonts={small=font,body=font,heading=font,big=font,title=font}
local visualLobby=setmetatable({fonts=fonts,labelFont=font,displayFont=font,background={getDimensions=function() return 1600,900 end},time=0,scoreAttackHover=0,traitsHover=0},Lobby)
assert(pcall(visualLobby.draw,visualLobby), "clearcut-only lobby draw contract failed")
-- 진행 상황판은 저장 데이터를 읽는다. 데이터가 없어도 그려져야 하고, 있으면 표시돼야 한다.
local Achievements = require("src.achievements")
local progressTraits = CharacterTraits.new(true); progressTraits.data.currency = 1240
progressTraits:unlockRegenTier(8)
local progressAchievements = Achievements.new(true)
progressAchievements:recordRun({scoreAttack=true,trees=412,maxChain=9,stage=1,highestRegenTier=8,lumberCoinTotal=980})
local goal = progressTraits:nextGoal()
assert(goal and goal.name and goal.cost, "다음 연구 목표를 계산하지 못한다")
assert(goal.affordable, "1240 코인으로 살 수 있는 노드가 있는데 못 산다고 나온다")
local broke = CharacterTraits.new(true); broke.data.currency = 0
local brokeGoal = broke:nextGoal()
assert(brokeGoal and not brokeGoal.affordable, "코인이 0인데 구매 가능으로 표시된다")
for _, id in ipairs({"universal_veteran_yard","universal_veteran_crew","universal_wildfire"}) do
    assert(brokeGoal.id ~= id, "재생 단계 게이트 노드가 1단계에서 다음 목표로 제시된다")
end
local okDraw, drawErr = pcall(visualLobby.draw, visualLobby,
    {characterTraits=progressTraits, achievements=progressAchievements})
assert(okDraw, "진행 상황판이 있는 로비 그리기가 실패한다: " .. tostring(drawErr))
local sprites={physical={image=image},fire={image=image},toxic={image=image},developer={image=image}}
store.data.levels.fire_score_prewarm=0
local board=CharacterTraitBoard.new(store,fonts,sprites)
assert(pcall(board.draw,board), "character trait board draw contract failed")
assert(board.researchBackground==nil,"research board restored the removed forest-photo backdrop")
local molePositions={};local minMoleY,maxMoleY=math.huge,-math.huge
for _,id in ipairs({"universal_mole_companion","universal_mole_damage","universal_mole_speed","universal_mole_attack_speed",
    "universal_mole_claw","universal_mole_dual","universal_mole_extra","universal_mole_burrow",
    "universal_mole_burrow_speed","universal_mole_burrow_damage","universal_mole_burrow_cooldown"})do
    local mx,my=board:nodeWorld(store:getNode(id));local key=mx..":"..my
    assert(not molePositions[key],"split mole research nodes overlap at "..key);molePositions[key]=true
    minMoleY,maxMoleY=math.min(minMoleY,my),math.max(maxMoleY,my)
end
assert(maxMoleY-minMoleY>=700,"mole research graph is still compressed into one non-scrollable node cluster")
local oilX,oilY=board:nodeWorld(store:getNode("universal_oil_drum"))
local catX,catY=board:nodeWorld(store:getNode("universal_gray_cat"))
local oilCatDistance=math.sqrt((oilX-catX)^2+(oilY-catY)^2)
assert(oilY<catY and oilCatDistance>=500 and oilCatDistance<=750,
    "oil drum root is not visibly separated above its connected gray-cat branch")
local chanceX,chanceY=board:nodeWorld(store:getNode("universal_gray_cat_chance"))
local delayX,delayY=board:nodeWorld(store:getNode("universal_gray_cat_delay"))
local speedX,speedY=board:nodeWorld(store:getNode("universal_gray_cat_speed"))
local exitX,exitY=board:nodeWorld(store:getNode("universal_gray_cat_exit_speed"))
local function catDistance(ax,ay,bx,by)return math.sqrt((ax-bx)^2+(ay-by)^2)end
assert(catDistance(catX,catY,chanceX,chanceY)<=320,
    "gray cat chance upgrade is not attached to the cat unlock")
assert(catDistance(chanceX,chanceY,delayX,delayY)<=320,
    "gray cat delay upgrade is not the next node in the cat branch")
assert(catDistance(catX,catY,speedX,speedY)<=430,
    "gray cat speed upgrade is not visibly grouped with the cat unlock")
local exitNode=store:getNode("universal_gray_cat_exit_speed")
assert(exitNode.requires[1][1]=="universal_gray_cat_speed"and not(speedX==exitX and speedY==exitY),
    "gray cat exit-speed upgrade is not a distinct child of the entry-speed node")
assert(not(chanceX==delayX and chanceY==delayY)and not(chanceX==speedX and chanceY==speedY),
    "gray cat upgrades overlap instead of forming visible branches")
local oilIds={"universal_oil_drum","universal_oil_interval","universal_oil_radius","universal_oil_splash_count",
    "universal_oil_patch_scale","universal_oil_radius_2","universal_oil_radius_3","universal_oil_splash_count_2",
    "universal_oil_ignition_radius","universal_oil_duration","universal_oil_damage","universal_oil_burn_duration"}
local oilPositions={}
for _,id in ipairs(oilIds)do
    local ox,oy=board:nodeWorld(store:getNode(id));oilPositions[id]={x=ox,y=oy}
end
assert(oilPositions.universal_oil_drum.y<catY and oilPositions.universal_oil_interval.y<oilPositions.universal_oil_drum.y,
    "oil drum research branch was not moved above the cat and facility cluster")
for i=1,#oilIds do for j=i+1,#oilIds do
    local a,b=oilPositions[oilIds[i]],oilPositions[oilIds[j]]
    local dx,dy=a.x-b.x,a.y-b.y
    assert(dx*dx+dy*dy>=300*300,"oil drum research nodes are still packed too closely: "..oilIds[i].." / "..oilIds[j])
end end
local root=store:getNode("fire_score_prewarm")
local rx,ry=board:nodeWorld(root)
assert(store:getNode("fire_score_impact")==nil,"removed cigarette-impact research still has a board position")
local directions={left=false,right=false,up=false,down=false}
for _,id in ipairs({"fire_score_filter","fire_score_lighter","fire_score_launch","fire_score_alwayssmoke"})do
    local nx,ny=board:nodeWorld(store:getNode(id));local dx,dy=nx-rx,ny-ry
    if math.abs(dx)>math.abs(dy)then directions[dx<0 and"left"or"right"]=true else directions[dy<0 and"up"or"down"]=true end
end
assert(directions.left and directions.right and directions.up and directions.down,"smoker root does not place always-smoking as its downward second node")
for i=1,#board.nodeBoxes do for j=i+1,#board.nodeBoxes do
    local a,b=board.nodeBoxes[i],board.nodeBoxes[j]
    local separated=a.x+a.w<=b.x or b.x+b.w<=a.x or a.y+a.h<=b.y or b.y+b.h<=a.y
    assert(separated,"research nodes overlap at 1280x720: "..a.id.." / "..b.id)
end end
assert(board.viewInitialized and board.zoom==board.referenceZoom and board.referenceZoom>=.56 and board.referenceZoom<=.80,"research tree did not open at its authored reference spacing")
local function distance(a,b)local ax,ay=board:nodeWorld(store:getNode(a));local bx,by=board:nodeWorld(store:getNode(b));return math.sqrt((ax-bx)^2+(ay-by)^2)end
assert(distance("fire_score_prewarm","fire_score_filter")==distance("fire_score_filter","fire_score_spark"),"left branch step lengths differ")
assert(distance("fire_score_prewarm","fire_score_lighter")==distance("fire_score_lighter","fire_score_ash"),"right branch step lengths differ")
assert(distance("fire_score_prewarm","fire_score_launch")==distance("fire_score_launch","fire_score_drag"),"upper branch step lengths differ")
assert(distance("fire_score_prewarm","fire_score_alwayssmoke")==distance("fire_score_alwayssmoke","fire_score_autothrow"),"always-smoking branch step lengths differ")
store.data.currency=1000
local rootBox
for _,box in ipairs(board.nodeBoxes)do
    local purchasable=store:status(box.id)
    if purchasable and box.cx>=board.viewport.x and box.cx<=board.viewport.x+board.viewport.w and box.cy>=board.viewport.y and box.cy<=board.viewport.y+board.viewport.h then rootBox=box;break end
end
rootBox=assert(rootBox,"no visible purchasable trait node found")
mouseX,mouseY,mouseDown=rootBox.cx,rootBox.cy,true
assert(board:mousepressed(mouseX,mouseY,1)=="dragging", "graph did not enter pointer interaction")
board:update(.016); mouseDown=false; board:update(.016)
assert(board.selectedNodeId==rootBox.id and board:buySelected()=="bought", "selected trait node was not purchased")
assert(board.unlockFx and #board.particles>=30, "graph unlock effect did not spawn")
local oldPan=board.panY
board:wheelmoved(0,1)
mouseX,mouseY,mouseDown=board.viewport.x+board.viewport.w/2,board.viewport.y+board.viewport.h/2,true
board:mousepressed(mouseX,mouseY,1)
mouseY=mouseY-100; board:update(.016)
assert(board.panY~=oldPan,"dragging did not pan the research canvas")
mouseDown=false; board:update(.016)
assert(math.abs(board.panVY)>0,"released research canvas has no inertial velocity")
local oldZoom=board.zoom
board:wheelmoved(0,1)
assert(board.zoom>oldZoom,"mouse wheel did not zoom the research canvas")
assert(board.zoom>=board.referenceZoom*.85 and board.zoom<=board.referenceZoom*1.15,"research canvas zoom escaped its spacing-preserving range")

-- 개발자 만렙은 현재 보이는 연구만이 아니라 등록된 캐릭터·공용 노드 전체를 채우고,
-- 코인·재생 단계·장비 상태는 그대로 둔 채 한 번만 저장해야 한다.
local maxStore=CharacterTraits.new(true)
maxStore.data.currency=4321;maxStore.data.regenTier=4
maxStore.data.equipmentConfigured=true;maxStore.data.playerWeapons={2,3}
local nodes,ranks=maxStore:maxAll()
local countedNodes,countedRanks=0,0
for _,group in pairs(maxStore:getJobs())do for _,node in ipairs(group.nodes)do
    countedNodes,countedRanks=countedNodes+1,countedRanks+node.max
    assert(maxStore:getLevel(node.id)==node.max,"developer max-all missed trait: "..node.id)
end end
assert(nodes==countedNodes and ranks==countedRanks,"developer max-all reported the wrong scope")
assert(maxStore.data.currency==4321 and maxStore:getRegenTier()==4
    and maxStore.data.equipmentConfigured and maxStore.data.playerWeapons[2]==3,
    "developer max-all changed currency, regen tier, or equipment state")

-- 10~100% 프리셋은 활성 기록 연구만 초기화해, 실제 가격이 싼 해금 가능
-- 단계부터 정확한 비율만큼 채운다. 보존된 일반 작전 특성 및 다른 저장 상태는 유지한다.
local presetStore=CharacterTraits.new(true)
presetStore.data.currency=4321;presetStore.data.regenTier=4
presetStore.data.levels.physical_quota=2
local previous={}
for percent=10,100,10 do
    local filled,total=presetStore:setScoreProgress(percent)
    assert(filled==math.floor(total*percent/100),"developer trait preset filled the wrong percentage")
    local counted=0
    for _,group in pairs(presetStore:getJobs())do for _,node in ipairs(group.nodes)do
        if node.scoreMode then
            local level=presetStore:getLevel(node.id);counted=counted+level
            assert(level>=(previous[node.id]or 0),"higher developer preset removed a selected research rank")
            if level>0 then for _,requirement in ipairs(presetStore:getRequirements(node))do
                assert(presetStore:getLevel(requirement[1])>=requirement[2],"developer trait preset broke a prerequisite: "..node.id)
            end end
            previous[node.id]=level
        end
    end end
    assert(counted==filled,"developer trait preset reported the wrong rank count")
end
assert(presetStore.data.levels.physical_quota==2 and presetStore.data.currency==4321 and presetStore:getRegenTier()==4,
    "developer trait preset changed legacy traits, currency, or regen tier")

print("CHARACTER_TRAITS_OK")
