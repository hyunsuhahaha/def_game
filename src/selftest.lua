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
    local food, oreBeforeGrant, wood, stoneBeforeGrant, seeds = game.food, game.ore, game.wood, game.stone, game.seeds
    game:grantTestRunResources()
    assert(game.food == food + 1000000 and game.ore == oreBeforeGrant + 1000000 and game.wood == wood + 1000000 and game.stone == stoneBeforeGrant + 1000000 and game.seeds == seeds + 1000000, "테스트 런 자원 지급 실패")
    game.food, game.ore, game.wood, game.stone, game.seeds = food, oreBeforeGrant, wood, stoneBeforeGrant, seeds
    local level, xp, nextXP, pending = game.runLevel, game.runXP, game.runXPNext, game.pendingLevels
    game:grantTestLevels(2)
    assert(game.runLevel == level + 2 and game.pendingLevels == pending + 2, "테스트 생산 레벨 지급 실패")
    game.runLevel, game.runXP, game.runXPNext, game.pendingLevels = level, xp, nextXP, pending
    game.ore = 14; game:keypressed("2")
    assert(#game.world.turrets == 1 and game.world.turrets[1].kind == "autocannon", "포탑 실물 배치 실패")
    game.world:spawnDefender("drone", 2, game)
    assert(#game.world.defenders == 1 and game.world.defenders[1].kind == "drone", "전투 드론 실물 생성 실패")
    assert(game.upgrades:choose("repair_station", game), "자동 수리소 선택 실패")
    local repairStation = game.world:getStructure("repair_station")
    assert(repairStation and repairStation.level == 1, "자동 수리소 월드 오브젝트 생성 실패")
    assert(game.upgrades:choose("repair_station", game) and game.world:getStructure("repair_station") == repairStation and repairStation.level == 2, "자동 수리소 강화 시 중복 생성 방지 실패")
    assert(game.upgrades:choose("auto_farm", game) and game.upgrades:choose("auto_farm", game), "런 시스템 강화 실패")
    assert(game.upgrades:choose("protein_feed", game), "런 보조 강화 실패")
    game.upgrades.levels.auto_farm = 5
    assert(game.upgrades:isEvolutionReady(game.upgrades:get("eternal_farm")) and game.upgrades:choose("eternal_farm", game), "런 진화 조합 실패")
    game.upgrades:rollChoices(); assert(#game.upgrades.choices == 3, "런 3택 생성 실패")
    local foodBeforeAutomation = game.food
    game.upgrades:update(10, game)
    assert(game.food > foodBeforeAutomation, "자동 생산 시스템 작동 실패")
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
    game.player:cancelInteraction()
    game.world.impactNode = originalImpact
    game.player.wood = 0
    game.world:harvestHit(tree, game, game.player)
    assert(game.player.wood == 1 and tree.active, "벌목 즉시 지급 실패")
    game.world:harvestHit(tree, game, game.player)
    assert(game.player.wood == 2, "벌목 반복 타격 지급 실패")
    local quarryDx, quarryDy = quarry.x - game.world.core.x, quarry.y - game.world.core.y
    assert(quarryDx * quarryDx + quarryDy * quarryDy <= 520 * 520, "채석장이 거점에서 너무 멀리 배치됨")
    for _ = 1, 4 do game.world:harvestHit(quarry, game, game.player) end
    assert(game.player.stone == 4 and game.player.ore == 0, "채석 즉시 지급 실패")
    game.world:harvestHit(quarry, game, game.player)
    assert(game.player.ore == 1, "채석 광석 비율 실패")
    for _ = 1, 5 do game.world:harvestHit(quarry, game, game.player) end
    assert(game.player.stone == 8 and game.player.ore == 2 and quarry.active, "채석 반복 타격 지급 실패")
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
    local beforeReward = game.progression.data.currency
    game.time, game.world.wave, game.world.kills, game.runStats.harvested = 600, 5, 8, 30
    game:finishRun(false)
    assert(game.mode == "results" and game.result.earned > 0 and game.progression.data.currency > beforeReward, "런 종료 영구 재화 정산 실패")
    local afterReward = game.progression.data.currency
    game:finishRun(false)
    assert(game.progression.data.currency == afterReward, "런 보상 중복 지급 방지 실패")
    print("SELF_TEST_OK: LOBBY_SINGLE_START LOBBY_AUX_NAV SETTINGS BIG_TREE_SINGLE TREE_INSTANT_HARVEST QUARRY_GROUNDED QUARRY_INSTANT_HARVEST QUARRY_ORE_RATIO FARM TREE QUARRY_INFINITE TOOL_SPEED IMPACT_SYNC HARVEST_FEEDBACK VISIBLE_TURRET VISIBLE_DRONE VISIBLE_REPAIR_STATION RUN_LEVELUP THREE_CHOICES AUTOMATION EVOLUTION WALL_UPGRADE WALL_BLOCK HAMMER_REPAIR META_SAVE TRAIT_TREE TRAIT_APPLY RUN_REWARD TEST_CURRENCY TEST_RESOURCES TEST_LEVELS TEST_RESET")
end

return SelfTest
