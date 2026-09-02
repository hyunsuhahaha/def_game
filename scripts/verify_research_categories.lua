package.path = "./?.lua;./?/init.lua;" .. package.path

local CharacterTraits = require("src.character_traits")

local store = CharacterTraits.new(true)
local categories = store:getResearchCategories()
assert(#categories == 7 and store.RESEARCH_FRONTIER_PER_CATEGORY == 5,
    "integrated research board category contract is missing")

-- 정의된 활성 노드를 그대로 세어 모든 노드가 정확히 한 카테고리에 남아 있는지
-- 검사한다. 특정 숫자를 새로 강제하지 않아 다른 기능 작업이 노드를 추가해도 이
-- 재구성 검사가 그 노드를 삭제하거나 가로채지 않는다.
local categorized,totalActiveNodes = {},0
for _,category in ipairs(categories) do categorized[category.id] = 0 end
for _,job in ipairs({"fire","universal"}) do
    for _,node in ipairs(store:getScoreAttackNodes(job)) do
        local category = store:getResearchCategory(node)
        assert(category and categorized[category.id] ~= nil,
            "active research node has no category: " .. node.id)
        categorized[category.id] = categorized[category.id] + 1
        totalActiveNodes = totalActiveNodes + 1
    end
end

assert(totalActiveNodes == #store:getScoreAttackNodes("fire") + #store:getScoreAttackNodes("universal"),
    "category reconstruction changed the active node inventory")
for id,count in pairs(categorized) do assert(count > 0,"empty research category: " .. id) end

local sawCappedCategory = false
for _,percent in ipairs({0,20,40,60,80,95}) do
    local frontierStore = CharacterTraits.new(true)
    frontierStore.data.currency = 1000000000
    frontierStore.data.regenTier = 10
    frontierStore:setScoreProgress(percent)
    for _,category in ipairs(categories) do
        local summary = frontierStore:categoryFrontierSummary(category.id)
        assert(summary.active <= 5,"category exposes more than five upgrades: " .. category.id)
        assert(summary.active == math.min(summary.ready,5),
            "category frontier did not fill deterministically: " .. category.id)
        if summary.ready > 5 and summary.active == 5 then sawCappedCategory = true end
    end
end
assert(sawCappedCategory,"category frontier cap was never exercised by progression fixtures")

print(("research category verification passed: %d nodes preserved across %d categories")
    :format(totalActiveNodes,#categories))
