local Camera = require("src.camera")
local World = require("src.world")
local Player = require("src.player")
local Lobby = require("src.lobby")
local UI = require("src.ui")

local Game = {}
Game.__index = Game

local function radial(size)
    local data, c = love.image.newImageData(size, size), (size - 1) / 2
    data:mapPixel(function(x, y) local d = math.min(1, math.sqrt((x - c)^2 + (y - c)^2) / c); return 1, .82, .55, (1 - d)^2 * .34 end)
    local img = love.graphics.newImage(data); img:setFilter("linear", "linear"); return img
end

local function makeFonts()
    local path = "assets/font-korean.ttf"
    return {small = love.graphics.newFont(path, 14), body = love.graphics.newFont(path, 17), heading = love.graphics.newFont(path, 21), big = love.graphics.newFont(path, 28), title = love.graphics.newFont(path, 36)}
end

function Game.new()
    local self = setmetatable({}, Game)
    self.fonts, self.light = makeFonts(), radial(512)
    self.tools = {
        axe = {name = "나무 도끼", speed = .8, type = "벌목"},
        hoe = {name = "나무 괭이", speed = 1, type = "농사"},
        pickaxe = {name = "나무 곡괭이", speed = .75, type = "채광"},
        water = {name = "휴대 급수기", speed = 1, type = "농사 보조"}
    }
    self.world = World.new(); self.lobby = Lobby.new(self.world.images, self.fonts)
    self.mode, self.notice, self.noticeKind, self.noticeTime = "lobby", "", "core", 0
    self:resetRun(2); self.mode = "lobby"
    return self
end

function Game:resetRun(plan)
    self.world = World.new()
    self.player = Player.new(1600, 1530, self.world.images.workerWalk, self.world.images.workerActions)
    self.camera = Camera.new(self.player.x, self.player.y)
    self.food, self.ore, self.wood, self.stone, self.seeds = 0, 0, 0, 0, 8
    self.time, self.ended, self.victory, self.hoverNode = 15 * 60, false, false, nil
    self.plan = plan or 2
    if self.plan == 1 then self.food, self.seeds = 12, 12; self.world.core.maxHp, self.world.core.hp = 550, 550 end
    if self.plan == 2 then self.ore = 14; self.world.core.damage = self.world.core.damage * 1.15 end
    if self.plan == 3 then self.player.capacity, self.player.gather = 23, 1.15 end
end

function Game:startRun(plan) self:resetRun(plan); self.mode = "playing"; self:setNotice("작전 시작 — 자원을 생산해 거점을 지키세요", "core") end
function Game:setNotice(text, kind) self.notice, self.noticeKind, self.noticeTime = text, kind or "core", 2.2 end

function Game:update(dt)
    if self.mode == "lobby" then self.lobby:update(dt); return end
    self.noticeTime = math.max(0, self.noticeTime - dt)
    local wx, wy = self.camera:screenToWorld(love.mouse.getPosition()); self.hoverNode = self.world:findNodeAt(wx, wy)
    if self.ended then return end
    self.time = math.max(0, self.time - dt); if self.time <= 0 then self.ended, self.victory = true, true end
    self.player:update(dt, self.world, self); self.world:update(dt, self); self.camera:update(dt, self.player, self.world)
end

