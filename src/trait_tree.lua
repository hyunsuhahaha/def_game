local UI = require("src.ui")

local TraitTree = {}
TraitTree.__index = TraitTree

local branchInfo = {
    {name = "채집 · 운반", color = {.4, .88, .48, 1}, iconKey = "crop"},
    {name = "방벽 · 수리", color = {1, .64, .2, 1}, iconKey = "repair_station"},
    {name = "자동 전선", color = {.32, .8, 1, 1}, iconKey = "autocannon_turret"},
    {name = "생산 시설", color = {.8, .6, 1, 1}, iconKey = "mining_drone"},
    {name = "전투 지원", color = {1, .42, .42, 1}, iconKey = "drone"}
}

local radiusByTier = {140, 230, 320, 410}

function TraitTree.new(progression, fonts, worldImages, buildingIcons)
    local icons = {}
    for _, info in ipairs(branchInfo) do
        icons[info.iconKey] = (buildingIcons and buildingIcons[info.iconKey]) or (worldImages and worldImages[info.iconKey])
    end
    return setmetatable({
        progression = progression, fonts = fonts, icons = icons, coreIcon = worldImages and worldImages.core,
        selected = "quick_work", message = "", messageTime = 0, hitboxes = {}
    }, TraitTree)
end

function TraitTree:update(dt) self.messageTime = math.max(0, self.messageTime - dt) end

function TraitTree:hubPosition(w, h) return w / 2, h / 2 + 20 end

function TraitTree:nodePosition(node, w, h)
    local cx, cy = self:hubPosition(w, h)
    local radius = radiusByTier[node.tier] or 410
    local rad = math.rad(node.angle)
    return cx + math.cos(rad) * radius, cy + math.sin(rad) * radius * .58
end

function TraitTree:keypressed(key)
    if key == "escape" or key == "t" or key == "return" then return "back" end
end

function TraitTree:mousepressed(x, y, button)
    if button ~= 1 then return end
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

local function isUnlocked(progression, node)
    return not node.requires or progression:getLevel(node.requires[1]) >= node.requires[2]
end

