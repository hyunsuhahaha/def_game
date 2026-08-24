local UI = require("src.ui")

local TraitTree = {}
TraitTree.__index = TraitTree

local branchInfo = {
    {name = "채집 · 운반", color = {.35, .92, .48, 1}, icon = "채"},
    {name = "방벽 · 수리", color = {1, .62, .18, 1}, icon = "벽"},
    {name = "자동 전선", color = {.3, .8, 1, 1}, icon = "포"}
}

function TraitTree.new(progression, fonts)
    return setmetatable({progression = progression, fonts = fonts, selected = "wall_base", message = "", messageTime = 0, hitboxes = {}}, TraitTree)
end

function TraitTree:update(dt) self.messageTime = math.max(0, self.messageTime - dt) end

local function nodePosition(node, w)
    local centers = {w * .27, w * .5, w * .73}
    return centers[node.branch], 190 + (node.tier - 1) * 102
end

function TraitTree:keypressed(key)
    if key == "escape" or key == "t" or key == "return" then return "back" end
end

function TraitTree:mousepressed(x, y, button)
    if button ~= 1 then return end
    local w, h = love.graphics.getDimensions()
    if x >= 28 and x <= 176 and y >= 25 and y <= 67 then return "back" end
    for _, hit in ipairs(self.hitboxes) do
        if x >= hit.x and x <= hit.x + hit.w and y >= hit.y and y <= hit.y + hit.h then
            self.selected = hit.id
            local ok, message = self.progression:buy(hit.id)
            self.message, self.messageTime = message, 2.3
            return ok and "bought" or nil
        end
    end
end

function TraitTree:draw()
    local w, h, fonts = love.graphics.getDimensions()
    fonts = self.fonts
    love.graphics.clear(.025, .06, .065)
    love.graphics.setColor(.055, .105, .105); love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setColor(.2, .38, .34, .3)
    for x = 0, w, 48 do love.graphics.line(x, 0, x, h) end
    for y = 0, h, 48 do love.graphics.line(0, y, w, y) end

    love.graphics.setColor(.04, .065, .075, .98); love.graphics.rectangle("fill", 0, 0, w, 102)
    love.graphics.setColor(.9, .56, .12); love.graphics.rectangle("fill", 0, 99, w, 3)
    UI.button(28, 25, 148, 42, "← 로비", true, fonts.body)
    love.graphics.setFont(fonts.title); love.graphics.setColor(1, 1, 1); love.graphics.printf("영구 특성 관제망", 0, 20, w, "center")
    love.graphics.setFont(fonts.small); love.graphics.setColor(.55, .68, .72); love.graphics.printf("런이 끝나도 유지되는 보급 사령부 강화", 0, 65, w, "center")
    UI.panel(w - 238, 22, 205, 58, {.95, .66, .2, 1}, .95)
    love.graphics.setFont(fonts.small); love.graphics.setColor(.58, .68, .71); love.graphics.print("보유 유산 부품", w - 218, 31)
    love.graphics.setFont(fonts.heading); love.graphics.setColor(1, .74, .26); love.graphics.print(tostring(self.progression.data.currency), w - 218, 50)

    self.hitboxes = {}
    for branch, info in ipairs(branchInfo) do
        local cx = ({w * .27, w * .5, w * .73})[branch]
        love.graphics.setFont(fonts.heading); love.graphics.setColor(info.color); love.graphics.printf(info.name, cx - 130, 122, 260, "center")
        for tier = 1, 3 do
            local y1, y2 = 190 + (tier - 1) * 102 + 66, 190 + tier * 102
            love.graphics.setColor(info.color[1], info.color[2], info.color[3], .36); love.graphics.setLineWidth(4); love.graphics.line(cx, y1, cx, y2)
        end
    end

    for _, node in ipairs(self.progression:getNodes()) do
        local cx, cy = nodePosition(node, w)
        local level, info = self.progression:getLevel(node.id), branchInfo[node.branch]
        local unlocked = not node.requires or self.progression:getLevel(node.requires[1]) >= node.requires[2]
        local selected, maxed = self.selected == node.id, level >= node.max
        local x, y, nw, nh = cx - 102, cy, 204, 66
        self.hitboxes[#self.hitboxes + 1] = {id = node.id, x = x, y = y, w = nw, h = nh}
        love.graphics.setColor(unlocked and .025 or .02, unlocked and .055 or .025, unlocked and .062 or .03, .98); love.graphics.rectangle("fill", x, y, nw, nh, 8, 8)
        love.graphics.setColor(selected and 1 or info.color[1], selected and .82 or info.color[2], selected and .35 or info.color[3], unlocked and 1 or .25)
        love.graphics.setLineWidth(selected and 3 or 2); love.graphics.rectangle("line", x, y, nw, nh, 8, 8)
        love.graphics.circle("fill", x + 27, y + 33, 18)
        love.graphics.setFont(fonts.small); love.graphics.setColor(.03, .04, .04, unlocked and 1 or .45); love.graphics.printf(unlocked and info.icon or "잠", x + 9, y + 23, 36, "center")
        love.graphics.setColor(unlocked and .94 or .35, unlocked and .97 or .4, unlocked and .98 or .42); love.graphics.print(node.name, x + 53, y + 10)
        love.graphics.setColor(info.color[1], info.color[2], info.color[3], unlocked and .9 or .25); love.graphics.print(string.format("%d / %d", level, node.max), x + 53, y + 36)
        local cost = not maxed and node.costs[level + 1]
        love.graphics.setColor(.72, .78, .8, unlocked and .9 or .25); love.graphics.printf(maxed and "완료" or ("부품 " .. cost), x + 115, y + 36, 76, "right")
    end

    local selected = self.progression:getNode(self.selected)
    if selected then
        local level = self.progression:getLevel(selected.id)
        local ok, reason = self.progression:status(selected.id)
        UI.panel(w / 2 - 260, h - 105, 520, 78, branchInfo[selected.branch].color, .97)
        love.graphics.setFont(fonts.body); love.graphics.setColor(1, 1, 1); love.graphics.print(selected.name .. "  " .. level .. "/" .. selected.max, w / 2 - 238, h - 90)
        love.graphics.setFont(fonts.small); love.graphics.setColor(.7, .78, .8); love.graphics.print(selected.desc .. " / 클릭하여 강화", w / 2 - 238, h - 61)
        love.graphics.setColor(ok and {.4, 1, .58} or {.95, .58, .32}); love.graphics.printf(reason, w / 2 + 30, h - 90, 265, "right")
    end
    if self.messageTime > 0 then
        love.graphics.setFont(fonts.body); love.graphics.setColor(0, 0, 0, .8); love.graphics.printf(self.message, 2, 107, w, "center")
        love.graphics.setColor(1, .72, .25); love.graphics.printf(self.message, 0, 105, w, "center")
    end
end

return TraitTree