function Game:keypressed(key)
    if self.mode == "lobby" then
        if key == "escape" then love.event.quit(); return end
        local plan = self.lobby:keypressed(key); if plan then self:startRun(plan) end; return
    end
    if key == "escape" then self.mode = "lobby"; return end
    if self.ended and (key == "r" or key == "return") then self:startRun(self.plan); return end
    if key == "1" and self.food >= 12 then self.food = self.food - 12; self.world.defenders[#self.world.defenders + 1] = {x = self.world.core.x + love.math.random(-110, 110), y = self.world.core.y - 130}; self:setNotice("생체 수호자를 부화했습니다", "food") end
    if key == "2" and self.ore >= 14 then self.ore = self.ore - 14; self.world.core.damage = self.world.core.damage * 1.2; self.world.core.fireRate = self.world.core.fireRate * 1.05; self:setNotice("포탑 기술을 강화했습니다", "ore") end
    if key == "3" and self.food >= 8 and self.ore >= 8 then self.food, self.ore = self.food - 8, self.ore - 8; self.player.gather = self.player.gather * 1.15; self.player.capacity = self.player.capacity + 5; self:setNotice("작업 장비를 개조했습니다", "core") end
    if key == "4" and self.ore >= 10 then self.ore = self.ore - 10; self.world.core.hp = math.min(self.world.core.maxHp, self.world.core.hp + 85); self:setNotice("거점을 수리했습니다", "ore") end
end

function Game:mousepressed(x, y, button)
    if self.mode == "lobby" then local plan = self.lobby:mousepressed(x, y, button); if plan then self:startRun(plan) end; return end
    if button ~= 1 or self.ended then return end
    local wx, wy = self.camera:screenToWorld(x, y)
    local node = self.world:findNodeAt(wx, wy)
    if node then self.player:beginInteraction(node, self.world, self) else self.player:cancelInteraction() end
end

function Game:draw()
    if self.mode == "lobby" then self.lobby:draw(); return end
    love.graphics.clear(.015, .02, .025); self.camera:attach(); self.world:draw(self.player)
    local left, top, right, bottom = self.camera:visibleBounds(); love.graphics.setColor(.015, .025, .035, .12); love.graphics.rectangle("fill", left, top, right - left, bottom - top)
    love.graphics.setBlendMode("add", "alphamultiply"); love.graphics.setColor(1, 1, 1, 1); love.graphics.draw(self.light, self.player.x, self.player.y, 0, 2.5, 2.5, 256, 256); love.graphics.draw(self.light, self.world.core.x, self.world.core.y, 0, 1.8, 1.8, 256, 256)
    love.graphics.setBlendMode("alpha"); self.camera:detach(); self:drawUI()
end

local function affordable(game, index)
    if index == 1 then return game.food >= 12 end
    if index == 2 then return game.ore >= 14 end
    if index == 3 then return game.food >= 8 and game.ore >= 8 end
    return game.ore >= 10
end

function Game:drawMinimap(x, y, w, h)
    UI.panel(x, y, w, h, {.35, .74, .82, 1}, .9)
    love.graphics.setColor(.55, .24, .19); love.graphics.rectangle("fill", x + 12, y + 26, w - 24, 26)
    love.graphics.setColor(.24, .5, .27); love.graphics.rectangle("fill", x + 12, y + 56, (w - 24) * .39, h - 68)
    love.graphics.setColor(.19, .39, .57); love.graphics.rectangle("fill", x + 12 + (w - 24) * .61, y + 56, (w - 24) * .39, h - 68)
    local function point(wx, wy, color, radius) love.graphics.setColor(color); love.graphics.circle("fill", x + 12 + wx / self.world.width * (w - 24), y + 26 + wy / self.world.height * (h - 38), radius) end
    point(self.world.core.x, self.world.core.y, {.98, .65, .18}, 4); point(self.player.x, self.player.y, {.35, .95, 1}, 4)
    for _, enemy in ipairs(self.world.enemies) do point(enemy.x, enemy.y, {.95, .2, .18}, 2) end
    love.graphics.setFont(self.fonts.small); love.graphics.setColor(.8, .86, .88); love.graphics.print("작전 지도", x + 12, y + 5)
end

function Game:drawToolBelt(x, y, w, h)
    UI.panel(x, y, w, h, {.92, .58, .16, 1}, .94)
    love.graphics.setFont(self.fonts.small); love.graphics.setColor(.57, .68, .71); love.graphics.print("기본 도구 · 대상 클릭 시 자동 사용", x + 14, y + 9)
    local order = {"axe", "hoe", "pickaxe"}
    for i, key in ipairs(order) do
        local tool, rowY, active = self.tools[key], y + 35 + (i - 1) * 28, self.player.activeTool == key
        love.graphics.setColor(active and {.95, .62, .18, .95} or {.1, .14, .16, .9}); love.graphics.rectangle("fill", x + 12, rowY, w - 24, 23, 4, 4)
        love.graphics.setColor(active and {.08, .08, .07} or {.83, .88, .89}); love.graphics.print(tool.name, x + 22, rowY + 2)
        love.graphics.printf(string.format("속도 %.2fx", tool.speed * self.player.gather), x + 95, rowY + 2, w - 120, "right")
    end
end

function Game:drawUI()
    local w, h, f = love.graphics.getWidth(), love.graphics.getHeight(), self.fonts
    UI.panel(16, 16, 382, 116, {.25, .78, .88, 1})
    local m, s = math.floor(self.time / 60), math.floor(self.time % 60)
    love.graphics.setFont(f.big); love.graphics.setColor(1, 1, 1); love.graphics.print(string.format("%02d:%02d", m, s), 32, 27)
    love.graphics.setFont(f.body); love.graphics.setColor(.76, .84, .87); love.graphics.print(string.format("웨이브 %02d   처치 %03d", self.world.wave, self.world.kills), 152, 35)
    love.graphics.setFont(f.small); love.graphics.print(string.format("보급 거점  %d / %d", math.max(0, math.floor(self.world.core.hp)), self.world.core.maxHp), 32, 72)
    UI.bar(32, 96, 348, 13, self.world.core.hp / self.world.core.maxHp, {.2, .82, .58, 1})

    UI.panel(w - 334, 16, 318, 122, {.92, .58, .16, 1})
    love.graphics.setFont(f.small); love.graphics.setColor(.58, .68, .71); love.graphics.print("거점 창고", w - 316, 27)
    love.graphics.setColor(.45, .95, .48); love.graphics.print("식량 " .. self.food, w - 316, 51); love.graphics.setColor(.35, .78, 1); love.graphics.print("광석 " .. self.ore, w - 240, 51)
    love.graphics.setColor(.9, .68, .35); love.graphics.print("목재 " .. self.wood, w - 164, 51); love.graphics.setColor(.75, .78, .8); love.graphics.print("돌 " .. self.stone, w - 88, 51)
    love.graphics.setColor(.95, .78, .25); love.graphics.print("씨앗 " .. self.seeds, w - 316, 76)
    love.graphics.setColor(.78, .84, .86); love.graphics.print(string.format("가방 %d / %d", self.player:totalCargo(), self.player.capacity), w - 222, 76)
    UI.bar(w - 316, 103, 282, 10, self.player:totalCargo() / self.player.capacity, {.96, .64, .18, 1})

    UI.panel(w / 2 - 105, 16, 210, 44, {.78, .2, .18, 1}, .86)
    love.graphics.setFont(f.body); love.graphics.setColor(1, .82, .72); love.graphics.printf(self.world.spawnTimer > 0 and string.format("다음 웨이브 %.1f초", self.world.spawnTimer) or "웨이브 접근 중", w / 2 - 105, 27, 210, "center")

    self:drawMinimap(16, h - 158, 205, 142); self:drawToolBelt(w - 276, h - 158, 260, 142)
    local abilities = {{"1", "수호자", "식량 12"}, {"2", "포탑", "광석 14"}, {"3", "장비", "식량8 광석8"}, {"4", "수리", "광석 10"}}
    local total, slotW, gap, startX, barY = 552, 132, 8, w / 2 - 276, h - 92
    for i, ability in ipairs(abilities) do
        local x, ready = startX + (i - 1) * (slotW + gap), affordable(self, i)
        UI.panel(x, barY, slotW, 70, ready and {.92, .58, .16, 1} or {.25, .3, .32, 1}, .94)
        love.graphics.setFont(f.heading); love.graphics.setColor(ready and 1 or .48, ready and .7 or .53, ready and .25 or .55); love.graphics.print("[" .. ability[1] .. "]", x + 10, barY + 9)
        love.graphics.setFont(f.body); love.graphics.setColor(ready and 1 or .5, ready and 1 or .54, ready and 1 or .56); love.graphics.print(ability[2], x + 48, barY + 11)
        love.graphics.setFont(f.small); love.graphics.setColor(.56, .68, .71); love.graphics.print(ability[3], x + 48, barY + 39)
    end

    local promptNode = self.player.interactionTarget or self.hoverNode
    if promptNode then
        local tool, label = self.world:getInteraction(promptNode, self)
        local distance = math.sqrt((promptNode.x - self.player.x)^2 + (promptNode.y - self.player.y)^2)
        local text = self.player.interactionTarget and ((self.tools[self.player.activeTool] and self.tools[self.player.activeTool].name or "도구") .. " 사용 중") or (distance <= 180 and ("클릭 — " .. (label or "상호작용")) or "더 가까이 이동하세요")
        UI.panel(w / 2 - 170, h - 142, 340, 40, {.32, .83, .9, 1}, .9)
        love.graphics.setFont(f.small); love.graphics.setColor(1, 1, 1); love.graphics.printf(text, w / 2 - 170, h - 132, 340, "center")
    end

    if self.noticeTime > 0 then
        local color = self.noticeKind == "food" and {.36, .95, .44, 1} or self.noticeKind == "ore" and {.36, .78, 1, 1} or {1, .68, .2, 1}
        love.graphics.setFont(f.body); love.graphics.setColor(0, 0, 0, .7); love.graphics.printf(self.notice, 2, 153, w, "center"); love.graphics.setColor(color); love.graphics.printf(self.notice, 0, 151, w, "center")
    end
    if self.ended then
        love.graphics.setColor(0, 0, 0, .82); love.graphics.rectangle("fill", 0, 0, w, h); love.graphics.setFont(f.title); love.graphics.setColor(1, 1, 1); love.graphics.printf(self.victory and "15분 생존 성공" or "보급 거점 파괴", 0, h / 2 - 60, w, "center"); love.graphics.setFont(f.body); love.graphics.setColor(.72, .8, .82); love.graphics.printf("ENTER를 눌러 다시 시작", 0, h / 2 + 8, w, "center")
    end
end

return Game
