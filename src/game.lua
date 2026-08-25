local Camera = require("src.camera")
local World = require("src.world")
local Player = require("src.player")
local Lobby = require("src.lobby")
local UI = require("src.ui")
local Progression = require("src.progression")
local TraitTree = require("src.trait_tree")
local Feedback = require("src.feedback")
local RunUpgrades = require("src.run_upgrades")
local Buildings = require("src.buildings")
local resourceLabels = {wood = "목재", stone = "돌", ore = "광석", food = "식량"}

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
    self.fonts, self.light, self.feedback = makeFonts(), radial(512), Feedback.new()
    self.settings = {fullscreen = love.window.getFullscreen(), screenShake = true}
    self.tools = {
        axe = {name = "나무 도끼", speed = .8, type = "벌목"},
        hoe = {name = "나무 괭이", speed = 1, type = "농사"},
        pickaxe = {name = "나무 곡괭이", speed = .75, type = "채광"},
        water = {name = "휴대 급수기", speed = 1, type = "농사 보조"},
        hammer = {name = "나무 수리 망치", speed = 1, type = "방벽 수리"}
    }
    self.wallCosts = {{wood = 0, stone = 0}, {wood = 12, stone = 8}, {wood = 22, stone = 16}, {wood = 36, stone = 28}}
    local temporaryProfile = os.getenv("LAST_HAUL_SELF_TEST") or os.getenv("LAST_HAUL_CAPTURE_META") or os.getenv("LAST_HAUL_CAPTURE_RESULTS") or os.getenv("LAST_HAUL_CAPTURE_TEST_OPTIONS")
    self.progression = Progression.new(temporaryProfile ~= nil)
    self.world = World.new(); self.lobby = Lobby.new(self.world.images, self.fonts)
    self.traitTree = TraitTree.new(self.progression, self.fonts, self.world.images, self.world.buildingIcons)
    self.mode, self.notice, self.noticeKind, self.noticeTime = "lobby", "", "core", 0
    self:resetRun(); self.mode = "lobby"
    return self
end

function Game:resetRun()
    self.world = World.new()
    self.player = Player.new(1600, 1470, self.world.images.workerWalk, self.world.images.workerActions, self.world.images.workerRepair)
    self.camera = Camera.new(self.player.x, self.player.y)
    self.camera.shakeScale = self.settings.screenShake and 1 or 0
    self.food, self.ore, self.wood, self.stone, self.seeds = 0, 0, 0, 0, 8
    self.time, self.ended, self.victory, self.hoverNode, self.hoverWall = 15 * 60, false, false, nil, false
    self.runStats, self.result = {harvested = 0}, nil
    self.upgrades, self.runLevel, self.runXP, self.runXPNext, self.pendingLevels = RunUpgrades.new(), 1, 0, 18, 0
    self.runXPVisual, self.runXPPulse, self.lastXPGain = 0, 0, 0
    local meta = self.progression:effects()
    self.player.gather = self.player.gather * meta.gather
    self.player.capacity = self.player.capacity + meta.capacity
    self.player.speed = self.player.speed * meta.move
    self.seeds, self.ore = self.seeds + meta.seeds, self.ore + meta.ore
    self.wood, self.stone = self.wood + meta.materials, self.stone + meta.materials
    self.world.core.damage = self.world.core.damage * meta.damage
    self.world.core.fireRate = self.world.core.fireRate * meta.fireRate
    self.world.wall.hpMultiplier, self.world.wall.damageReduction = meta.wallHp, meta.wallGuard
    self.world.wall.maxHp = math.floor(self.world.wall.maxHp * meta.wallHp + .5)
    self.world.wall.hp = self.world.wall.maxHp
    self.repairBonus, self.rewardMultiplier = meta.repair, meta.reward
    self.harvestBonus = meta.harvestBonus
    self.buildCostMultiplier = meta.buildCost
    self.metaFuelEfficiency = meta.fuelEff
    self.metaProduceBonus = meta.produceBonus
    self.world.core.maxHp = math.floor(self.world.core.maxHp * meta.coreHp + .5)
    self.world.core.hp = self.world.core.maxHp
    self.world.spawnTimer = self.world.spawnTimer + meta.prepTime
    if meta.startTurret then self.world:addBuilding("autocannon_turret", self.world.core.x - 130, self.world.core.y + 210) end
    if self.testGrantNextRun then self:grantTestRunResources(); self.testGrantNextRun = false end
    if (self.testLevelsNextRun or 0) > 0 then self:grantTestLevels(self.testLevelsNextRun); self.testLevelsNextRun = 0 end
end

function Game:startRun()
    self:resetRun(); self.mode = "playing"; self:setNotice("작전 시작 — 자원을 생산해 거점을 지키세요", "core")
    if self.pendingLevels > 0 then self.upgrades:rollChoices(self); self.mode = "upgrade" end
end
function Game:setNotice(text, kind) self.notice, self.noticeKind, self.noticeTime = text, kind or "core", 2.2 end

function Game:grantTestRunResources()
    self.food, self.ore, self.wood, self.stone, self.seeds = self.food + 1000000, self.ore + 1000000, self.wood + 1000000, self.stone + 1000000, self.seeds + 1000000
end

