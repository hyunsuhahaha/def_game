package.path = "./?.lua;./?/init.lua;" .. package.path

math.randomseed(20260826)
love = {
    math = {random = math.random},
    graphics = {
        setColor=function() end, setLineWidth=function() end, ellipse=function() end,
        circle=function() end, line=function() end, rectangle=function() end,
        push=function() end, pop=function() end, translate=function() end,
        rotate=function() end, draw=function() end
    }
}

local ClearcutMode = require("src.clearcut_mode")
local mode = ClearcutMode.new()
local variants = {{}, {}, {}, {}}
local game = {
    world = {
        width = 3200,
        height = 2000,
        nodes = {},
        images = {tree = {}, treeVariants = variants}
    }
}

mode:generateForest(game, 40)
assert(#game.world.nodes == 40, "forest generation did not reach the target")

local counts, identity = {}, {}
for i, node in ipairs(game.world.nodes) do
    assert(node.treeVariant and variants[node.treeVariant], "tree has no valid stable variant")
    counts[node.treeVariant] = (counts[node.treeVariant] or 0) + 1
    identity[i] = node.treeVariant
end
for variant = 1, #variants do
    assert((counts[variant] or 0) > 0, "tree variant " .. variant .. " was not distributed")
end

for i, node in ipairs(game.world.nodes) do
    node.active = not node.active
    node.active = not node.active
    assert(node.treeVariant == identity[i], "tree variant changed across lifecycle state")
end

print("TREE_VARIANTS_OK " .. table.concat({counts[1], counts[2], counts[3], counts[4]}, ","))
