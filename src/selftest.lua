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
    game.progression.data.currency = 200
    local blocked = game.progression:buy("cargo_rig")
    assert(blocked == false, "선행 특성 잠금 실패")
    assert(game.progression:buy("quick_work") and game.progression:buy("quick_work"), "기초 특성 구매 실패")
    assert(game.progression:buy("cargo_rig"), "연결 특성 구매 실패")
    game:startRun(3)
    game.ore = 14; game:keypressed("2")
    assert(#game.world.turrets == 1 and game.world.turrets[1].kind == "autocannon", "포탑 실물 배치 실패")
    game.world:spawnDefender("drone", 2, game)
    assert(#game.world.defenders == 1 and game.world.defenders[1].kind == "drone", "전투 드론 실물 생성 실패")
    assert(game.upgrades:choose("auto_farm", game) and game.upgrades:choose("auto_farm", game), "런 시스템 강화 실패")
    assert(game.upgrades:choose("protein_feed", game), "런 보조 강화 실패")
    game.upgrades.levels.auto_farm = 5
    assert(game.upgrades:isEvolutionReady(game.upgrades:get("eternal_farm")) and game.upgrades:choose("eternal_farm", game), "런 진화 조합 실패")
    game.upgrades:rollChoices(); assert(#game.upgrades.choices == 3, "런 3택 생성 실패")
    local foodBeforeAutomation = game.food
    game.upgrades:update(10, game)
    assert(game.food > foodBeforeAutomation, "자동 생산 시스템 작동 실패")
    assert(game.player.gather > 1.28 and game.player.capacity == 26, "영구 특성 런 적용 실패")
    game.player.capacity = 100
    local farm = find(game.world, "plot")
    assert(game.world:workNode(farm, game, game.player, "hoe", 1) == false and farm.state == "planted", "파종 실패")
    assert(game.world:workNode(farm, game, game.player, "water", 1) == false and farm.state == "growing", "물주기 실패")
    game.world:update(13, game)
    assert(farm.state == "ready", "작물 성장 실패")
    assert(game.world:workNode(farm, game, game.player, "hoe", 1) == false and farm.state == "empty" and game.player.food == 6, "수확 실패")
    local tree, stone, ore = find(game.world, "tree"), find(game.world, "stone"), find(game.world, "ore")
    game.world:workNode(tree, game, game.player, "axe", tree.workTime / game.tools.axe.speed + .1)
    game.world:workNode(stone, game, game.player, "pickaxe", stone.workTime / game.tools.pickaxe.speed + .1)
    game.world:workNode(ore, game, game.player, "pickaxe", ore.workTime / game.tools.pickaxe.speed + .1)
    assert(game.player.wood == 6 and game.player.stone == 5 and game.player.ore == 5, "벌목/채광 보상 실패")
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
    print("SELF_TEST_OK: FARM TREE STONE ORE TOOL_SPEED HARVEST_FEEDBACK VISIBLE_TURRET VISIBLE_DRONE RUN_LEVELUP THREE_CHOICES AUTOMATION EVOLUTION WALL_UPGRADE WALL_BLOCK HAMMER_REPAIR META_SAVE TRAIT_TREE TRAIT_APPLY RUN_REWARD")
end

return SelfTest
