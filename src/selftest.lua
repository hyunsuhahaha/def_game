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
    print("SELF_TEST_OK: FARM TREE STONE ORE TOOL_SPEED")
end

return SelfTest
