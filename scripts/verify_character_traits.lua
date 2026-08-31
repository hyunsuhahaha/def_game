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

local store = CharacterTraits.new(true)
assert(store:getRegenTier()==1 and store:unlockRegenTier(3) and store:getRegenTier()==3 and not store:unlockRegenTier(2),"persistent regeneration tier did not advance monotonically")
local moleUpgradeStore=CharacterTraits.new(true)
moleUpgradeStore.data.currency=5000
moleUpgradeStore.data.levels.universal_robot_start=1
assert(moleUpgradeStore:buy("universal_mole_companion")and not moleUpgradeStore:buy("universal_mole_companion"),"mole hire root was not a one-rank node")
assert(moleUpgradeStore:buy("universal_oil_drum")and moleUpgradeStore:buy("universal_gray_cat"),"gray oil-cat research chain was not purchasable")
for _,spec in ipairs({{"universal_oil_interval",3},{"universal_oil_radius",3},{"universal_oil_ignition_radius",3},
    {"universal_oil_duration",3},{"universal_oil_burn_duration",3},{"universal_oil_damage",3},
    {"universal_gray_cat_chance",3},{"universal_gray_cat_delay",3},{"universal_gray_cat_speed",3}})do
    for rank=1,spec[2]do assert(moleUpgradeStore:buy(spec[1]),spec[1].." rank "..rank.." was not purchasable")end
end
for _,spec in ipairs({{"universal_mole_damage",3},{"universal_mole_speed",3},{"universal_mole_attack_speed",3},
    {"universal_mole_claw",2},{"universal_mole_dual",1},{"universal_mole_extra",2}})do
    for rank=1,spec[2]do assert(moleUpgradeStore:buy(spec[1]),spec[1].." rank "..rank.." was not purchasable")end
end
local moleEffects=moleUpgradeStore:scoreAttackEffects()
assert(moleEffects.scoreMoleCompanion==1 and moleEffects.scoreMoleDamage==3 and math.abs(moleEffects.scoreMoleSpeed-.30)<1e-9 and
    math.abs(moleEffects.scoreMoleAttackSpeed-.36)<1e-9 and moleEffects.scoreMoleClawTier==2 and moleEffects.scoreMoleDualClaw==1 and
    moleEffects.scoreMoleExtraCompanions==2,"split mole research nodes did not accumulate independently")
assert(moleEffects.scoreOilDrum==1 and moleEffects.scoreGrayCat==1,"gray oil-cat research effects were not accumulated")
assert(moleEffects.scoreOilDrumInterval==6 and moleEffects.scoreOilRadius==54 and moleEffects.scoreOilIgnitionRadius==42 and
    moleEffects.scoreOilDuration==9 and moleEffects.scoreOilBurnDuration==4.5 and moleEffects.scoreOilDamage==3 and
    math.abs(moleEffects.scoreGrayCatChance-.6)<1e-9 and math.abs(moleEffects.scoreGrayCatDelay-1.35)<1e-9 and
    math.abs(moleEffects.scoreGrayCatSpeed-.45)<1e-9,"split oil drum and gray cat upgrades did not accumulate")
local roundTrip=CharacterTraits.decode(CharacterTraits.encode(store.data))
assert(roundTrip.regenTier==3,"persistent regeneration tier did not survive save encoding")
local migrated=CharacterTraits.decode("fire_score_filter=6\nfire_score_lighter=6\nfire_score_ash=6\nfire_score_drag=6\nfire_score_heat=6\n")
assert(migrated.levels.fire_score_filter==6 and migrated.levels.fire_score_heat==6 and migrated.levels.fire_score_spark==0 and migrated.levels.fire_score_stock==0,
    "legacy score research ranks were not preserved as granular traits")
local migratedMole=CharacterTraits.decode("universal_mole_companion=6\n")
assert(migratedMole.levels.universal_mole_companion==1 and migratedMole.levels.universal_mole_damage==3 and
    migratedMole.levels.universal_mole_claw==2 and migratedMole.levels.universal_mole_dual==1 and
    migratedMole.levels.universal_mole_extra==1,"legacy six-rank mole purchase was not migrated into the split graph")
