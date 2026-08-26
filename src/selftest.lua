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
    assert(#game.clearcut.molotovs >= 1, "흡연 완료 후 담배꽁초 투척 실패")
    assert(game.clearcut.smoking and game.clearcut.smoking.t < game.clearcut.smoking.dur, "투척 즉시 다음 담배로 재장전 실패")
    game.clearcut.molotovs = {}
    game.clearcut:rollChoices()
    assert(#game.clearcut.choices == 3, "벌목 방식 진화 3택 생성 실패")
    game.mode = "clearcut_upgrade"
    local cardDrawOk, cardDrawErr = pcall(game.draw, game)
    assert(cardDrawOk, "업그레이드 카드 프레임 렌더 실패: " .. tostring(cardDrawErr))
    game.mode = "playing"
    game:startClearcut("physical")
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
    assert(not game.clearcut.reaperSpawned, "사신 조기 등장 방지 실패")
    game.clearcut.elapsed = 650
    game.clearcut:updateReaper(.01, game)
    assert(game.clearcut.reaperSpawned, "사신 등장 실패")
    local reaperFound = false
    for _, e in ipairs(game.clearcut.enemies) do if e.kind == "reaper" then reaperFound = true end end
    assert(reaperFound, "사신 개체 실제 스폰 실패")
    local reaper
    for _, e in ipairs(game.clearcut.enemies) do if e.kind == "reaper" then reaper = e end end
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

    print("SELF_TEST_OK: LOBBY_DUAL_MODE RUSH_3MIN RUSH_FOREST RUSH_HOLD_TO_CHOP RUSH_MULTI_HIT RUSH_CHAIN_FELL RUSH_AUTO_PICKUP RUSH_THREE_CHOICES RUSH_AUTO_FRONT RUSH_RESULTS LOBBY_AUX_NAV SETTINGS BIG_TREE_SINGLE TREE_PER_HIT_DROP TREE_PROXIMITY_PICKUP QUARRY_GROUNDED QUARRY_PER_HIT_DROP QUARRY_ORE_RATIO QUARRY_PROXIMITY_PICKUP FARM TREE QUARRY_INFINITE TOOL_SPEED IMPACT_SYNC HARVEST_FEEDBACK VISIBLE_TURRET VISIBLE_DRONE VISIBLE_REPAIR_STATION MINING_DRILL_VFX RUN_LEVELUP THREE_CHOICES AUTOMATION EVOLUTION WALL_UPGRADE WALL_BLOCK HAMMER_REPAIR CRIT_CHANCE PRESTIGE_RUN MOVE_WHILE_FARM TURRET_SLOT_BASE TURRET_SLOT_TRAIT TURRET_SLOT_OCCUPIED TURRET_NEARBY TURRET_F_INTERACT TURRET_UPGRADE TURRET_AIM VISIBLE_BULLET MUZZLE_FLASH CHAIN_COIL_VFX EXPLOSIVE_SHELL_VFX META_SAVE TRAIT_TREE TRAIT_APPLY RUN_REWARD TEST_CURRENCY TEST_RESOURCES TEST_LEVELS TEST_RESET CIGARETTE_SMOKE_WINDUP CLEARCUT_CARD_FRAME CURSE_SCALING SWARM_SCALING TIME_SPAWNER ELITE_SPAWN REAPER_SPAWN REAPER_DASH_AI ELITE_THORN_FIRE STAGE_PROGRESSION WORLDTREE_ATTACKS WORLDTREE_ENRAGE SHADED_SPRITES")
end

return SelfTest