function Game:grantTestLevels(count)
    count = math.max(1, math.floor(count or 10))
    for _ = 1, count do self:addRunXP(math.max(0, self.runXPNext - self.runXP)) end
end

function Game:openTestOptions(returnMode)
    self.testReturnMode, self.mode, self.testMessage, self.testResetArmed, self.testResetTime = returnMode or self.mode, "test_options", "테스트 기능은 실제 저장 데이터에 반영됩니다.", false, 0
end

function Game:closeTestOptions()
    local target=self.testReturnMode or "lobby"
    self.mode=target
    if target=="playing" and self.pendingLevels>0 then self.upgrades:rollChoices(self); self.mode="upgrade" end
end

function Game:useTestOption(index)
    if index==1 then
        self.progression:addCurrency(1000000); self.testMessage="유산 부품 1,000,000개를 지급했습니다."
    elseif index==2 then
        if self.testReturnMode=="playing" or self.testReturnMode=="upgrade" then self:grantTestRunResources(); self.testMessage="현재 런 자원을 각각 1,000,000개 지급했습니다."
        else self.testGrantNextRun=true; self.testMessage="다음 런 자원 1,000,000개 지급을 예약했습니다." end
    elseif index==3 then
        if self.testReturnMode=="playing" or self.testReturnMode=="upgrade" then self:grantTestLevels(10); self.testMessage="생산 레벨 10회분을 지급했습니다. 메뉴를 닫으면 3택이 시작됩니다."
        else self.testLevelsNextRun=(self.testLevelsNextRun or 0)+10; self.testMessage="다음 런 생산 레벨 +10을 예약했습니다." end
    elseif index==4 then
        if self.testResetArmed and self.testResetTime>0 then self.progression:reset(); self.testResetArmed=false; self.testMessage="영구 재화와 모든 영구 특성을 초기화했습니다."
        else self.testResetArmed,self.testResetTime=true,4; self.testMessage="초기화하려면 4초 안에 버튼을 한 번 더 누르세요." end
    end
end

function Game:depositCargo(message)
    local total = self.player:totalCargo()
    if total <= 0 then return false end
    self.food, self.ore, self.wood, self.stone = self.food + self.player.food, self.ore + self.player.ore, self.wood + self.player.wood, self.stone + self.player.stone
    self.player.food, self.player.ore, self.player.wood, self.player.stone = 0, 0, 0, 0
    self:setNotice(message or "모든 자원을 거점에 납품했습니다", "core")
    return true
end

function Game:addRunXP(amount)
    amount = math.max(0, amount or 0)
    self.runXP = self.runXP + amount
    if amount > 0 then self.runXPPulse, self.lastXPGain = 1, amount end
    while self.runXP >= self.runXPNext do
        self.runXP = self.runXP - self.runXPNext
        self.runLevel, self.pendingLevels = self.runLevel + 1, self.pendingLevels + 1
        self.runXPNext = 18 + (self.runLevel - 1) * 10
    end
    if self.pendingLevels > 0 and self.mode == "playing" and not os.getenv("LAST_HAUL_SELF_TEST") then
        self.upgrades:rollChoices(self); self.mode = "upgrade"
    end
end

function Game:selectRunUpgrade(index)
    if self.mode ~= "upgrade" or not self.upgrades:choose(index, self) then return end
    self.pendingLevels = math.max(0, self.pendingLevels - 1)
    if self.pendingLevels > 0 then self.upgrades:rollChoices() else self.mode = "playing" end
end

function Game:finishRun(victory)
    if (self.mode ~= "playing" and self.mode ~= "upgrade") or self.result then return end
    self.ended, self.victory = true, victory == true
    local elapsed = math.floor(15 * 60 - self.time)
    local survival = math.floor(elapsed / 60)
    local waves = math.floor(self.world.wave / 5)
    local kills = math.floor(self.world.kills / 15)
    local harvest = math.floor((self.runStats.harvested or 0) / 25)
    local victoryBonus = self.victory and 12 or 0
    local base = math.max(2, survival + waves + kills + harvest + victoryBonus)
    local earned = math.floor(base * (self.rewardMultiplier or 1) + .5)
    self.progression:addCurrency(earned)
    self.result = {elapsed = elapsed, survival = survival, waves = waves, kills = kills, harvest = harvest, victory = victoryBonus, earned = earned}
    self.mode = "results"
end

function Game:update(dt)
    if self.mode == "lobby" then self.lobby:update(dt); return end
    if self.mode == "settings" then self.lobby:update(dt); return end
    if self.mode == "test_options" then self.testResetTime=math.max(0,(self.testResetTime or 0)-dt); if self.testResetTime<=0 then self.testResetArmed=false end; return end
    if self.mode == "meta" then self.traitTree:update(dt); return end
    if self.mode == "results" then return end
    if self.mode == "build_select" then return end
    self.runXPVisual = self.runXPVisual + (self.runXP - self.runXPVisual) * (1 - math.exp(-dt * 9))
    self.runXPPulse = math.max(0, self.runXPPulse - dt * 1.35)
    if self.mode == "upgrade" then return end
    self.noticeTime = math.max(0, self.noticeTime - dt)
    local wx, wy = self.camera:screenToWorld(love.mouse.getPosition()); self.hoverNode, self.hoverWall = self.world:findNodeAt(wx, wy), self.world:isWallAt(wx, wy)
    if self.ended then return end
    self.time = math.max(0, self.time - dt); if self.time <= 0 then self:finishRun(true); return end
    self.player:update(dt, self.world, self); self.upgrades:update(dt, self); self.world:update(dt, self); self.camera:update(dt, self.player, self.world)
    if self.ended then self:finishRun(self.victory) end