store.data.currency = 300
local blocked = store:buy("physical_axe")
assert(not blocked, "dependent character trait unlocked before its prerequisite")
assert(store:buy("physical_quota"), "first character trait purchase failed")
assert(store:buy("physical_axe"), "dependent character trait purchase failed")
local physical = store:effects("physical")
local smoker = store:effects("fire")
assert(physical.attackSpeed > 1 and physical.range == 14, "logger traits did not produce runtime effects")
assert(smoker.attackSpeed == 1 and smoker.range == 0, "logger traits leaked into another character")
store.data.levels.universal_yard=7
store.data.levels.universal_robot_start=1
store.data.levels.universal_robot_motor=5
store.data.levels.universal_oil_drum=1
store.data.levels.universal_gray_cat=1
store.data.levels.universal_oil_interval=3;store.data.levels.universal_oil_radius=3
store.data.levels.universal_oil_ignition_radius=3;store.data.levels.universal_oil_duration=3
store.data.levels.universal_oil_burn_duration=3;store.data.levels.universal_oil_damage=3
store.data.levels.universal_gray_cat_chance=3;store.data.levels.universal_gray_cat_delay=3;store.data.levels.universal_gray_cat_speed=3
store.data.levels.universal_mole_companion=1
store.data.levels.universal_mole_damage=3;store.data.levels.universal_mole_speed=3
store.data.levels.universal_mole_attack_speed=3;store.data.levels.universal_mole_claw=2
store.data.levels.universal_mole_dual=1;store.data.levels.universal_mole_extra=2
assert(store:effects("fire").scoreTreeAllowance==28,"permanent logging-yard capacity did not reach +28 trees at max rank")
for _,id in ipairs({"fire_score_prewarm","fire_score_filter","fire_score_lighter","fire_score_spark","fire_score_launch","fire_score_ash","fire_score_drag","fire_score_heat"})do store.data.levels[id]=5 end
store.data.levels.fire_score_stock=1
local scoreSmoker=store:effects("fire")
assert(scoreSmoker.scoreRange==80 and scoreSmoker.scoreArea==60,"score-mode permanent smoker geometry was not subdivided correctly")
-- 확산은 런타임이 기준 연소시간 3.6초를 곱해 "옮겨붙는 기대 그루 수"로 쓴다.
-- 5레벨 .235 → 만렙(6) .282, 즉 (.12+.282)*3.6 = 1.45그루로 임계점 1.00을 넘긴다.
assert(math.abs(scoreSmoker.scoreIgnitionChance-.06)<1e-9 and math.abs(scoreSmoker.scoreSpreadChance-.235)<1e-9,"score-mode ignition traits were not separated")
assert(math.abs(scoreSmoker.scoreAttackSpeed-.20)<1e-9 and math.abs(scoreSmoker.scoreProjectileSpeed-.35)<1e-9 and math.abs(scoreSmoker.scoreBurnSpeed-.30)<1e-9 and scoreSmoker.scoreExtraFires==1,"score-mode permanent smoker pacing was not subdivided correctly")
local earlySmoking=CharacterTraits.new(true)
earlySmoking.data.currency=500
assert(earlySmoking:buy("fire_score_prewarm"),"smoker root purchase failed")
assert(earlySmoking:buy("fire_score_impact"),"early cigarette-impact node is not purchasable directly after the root")
assert(earlySmoking:scoreAttackEffects().scoreCigaretteImpact==1,"early impact purchase did not reach score runtime effects")
assert(earlySmoking:buy("fire_score_alwayssmoke"),"always-smoking node is not purchasable directly after the root")
assert(earlySmoking:scoreAttackEffects().scoreAlwaysSmoking==1,"early always-smoking purchase did not reach score runtime effects")
local activeScore=store:scoreAttackEffects()
assert(activeScore.scoreInitialIgnitionReduction==.4,"score-mode opening ignition trait is not active")
assert(activeScore.scoreStartingBabyRobot==1 and activeScore.scoreRobotSpeed==.5,"score-mode baby robot permanent research is not active")
assert(activeScore.scoreMoleCompanion==1 and activeScore.scoreMoleDamage==3 and activeScore.scoreMoleExtraCompanions==2,
    "split score-mode mole companion upgrades are not active")
assert(activeScore.scoreOilDrum==1 and activeScore.scoreOilIgnitionRadius==42 and activeScore.scoreOilBurnDuration==4.5 and activeScore.scoreGrayCat==1,
    "oil drum ignition upgrades or gray oil-cat permanent research are not active")
local linkedOilMode=ClearcutMode.new()
linkedOilMode.scoreAttack=true
linkedOilMode.permanentTraits=activeScore
linkedOilMode.smokerGroundTime=0
local linkedDrum={id=77,x=400,y=300,state="settled",hp=8,maxHp=8,angle=0}
assert(linkedOilMode:spillOilDrum(linkedDrum,"axe"),"lobby oil research did not reach the runtime spill path")
local linkedGroup=assert(linkedOilMode.oilPuddleGroups.drum_77,"runtime did not register the lobby-upgraded oil group")
local linkedSpill=assert(linkedOilMode.oilDrumSpills[1],"runtime did not create the lobby-upgraded visible oil spill")
assert(linkedGroup.radius==194 and math.abs(linkedSpill.scale-194/105)<1e-9,
    "lobby oil-radius ranks did not enlarge both collision and visible spill geometry")
