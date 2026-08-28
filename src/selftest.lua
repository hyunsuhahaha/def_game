local SelfTest = {}

local function find(world, kind)
    for _, node in ipairs(world.nodes) do if node.kind == kind then return node end end
    error("테스트 자원 누락: " .. kind)
end

function SelfTest.run(game)
    local Progression = require("src.progression")
    local encoded = Progression.encode({currency = 17, levels = {quick_work = 2, wall_base = 1}})
    local decoded = Progression.decode(encoded)
    assert(decoded.currency == 17 and decoded.levels.quick_work == 2 and decoded.levels.wall_base == 1, "영구 데이터 직렬화 실패")
    game.progression.data.levels.turret_slots = 1
    assert(game.progression:effects().turretSlots == 2, "포대 확장 1단계 슬롯 지급 실패")
    game.progression.data.levels.turret_slots = 2
    assert(game.progression:effects().turretSlots == 3, "포대 확장 2단계 슬롯 지급 실패")
    game.progression.data.levels.turret_slots = 0
    game.progression.data.currency = 99
    game.progression.data.levels.quick_work = 3
    game.progression:reset()
    assert(game.progression.data.currency == 0 and game.progression:getLevel("quick_work") == 0, "테스트 영구 데이터 초기화 실패")
    game:useTestOption(1)
    assert(game.progression.data.currency == 1000000, "테스트 영구 재화 지급 실패")
    game.progression:reset()
    game.progression.data.currency = 200
    local blocked = game.progression:buy("cargo_rig")
    assert(blocked == false, "선행 특성 잠금 실패")
    assert(game.progression:buy("quick_work") and game.progression:buy("quick_work"), "기초 특성 구매 실패")
    assert(game.progression:buy("cargo_rig"), "연결 특성 구매 실패")
    game.lobby.clearcutBox = {x = 10, y = 10, w = 100, h = 50}
    game.lobby.traitsBox = {x = 120, y = 10, w = 100, h = 50}
    game.lobby.settingsBox = {x = 230, y = 10, w = 100, h = 50}
    assert(game.lobby:keypressed("return") == "clearcut" and game.lobby:mousepressed(30, 30, 1) == "clearcut", "숲 전멸 전용 로비 시작 버튼 실패")
    assert(game.lobby:keypressed("t") == "character_traits", "캐릭터 특성 단축키 실패")
    assert(game.lobby:mousepressed(140, 30, 1) == "character_traits" and game.lobby:mousepressed(250, 30, 1) == "settings", "로비 보조 메뉴 진입 실패")
    game:startRush()
    assert(game.runType=="rush" and game.world.theme=="forest" and game.time==180 and game.player.capacity==99999 and #game.world.nodes>=60, "3분 채집 러시 숲 맵 초기화 실패")
    local rushTree=game.world.nodes[1]
    game.player.x,game.player.y=rushTree.x,rushTree.y
    rushTree.rushHp=2
    assert(game.rush:updateHeldAxe(.01,game,true) and rushTree.rushHp==1 and game.player.autoAxeClock~=nil, "누른 채 이동 자동 벌목 실패")
    game.rush.levels.twin_axe,game.rush.levels.wide_swing,game.rush.levels.chain_fell=1,3,1
    rushTree.rushHp=1
    game.rush:hitTree(rushTree,game)
    assert(game.rush.treesFelled>=1 and #game.world.drops>=3 and game.rush.maxMulti>=2, "광역·연쇄 벌목 실패")
    for _,drop in ipairs(game.world.drops) do drop.x,drop.y,drop.height,drop.vx,drop.vy,drop.vz=game.player.x,game.player.y,0,0,0,0 end
    game.world:updateDrops(.1,game)
    assert(game.rush.totalWood>=3, "목재 자동 흡수 실패")
    if game.rush.pending<1 then game.rush:onWood(10,game) end
    assert(game.rush.pending>=1, "러시 경험치·레벨업 실패")
    game.rush:rollChoices(); assert(#game.rush.choices==3, "러시 강화 3택 실패")
    game.mode="rush_upgrade"
    local choiceDrawOk,choiceDrawError=pcall(game.draw,game); assert(choiceDrawOk,"러시 3택 렌더 실패: "..tostring(choiceDrawError))
    assert(game.rush:choose(1,game), "러시 강화 선택 실패")
    game.rush:onWood(40,game)
    assert(game.rush.combatTier>=1 and #game.world.turrets>=2, "목재 기반 자동 전선 성장 실패")
    game.world.enemies={{x=game.world.core.x,y=game.world.wall.y-120,hp=1000,speed=0,hit=0}}
    game.world.core.cooldown=0; game.world:update(.01,game)
    assert(#game.world.shots>=2,"러시 다중 자동 포탑 일제사격 실패")
    local rushDrawOk,rushDrawError=pcall(game.draw,game); assert(rushDrawOk,"러시 HUD 렌더 실패: "..tostring(rushDrawError))
    game.rush:finish(game,true); assert(game.mode=="rush_results" and game.result.wood>=43, "러시 결과 보고서 실패")
    local resultDrawOk,resultDrawError=pcall(game.draw,game); assert(resultDrawOk,"러시 결과 렌더 실패: "..tostring(resultDrawError))
    game:startRun()
    assert(game.world.turretSlotLimit == 1 and game.world:firstAvailableTurretSlot().index == 1, "기본 포대 슬롯 1개 실패")
    local food, oreBeforeGrant, wood, stoneBeforeGrant, seeds = game.food, game.ore, game.wood, game.stone, game.seeds
    game:grantTestRunResources()
    assert(game.food == food + 1000000 and game.ore == oreBeforeGrant + 1000000 and game.wood == wood + 1000000 and game.stone == stoneBeforeGrant + 1000000 and game.seeds == seeds + 1000000, "테스트 런 자원 지급 실패")
    game.food, game.ore, game.wood, game.stone, game.seeds = food, oreBeforeGrant, wood, stoneBeforeGrant, seeds
    local level, xp, nextXP, pending = game.runLevel, game.runXP, game.runXPNext, game.pendingLevels
    game:grantTestLevels(2)
    assert(game.runLevel == level + 2 and game.pendingLevels == pending + 2, "테스트 생산 레벨 지급 실패")
    game.runLevel, game.runXP, game.runXPNext, game.pendingLevels = level, xp, nextXP, pending
    game.ore = 14; game:keypressed("2")
    assert(game.placingBuilding and game.placingBuilding.id == "autocannon_turret", "포탑 건설 배치 모드 진입 실패")
    local firstTurretSlot = game.world:firstAvailableTurretSlot()
    local screenW, screenH = love.graphics.getDimensions()
    local slotScreenX = screenW / 2 + (firstTurretSlot.x - game.camera.x) * game.camera.zoom
    local slotScreenY = screenH / 2 + (firstTurretSlot.y - game.camera.y) * game.camera.zoom
    game:mousepressed(slotScreenX, slotScreenY, 1)
    local turret = game.world:turretInSlot(firstTurretSlot.index)
    assert(turret and #game.world.buildings == 1, "포탑 실물 배치 실패")
    assert(game.world:firstAvailableTurretSlot() == nil, "사용 중 포대 슬롯 점유 실패")
    game.placingBuilding = nil; game:keypressed("2")
    assert(game.placingBuilding == nil, "가득 찬 포대 슬롯 추가 건설 차단 실패")
    assert(turret.fuel == 1, "포탑 초기 연료 실패")
    game.player.x, game.player.y = turret.x, turret.y
    game.world:updateBuildings(1, game)
    assert(turret.fuel == 1, "연료 반경 안에서 감소 방지 실패")
    game.player.x, game.player.y = turret.x + 5000, turret.y
    game.world:updateBuildings(1, game)
    assert(turret.fuel < 1, "연료 반경 밖에서 소모 실패")
    local baselineDrain = 1 - turret.fuel
    assert(game.upgrades:choose("fuel_efficiency", game), "연료 효율 강화 선택 실패")
    assert((game.upgrades.resourcePct.fuelEfficiency or 0) > 0, "연료 효율 강화 적용 실패")
    turret.fuel = 1
    game.world:updateBuildings(1, game)
    assert(1 - turret.fuel < baselineDrain, "연료 효율 강화가 소모량을 줄이지 못함")
    for _ = 1, 10 do game.world:updateBuildings(1, game) end
    assert(turret.fuel == 0, "연료 완전 소모 실패")
    game.world.enemies[#game.world.enemies + 1] = {x = turret.x, y = turret.y, hp = 100, speed = 0, hit = 0}
    local dummy = game.world.enemies[#game.world.enemies]
    turret.timer = 0
    game.world:updateBuildings(.01, game)
    assert(dummy.hp == 100, "연료 소진 시 포탑 정지 실패")
    game.player.x, game.player.y = turret.x, turret.y
    for _ = 1, 10 do game.world:updateBuildings(1, game) end
    assert(turret.fuel == 1, "연료 재충전 실패")
    turret.timer = 0
    game.world:updateBuildings(.01, game)
    for _ = 1, 12 do game.world:updateProjectiles(.05, game) end
    assert(dummy.hp < 100, "연료 충전 후 포탑 재가동 실패")
    game.world.enemies[#game.world.enemies] = nil
    game.placingBuilding = nil
    game.world.buildings = {}
    game.world:spawnDefender("drone", 2, game)
    assert(#game.world.defenders == 1 and game.world.defenders[1].kind == "drone", "전투 드론 실물 생성 실패")
    game.food, game.wood, game.stone, game.ore = 1000, 1000, 1000, 1000
    local repairA = game.world:addBuilding("repair_station", 950, 1180)
    assert(repairA and #game.world.buildings == 1, "생산 시설 건설 실패")
    assert(game.world:addBuilding("repair_station", 950, 1180) == nil and #game.world.buildings == 1, "겹치는 위치 건설 방지 실패")
    assert(game.world:addBuilding("repair_station", 1010, 1180) and #game.world.buildings == 2, "동일 건물 다중 건설 실패")
    local quarry = find(game.world, "quarry")
    assert(not game.world:canPlaceBuilding(quarry.x, quarry.y, 46), "채집 노드와 겹치는 위치 건설 방지 실패")
    for i = 1, 5 do
        assert(game.world:addBuilding("auto_farm", 1070 + (i - 1) * 60, 1180), "자동 농기계 건설 실패")
    end
    assert(#game.world.buildings == 7, "건설된 생산 시설 개수 불일치")
    local miningDrone = game.world:addBuilding("mining_drone", 1390, 1180)
    assert(miningDrone, "채굴 드론 건설 실패")
    local drillBefore = miningDrone.drillAngle or 0
    miningDrone.timer = 0
    game.world:updateBuildings(.05, game)
    assert((miningDrone.drillAngle or 0) > drillBefore and (miningDrone.drillBurst or 0) > 0, "채굴 드론 회전·채굴 분진 효과 실패")
    local combatSlot = game.world:firstAvailableTurretSlot()
    local combatTurret = game.world:addBuilding("autocannon_turret", combatSlot.x, combatSlot.y, combatSlot.index)
    assert(combatTurret and combatTurret.level == 0, "포탑 초기 레벨 실패")
    assert(game.world:isTurretBuilding("autocannon_turret") and not game.world:isTurretBuilding("auto_farm"), "포탑 판정 실패")
    local costBefore, oreBefore = game.world:turretUpgradeCost(combatTurret), game.ore
    game.player.x, game.player.y = combatTurret.x, combatTurret.y
    game.nearTurret = game:getNearbyTurret()
    assert(game.nearTurret == combatTurret, "근처 포탑 감지 실패")
    game:keypressed("f")
    assert(game.mode == "turret_upgrade" and #game.turretUpgradeChoices == 3, "F키 포탑 강화 선택지 생성 실패")
    game:chooseTurretMod(1)
    assert(combatTurret.level == 1 and game.mode == "playing" and game.ore == oreBefore - costBefore, "포탑 강화 적용 실패")
    local pickedMod
    for id in pairs(combatTurret.mods) do pickedMod = id end
    assert(pickedMod ~= nil, "포탑 강화 중첩 기록 실패")
    game:tryOpenTurretUpgrade(combatTurret)
    game:cancelTurretUpgrade()
    assert(game.mode == "playing" and combatTurret.level == 1, "포탑 강화 취소 실패")
    combatTurret.mods, combatTurret.level = {multishot = 1, double_tap = 1, rapid_coil = 1, heavy_shell = 1}, 4
    local turretDef = game.world:defFor("autocannon_turret")
    for i = 1, 4 do game.world.enemies[#game.world.enemies + 1] = {x = combatTurret.x + i * 10, y = combatTurret.y, hp = 500, speed = 0, hit = 0} end
    combatTurret.timer = 0
    game.world:updateBuildings(.01, game)
    assert(#game.world.bullets >= 4 and #game.world.muzzleFlashes > 0, "가시 탄환·총구 섬광 생성 실패")
    assert(combatTurret.aimAngle > .5, "포탑 목표 방향 회전 실패")
    local sawChain, sawExplosion, effectsRendered = false, false, false
    for _ = 1, 12 do
        game.world:updateProjectiles(.05, game)
        sawChain = sawChain or #game.world.chainArcs > 0
        sawExplosion = sawExplosion or #game.world.explosions > 0
        if not effectsRendered and #game.world.chainArcs > 0 and #game.world.explosions > 0 then
            local drawOk, drawError = pcall(game.draw, game)
            assert(drawOk, "전투 이펙트 렌더 실패: " .. tostring(drawError))
            effectsRendered = true
        end
    end
    assert(sawChain and sawExplosion and effectsRendered, "연쇄 코일·폭발 탄두 시각 효과 실패")
    local totalDamage = 0
    for _, e in ipairs(game.world.enemies) do totalDamage = totalDamage + (500 - e.hp) end
    assert(totalDamage >= turretDef.damage * 4, "다중공격·이중발사 배수 적용 실패")
    game.world.enemies = {}
    assert(game.upgrades:choose("protein_feed", game), "런 보조 강화 실패")
    assert(game.upgrades:isEvolutionReady(game.upgrades:get("eternal_farm"), game) and game.upgrades:choose("eternal_farm", game), "런 진화 조합 실패")
    game.upgrades:rollChoices(game); assert(#game.upgrades.choices == 3, "런 3택 생성 실패")
    local dropsBeforeAutomation = #game.world.drops
    game.world:updateBuildings(6.5, game)
    assert(#game.world.drops > dropsBeforeAutomation, "자동 생산 건물 드롭 생성 실패")
    local foodDrop
    for _, drop in ipairs(game.world.drops) do if drop.kind == "food" then foodDrop = drop end end
    assert(foodDrop, "자동 농기계 식량 드롭 종류 실패")
    foodDrop.x, foodDrop.y, foodDrop.height, foodDrop.vx, foodDrop.vy, foodDrop.vz = game.player.x, game.player.y, 0, 0, 0, 0
    local playerFoodBefore = game.player.food
    game.world:updateDrops(.1, game)
    assert(game.player.food > playerFoodBefore, "자동 생산 드롭 근접 흡수 실패")
    game.player.food = 0
    assert(game.upgrades:choose("baby_robot", game), "아기 운반 로봇 선택 실패")
    game.world:updateHelpers(0, game)
    assert(#game.world.helpers == 1, "아기 로봇 생성 실패")
    local helper = game.world.helpers[1]
    helper.x, helper.y = game.world.core.x, game.world.core.y
    game.world.drops = {}
    game.world:spawnDrop("stone", 1, helper.x + 300, helper.y, 0, 0)
    local stoneBefore = game.stone
    for _ = 1, 400 do
        game.world:updateHelpers(.1, game)
        if game.stone > stoneBefore then break end
    end
    assert(#game.world.drops == 0, "아기 로봇이 드롭을 수거하지 못함")
    assert(game.stone > stoneBefore, "아기 로봇 자원 납품 실패 (왕복 배송 실패)")
    assert(game.player.gather > 1.11 and game.player.capacity == 21, "영구 특성 런 적용 실패")
    game.player.capacity = 100
    local farm = find(game.world, "plot")
    assert(game.world:workNode(farm, game, game.player, "hoe", 1) == false and farm.state == "planted", "파종 실패")
    assert(game.world:workNode(farm, game, game.player, "water", 1) == false and farm.state == "growing", "물주기 실패")
    game.world:update(13, game)
    assert(farm.state == "ready", "작물 성장 실패")
    assert(game.world:workNode(farm, game, game.player, "hoe", 1) == false and farm.state == "empty" and game.player.food == 6, "수확 실패")
    local tree, quarry, treeCount = find(game.world, "tree"), find(game.world, "quarry"), 0
    for _, node in ipairs(game.world.nodes) do if node.kind == "tree" then treeCount = treeCount + 1 end end
    assert(treeCount == 1 and tree.x < game.world.core.x and quarry.x > game.world.core.x, "단일 대형 나무·거점·채석장 배치 실패")
    local quarryVisual = game.world.quarryVisual
    assert(quarryVisual and quarryVisual.shadowRx <= 110 and quarryVisual.shadowRy <= 14 and quarryVisual.shadowAlpha <= .26, "채석장 접지 그림자가 과도함")
    local originalImpact, impactCount = game.world.impactNode, 0
    game.world.impactNode = function() impactCount = impactCount + 1 end
    game.player.x, game.player.y = tree.x + 100, tree.y
    game.player:beginInteraction(tree, game.world, game)
    assert(impactCount == 0, "도구 타격 전에 이펙트 발생")
    game.player:update(game.player.actionFrameDuration - .01, game.world, game)
    assert(impactCount == 0, "도구 타격 프레임 전에 이펙트 발생")
    game.player:update(.02, game.world, game)
    assert(impactCount == 1, "도구 타격 프레임과 이펙트 불일치")
    game.player.x = tree.x + 150
    game.player:update(.02, game.world, game)
    assert(game.player.interactionTarget == tree, "이동 중 채집이 중단됨")
    game.player.x = tree.x + 500
    game.player:update(.02, game.world, game)
    assert(game.player.interactionTarget == nil, "채집 대상과 멀어졌을 때 자동 중단 실패")
    game.player:cancelInteraction()
    game.world.impactNode = originalImpact
    game.player.wood, game.world.drops = 0, {}
    game.world:harvestHit(tree, game, game.player)
    assert(game.player.wood == 0 and #game.world.drops == 1 and game.world.drops[1].kind == "wood" and tree.active, "벌목 즉시 획득 방지 실패")
    local woodDrop = game.world.drops[1]
    woodDrop.x, woodDrop.y, woodDrop.height, woodDrop.vx, woodDrop.vy, woodDrop.vz = game.player.x, game.player.y, 0, 0, 0, 0
    game.world:updateDrops(.1, game)
    assert(game.player.wood == 1 and #game.world.drops == 0, "목재 근접 흡수 실패")
    game.upgrades.resourcePct.critChance = 1
    game.world:harvestHit(tree, game, game.player)
    assert(#game.world.drops == 3, "치명타 확정 시 드롭 개수 증가 실패")
    game.world.drops = {}
    game.upgrades.resourcePct.critChance = 0
    local quarryDx, quarryDy = quarry.x - game.world.core.x, quarry.y - game.world.core.y
    assert(quarryDx * quarryDx + quarryDy * quarryDy <= 520 * 520, "채석장이 거점에서 너무 멀리 배치됨")
    for _ = 1, 5 do game.world:harvestHit(quarry, game, game.player) end
    assert(#game.world.drops == 5, "채석 타격당 드롭 생성 실패")
    local oreDrops, stoneDrops = 0, 0
    for _, drop in ipairs(game.world.drops) do
        drop.x, drop.y, drop.height, drop.vx, drop.vy, drop.vz = game.player.x, game.player.y, 0, 0, 0, 0
        if drop.kind == "ore" then oreDrops = oreDrops + 1 else stoneDrops = stoneDrops + 1 end
    end
    assert(oreDrops == 1 and stoneDrops == 4, "채석 광석 비율 실패")
    game.world:updateDrops(.1, game)
    assert(game.player.stone == 4 and game.player.ore == 1 and #game.world.drops == 0 and quarry.active, "채석물 근접 흡수 실패")
    for _ = 1, 5 do game.world:harvestHit(quarry, game, game.player) end
    for _, drop in ipairs(game.world.drops) do drop.x, drop.y, drop.height, drop.vx, drop.vy, drop.vz = game.player.x, game.player.y, 0, 0, 0, 0 end
    game.world:updateDrops(.1, game)
    assert(game.player.stone == 8 and game.player.ore == 2 and #game.world.drops == 0 and quarry.active, "채석장 반복 타격 지급 실패")
    assert(#game.world.particles > 0 and #game.world.popups > 0 and game.camera.trauma > 0, "채집 타격 피드백 실패")
    game.wood, game.stone = 100, 100
    game:keypressed("4"); game:keypressed("4"); game:keypressed("4")
    assert(game.world.wall.level == 4 and game.world.wall.maxHp == 950, "방어벽 강화 실패")
    local coreHp, wallHp = game.world.core.hp, game.world.wall.hp
    game.world.core.damage, game.world.spawnTimer = 0, 999
    game.world.enemies = {{x = game.world.core.x, y = game.world.wall.y - 35, hp = 9999, speed = 0, hit = 10}}
    game.world:update(.5, game)
    assert(game.world.wall.hp < wallHp and game.world.core.hp == coreHp, "방어벽 차단 실패")
    local damagedHp = game.world.wall.hp
    game.wood, game.stone = 10, 10
    game.player.food, game.player.ore, game.player.wood, game.player.stone = 0, 0, 0, 0
    game.player.x, game.player.y = 1300, game.world.wall.y + 100
    game.player:beginWallRepair(game.world, game)
    game.player:update(.7, game.world, game)
    assert(game.world.wall.hp > damagedHp and game.wood == 9 and game.stone == 9, "망치 직접 수리 실패")
    game:startRun()
    local prestigeBefore = game.progression.data.currency
    game.time, game.world.wave, game.world.kills, game.runStats.harvested = 500, 3, 4, 20
    game:prestigeRun()
    assert(game.prestiged == true and game.mode == "results" and game.result.earned > 0 and game.progression.data.currency > prestigeBefore, "조기 철수 명예 정산 실패")
    game:startRun()
    local beforeReward = game.progression.data.currency
    game.time, game.world.wave, game.world.kills, game.runStats.harvested = 600, 5, 8, 30
    game:finishRun(false)
    assert(game.mode == "results" and game.result.earned > 0 and game.progression.data.currency > beforeReward, "런 종료 영구 재화 정산 실패")
    local afterReward = game.progression.data.currency
    game:finishRun(false)
    assert(game.progression.data.currency == afterReward, "런 보상 중복 지급 방지 실패")
    game:startClearcut("fire")
    assert(game.clearcut.smoking, "항상 흡연 루프 자동 시작 실패")
    game.clearcut:updateFireAttack(game.clearcut.smoking.dur * .5, game, true)
    assert(game.clearcut.smoking and #game.clearcut.molotovs == 0, "흡연 도중 조기 투척 방지 실패")
    local remaining = game.clearcut.smoking.dur - game.clearcut.smoking.t
    game.clearcut:updateFireAttack(remaining + .02, game, true)
    assert(game.clearcut.smoking.phase == "loaded", "흡연 완료 후 대기 상태 진입 실패")
    -- "loaded" 단계는 새로 눌리는 입력(press edge)에서만 투척으로 넘어간다: 계속 누르고
    -- 있던 상태가 아니라 뗐다가(false) 다시 누르는(true) 순간을 시뮬레이션해야 한다.
    game.clearcut:updateFireAttack(.01, game, false)
    game.clearcut:updateFireAttack(.01, game, true)
    assert(game.clearcut.smoking.phase == "flick", "마우스 재입력 시 투척 동작 진입 실패")
    game.clearcut:updateFireAttack(10, game, true)
    assert(#game.clearcut.molotovs >= 1, "흡연 완료 후 담배꽁초 투척 실패")
    assert(game.clearcut.smoking and game.clearcut.smoking.t < game.clearcut.smoking.dur, "투척 즉시 다음 담배로 재장전 실패")
    game.clearcut.molotovs = {}
    game.clearcut:rollChoices()
    assert(#game.clearcut.choices == 3, "벌목 방식 진화 3택 생성 실패")
    game.mode = "clearcut_upgrade"
    local cardDrawOk, cardDrawErr = pcall(game.draw, game)
    assert(cardDrawOk, "업그레이드 카드 프레임 렌더 실패: " .. tostring(cardDrawErr))
    game.mode = "playing"

    local ct = game.characterTraits
    ct.data.currency = 999
    local beforeMoveSpeed = ct:effects("physical").moveSpeed
    assert(ct:buy("universal_shuttle"), "공용 특성 구매 실패")
    assert(ct:effects("physical").moveSpeed > beforeMoveSpeed, "공용 특성이 직업 효과에 반영되지 않음")
    assert(ct:effects("fire").moveSpeed == ct:effects("physical").moveSpeed, "공용 특성이 직업별로 다르게 적용됨")
    ct:reset()

    game.mode = "clearcut_select"
    assert(not game.characterTraits:hasSeenStory("physical"), "초기 상태에서 스토리를 이미 본 것으로 표시됨")
    game:chooseClearcutCharacter(1)
    assert(game.mode == "character_story" and game.storyForced == true, "캐릭터 최초 선택 시 스토리 강제 노출 실패")
    game:advanceStory()
    assert(game.mode == "clearcut_map_select", "스토리 완료 후 맵 선택으로 진행 실패")
    assert(game.characterTraits:hasSeenStory("physical"), "스토리 시청 기록 저장 실패")
    game.mode = "clearcut_select"
    game:chooseClearcutCharacter(1)
    assert(game.mode == "clearcut_map_select", "이미 본 스토리는 다시 강제 노출되면 안 됨")
    game.mode = "clearcut_select"
    game:openCharacterStory("physical", false)
    assert(game.mode == "character_story" and game.storyForced == false, "다시보기 진입 실패")
    game:advanceStory()
    assert(game.mode == "clearcut_select", "다시보기 종료 후 캐릭터 선택 화면 복귀 실패")

    -- 로비 캐릭터 도감: 캐릭터 선택 화면의 강제 노출 로직과 완전히 분리되어야 한다.
    assert(not game.characterTraits:hasSeenStory("toxic"), "초기 상태에서 toxic 스토리를 이미 본 것으로 표시됨")
    game.mode = "character_codex"
    local codexDrawOk, codexDrawErr = pcall(game.draw, game)
    assert(codexDrawOk, "캐릭터 도감 렌더 실패: " .. tostring(codexDrawErr))
    game:openCharacterStory("toxic", false, "character_codex")
    assert(game.mode == "character_story" and game.storyForced == false, "도감에서 스토리 열람 진입 실패")
    game:advanceStory()
    assert(game.mode == "character_codex", "도감에서 스토리 종료 후 도감 화면 복귀 실패")
    assert(not game.characterTraits:hasSeenStory("toxic"), "도감 열람이 강제 노출 시청 기록에 영향을 줌")
    game.mode = "clearcut_select"
    game:chooseClearcutCharacter(3)
    assert(game.mode == "character_story" and game.storyForced == true, "도감에서 미리 본 캐릭터가 실제 최초 선택 시 강제 노출을 건너뜀")
    game:advanceStory()
    ct:reset()

    -- 스킬 연습장: 스토리/맵 선택을 건너뛰고 바로 진입하며, 자동 스폰이 전부 꺼지고
    -- 스킬 목록은 해당 직업 전용 + 공용으로만 한정된다.
    game.mode = "lobby"
    game.sandboxMode = true
    game:chooseClearcutCharacter(2)
    assert(game.clearcut and game.clearcut.sandbox == true and game.clearcut.job == "fire", "스킬 연습장 진입 실패")
    assert(game.mode == "playing" and not game.sandboxMode, "연습장 진입 후 상태 전환 실패")
    local sandboxSkills = game.clearcut:sandboxSkillList()
    local hasJobSkill, hasUniversalSkill, hasOtherJobSkill = false, false, false
    for _, def in ipairs(sandboxSkills) do
        if def.id == "molotov" then hasJobSkill = true end
        if def.id == "forced_growth" then hasUniversalSkill = true end
        if def.id == "berserker" then hasOtherJobSkill = true end
    end
    assert(hasJobSkill and hasUniversalSkill and not hasOtherJobSkill, "연습장 스킬 목록이 직업 전용+공용으로 한정되지 않음")
    game.clearcut:sandboxSetLevel("molotov", 1)
    assert(game.clearcut:levelOf("molotov") == 1, "연습장 스킬 레벨 증가 실패")
    game.clearcut:sandboxSetLevel("molotov", 99)
    assert(game.clearcut:levelOf("molotov") == game.clearcut:getUpgradeDefinition("molotov").max, "연습장 스킬 레벨이 만렙을 넘음")
    game.clearcut:sandboxSetLevel("molotov", -99)
    assert(game.clearcut:levelOf("molotov") == 0, "연습장 스킬 레벨이 0 밑으로 안 내려감")
    game.clearcut.enemies = {}
    game.clearcut.timeSpawnTimer = 0
    game.clearcut:updateTimeSpawner(.01, game)
    game.clearcut.eliteTimer = 0
    game.clearcut:updateEliteTimer(.01, game)
    assert(#game.clearcut.enemies == 0, "연습장에서 자동 스폰(시간/정예)이 꺼지지 않음")
    local sandboxDrawOk, sandboxDrawErr = pcall(game.draw, game)
    assert(sandboxDrawOk, "스킬 연습장 렌더 실패: " .. tostring(sandboxDrawErr))
    assert(game.sandboxSkyviewBox,"연습장 SKYVIEW 버튼이 없음")
    game:sandboxPanelClick(game.sandboxSkyviewBox.x+1,game.sandboxSkyviewBox.y+1)
    assert(game.camera.mode=="skyview" and game.camera.skyviewTarget==1,"연습장 SKYVIEW 버튼이 카메라를 켜지 못함")
    game.camera:updateMode(.6)
    local beforeX,beforeY=game.player.x,game.player.y
    game:sandboxPanelClick(game.sandboxSkyviewBox.x+1,game.sandboxSkyviewBox.y+1)
    game.camera:updateMode(.6)
    assert(game.camera.mode=="default" and game.camera.skyviewBlend==0,"연습장 SKYVIEW 버튼이 기본 시점을 복구하지 못함")
    assert(game.player.x==beforeX and game.player.y==beforeY,"SKYVIEW 전환이 월드 좌표를 변경함")
    game:sandboxPanelClick(game.sandboxMobBox.x + 1, game.sandboxMobBox.y + 1)
    assert(#game.clearcut.enemies > 0, "몹 소환 버튼으로 적 생성 실패")
    game.clearcut.enemies = {}

    -- 흡연자 SPACE 액션: 도넛 연기 — 입에서 조준 방향으로 날아가는 고리에 닿는 적에게
    -- 피해+넉백을 준다(자기 자리에서 팽창하는 게 아니라 실제로 날아가는 투사체).
    assert(game.clearcut:activateSmokeRing(game), "도넛 연기 발동 실패")
    assert(game.clearcut.smokeRingCooldown > 0, "도넛 연기 쿨다운 시작 실패")
    -- 조준(마우스) 방향은 헤드리스 환경에서 예측 불가하므로, 테스트에서는 +x 방향으로
    -- 고정해 결정론적으로 검증한다.
    local ring = game.clearcut.smokeRing
    ring.vx, ring.vy = 480, 0
    local smokeTarget = game.clearcut:spawnEnemy("squirrel", ring.x + 120, ring.y)
    smokeTarget.hp = 50
    local smokeXBefore = smokeTarget.x
    local smokeTreeNode = {kind="tree", x=ring.x + 300, y=ring.y, active=true, rushTree=true, rushHp=999, rushMaxHp=999, work=0, workTime=1, respawn=0}
    game.world.nodes[#game.world.nodes+1] = smokeTreeNode
    game.mode = "playing"
    local smokeDrawOk, smokeDrawErr = pcall(game.draw, game)
    assert(smokeDrawOk, "도넛 연기 비행 중 렌더 실패: " .. tostring(smokeDrawErr))
    for _ = 1, 60 do game.clearcut:updateSmokeRing(1 / 60, game) end
    assert(smokeTarget.hp < 50, "도넛 연기가 적에게 피해를 주지 않음")
    assert((smokeTarget.knockTimer or 0) > 0, "도넛 연기가 적을 넉백 상태로 만들지 않음")
    assert(smokeTreeNode.rushHp < 999, "도넛 연기가 나무에게 피해를 주지 않음")
    game.clearcut:updateEnemies(.05, game)
    assert(smokeTarget.x ~= smokeXBefore, "도넛 연기 넉백이 실제로 이동에 반영되지 않음")
    assert(game.clearcut.smokeRing == nil, "도넛 연기가 최대 사거리 도달 후 소멸하지 않음")
    assert(not game.clearcut:activateSmokeRing(game), "쿨다운 중에도 도넛 연기가 재발동됨")
    game.clearcut.enemies = {}

    -- 도넛 강화(smoke_ring) 스킬을 레벨업하면 실제로 재사용시간/피해/크기가 좋아져야 한다.
    game.clearcut.smokeRingCooldown = 0
    game.clearcut.levels.smoke_ring = 6
    assert(game.clearcut:activateSmokeRing(game), "도넛 강화 만렙 상태에서 도넛 연기 재발동 실패")
    assert(game.clearcut.smokeRingCooldown < 8, "도넛 강화가 재사용 대기시간을 줄이지 않음")
    assert(game.clearcut.smokeRing.dmg > 10, "도넛 강화가 피해를 늘리지 않음")
    assert(game.clearcut.smokeRing.maxRadius > 52, "도넛 강화가 크기를 늘리지 않음")
    local normalMaxDmg, normalMaxRadius = game.clearcut.smokeRing.dmg, game.clearcut.smokeRing.maxRadius
    -- 만렙 SPACE 차지는 완충했을 때만 강화된다. 중간 해제는 같은 만렙 일반 도넛이다.
    game.clearcut.smokeRing, game.clearcut.smokeRingCooldown = nil, 0
    assert(game.clearcut:beginSmokeRingCharge(game), "만렙 도넛 차지 시작 실패")
    game.clearcut:updateSmokeRing(.5, game)
    assert(game.clearcut:releaseSmokeRingCharge(game), "미완충 도넛 해제 발사 실패")
    assert(not game.clearcut.smokeRing.charged, "미완충 도넛이 차지 판정됨")
    assert(game.clearcut.smokeRing.dmg == normalMaxDmg and game.clearcut.smokeRing.maxRadius == normalMaxRadius, "미완충 도넛이 일반 만렙 수치와 다름")
    game.clearcut.smokeRing, game.clearcut.smokeRingCooldown = nil, 0
    assert(game.clearcut:beginSmokeRingCharge(game), "초농축 도넛 차지 재시작 실패")
    game.clearcut:updateSmokeRing(game.clearcut.smokeRingChargeDuration, game)
    assert(game.clearcut.smokeRing and game.clearcut.smokeRing.charged, "완충 시 초농축 도넛 자동 발사 실패")
    assert(game.clearcut.smokeRing.dmg > normalMaxDmg * 2 and game.clearcut.smokeRing.maxRadius > normalMaxRadius * 1.5, "초농축 도넛 강화 폭이 부족함")
    game.clearcut.levels.smoke_ring = 0
    game.clearcut.smokeRing, game.clearcut.smokeRingCooldown = nil, 0

    -- 융합 스킬: 재료를 만렙 찍을 필요 없이 목록에서 바로 켜고 끌 수 있어야 한다.
    local sandboxFusions = game.clearcut:sandboxFusionList()
    local hasSecondhandSmoke = false
    for _, def in ipairs(sandboxFusions) do if def.id == "secondhand_smoke" then hasSecondhandSmoke = true end end
    assert(hasSecondhandSmoke, "연습장 융합 스킬 목록에 해당 직업 융합이 없음")
    assert(not game.clearcut.evolutions.secondhand_smoke, "초기 상태에서 이미 융합을 배운 것으로 표시됨")
    local secondhandSmokeBox
    for _, box in ipairs(game.sandboxFusionBoxes or {}) do if box.id == "secondhand_smoke" then secondhandSmokeBox = box.box end end
    assert(secondhandSmokeBox, "융합 스킬 토글 버튼 생성 실패")
    game:sandboxPanelClick(secondhandSmokeBox.x + 1, secondhandSmokeBox.y + 1)
    assert(game.clearcut.evolutions.secondhand_smoke == true, "융합 스킬 토글(켜기) 실패")
    game:sandboxPanelClick(secondhandSmokeBox.x + 1, secondhandSmokeBox.y + 1)
    assert(not game.clearcut.evolutions.secondhand_smoke, "융합 스킬 토글(끄기) 실패")

    game:sandboxPanelClick(game.sandboxExitBox.x + 1, game.sandboxExitBox.y + 1)
    assert(game.mode == "lobby" and game.clearcut == nil, "연습장 나가기 버튼 동작 실패")

    game:startClearcut("physical")
    game.clearcut.reviveCharges = 1
    game.clearcut.hp, game.clearcut.maxHp, game.clearcut.invulnTimer, game.clearcut.dead = 10, 100, 0, false
    game.clearcut:damagePlayer(999, game)
    assert(not game.clearcut.dead and game.clearcut.reviveCharges == 0 and game.clearcut.hp > 0, "공용 특성 부활 실패")
    game.clearcut.invulnTimer = 0
    game.clearcut:damagePlayer(999, game)
    assert(game.clearcut.dead, "부활 소진 후에는 사망해야 함")
    game.clearcut.dead, game.clearcut.hp, game.clearcut.maxHp = false, 100, 100

    game.clearcut.elapsed = 0
    assert(math.abs(game.clearcut:curseLevel() - 1) < .001, "초기 저주 레벨 실패")
    local baseEnemy = game.clearcut:spawnEnemy("squirrel", game.player.x, game.player.y)
    local baseHp, baseSpeedMul, baseDmgMul = baseEnemy.maxHp, baseEnemy.speedMul, baseEnemy.dmgMul
    game.clearcut.enemies = {}
    game.clearcut.elapsed = 600
    assert(game.clearcut:curseLevel() > 1.5, "저주 레벨 시간 경과 상승 실패")
    local scaledEnemy = game.clearcut:spawnEnemy("squirrel", game.player.x, game.player.y)
    assert(scaledEnemy.maxHp > baseHp and scaledEnemy.speedMul > baseSpeedMul and scaledEnemy.dmgMul > baseDmgMul, "저주 레벨에 따른 적 스탯 스케일링 실패")
    game.clearcut.enemies = {}
    game.clearcut.elapsed = 0
    game.clearcut:spawnWave({squirrel = 2}, game)
    local baseWaveCount = #game.clearcut.enemies
    game.clearcut.enemies = {}
    game.clearcut.elapsed = 900
    game.clearcut:spawnWave({squirrel = 2}, game)
    assert(#game.clearcut.enemies > baseWaveCount, "시간 경과에 따른 웨이브 물량 스케일링 실패")
    game.clearcut.enemies = {}
    game.clearcut.timeSpawnTimer = 0
    game.clearcut:updateTimeSpawner(.01, game)
    assert(#game.clearcut.enemies > 0, "경과시간 기반 지속 스포너 실패")
    game.clearcut.enemies = {}
    game.clearcut.eliteTimer = 0
    game.clearcut:updateEliteTimer(.01, game)
    local eliteFound = false
    for _, e in ipairs(game.clearcut.enemies) do if e.elite then eliteFound = true end end
    assert(eliteFound, "정예 개체 스폰 실패")
    game.clearcut.enemies = {}
    game.clearcut.reaperSpawned, game.clearcut.elapsed = false, 300
    game.clearcut:updateReaper(.01, game)
    assert(not game.clearcut.reaperSpawned, "타임어택 사신 비활성화 실패")
    game.clearcut.elapsed = 650
    game.clearcut:updateReaper(.01, game)
    assert(not game.clearcut.reaperSpawned and #game.clearcut.enemies==0, "제한시간 대신 사신이 다시 등장함")
    local reaper=game.clearcut:spawnEnemy("reaper",game.player.x+50,game.player.y)
    reaper.x, reaper.y = game.player.x + 50, game.player.y
    reaper.reaperTimer = 0
    game.clearcut:updateReaperAI(reaper, .01, game)
    assert(reaper.reaperState == "charging", "사신 돌진 예열 진입 실패")
    game.clearcut:updateReaperAI(reaper, 1, game)
    assert(reaper.reaperState == "dashing", "사신 돌진 발동 실패")
    game.clearcut:updateReaperAI(reaper, 1, game)
    assert(reaper.reaperState == "idle", "사신 돌진 종료 후 복귀 실패")
    game.clearcut.enemies = {}
    local eliteEnemy = game.clearcut:spawnEnemy("boar", game.player.x + 300, game.player.y, {elite = true})
    eliteEnemy.eliteFireTimer = 0
    game.clearcut:updateEnemies(.01, game)
    local thornFound = false
    for _, p in ipairs(game.clearcut.projectiles) do if p.kind == "thorn" then thornFound = true end end
    assert(thornFound, "정예 개체 가시 투사체 발사 실패")
    game.clearcut.enemies, game.clearcut.projectiles = {}, {}
    assert(game.clearcut.stage == 1, "초기 스테이지 실패")
    local stageBeforeTrees = game.clearcut.initialTrees
    local pendingBefore = game.clearcut.pending
    game.clearcut.worldTree = game.clearcut:spawnEnemy("worldtree", game.player.x, game.player.y)
    game.clearcut:onEnemyDefeated(game.clearcut.worldTree, game)
    assert(game.clearcut.stage == 2, "세계수 처치 후 스테이지 증가 실패")
    assert(game.clearcut.initialTrees > stageBeforeTrees, "다음 스테이지 숲 규모 증가 실패")
    assert(game.clearcut.worldTreeSpawned == false and game.clearcut.worldTree == nil, "스테이지 전환 시 세계수 상태 초기화 실패")
    assert(game.clearcut.pending == pendingBefore + 1 and game.mode == "clearcut_upgrade", "스테이지 클리어 보상 3택 지급 실패")
    assert(game.clearcut.stageBossHpMul > 1, "스테이지 보스 강화 배율 실패")
    game.clearcut:choose(1, game)
    game.mode = "playing"
    game.clearcut.enemies = {}

    game.clearcut.bossTelegraphs = {}
    local wtree = game.clearcut:spawnEnemy("worldtree", game.player.x, game.player.y)
    game.clearcut:worldTreeRootSpikes(wtree, game)
    assert(#game.clearcut.bossTelegraphs >= 4, "세계수 뿌리 솟구침 텔레그래프 생성 실패")
    for _, tel in ipairs(game.clearcut.bossTelegraphs) do
        assert(tel.phase == "warn" and tel.radius and tel.kind ~= "line", "세계수 뿌리 솟구침 텔레그래프 형태 실패")
    end
    game.clearcut.bossTelegraphs = {}
    wtree.x, wtree.y = game.player.x - 200, game.player.y
    game.clearcut:worldTreeVineWhip(wtree, game)
    assert(#game.clearcut.bossTelegraphs == 1 and game.clearcut.bossTelegraphs[1].kind == "line", "세계수 덩굴 채찍 텔레그래프 생성 실패")
    local vine = game.clearcut.bossTelegraphs[1]
    vine.phase, vine.timer = "warn", 0
    game.clearcut.invulnTimer, game.clearcut.dead = 0, false
    local playerHpBefore = game.clearcut.hp
    game.clearcut:updateBossTelegraphs(.01, game)
    assert(vine.phase == "active", "세계수 덩굴 채찍 판정 전환 실패")
    assert(game.clearcut.hp < playerHpBefore, "세계수 덩굴 채찍 직선 판정 피해 실패")

    wtree.hp, wtree.maxHp = 30, 100
    wtree.rootSpikeTimer, wtree.vineWhipTimer = 3, 5.5
    game.clearcut:updateWorldTreeAI(wtree, .01, game)
    assert(wtree.enraged == true, "세계수 격노 전환 실패")
    assert(wtree.rootSpikeTimer < 3 and wtree.vineWhipTimer < 5.5, "세계수 격노 후 공격 주기 단축 실패")

    game.clearcut.enemies = {}
    game.clearcut.berserkState, game.clearcut.berserkTimer, game.clearcut.berserkCycleCount = "idle", 0, 0
    game.clearcut:updateBerserk(.01, game)
    assert(game.clearcut.berserkState == "warn", "광폭화 경고 단계 진입 실패")
    game.clearcut.berserkTimer = 0
    game.clearcut:updateBerserk(.01, game)
    assert(game.clearcut.berserkState == "active" and game.clearcut.berserkCycleCount == 1, "광폭화 진행 단계 진입 실패")
    local berserkEliteFound = false
    for _, e in ipairs(game.clearcut.enemies) do if e.elite then berserkEliteFound = true end end
    assert(berserkEliteFound, "광폭화 시작 시 강제 정예 스폰 실패")
    assert(game.clearcut:berserkMultiplier() > 2, "광폭화 진행 중 스폰 배율 실패")
    game.clearcut.berserkTimer = 0
    game.clearcut.kills = game.clearcut.berserkKillsStart + 3
    game.clearcut:updateBerserk(.01, game)
    assert(game.clearcut.berserkState == "cooldown", "광폭화 냉각 단계 진입 실패")
    game.clearcut.berserkTimer = 0
    game.clearcut:updateBerserk(.01, game)
    assert(game.clearcut.berserkState == "idle" and game.clearcut.berserkTimer > 0, "광폭화 냉각 후 대기 복귀 실패")

    game.clearcut.rootHazards = {}
    game.world.nodes[#game.world.nodes+1] = {kind="tree", x=game.player.x+40, y=game.player.y, work=0, workTime=1, active=true, respawn=0, rushTree=true, rushHp=3, rushMaxHp=3}
    game.clearcut.berserkCycleCount = 2
    game.clearcut:berserkTreeLash(game)
    assert(#game.clearcut.rootHazards > 0 and game.clearcut.rootHazards[1].berserk == true, "광폭화 나무 반격 텔레그래프 생성 실패")
    local berserkHazard = game.clearcut.rootHazards[1]
    berserkHazard.x, berserkHazard.y = game.player.x, game.player.y
    berserkHazard.phase, berserkHazard.timer = "warn", 0
    game.clearcut.invulnTimer, game.clearcut.dead = 0, false
    local berserkHpBefore = game.clearcut.hp
    game.clearcut:updateRootHazards(.01, game)
    assert(game.clearcut.hp < berserkHpBefore, "광폭화 나무 반격 피해 판정 실패")

    assert(#game.clearcut.berserkFlashNodes > 0, "반격한 나무의 붉은 기운 표시 실패")
    local flashNode = game.clearcut.berserkFlashNodes[1]
    local flashCountBefore = #game.clearcut.berserkFlashNodes
    assert(flashNode.berserkFlash and flashNode.berserkFlash > 0, "반격 나무 berserkFlash 값 실패")
    flashNode.berserkFlash = 0.001
    game.clearcut:updateBerserkFlashNodes(.01)
    assert(flashNode.berserkFlash == nil, "반격 나무 붉은 기운 소멸 처리 실패")
    local stillTracked = false
    for _, n in ipairs(game.clearcut.berserkFlashNodes) do if n == flashNode then stillTracked = true end end
    assert(not stillTracked and #game.clearcut.berserkFlashNodes == flashCountBefore - 1, "반격 나무 리스트 제거 실패")

    -- 카드 리롤 / 배니시
    game.clearcut.totalWood = 500
    game.clearcut:openUpgradeChoices(game)
    local rerollCostBefore = game.clearcut:rerollCost()
    local woodBeforeReroll = game.clearcut.totalWood
    assert(game.clearcut:choose("reroll", game) == true, "리롤 실행 실패")
    assert(game.clearcut.totalWood == woodBeforeReroll - rerollCostBefore, "리롤 목재 차감 실패")
    assert(game.clearcut.rerollCount == 1, "리롤 횟수 누적 실패")
    assert(game.clearcut:rerollCost() > rerollCostBefore, "리롤 비용 스케일링 실패")

    local banishTarget, banishIdx
    for i, def in ipairs(game.clearcut.choices) do
        if def.id ~= "berserker" and def.id ~= "molotov" and def.id ~= "fork_feast" and def.id ~= "heavy_machinery" then
            banishTarget, banishIdx = def, i
            break
        end
    end
    assert(banishTarget, "배니시 테스트용 비전직 카드 탐색 실패")
    assert(game.clearcut:choose("banish", game) == true, "배니시 무장 실패")
    assert(game.clearcut.banishArmed == true, "배니시 무장 상태 실패")
    local woodBeforeBanish = game.clearcut.totalWood
    assert(game.clearcut:choose(banishIdx, game) == true, "배니시 확정 실패")
    assert(game.clearcut.banished[banishTarget.id] == true, "카드 영구 제외 실패")
    assert(game.clearcut.totalWood == woodBeforeBanish - 45, "배니시 목재 차감 실패")
    assert(game.clearcut.banishArmed == false, "배니시 이후 무장 해제 실패")
    for _, def in ipairs(game.clearcut:upgradePool()) do assert(def.id ~= banishTarget.id, "배니시된 카드가 풀에 남아있음") end

    game.clearcut.choices[1] = game.clearcut:getUpgradeDefinition("berserker")
    game.clearcut.banishArmed = true
    assert(game.clearcut:choose(1, game) == false, "전직 카드 배니시 방지 실패")
    assert(not game.clearcut.banished["berserker"], "전직 카드가 잘못 배니시됨")
    game.clearcut.banishArmed = false

    -- 아르카나 (스테이지 클리어 시 딱 1번, 룰을 바꾸는 영구 카드 — 풀이 소진될 때까지 반복 지급되는지 확인)
    game.clearcut:advanceStage(game)
    assert(game.clearcut.selectionKind == "arcana", "스테이지 클리어 후 아르카나 선택 진입 실패")
    assert(#game.clearcut.arcanaChoices >= 1, "아르카나 선택지 생성 실패")
    local arcanaPick = game.clearcut.arcanaChoices[1]
    assert(game.clearcut:choose(1, game) == true, "아르카나 선택 실패")
    assert(game.clearcut.arcanaPicked[arcanaPick.id] == true, "아르카나 선택 기록 실패")
    assert(game.clearcut.selectionKind == "upgrade", "아르카나 선택 후 업그레이드 화면 복귀 실패")
    local remainingArcana = #game.clearcut:arcanaPool()
    for i = 1, remainingArcana do
        game.clearcut:advanceStage(game)
        assert(game.clearcut.selectionKind == "arcana", "아르카나 반복 지급 실패")
        game.clearcut:choose(1, game)
    end
    assert(#game.clearcut:arcanaPool() == 0, "아르카나 풀 소진 실패")
    game.clearcut:advanceStage(game)
    assert(game.clearcut.selectionKind == "upgrade", "아르카나 소진 후 일반 업그레이드 화면 폴백 실패")
    game.clearcut.enemies, game.mode = {}, "playing"

    -- 스페셜 카드: 아주 낮은 확률로 뜨는 4번째 슬롯, choose("special", game)로 즉시 적용된다
    game.clearcut.arcanaPicked = {}
    local specialPool = game.clearcut:arcanaPool()
    assert(#specialPool > 0, "스페셜 카드 테스트용 아르카나 풀 확보 실패")
    game.clearcut.specialCard = specialPool[1]
    game.clearcut.specialCardRevealAt = love.timer.getTime() - 10
    local specialId = specialPool[1].id
    assert(game.clearcut:choose("special", game) == true, "스페셜 카드 선택 실패")
    assert(game.clearcut.arcanaPicked[specialId] == true, "스페셜 카드 선택 기록 실패")
    assert(game.clearcut.specialCard == nil, "스페셜 카드 선택 후 정리 실패")

    -- 자이라식 소환 식물: 텔레그래프로 자란 뒤 진짜 몹으로 스폰된다
    game.clearcut.vineSpawns, game.clearcut.enemies = {}, {}
    game.clearcut.vinePlantTimer = 0
    game.clearcut:updateVinePlants(.01, game)
    assert(#game.clearcut.vineSpawns > 0, "덩굴괴수 소환 텔레그래프 생성 실패")
    local vineSpawn = game.clearcut.vineSpawns[1]
    vineSpawn.timer = 0
    game.clearcut:updateVinePlants(.01, game)
    local vineFound = false
    for _, e in ipairs(game.clearcut.enemies) do if e.kind == "vineSprout" then vineFound = true end end
    assert(vineFound, "덩굴괴수 실제 스폰 실패")
    local vinePlant
    for _, e in ipairs(game.clearcut.enemies) do if e.kind == "vineSprout" then vinePlant = e end end
    vinePlant.x, vinePlant.y = game.player.x + 50, game.player.y
    vinePlant.fireTimer = 0
    game.clearcut.projectiles = {}
    game.clearcut:updateEnemies(.01, game)
    local thornFromVine = false
    for _, p in ipairs(game.clearcut.projectiles) do if p.kind == "thorn" then thornFromVine = true end end
    assert(thornFromVine, "덩굴괴수 가시 공격 실패")
    game.clearcut.enemies, game.clearcut.projectiles = {}, {}

    -- 자연재해: 비는 방화를 완전히 봉쇄하고, 지진은 회피형 광역 텔레그래프를 뿌린다
    game.clearcut.disasterState, game.clearcut.disasterTimer, game.clearcut.disasterType = "idle", 0, nil
    game.clearcut:updateDisasters(.01, game)
    assert(game.clearcut.disasterState == "warn" and game.clearcut.disasterType, "자연재해 경고 단계 진입 실패")
    game.clearcut.disasterType = "rain"
    game.clearcut.disasterTimer = 0
    game.clearcut:updateDisasters(.01, game)
    assert(game.clearcut.disasterState == "active" and game.clearcut.rainSuppressFire == true, "비 활성화 실패")
    local rainNode = {kind="tree", x=game.player.x, y=game.player.y, active=true, rushTree=true, rushHp=3, rushMaxHp=3, burning=false}
    game.world.nodes[#game.world.nodes+1] = rainNode
    game.clearcut:igniteNear(rainNode, game, 999, 5)
    assert(rainNode.burning ~= true, "비가 오는데도 발화됨 - 방화 봉쇄 실패")
    game.clearcut.disasterTimer = 0
    game.clearcut:updateDisasters(.01, game)
    assert(game.clearcut.disasterState == "cooldown" and game.clearcut.rainSuppressFire == false, "비 종료 처리 실패")

    game.clearcut.disasterState, game.clearcut.disasterTimer, game.clearcut.disasterType = "warn", 0, "quake"
    game.clearcut.bossTelegraphs = {}
    game.clearcut:updateDisasters(.01, game)
    assert(game.clearcut.disasterState == "active", "지진 활성화 실패")
    game.clearcut.quakeTickTimer = 0
    game.clearcut:updateDisasters(.01, game)
    local quakeTelFound = false
    for _, tel in ipairs(game.clearcut.bossTelegraphs) do if tel.quake then quakeTelFound = true end end
    assert(quakeTelFound, "지진 낙석 텔레그래프 생성 실패")
    game.clearcut.disasterState, game.clearcut.disasterTimer, game.clearcut.disasterType = "idle", 999, nil
    game.clearcut.bossTelegraphs = {}

    -- 오프스크린 인디케이터 + 새 카드 이펙트가 실제 렌더 경로에서 에러 없이 그려지는지 확인
    game.clearcut:spawnEnemy("reaper", game.camera.x + 4000, game.camera.y + 4000)
    game.mode = "playing"
    local drawOk, drawErr = pcall(game.draw, game)
    assert(drawOk, "오프스크린 인디케이터/신규 이펙트 렌더 실패: " .. tostring(drawErr))
    game.clearcut.enemies = {}

    -- 철학자 기본공격 "끝없는 설교": 누르고 있으면 침 게이지가 계속 줄고, 바닥나면
    -- 누르고 있어도 강제로 멈춘다. 25%까지 회복해야 다시 쏠 수 있다(깜빡임 방지).
    game:startClearcut("philosopher")
    assert(game.clearcut.salivaGauge == game.clearcut.salivaGaugeMax, "침 게이지 초기값 실패")
    for _ = 1, 200 do game.clearcut:updatePhilosopherAttack(1 / 60, game, true) end
    assert(game.clearcut.salivaGauge < 1, "계속 눌러도 침 게이지가 소모되지 않음")
    assert(game.clearcut.salivaExhausted == true, "게이지 소진 시 탈진 상태로 전환되지 않음")
    for _ = 1, 30 do game.clearcut:updatePhilosopherAttack(1 / 60, game, true) end
    assert(game.clearcut.salivaGauge > 0, "탈진 중에도 게이지가 회복되지 않음(들고 있어도 회복은 되어야 함)")
    assert(game.clearcut.salivaGauge < game.clearcut.salivaGaugeMax * .25, "게이지가 이미 25% 넘게 회복된 상태에서 테스트를 계속할 수 없음")
    for _ = 1, 300 do game.clearcut:updatePhilosopherAttack(1 / 60, game, false) end
    assert(game.clearcut.salivaExhausted == false, "25% 이상 회복 후에도 탈진 상태가 풀리지 않음")
    assert(game.clearcut.salivaGauge == game.clearcut.salivaGaugeMax, "쉬는 동안 게이지가 완전히 회복되지 않음")

    -- 철학자 SPACE 액션: 부흥회 개최 — 몇 초간 침 게이지 소모 없이 설교할 수 있다.
    game.clearcut.salivaGauge, game.clearcut.salivaExhausted = game.clearcut.salivaGaugeMax, false
    assert(game.clearcut:activateRevival(game), "부흥회 개최 실패")
    assert(game.clearcut.revivalCooldown > 0, "부흥회 쿨다운 시작 실패")
    assert(game.clearcut.revivalTimer > 0, "부흥회 지속시간 시작 실패")
    assert(not game.clearcut:activateRevival(game), "쿨다운 중에도 부흥회가 재개최됨")
    local gaugeBeforeRevivalFiring = game.clearcut.salivaGauge
    for _ = 1, 60 do game.clearcut:updatePhilosopherAttack(1 / 60, game, true) end
    assert(game.clearcut.salivaGauge == gaugeBeforeRevivalFiring, "부흥회 중에도 침 게이지가 소모됨")
    local revivalTimerBefore, revivalCooldownBefore = game.clearcut.revivalTimer, game.clearcut.revivalCooldown
    game.clearcut:updateRevival(1, game)
    assert(game.clearcut.revivalTimer < revivalTimerBefore and game.clearcut.revivalCooldown < revivalCooldownBefore, "부흥회 지속시간/쿨다운이 시간에 따라 줄지 않음")
    game.clearcut.revivalTimer, game.clearcut.revivalCooldown = 0, 0

    -- 부흥회 강화(revival_meeting) 스킬을 레벨업하면 쿨다운이 줄고 지속시간이 늘어야 한다.
    game.clearcut.levels.revival_meeting = 6
    assert(game.clearcut:activateRevival(game), "부흥회 강화 만렙 상태에서 부흥회 재발동 실패")
    assert(game.clearcut.revivalCooldown < 20, "부흥회 강화가 재사용 대기시간을 줄이지 않음")
    assert(game.clearcut.revivalTimer > 6, "부흥회 강화가 지속시간을 늘리지 않음")
    game.clearcut.levels.revival_meeting = 0
    game.clearcut.revivalTimer, game.clearcut.revivalCooldown = 0, 0

    print("SELF_TEST_OK: LOBBY_DUAL_MODE RUSH_3MIN RUSH_FOREST RUSH_HOLD_TO_CHOP RUSH_MULTI_HIT RUSH_CHAIN_FELL RUSH_AUTO_PICKUP RUSH_THREE_CHOICES RUSH_AUTO_FRONT RUSH_RESULTS LOBBY_AUX_NAV SETTINGS BIG_TREE_SINGLE TREE_PER_HIT_DROP TREE_PROXIMITY_PICKUP QUARRY_GROUNDED QUARRY_PER_HIT_DROP QUARRY_ORE_RATIO QUARRY_PROXIMITY_PICKUP FARM TREE QUARRY_INFINITE TOOL_SPEED IMPACT_SYNC HARVEST_FEEDBACK VISIBLE_TURRET VISIBLE_DRONE VISIBLE_REPAIR_STATION MINING_DRILL_VFX RUN_LEVELUP THREE_CHOICES AUTOMATION EVOLUTION WALL_UPGRADE WALL_BLOCK HAMMER_REPAIR CRIT_CHANCE PRESTIGE_RUN MOVE_WHILE_FARM TURRET_SLOT_BASE TURRET_SLOT_TRAIT TURRET_SLOT_OCCUPIED TURRET_NEARBY TURRET_F_INTERACT TURRET_UPGRADE TURRET_AIM VISIBLE_BULLET MUZZLE_FLASH CHAIN_COIL_VFX EXPLOSIVE_SHELL_VFX META_SAVE TRAIT_TREE TRAIT_APPLY RUN_REWARD TEST_CURRENCY TEST_RESOURCES TEST_LEVELS TEST_RESET CIGARETTE_SMOKE_WINDUP CLEARCUT_CARD_FRAME CURSE_SCALING SWARM_SCALING TIME_SPAWNER ELITE_SPAWN REAPER_SPAWN REAPER_DASH_AI ELITE_THORN_FIRE STAGE_PROGRESSION WORLDTREE_ATTACKS WORLDTREE_ENRAGE SHADED_SPRITES BERSERK_ROUND BERSERK_TREE_FX CARD_REROLL CARD_BANISH ARCANA_STAGE SPECIAL_CARD VINE_PLANT NATURAL_DISASTER OFFSCREEN_INDICATOR CHARACTER_STORY_FLOW CHARACTER_CODEX SKILL_SANDBOX SANDBOX_FUSION SMOKE_RING SALIVA_GAUGE REVIVAL_MEETING")
end

return SelfTest
