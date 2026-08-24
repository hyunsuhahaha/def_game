local SelfTest = {}

local function find(world, kind)
    for _, node in ipairs(world.nodes) do if node.kind == kind then return node end end
    error("테스트 자원 누락: " .. kind)
end

function SelfTest.run(game)
    game:startRun(3)
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
    print("SELF_TEST_OK: FARM TREE STONE ORE TOOL_SPEED WALL_UPGRADE WALL_BLOCK HAMMER_REPAIR")
end

return SelfTest
