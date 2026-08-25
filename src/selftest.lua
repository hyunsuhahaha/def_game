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
    game.lobby.startBox = {x = 10, y = 10, w = 100, h = 50}
    game.lobby.traitsBox = {x = 120, y = 10, w = 100, h = 50}
    game.lobby.settingsBox = {x = 230, y = 10, w = 100, h = 50}
    assert(game.lobby:keypressed("return") == "start" and game.lobby:mousepressed(30, 30, 1) == "start", "로비 단일 시작 버튼 실패")
    assert(game.lobby:mousepressed(140, 30, 1) == "meta" and game.lobby:mousepressed(250, 30, 1) == "settings", "로비 보조 메뉴 진입 실패")
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
    combatTurret.mods, combatTurret.level = {multishot = 1, double_tap = 1}, 2
    local turretDef = game.world:defFor("autocannon_turret")
    for i = 1, 4 do game.world.enemies[#game.world.enemies + 1] = {x = combatTurret.x + i * 10, y = combatTurret.y, hp = 500, speed = 0, hit = 0} end
    combatTurret.timer = 0
    game.world:updateBuildings(.01, game)
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
    print("SELF_TEST_OK: LOBBY_SINGLE_START LOBBY_AUX_NAV SETTINGS BIG_TREE_SINGLE TREE_PER_HIT_DROP TREE_PROXIMITY_PICKUP QUARRY_GROUNDED QUARRY_PER_HIT_DROP QUARRY_ORE_RATIO QUARRY_PROXIMITY_PICKUP FARM TREE QUARRY_INFINITE TOOL_SPEED IMPACT_SYNC HARVEST_FEEDBACK VISIBLE_TURRET VISIBLE_DRONE VISIBLE_REPAIR_STATION RUN_LEVELUP THREE_CHOICES AUTOMATION EVOLUTION WALL_UPGRADE WALL_BLOCK HAMMER_REPAIR CRIT_CHANCE PRESTIGE_RUN MOVE_WHILE_FARM TURRET_SLOT_BASE TURRET_SLOT_TRAIT TURRET_SLOT_OCCUPIED TURRET_NEARBY TURRET_F_INTERACT TURRET_UPGRADE META_SAVE TRAIT_TREE TRAIT_APPLY RUN_REWARD TEST_CURRENCY TEST_RESOURCES TEST_LEVELS TEST_RESET")
end

return SelfTest