end

function Game:keypressed(key)
    if self.mode=="test_options" then if key=="escape" or key=="f10" then self:closeTestOptions() end; return end
    if key=="f10" then self:openTestOptions(self.mode); return end
    if self.mode == "lobby" then
        if key == "escape" then love.event.quit(); return end
        if key == "t" then self.mode = "meta"; return end
        if self.lobby:keypressed(key) == "start" then self:startRun() end; return
    end
    if self.mode == "settings" then if key == "escape" then self.mode = "lobby" end; return end
    if self.mode == "meta" then if self.traitTree:keypressed(key) == "back" then self.mode = "lobby" end; return end
    if self.mode == "upgrade" then if key == "1" or key == "2" or key == "3" then self:selectRunUpgrade(tonumber(key)) end; return end
    if self.mode == "build_select" then if key == "escape" then self.mode = "playing" end; return end
    if self.mode == "results" then
        if key == "t" then self.mode = "meta"
        elseif key == "return" or key == "escape" then self.mode = "lobby" end
        return
    end
    if key == "escape" and self.placingBuilding then self.placingBuilding = nil; self:setNotice("건설을 취소했습니다", "core"); return end
    if key == "escape" then self.mode = "lobby"; return end
    if self.ended and (key == "r" or key == "return") then self:startRun(); return end
    if key == "1" or key == "2" or key == "3" or key == "4" or key == "5" then self:useAbility(tonumber(key)) end
end

function Game:useAbility(index)
    if index == 1 and self.food >= 12 then self.food = self.food - 12; self.world:spawnDefender("bio", 1, self); self:setNotice("생체 수호자를 부화했습니다", "food") end
    if index == 2 then
        for _, def in ipairs(Buildings) do if def.id == "autocannon_turret" then self.placingBuilding = def; break end end
    end
    if index == 3 and self.food >= 8 and self.ore >= 8 then self.food, self.ore = self.food - 8, self.ore - 8; self.player.gather = self.player.gather * 1.15; self.player.capacity = self.player.capacity + 5; self:setNotice("작업 장비를 개조했습니다", "core") end
    if index == 4 then
        local wall = self.world.wall
        if wall.level < wall.maxLevel then
            local cost = self.wallCosts[wall.level + 1]
            if self.wood >= cost.wood and self.stone >= cost.stone then
                self.wood, self.stone = self.wood - cost.wood, self.stone - cost.stone
                self.world:upgradeWall(); self:setNotice("방어벽 " .. wall.level .. "단계 강화 완료", "core")
            else self:setNotice(string.format("방어벽 강화 필요: 목재 %d · 돌 %d", cost.wood, cost.stone), "core") end
        else self:setNotice("방어벽이 최고 단계입니다", "core") end
    end
    if index == 5 then self.mode = "build_select" end
end