assert(linkedSpill.lifetime==29 and linkedGroup.damage==4 and linkedOilMode.oilTrail[1].damage==7,
    "lobby oil duration or damage ranks did not reach the runtime puddle")
assert(activeScore.scoreStartingWood==nil and activeScore.scoreAutomationDiscount==nil,"removed score automation traits still affect runtime")

-- 담배 탄약 관리 갈래. 이 세 노드는 startSmoking에 상수로 박혀 있던 세 벽
-- (개비 재장전 하한 0.75초, 보루 재장전 하한 2.4초, 보루 크기 20개비)을 각각 연다.
-- 하한에도 배수를 걸지 않으면 2~3단계부터 노드가 아무 일도 하지 않으므로,
-- 여기서는 "하한에 걸린 상태"를 일부러 만들어 그 하한이 실제로 내려가는지 본다.
local ammoStore=CharacterTraits.new(true)
ammoStore.data.currency=4000
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
throwStore.data.currency=4000
throwStore.data.levels.fire_score_prewarm=1
throwStore.data.levels.fire_score_alwayssmoke=1
throwStore.data.levels.fire_score_autothrow=1
for _=1,4 do assert(throwStore:buy("fire_score_autothrow_rate"),"auto-throw rate rank purchase failed") end
local throwEffects=throwStore:scoreAttackEffects()
assert(math.abs(throwEffects.scoreAutoThrowRate-.36)<1e-9,"auto-throw rate research did not reach score runtime effects")
assert(math.abs(2.6/(1+throwEffects.scoreAutoThrowRate)-2.6/1.36)<1e-9,"auto-throw interval formula drifted from the runtime")

-- 추가 꽁초는 자동 투척에도 그대로 실린다. 1단계에서 멈춰 있던 상한을 2단계로 연다.
assert(store:getNode("fire_score_stock").max==2,"extra-butt research is still capped at a single rank")
-- 불 갈래 33 = 기존 30개 + 폭죽 시각 특성 3개(쌍발·자탄·삼단 대단원).
-- + 도끼 4 + 도끼 상위 3(충격파·연속 벌목·나무꾼 고용) + 후반 해금 3(상시 흡연·자동 투척·폭죽)
-- + 자동 투척 주기 1 + 폭죽 5. 탄약 관리 갈래는 startSmoking의 세 상수(개비 재장전 하한,
-- 보루 재장전 하한, 보루 크기 20)를 각각 여는 노드다.
assert(#store:getScoreAttackNodes("fire")==33 and #store:getScoreAttackNodes("universal")==21,"active research board did not expose the split companion graphs and the weapon-slot branches")
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
local sprites={physical={image=image},fire={image=image},toxic={image=image},developer={image=image}}
store.data.levels.fire_score_prewarm=0
local board=CharacterTraitBoard.new(store,fonts,sprites)
assert(pcall(board.draw,board), "character trait board draw contract failed")
assert(board.researchBackground==nil,"research board restored the removed forest-photo backdrop")
local molePositions={};local minMoleY,maxMoleY=math.huge,-math.huge
for _,id in ipairs({"universal_mole_companion","universal_mole_damage","universal_mole_speed","universal_mole_attack_speed",
    "universal_mole_claw","universal_mole_dual","universal_mole_extra"})do
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
local function catDistance(ax,ay,bx,by)return math.sqrt((ax-bx)^2+(ay-by)^2)end
assert(catDistance(catX,catY,chanceX,chanceY)<=320,
    "gray cat chance upgrade is not attached to the cat unlock")
assert(catDistance(chanceX,chanceY,delayX,delayY)<=320,
    "gray cat delay upgrade is not the next node in the cat branch")
assert(catDistance(catX,catY,speedX,speedY)<=430,
    "gray cat speed upgrade is not visibly grouped with the cat unlock")
assert(not(chanceX==delayX and chanceY==delayY)and not(chanceX==speedX and chanceY==speedY),
    "gray cat upgrades overlap instead of forming visible branches")
local oilIds={"universal_oil_drum","universal_oil_interval","universal_oil_radius","universal_oil_ignition_radius",
    "universal_oil_duration","universal_oil_damage","universal_oil_burn_duration"}
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
local impact=store:getNode("fire_score_impact")
local ix,iy=board:nodeWorld(impact)
assert(root.costs[1]+impact.costs[1]==50 and impact.requires[1][1]=="fire_score_prewarm" and ix<rx and iy<ry,
    "cigarette impact unlock is not a 2-3 run early branch beside the smoker root")
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

print("CHARACTER_TRAITS_OK")