function TraitTree:draw()
    local w, h = love.graphics.getDimensions()
    local fonts = self.fonts
    local nodes = self.progression:getNodes()

    love.graphics.clear(.05, .035, .028)
    love.graphics.setColor(.09, .062, .045); love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setColor(.16, .1, .06, .5)
    for gx = 0, w, 46 do love.graphics.line(gx, 0, gx, h) end
    for gy = 0, h, 46 do love.graphics.line(0, gy, w, gy) end
    local hubX, hubY = self:hubPosition(w, h)
    love.graphics.setColor(1, .72, .3, .1)
    love.graphics.circle("fill", hubX, hubY, 470)

    love.graphics.setColor(.045, .028, .02, .98); love.graphics.rectangle("fill", 0, 0, w, 102)
    love.graphics.setColor(.9, .62, .2); love.graphics.rectangle("fill", 0, 99, w, 3)
    UI.button(28, 25, 148, 42, "← 로비", true, fonts.body)
    love.graphics.setFont(fonts.title); love.graphics.setColor(1, .95, .86); love.graphics.printf("영구 특성 관제망", 0, 20, w, "center")
    love.graphics.setFont(fonts.small); love.graphics.setColor(.78, .64, .5); love.graphics.printf("런이 끝나도 유지되는 보급 사령부 강화 — 다섯 갈래로 뻗어나가는 확장 계통도", 0, 65, w, "center")
    UI.panel(w - 238, 22, 205, 58, {1, .74, .26, 1}, .95)
    love.graphics.setFont(fonts.small); love.graphics.setColor(.6, .5, .4); love.graphics.print("보유 유산 부품", w - 218, 31)
    love.graphics.setFont(fonts.heading); love.graphics.setColor(1, .78, .3); love.graphics.print(tostring(self.progression.data.currency), w - 218, 50)

    -- connector lines (drawn first so nodes sit on top)
    love.graphics.setLineWidth(3)
    for _, node in ipairs(nodes) do
        local info = branchInfo[node.branch]
        local nx, ny = self:nodePosition(node, w, h)
        local px, py
        if node.requires then
            local parent = self.progression:getNode(node.requires[1])
            px, py = self:nodePosition(parent, w, h)
        else
            px, py = hubX, hubY
        end
        local owned = self.progression:getLevel(node.id) > 0
        love.graphics.setColor(info.color[1], info.color[2], info.color[3], owned and .85 or .22)
        love.graphics.line(px, py, nx, ny)
    end
    love.graphics.setLineWidth(1)

    -- hub
    love.graphics.setColor(1, .8, .4, .9); love.graphics.setLineWidth(3); love.graphics.circle("line", hubX, hubY, 44)
    love.graphics.setColor(.12, .08, .05, .96); love.graphics.circle("fill", hubX, hubY, 40)
    if self.coreIcon then
        love.graphics.setColor(1, 1, 1, .95)
        local scale = 56 / math.max(self.coreIcon:getWidth(), self.coreIcon:getHeight())
        love.graphics.draw(self.coreIcon, hubX, hubY, 0, scale, scale, self.coreIcon:getWidth() / 2, self.coreIcon:getHeight() / 2)
    end
    love.graphics.setFont(fonts.small); love.graphics.setColor(1, .9, .7)
    love.graphics.printf("사령부", hubX - 60, hubY + 48, 120, "center")

    self.hitboxes = {}
    local size = 52
    for _, node in ipairs(nodes) do
        local info = branchInfo[node.branch]
        local nx, ny = self:nodePosition(node, w, h)
        local level = self.progression:getLevel(node.id)
        local unlocked = isUnlocked(self.progression, node)
        local maxed = level >= node.max
        local owned = level > 0
        local selected = self.selected == node.id
        local x, y = nx - size / 2, ny - size / 2
        self.hitboxes[#self.hitboxes + 1] = {id = node.id, x = x, y = y, w = size, h = size}

        if owned then
            love.graphics.setColor(info.color[1], info.color[2], info.color[3], .22)
            love.graphics.circle("fill", nx, ny, size * .72)
        end
        love.graphics.setColor(unlocked and .1 or .06, unlocked and .07 or .045, unlocked and .05 or .035, .98)
        love.graphics.rectangle("fill", x, y, size, size, 10, 10)
        local ringColor = selected and {1, .85, .4} or info.color
        love.graphics.setColor(ringColor[1], ringColor[2], ringColor[3], unlocked and (owned and 1 or .7) or .25)
        love.graphics.setLineWidth(selected and 3 or (owned and 2.4 or 1.6))
        love.graphics.rectangle("line", x, y, size, size, 10, 10)

        local icon = self.icons[info.iconKey]
        if icon then
            love.graphics.setColor(1, 1, 1, unlocked and 1 or .3)
            local scale = (size - 16) / math.max(icon:getWidth(), icon:getHeight())
            love.graphics.draw(icon, nx, ny - 4, 0, scale, scale, icon:getWidth() / 2, icon:getHeight() / 2)
        end

        local pipY = y + size + 6
        love.graphics.setColor(.03, .02, .015, .9); love.graphics.rectangle("fill", x, pipY, size, 14, 4, 4)
        love.graphics.setFont(fonts.small)
        love.graphics.setColor(unlocked and 1 or .4, unlocked and .9 or .4, unlocked and .7 or .4, unlocked and 1 or .5)
        love.graphics.printf(maxed and "MAX" or (level .. "/" .. node.max), x, pipY - 1, size, "center")

        if not unlocked then
            love.graphics.setColor(0, 0, 0, .55); love.graphics.rectangle("fill", x, y, size, size, 10, 10)
            love.graphics.setFont(fonts.small); love.graphics.setColor(1, 1, 1, .6)
            love.graphics.printf("잠김", x, y + size / 2 - 8, size, "center")
        end
    end

    -- branch labels drawn last so they sit on top of any overlapping node tile
    for branch, info in ipairs(branchInfo) do
        local rad = math.rad(({190, -90, -20, 60, 130})[branch])
        local lx, ly = hubX + math.cos(rad) * 460, hubY + math.sin(rad) * 460 * .58
        love.graphics.setFont(fonts.small)
        love.graphics.setColor(0, 0, 0, .75); love.graphics.printf(info.name, lx - 89, ly - 7, 180, "center")
        love.graphics.setColor(info.color[1], info.color[2], info.color[3], 1); love.graphics.printf(info.name, lx - 90, ly - 8, 180, "center")
    end

    local selectedNode = self.progression:getNode(self.selected)
    if selectedNode then
        local level = self.progression:getLevel(selectedNode.id)
        local ok, reason = self.progression:status(selectedNode.id)
        local color = branchInfo[selectedNode.branch].color
        UI.panel(w / 2 - 280, h - 105, 560, 78, color, .97)
        love.graphics.setFont(fonts.body); love.graphics.setColor(1, 1, 1); love.graphics.print(selectedNode.name .. "  " .. level .. "/" .. selectedNode.max, w / 2 - 258, h - 90)
        love.graphics.setFont(fonts.small); love.graphics.setColor(.85, .82, .74); love.graphics.print(selectedNode.desc .. " / 클릭하여 강화", w / 2 - 258, h - 61)
        love.graphics.setColor(ok and {.4, 1, .58} or {.95, .58, .32}); love.graphics.printf(reason, w / 2 + 30, h - 90, 265, "right")
    end
    if self.messageTime > 0 then
        love.graphics.setFont(fonts.body); love.graphics.setColor(0, 0, 0, .8); love.graphics.printf(self.message, 2, 107, w, "center")
        love.graphics.setColor(1, .78, .3); love.graphics.printf(self.message, 0, 105, w, "center")
    end
end

return TraitTree