function Game:mousepressed(x, y, button)
    if self.mode=="test_options" then
        if button==1 then
            local w=love.graphics.getWidth(); local bx=w/2-290
            if x>=bx and x<=bx+580 then
                if y>=220 and y<=278 then self:useTestOption(1)
                elseif y>=300 and y<=358 then self:useTestOption(2)
                elseif y>=380 and y<=438 then self:useTestOption(3)
                elseif y>=460 and y<=518 then self:useTestOption(4)
                elseif y>=550 and y<=596 then self:closeTestOptions() end
            end
        end
        return
    end
    if self.mode == "lobby" then
        local action = self.lobby:mousepressed(x, y, button)
        if action == "start" then self:startRun()
        elseif action == "meta" then self.mode = "meta"
        elseif action == "settings" then self.mode = "settings" end
        return
    end
    if self.mode == "settings" then
        if button == 1 then
            local w = love.graphics.getWidth()
            if x >= 28 and x <= 176 and y >= 25 and y <= 67 then self.mode = "lobby"
            elseif x >= w / 2 - 220 and x <= w / 2 + 220 and y >= 260 and y <= 316 then
                self.settings.screenShake = not self.settings.screenShake
                self.camera.shakeScale = self.settings.screenShake and 1 or 0
            elseif x >= w / 2 - 220 and x <= w / 2 + 220 and y >= 334 and y <= 390 then
                local nextValue = not self.settings.fullscreen
                local ok = love.window.setFullscreen(nextValue, "desktop")
                if ok ~= false then self.settings.fullscreen = nextValue end
            elseif x >= w / 2 - 220 and x <= w / 2 + 220 and y >= 408 and y <= 464 then
                self.progression:addCurrency(1000000)
            end
        end
        return
    end
    if self.mode == "meta" then if self.traitTree:mousepressed(x, y, button) == "back" then self.mode = "lobby" end; return end
    if self.mode == "upgrade" then if button == 1 then local index = self.upgrades:choiceAt(x, y); if index then self:selectRunUpgrade(index) end end; return end
    if self.mode == "build_select" then
        if button == 1 then
            if x >= 28 and x <= 176 and y >= 25 and y <= 67 then self.mode = "playing"; return end
            local index = self:buildCardAt(x, y)
            if index then self.placingBuilding = Buildings[index]; self.mode = "playing" end
        end
        return
    end
    if self.mode == "results" then
        if button == 1 then
            local w, h = love.graphics.getDimensions()
            if y >= h / 2 + 174 and y <= h / 2 + 224 then
                if x >= w / 2 - 240 and x <= w / 2 - 10 then self.mode = "lobby"
                elseif x >= w / 2 + 10 and x <= w / 2 + 240 then self.mode = "meta" end
            end
        end
        return
    end
    if self.ended then return end
    if self.placingBuilding then
        local wx, wy = self.camera:screenToWorld(x, y)
        local def = self.placingBuilding
        if button == 1 then
            if self.world:canPlaceBuilding(wx, wy, def.footprint) then
                local cost = self:buildingCost(def)
                local canAfford = true
                for res, amt in pairs(cost) do if (self[res] or 0) < amt then canAfford = false end end
                if canAfford then
                    for res, amt in pairs(cost) do self[res] = self[res] - amt end
                    self.world:addBuilding(def.id, wx, wy)
                    self:setNotice(def.name .. " 건설 완료", "core")
                    self.placingBuilding = nil
                else
                    local parts = {}
                    for res, amt in pairs(cost) do parts[#parts + 1] = resourceLabels[res] .. " " .. amt end
                    self:setNotice("자원 부족 — 필요: " .. table.concat(parts, " · "), "core")
                end
            else
                self:setNotice("여기엔 지을 수 없습니다", "core")
            end
        elseif button == 2 then
            self.placingBuilding = nil; self:setNotice("건설을 취소했습니다", "core")
        end
        return
    end
    if button ~= 1 then return end
    local hw, hh = love.graphics.getDimensions()
    local slotW, gap, startX, barY = 132, 8, hw / 2 - 346, hh - 92
    for i = 1, 5 do
        local sx = startX + (i - 1) * (slotW + gap)
        if x >= sx and x <= sx + slotW and y >= barY and y <= barY + 70 then self:useAbility(i); return end
    end
    local wx, wy = self.camera:screenToWorld(x, y)
    if self.world:isWallAt(wx, wy) then self.player:beginWallRepair(self.world, self); return end
    local node = self.world:findNodeAt(wx, wy)
    if node then self.player:beginInteraction(node, self.world, self) else self.player:cancelInteraction() end
end

function Game:wheelmoved(x, y)
    if self.mode ~= "playing" or y == 0 then return end
    if not (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then return end
    local factor = y > 0 and 1.1 or 1 / 1.1
    self.camera.zoom = math.max(.6, math.min(1.8, self.camera.zoom * factor))
end

function Game:buildingCost(def)
    local mult = self.buildCostMultiplier or 1
    local cost = {}
    for res, amt in pairs(def.cost) do cost[res] = math.max(1, math.floor(amt * mult + .5)) end
    return cost
end

function Game:buildCardAt(x, y)
    for i, box in ipairs(self.buildCardBoxes or {}) do
        if x >= box.x and x <= box.x + box.w and y >= box.y and y <= box.y + box.h then return i end
    end
end

function Game:drawBuildSelect()
    local w, h, f = love.graphics.getWidth(), love.graphics.getHeight(), self.fonts
    self.lobby:drawBackground(w, h)
    love.graphics.setColor(.018, .042, .034, .88); love.graphics.rectangle("fill", 0, 0, w, h)
    UI.button(28, 25, 148, 42, "← 나가기", true, f.body)
    love.graphics.setFont(f.title); love.graphics.setColor(.98, .98, .92); love.graphics.printf("건설", 0, 66, w, "center")
    love.graphics.setFont(f.small); love.graphics.setColor(.75, .83, .75)
    love.graphics.printf("자원을 소모해 생산 시설을 짓습니다 — 카드를 고르면 거점 안 원하는 위치에 배치합니다", 0, 108, w, "center")
    local cols, gap = 5, 14
    local cardW = math.min(206, (w - 80 - gap * (cols - 1)) / cols)
    local cardH = 214
    local startX, startY = w / 2 - (cardW * cols + gap * (cols - 1)) / 2, 150
    local mx, my = love.mouse.getPosition()
    self.buildCardBoxes = {}
    for i, def in ipairs(Buildings) do
        local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
        local x, y = startX + col * (cardW + gap), startY + row * (cardH + gap)
        self.buildCardBoxes[i] = {x = x, y = y, w = cardW, h = cardH}
        local hovered = mx >= x and mx <= x + cardW and my >= y and my <= y + cardH
        local cost = self:buildingCost(def)
        local canAfford = true
        for res, amt in pairs(cost) do if (self[res] or 0) < amt then canAfford = false end end
        UI.panel(x, y, cardW, cardH, canAfford and {.92, .58, .16, 1} or {.4, .42, .44, 1}, hovered and .97 or .9)
        local icon = self.world.buildingIcons[def.id]
        if icon then
            local scale = math.min(90, cardW * .48) / math.max(icon:getWidth(), icon:getHeight())
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(icon, x + cardW / 2, y + 66, 0, scale, scale, icon:getWidth() / 2, icon:getHeight() / 2)
        end
        love.graphics.setFont(f.body); love.graphics.setColor(.95, .96, .9); love.graphics.printf(def.name, x + 8, y + 122, cardW - 16, "center")
        love.graphics.setFont(f.small); love.graphics.setColor(.68, .76, .7); love.graphics.printf(def.desc, x + 10, y + 148, cardW - 20, "center")
        local parts = {}
        for res, amt in pairs(cost) do parts[#parts + 1] = resourceLabels[res] .. " " .. amt end
        love.graphics.setColor(canAfford and {.95, .8, .3, 1} or {1, .5, .45, 1})
        love.graphics.printf(table.concat(parts, " · "), x + 8, y + cardH - 24, cardW - 16, "center")
    end
end

function Game:draw()
    if self.mode=="test_options" then self:drawTestOptions(); return end
    if self.mode == "lobby" then self.lobby:draw(); return end
    if self.mode == "settings" then self:drawSettings(); return end
    if self.mode == "meta" then self.traitTree:draw(); return end
    if self.mode == "build_select" then self:drawBuildSelect(); return end
    love.graphics.clear(.08, .11, .12); self.camera:attach(); self.world:draw(self.player)
    local left, top, right, bottom = self.camera:visibleBounds()
    love.graphics.setBlendMode("screen", "alphamultiply"); love.graphics.setColor(.25, .34, .22, .13); love.graphics.rectangle("fill", left, top, right - left, bottom - top)
    local coreDx,coreDy=self.player.x-self.world.core.x,self.player.y-self.world.core.y
    local playerLight=coreDx*coreDx+coreDy*coreDy<400*400 and 1.45 or 2.2
    love.graphics.setBlendMode("add", "alphamultiply"); love.graphics.setColor(1, 1, 1, 1); love.graphics.draw(self.light, self.player.x, self.player.y, 0, playerLight, playerLight, 256, 256); love.graphics.draw(self.light, self.world.core.x, self.world.core.y, 0, 1.05, 1.05, 256, 256)
    love.graphics.setBlendMode("alpha")
    if self.placingBuilding then
        local def = self.placingBuilding
        local wx, wy = self.camera:screenToWorld(love.mouse.getPosition())
        local valid = self.world:canPlaceBuilding(wx, wy, def.footprint)
        love.graphics.setColor(valid and .4 or 1, valid and 1 or .3, valid and .5 or .3, .28)
        love.graphics.circle("fill", wx, wy, def.footprint / 2 + 8)
        love.graphics.setLineWidth(2); love.graphics.setColor(valid and .5 or 1, valid and 1 or .35, valid and .6 or .35, .8)
        love.graphics.circle("line", wx, wy, def.footprint / 2 + 8)
        local icon = self.world.buildingIcons[def.id]
        if icon then
            local scale = 78 / math.max(icon:getWidth(), icon:getHeight())
            love.graphics.setColor(1, 1, 1, valid and .9 or .5)
            love.graphics.draw(icon, wx, wy + 12, 0, scale, scale, icon:getWidth() / 2, icon:getHeight() * .91)
        end
    end
    self.camera:detach(); self:drawUI()
    if self.mode == "upgrade" then self.upgrades:drawSelection(self, self.fonts) end
    if self.mode == "results" then self:drawResults() end
    if self.placingBuilding then
        local w = love.graphics.getWidth()
        local def, f = self.placingBuilding, self.fonts
        local cost = self:buildingCost(def)
        local parts = {}
        for res, amt in pairs(cost) do parts[#parts + 1] = resourceLabels[res] .. " " .. amt end
        UI.panel(w / 2 - 220, 16, 440, 40, {.35, 1, .62, 1}, .92)
        love.graphics.setFont(f.small); love.graphics.setColor(1, 1, 1)
        love.graphics.printf(def.name .. " 배치 중 · 비용 " .. table.concat(parts, " · ") .. " · 클릭 배치 / 우클릭·ESC 취소", w / 2 - 220, 27, 440, "center")
    end
end

function Game:drawSettings()
    local w, h, f = love.graphics.getWidth(), love.graphics.getHeight(), self.fonts
    self.lobby:drawBackground(w, h)
    love.graphics.setColor(.018, .042, .034, .84); love.graphics.rectangle("fill", 0, 0, w, h)
    UI.button(28, 25, 148, 42, "← 로비", true, f.body)
    love.graphics.setFont(f.title); love.graphics.setColor(.98, .98, .92); love.graphics.printf("설정", 0, 88, w, "center")
    love.graphics.setFont(f.small); love.graphics.setColor(.75, .83, .75); love.graphics.printf("플레이 환경", 0, 137, w, "center")
    local x, boxW = w / 2 - 220, 440
    UI.button(x, 260, boxW, 56, "화면 흔들림  ·  " .. (self.settings.screenShake and "켜짐" or "꺼짐"), true, f.body)
    UI.button(x, 334, boxW, 56, "화면 모드  ·  " .. (self.settings.fullscreen and "전체 화면" or "창 모드"), true, f.body)
    UI.button(x, 408, boxW, 56, "테스트 — 유산 부품 +1,000,000", true, f.body)
    love.graphics.setFont(f.small); love.graphics.setColor(.78, .84, .62)
    love.graphics.printf("현재 보유 유산 부품: " .. self.progression.data.currency, 0, 470, w, "center")
    love.graphics.setColor(.72, .8, .73)
    love.graphics.printf("ESC로 로비로 돌아갑니다.", 0, math.min(h - 52, 498), w, "center")
end

function Game:drawTestOptions()
    local w,h,f=love.graphics.getWidth(),love.graphics.getHeight(),self.fonts
    love.graphics.clear(.055,.11,.105)
    love.graphics.setColor(.12,.28,.23,.32); for x=0,w,48 do love.graphics.line(x,0,x,h) end; for y=0,h,48 do love.graphics.line(0,y,w,y) end
    UI.panel(w/2-360,84,720,548,{.42,1,.6,1},.98)
    love.graphics.setFont(f.title); love.graphics.setColor(1,1,1); love.graphics.printf("테스트 옵션",w/2-330,105,660,"center")
    love.graphics.setFont(f.small); love.graphics.setColor(.62,.78,.72); love.graphics.printf("개발 중인 특성·생산·방어 시스템을 빠르게 확인하는 메뉴",w/2-330,153,660,"center")
    love.graphics.setColor(1,.72,.25); love.graphics.printf("보유 유산 부품  "..self.progression.data.currency,w/2-330,181,660,"center")
    local bx=w/2-290
    UI.button(bx,220,580,58,"유산 부품 +1,000,000",true,f.heading)
    UI.button(bx,300,580,58,"런 자원 각 +1,000,000  (식량·광석·목재·돌)",true,f.body)
    UI.button(bx,380,580,58,"생산 레벨 +10  (런 강화 3택 테스트)",true,f.body)
    UI.button(bx,460,580,58,self.testResetArmed and "정말 초기화 — 다시 클릭" or "영구 재화·특성 초기화",true,f.body)
    UI.button(bx,550,580,46,"돌아가기  [F10 / ESC]",true,f.body)
    love.graphics.setColor(self.testResetArmed and {1,.42,.25} or {.68,.82,.76}); love.graphics.printf(self.testMessage or "",w/2-315,525,630,"center")
end

function Game:drawResults()
    local w, h, f, r = love.graphics.getWidth(), love.graphics.getHeight(), self.fonts, self.result
    love.graphics.setColor(0, 0, 0, .84); love.graphics.rectangle("fill", 0, 0, w, h)
    UI.panel(w / 2 - 310, h / 2 - 245, 620, 490, r and r.victory > 0 and {.35, .94, .55, 1} or {.95, .4, .24, 1}, .98)
    love.graphics.setFont(f.title); love.graphics.setColor(1, 1, 1); love.graphics.printf(self.victory and "작전 생존 성공" or "방어벽 붕괴", w / 2 - 280, h / 2 - 214, 560, "center")
    love.graphics.setFont(f.small); love.graphics.setColor(.55, .67, .71); love.graphics.printf("회수 보고서 · 영구 재화 정산", w / 2 - 280, h / 2 - 166, 560, "center")
    local rows = {
        {"생존 시간", string.format("%02d:%02d", math.floor(r.elapsed / 60), r.elapsed % 60), r.survival},
        {"도달 웨이브", tostring(self.world.wave), r.waves}, {"처치", tostring(self.world.kills), r.kills},
        {"채집량", tostring(self.runStats.harvested), r.harvest}, {"15분 생존 보너스", self.victory and "달성" or "미달성", r.victory}
    }
    for i, row in ipairs(rows) do
        local y = h / 2 - 125 + (i - 1) * 42
        love.graphics.setColor(i % 2 == 0 and {.06, .085, .095, .8} or {.045, .065, .074, .8}); love.graphics.rectangle("fill", w / 2 - 260, y, 520, 35, 4, 4)
        love.graphics.setFont(f.small); love.graphics.setColor(.72, .8, .82); love.graphics.print(row[1], w / 2 - 242, y + 8)
        love.graphics.printf(row[2], w / 2 - 65, y + 8, 135, "right"); love.graphics.setColor(1, .7, .25); love.graphics.printf("+" .. row[3], w / 2 + 90, y + 8, 145, "right")
    end
    love.graphics.setFont(f.heading); love.graphics.setColor(1, .75, .25); love.graphics.printf("획득한 유산 부품  " .. r.earned, w / 2 - 260, h / 2 + 100, 520, "center")
    UI.button(w / 2 - 240, h / 2 + 174, 230, 50, "로비로  [ENTER]", true, f.body)
    UI.button(w / 2 + 10, h / 2 + 174, 230, 50, "특성 트리  [T]", true, f.body)
end

local function affordable(game, index)
    if index == 1 then return game.food >= 12 end
    if index == 2 then return game.ore >= 6 end
    if index == 3 then return game.food >= 8 and game.ore >= 8 end
    if index == 5 then return true end
    local wall = game.world.wall
    if wall.level >= wall.maxLevel then return false end
    local cost = game.wallCosts[wall.level + 1]
    return game.wood >= cost.wood and game.stone >= cost.stone
end

function Game:drawMinimap(x, y, w, h)
    UI.panel(x, y, w, h, {.35, .74, .82, 1}, .9)
    love.graphics.setColor(.55, .24, .19); love.graphics.rectangle("fill", x + 12, y + 26, w - 24, 26)
    love.graphics.setColor(.94, .58, .14); love.graphics.rectangle("fill", x + 12, y + 53, w - 24, 3)
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
    local order = {"axe", "hoe", "pickaxe", "hammer"}
    for i, key in ipairs(order) do
        local tool, rowY, active = self.tools[key], y + 35 + (i - 1) * 28, self.player.activeTool == key
        love.graphics.setColor(active and {.95, .62, .18, .95} or {.1, .14, .16, .9}); love.graphics.rectangle("fill", x + 12, rowY, w - 24, 23, 4, 4)
        love.graphics.setColor(active and {.08, .08, .07} or {.83, .88, .89}); love.graphics.print(tool.name, x + 22, rowY + 2)
        love.graphics.printf(string.format("속도 %.2fx", tool.speed * self.player.gather), x + 95, rowY + 2, w - 120, "right")
    end
end

function Game:drawUI()
    local w, h, f = love.graphics.getWidth(), love.graphics.getHeight(), self.fonts
    UI.panel(16, 16, 382, 142, {.25, .78, .88, 1})
    local m, s = math.floor(self.time / 60), math.floor(self.time % 60)
    love.graphics.setFont(f.big); love.graphics.setColor(1, 1, 1); love.graphics.print(string.format("%02d:%02d", m, s), 32, 27)
    love.graphics.setFont(f.body); love.graphics.setColor(.76, .84, .87); love.graphics.print(string.format("웨이브 %02d   처치 %03d", self.world.wave, self.world.kills), 152, 35)
    love.graphics.setFont(f.small); love.graphics.setColor(.4, .95, .62); love.graphics.print("보급 센터  가동 중", 32, 72)
    local wall = self.world.wall
    love.graphics.setColor(.76, .84, .87); love.graphics.print(string.format("방어벽 %d단계  %d / %d", wall.level, math.floor(wall.hp), wall.maxHp), 32, 98)
    UI.bar(32, 122, 348, 12, wall.hp / wall.maxHp, wall.level == 4 and {.18, .86, 1, 1} or {.94, .58, .14, 1})

    local hx, hy, hw = w - 334, 16, 318
    UI.panel(hx, hy, hw, 150, {.92, .58, .16, 1})
    love.graphics.setFont(f.small); love.graphics.setColor(.58, .68, .71); love.graphics.print("거점 창고", hx + 16, hy + 10)
    local resources = {
        {img = self.world.images.crop, label = "식량", color = {.45, .95, .48}, value = self.food},
        {img = self.world.images.ore, label = "광석", color = {.35, .78, 1}, value = self.ore},
        {img = self.world.images.lumber, label = "목재", color = {.9, .68, .35}, value = self.wood},
        {img = self.world.images.stone, label = "돌", color = {.75, .78, .8}, value = self.stone},
        {img = nil, label = "씨앗", color = {.95, .78, .25}, value = self.seeds}
    }
    local chipW, chipH, gap, chipX0, chipY = 53, 58, 6, hx + 14, hy + 32
    for i, res in ipairs(resources) do
        local cx = chipX0 + (i - 1) * (chipW + gap)
        love.graphics.setColor(.08, .11, .13, .9); love.graphics.rectangle("fill", cx, chipY, chipW, chipH, 6, 6)
        love.graphics.setColor(1, 1, 1, .1); love.graphics.setLineWidth(1); love.graphics.rectangle("line", cx, chipY, chipW, chipH, 6, 6)
        love.graphics.setColor(1, 1, 1, 1)
        if res.img then
            local scale = 30 / math.max(res.img:getWidth(), res.img:getHeight())
            love.graphics.draw(res.img, cx + chipW / 2, chipY + 21, 0, scale, scale, res.img:getWidth() / 2, res.img:getHeight() / 2)
        else
            love.graphics.setColor(res.color)
            for d = -1, 1 do love.graphics.circle("fill", cx + chipW / 2 + d * 7, chipY + 21, 3) end
        end
        love.graphics.setFont(f.small); love.graphics.setColor(res.color)
        love.graphics.printf(tostring(res.value), cx, chipY + chipH - 20, chipW, "center")
    end
    local barY = chipY + chipH + 12
    love.graphics.setFont(f.small); love.graphics.setColor(.78, .84, .86)
    love.graphics.print(string.format("가방  %d / %d", self.player:totalCargo(), self.player.capacity), hx + 14, barY)
    UI.bar(hx + 14, barY + 20, hw - 28, 10, self.player:totalCargo() / self.player.capacity, {.96, .64, .18, 1})

    UI.panel(w / 2 - 105, 16, 210, 44, {.78, .2, .18, 1}, .86)
    love.graphics.setFont(f.body); love.graphics.setColor(1, .82, .72); love.graphics.printf(self.world.spawnTimer > 0 and string.format("다음 웨이브 %.1f초", self.world.spawnTimer) or "웨이브 접근 중", w / 2 - 105, 27, 210, "center")
    love.graphics.setFont(f.small); love.graphics.setColor(.08, .12, .12, .9); love.graphics.rectangle("fill", w / 2 - 105, 64, 210, 50, 5, 5)
    love.graphics.setColor(.52, 1, .63); love.graphics.printf(string.format("생산 레벨 %d", self.runLevel), w / 2 - 105, 74, 210, "center")
    local droneCount=0; for _,defender in ipairs(self.world.defenders) do if defender.kind=="drone" then droneCount=droneCount+1 end end
    local turretCount=0; for _,b in ipairs(self.world.buildings) do if b.kind=="autocannon_turret" or b.kind=="rail_turret" or b.kind=="blade_turret" then turretCount=turretCount+1 end end
    love.graphics.setColor(.55,.82,.86); love.graphics.printf(string.format("배치 포탑 %d   전투 드론 %d",turretCount,droneCount),w/2-105,96,210,"center")

    self:drawMinimap(16, h - 158, 205, 142); self:drawToolBelt(w - 276, h - 158, 260, 142)
    local nextWall = wall.level < wall.maxLevel and self.wallCosts[wall.level + 1] or nil
    local wallCostText = nextWall and string.format("목%d 돌%d", nextWall.wood, nextWall.stone) or "최고 단계"
    local abilities = {{"1", "수호자", "식량 12"}, {"2", "포탑", "광석 6"}, {"3", "장비", "식8 광8"}, {"4", "방벽강화", wallCostText}, {"5", "건설", "건물 배치"}}
    local total, slotW, gap, startX, barY = 692, 132, 8, w / 2 - 346, h - 92
    for i, ability in ipairs(abilities) do
        local x, ready = startX + (i - 1) * (slotW + gap), affordable(self, i)
        UI.panel(x, barY, slotW, 70, ready and {.92, .58, .16, 1} or {.25, .3, .32, 1}, .94)
        love.graphics.setFont(f.heading); love.graphics.setColor(ready and 1 or .48, ready and .7 or .53, ready and .25 or .55); love.graphics.print("[" .. ability[1] .. "]", x + 10, barY + 9)
        love.graphics.setFont(f.body); love.graphics.setColor(ready and 1 or .5, ready and 1 or .54, ready and 1 or .56); love.graphics.print(ability[2], x + 48, barY + 11)
        love.graphics.setFont(f.small); love.graphics.setColor(.56, .68, .71); love.graphics.print(ability[3], x + 48, barY + 39)
    end

    local promptNode = self.player.interactionTarget or self.hoverNode
    if self.player.repairingWall or self.hoverWall then
        local distance = math.abs(self.player.y - self.world.wall.y)
        local text = self.player.repairingWall and "나무 수리 망치 사용 중 · 타격당 목재 1 + 돌 1" or (distance <= 185 and "클릭 — 방어벽 직접 수리" or "방어벽에 더 가까이 이동하세요")
        UI.panel(w / 2 - 200, h - 142, 400, 40, {.95, .62, .18, 1}, .9)
        love.graphics.setFont(f.small); love.graphics.setColor(1, 1, 1); love.graphics.printf(text, w / 2 - 200, h - 132, 400, "center")
    elseif promptNode then
        local tool, label = self.world:getInteraction(promptNode, self)
        local distance = math.sqrt((promptNode.x - self.player.x)^2 + (promptNode.y - self.player.y)^2)
        local text = self.player.interactionTarget and ((self.tools[self.player.activeTool] and self.tools[self.player.activeTool].name or "도구") .. " 사용 중") or (distance <= 180 and ("클릭 — " .. (label or "상호작용")) or "더 가까이 이동하세요")
        UI.panel(w / 2 - 170, h - 142, 340, 40, {.32, .83, .9, 1}, .9)
        love.graphics.setFont(f.small); love.graphics.setColor(1, 1, 1); love.graphics.printf(text, w / 2 - 170, h - 132, 340, "center")
    end

    if self.noticeTime > 0 then
        local color = self.noticeKind == "food" and {.36, .95, .44, 1} or self.noticeKind == "ore" and {.36, .78, 1, 1} or {1, .68, .2, 1}
        love.graphics.setFont(f.body); love.graphics.setColor(0, 0, 0, .7); love.graphics.printf(self.notice, 2, 177, w, "center"); love.graphics.setColor(color); love.graphics.printf(self.notice, 0, 175, w, "center")
    end

    local xpRatio = math.max(0, math.min(1, self.runXPVisual / self.runXPNext))
    love.graphics.setColor(.025, .07, .08, .96); love.graphics.rectangle("fill", 0, h - 7, w, 7)
    love.graphics.setColor(.3, .92, .58, 1); love.graphics.rectangle("fill", 0, h - 6, w * xpRatio, 6)
    love.graphics.setColor(.74, 1, .66, .8); love.graphics.rectangle("fill", 0, h - 6, w * xpRatio, 2)
    if self.runXPPulse > 0 then
        local headX = w * xpRatio
        love.graphics.setBlendMode("add", "alphamultiply")
        love.graphics.setColor(.45, 1, .67, self.runXPPulse); love.graphics.circle("fill", headX, h - 4, 10 + 8 * self.runXPPulse)
        love.graphics.setBlendMode("alpha")
        love.graphics.setFont(f.small); love.graphics.setColor(.78, 1, .72, self.runXPPulse)
        love.graphics.printf("+" .. math.floor(self.lastXPGain) .. " XP", math.max(4, math.min(w - 72, headX - 34)), h - 28, 68, "center")
    end
    love.graphics.setFont(f.small); love.graphics.setColor(.9, 1, .92, .88)
    love.graphics.printf(string.format("생산 Lv.%d   %d / %d", self.runLevel, math.floor(self.runXP), self.runXPNext), w / 2 - 100, h - 27, 200, "center")
end

return Game
