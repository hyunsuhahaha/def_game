local UI = require("src.ui")

local RunUpgrades = {}
RunUpgrades.__index = RunUpgrades

local definitions = {
    {id="explosive_payload", name="폭발 탄두", category="passive", max=5, color={1,.42,.2}, tags={"폭발","포탑"}, desc="포탑 명중 지점에 범위 피해를 줍니다."},
    {id="chain_coil", name="연쇄 코일", category="passive", max=5, color={.48,.78,1}, tags={"전기","포탑"}, desc="포탑 공격이 주변 적에게 연쇄됩니다."},

    {id="protein_feed", name="고단백 사료", category="passive", max=5, color={.72,1,.55}, tags={"생명","증식"}, desc="수호자 생산과 공격 속도가 빨라집니다."},
    {id="super_magnet", name="초전도 자석", category="passive", max=5, color={.44,.9,1}, tags={"채광","자기장"}, desc="광석 생산량과 레일 포격이 강화됩니다."},
    {id="high_motor", name="고성능 모터", category="passive", max=5, color={1,.68,.3}, tags={"벌목","기계"}, desc="목재 생산과 톱날 속도가 증가합니다."},
    {id="production_clock", name="과급 생산축", category="passive", max=5, color={1,.8,.3}, tags={"생산","속도"}, desc="모든 자동 생산 주기가 빨라집니다."},
    {id="cargo_frame", name="확장 적재함", category="passive", max=5, color={.72,.9,.92}, tags={"운반","가방"}, desc="가방 용량이 3 증가합니다."},
    {id="field_boots", name="현장 기동화", category="passive", max=5, color={.75,1,.75}, tags={"이동","탐사"}, desc="이동 속도가 6% 증가합니다."},
    {id="recycler", name="자원 복제기", category="passive", max=5, color={.82,.65,1}, tags={"자원","복제"}, desc="채집 자원을 복제할 확률이 생깁니다."},
    {id="wide_lens", name="장거리 조준경", category="passive", max=5, color={.62,.82,1}, tags={"포탑","사거리"}, desc="거점 포탑 사거리가 증가합니다."},

    {id="eternal_farm", name="영원의 농장", category="evolution", max=1, color={.55,1,.32}, tags={"진화","농업"}, desc="모든 작물 성장이 가속되고 식량이 폭발적으로 생산됩니다.", base="auto_farm", passive="protein_feed"},
    {id="planet_drill", name="행성 굴착기", category="evolution", max=1, color={.25,.9,1}, tags={"진화","채광"}, desc="광역 채굴 때마다 초대형 레일포를 발사합니다.", base="mining_drone", passive="super_magnet"},
    {id="forest_shredder", name="산림 분쇄기", category="evolution", max=1, color={1,.55,.16}, tags={"진화","벌목"}, desc="숲을 자동 분쇄하고 거대한 톱날 폭풍을 만듭니다.", base="logging_bot", passive="high_motor"},

    {id="wood_gain", name="벌목 효율 강화", category="passive", max=5, color={.4,.43,.46}, tags={"자원","목재"}, resource="wood", resourceLabel="목재", desc="목재 획득량이 증가합니다."},
    {id="stone_gain", name="채석 효율 강화", category="passive", max=5, color={.4,.43,.46}, tags={"자원","채석"}, resource="stone", resourceLabel="돌", desc="돌 획득량이 증가합니다."},
    {id="ore_refine", name="정제 효율 강화", category="passive", max=5, color={.4,.43,.46}, tags={"자원","채광"}, resource="ore", resourceLabel="광석", desc="광석 획득량이 증가합니다."},
    {id="food_gain", name="수확 효율 강화", category="passive", max=5, color={.4,.43,.46}, tags={"자원","농업"}, resource="food", resourceLabel="식량", desc="식량 획득량이 증가합니다."},
    {id="farm_speed", name="속성 재배 기술", category="passive", max=5, color={.4,.43,.46}, tags={"농업","속도"}, resource="farmSpeed", resourceLabel="작물 성장 속도", desc="작물 성장 속도가 증가합니다."},
    {id="fuel_efficiency", name="연료 효율 강화", category="passive", max=5, color={.4,.43,.46}, tags={"포탑","연료"}, resource="fuelEfficiency", resourceLabel="포탑 연료 효율", desc="포탑류 건물의 연료 소모가 줄고 재충전이 빨라집니다."}
}

local byId = {}
for _, definition in ipairs(definitions) do byId[definition.id] = definition end

local rarities = {
    {id="normal", name="노멀", color={.4,.43,.46,1}, weight=44, percent=.06},
    {id="rare", name="레어", color={.35,.62,1,1}, weight=27, percent=.12},
    {id="epic", name="에픽", color={.72,.38,1,1}, weight=16, percent=.20},
    {id="unique", name="유니크", color={1,.55,.18,1}, weight=9, percent=.32},
    {id="legendary", name="레전더리", color={1,.84,.25,1}, weight=4, percent=.50}
}
local legendary = rarities[#rarities]

local function rollRarity()
    local total = 0
    for _, tier in ipairs(rarities) do total = total + tier.weight end
    local roll = love.math.random() * total
    for _, tier in ipairs(rarities) do
        roll = roll - tier.weight
        if roll <= 0 then return tier end
    end
    return rarities[1]
end

function RunUpgrades.new()
    local icons = {}
    for _, def in ipairs(definitions) do
        local path = "assets/upgrades/" .. def.id .. ".png"
        if love.filesystem.getInfo(path) then
            icons[def.id] = love.graphics.newImage(path)
            icons[def.id]:setFilter("linear", "linear", 4)
        end
    end
    local lightBackgroundShader = love.graphics.newShader([[
        vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords) {
            vec4 pixel = Texel(texture, textureCoords);
            float hi = max(pixel.r, max(pixel.g, pixel.b));
            float lo = min(pixel.r, min(pixel.g, pixel.b));
            if (pixel.a > .99 && lo > .88 && hi - lo < .035) pixel.a = 0.0;
            return pixel * color;
        }
    ]])
    return setmetatable({levels={}, choices={}, passiveCount=0, timers={}, icons=icons, lightBackgroundShader=lightBackgroundShader, maxPassives=9, resourcePct={wood=0, stone=0, ore=0, food=0, farmSpeed=0, fuelEfficiency=0}}, RunUpgrades)
end

function RunUpgrades:level(id) return self.levels[id] or 0 end
function RunUpgrades:get(id) return byId[id] end

local function buildingCount(game, kind)
    if not (game and game.world and game.world.buildings) then return 0 end
    local count = 0
    for _, building in ipairs(game.world.buildings) do if building.kind == kind then count = count + 1 end end
    return count
end

function RunUpgrades:isEvolutionReady(def, game)
    return def.category == "evolution" and self:level(def.id) == 0 and buildingCount(game, def.base) >= 5 and self:level(def.passive) >= 1
end

function RunUpgrades:canOffer(def, game)
    if def.category == "evolution" then return self:isEvolutionReady(def, game) end
    local level = self:level(def.id)
    if level >= def.max then return false end
    if level > 0 then return true end
    return self.passiveCount < self.maxPassives
end

local function cloneWithRarity(def, rarity)
    local choice = {}
    for k, v in pairs(def) do choice[k] = v end
    choice.rarity = rarity
    if def.resource then
        choice.color = rarity.color
        choice.gainPercent = rarity.percent
        local percentText = math.floor(rarity.percent * 100)
        choice.desc = def.resource == "farmSpeed" and string.format("작물 성장 속도가 %d%% 증가합니다.", percentText)
            or def.resource == "fuelEfficiency" and string.format("포탑 연료 효율이 %d%% 증가합니다 (소모 감소·재충전 증가).", percentText)
            or string.format("%s 획득량이 %d%% 증가합니다.", def.resourceLabel, percentText)
    end
    return choice
end

function RunUpgrades:rollChoices(game)
    local pool, evolutions = {}, {}
    for _, def in ipairs(definitions) do
        if self:canOffer(def, game) then
            if def.category == "evolution" then evolutions[#evolutions + 1] = def else pool[#pool + 1] = def end
        end
    end
    for i = #pool, 2, -1 do local j = love.math.random(i); pool[i], pool[j] = pool[j], pool[i] end
    local picked = {}
    if #evolutions > 0 then picked[1] = evolutions[love.math.random(#evolutions)] end
    local used = {}; if picked[1] then used[picked[1].id] = true end
    for _, def in ipairs(pool) do
        if not used[def.id] and #picked < 3 then picked[#picked + 1], used[def.id] = def, true end
    end
    self.choices = {}
    for i, def in ipairs(picked) do
        self.choices[i] = cloneWithRarity(def, def.category == "evolution" and legendary or rollRarity())
    end
    return self.choices
end

function RunUpgrades:choose(index, game)
    local def = type(index) == "number" and self.choices[index] or byId[index]
    if not def or not self:canOffer(def, game) then return false end
    local first = self:level(def.id) == 0
    self.levels[def.id] = self:level(def.id) + 1
    if first and def.category == "passive" then self.passiveCount = self.passiveCount + 1 end
    if def.resource then
        local percent = def.gainPercent or rollRarity().percent
        self.resourcePct[def.resource] = (self.resourcePct[def.resource] or 0) + percent
    end
    if def.id == "cargo_frame" then game.player.capacity = game.player.capacity + 3 end
    if def.id == "field_boots" then game.player.speed = game.player.speed * 1.06 end
    if def.id == "wide_lens" then game.world.core.range = (game.world.core.range or 510) + 45 end
    game:setNotice(def.category == "evolution" and ("시스템 진화 — " .. def.name) or (def.name .. " " .. self:level(def.id) .. "단계"), def.color[3] > .8 and "ore" or "core")
    return true
end

function RunUpgrades:speedMultiplier()
    return 1 + self:level("production_clock") * .12
end

function RunUpgrades:cropGrowthMultiplier()
    local base = self:level("eternal_farm") > 0 and 2.4 or 1
    return base * (1 + (self.resourcePct.farmSpeed or 0))
end

function RunUpgrades:applyGain(kind, amount)
    local pct = self.resourcePct[kind]
    if not pct or pct <= 0 or amount <= 0 then return amount end
    return math.max(amount, math.floor(amount * (1 + pct) + 0.5))
end

function RunUpgrades:duplicateAmount(amount)
    if self:level("recycler") > 0 and love.math.random() < self:level("recycler") * .08 then return amount * 2, true end
    return amount, false
end

function RunUpgrades:update(dt, game)
end

function RunUpgrades:drawSelection(game, fonts)
    local w, h = love.graphics.getDimensions()
    love.graphics.setColor(.035, .085, .075, .78); love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setColor(.95, .75, .28, .1); love.graphics.circle("fill", w / 2, 0, math.max(w, h) * .52)
    love.graphics.setColor(.025, .065, .055, .9); love.graphics.rectangle("fill", 0, 0, w, 124)
    love.graphics.setFont(fonts.small); love.graphics.setColor(.98, .78, .3); love.graphics.printf("PRODUCTION LEVEL  " .. game.runLevel, 0, 34, w, "center")
    love.graphics.setFont(fonts.title); love.graphics.setColor(.98, 1, .96); love.graphics.printf("새 설비를 선택하세요", 0, 58, w, "center")
    love.graphics.setFont(fonts.small); love.graphics.setColor(.78,.9,.83); love.graphics.printf(string.format("보조 %d/%d", self.passiveCount, self.maxPassives), 0, 105, w, "center")
    local gap = math.max(16, math.min(24, w * .018))
    local cardW = math.min(332, (w - 72 - gap * 2) / 3)
    local cardH, y = math.min(470, h - 164), 132
    local startX = w / 2 - (cardW * 3 + gap * 2) / 2
    local mx, my = love.mouse.getPosition()
    self.choiceBoxes = {}
    for i, def in ipairs(self.choices) do
        local x, level = startX + (i - 1) * (cardW + gap), self:level(def.id)
        local hovered = mx >= x and mx <= x + cardW and my >= y and my <= y + cardH
        self.choiceBoxes[i] = {x=x,y=y,w=cardW,h=cardH}
        local rarity = def.rarity
        if rarity and rarity.id == "legendary" then
            local pulse = .5 + .5 * math.sin(love.timer.getTime() * 4)
            love.graphics.setColor(rarity.color[1], rarity.color[2], rarity.color[3], .12 + pulse * .14)
            love.graphics.rectangle("fill", x - 5, y - 5, cardW + 10, cardH + 10, 15, 15)
        end
        love.graphics.setColor(0, 0, 0, .28); love.graphics.rectangle("fill", x + 5, y + 8, cardW, cardH, 12, 12)
        love.graphics.setColor(hovered and {.98, .97, .88, 1} or {.91, .91, .83, .98}); love.graphics.rectangle("fill", x, y, cardW, cardH, 12, 12)
        love.graphics.setColor(def.color); love.graphics.rectangle("fill", x, y, cardW, 7, 12, 12)
        love.graphics.setLineWidth(hovered and 3 or 1.5); love.graphics.setColor(def.color[1], def.color[2], def.color[3], hovered and 1 or .58); love.graphics.rectangle("line", x, y, cardW, cardH, 12, 12)

        love.graphics.setColor(.12, .18, .17, 1); love.graphics.rectangle("fill", x + 18, y + 18, 38, 32, 8, 8)
        love.graphics.setFont(fonts.heading); love.graphics.setColor(1, 1, 1); love.graphics.printf(tostring(i), x + 18, y + 20, 38, "center")
        local category = def.category == "evolution" and "최종 진화" or (def.category == "passive" and "보조 장비" or "생산 설비")
        love.graphics.setFont(fonts.small); love.graphics.setColor(.18, .26, .24); love.graphics.printf(category, x + cardW - 108, y + 27, 88, "right")
        if rarity then
            local badgeX, badgeW = x + 64, cardW - 108 - 64 - 8
            if badgeW > 44 then
                love.graphics.setColor(rarity.color[1], rarity.color[2], rarity.color[3], .2); love.graphics.rectangle("fill", badgeX, y + 20, badgeW, 26, 7, 7)
                love.graphics.setLineWidth(1.5); love.graphics.setColor(rarity.color); love.graphics.rectangle("line", badgeX, y + 20, badgeW, 26, 7, 7)
                love.graphics.setFont(fonts.small); love.graphics.printf(rarity.name, badgeX, y + 26, badgeW, "center")
            end
        end

        local icon = self.icons[def.id]
        if icon then
            local maxSize = math.min(196, cardW * .6)
            local scale = math.min(maxSize / icon:getWidth(), maxSize / icon:getHeight())
            if def.id == "recycler" or def.id == "super_magnet" then love.graphics.setShader(self.lightBackgroundShader) end
            love.graphics.setColor(1, 1, 1, 1); love.graphics.draw(icon, x + cardW / 2, y + 146, 0, scale, scale, icon:getWidth() / 2, icon:getHeight() / 2)
            love.graphics.setShader()
        else
            love.graphics.setColor(def.color[1], def.color[2], def.color[3], .2); love.graphics.circle("fill", x + cardW / 2, y + 135, 52)
            love.graphics.setColor(def.color); love.graphics.setLineWidth(5); love.graphics.circle("line", x + cardW / 2, y + 135, 32)
        end

        love.graphics.setFont(fonts.heading); love.graphics.setColor(.1, .16, .15); love.graphics.printf(def.name, x + 20, y + 244, cardW - 40, "center")
        love.graphics.setFont(fonts.small); love.graphics.setColor(def.color[1] * .55, def.color[2] * .55, def.color[3] * .55); love.graphics.printf(table.concat(def.tags, "  ·  "), x + 20, y + 278, cardW - 40, "center")
        love.graphics.setColor(.28, .34, .32); love.graphics.printf(def.desc, x + 30, y + 315, cardW - 60, "center")

        local nextLevel = def.category == "evolution" and 1 or level + 1
        local dotY, dotGap = y + cardH - 46, 18
        local dotStart = x + cardW / 2 - (def.max - 1) * dotGap / 2
        for dot = 1, def.max do
            love.graphics.setColor(dot <= nextLevel and def.color or {.62, .64, .59, .45})
            love.graphics.circle("fill", dotStart + (dot - 1) * dotGap, dotY, dot <= level and 5 or 4)
        end
        love.graphics.setFont(fonts.small); love.graphics.setColor(.24, .3, .28)
        local nextText = def.category == "evolution" and "진화 확정" or string.format("Lv.%d  →  Lv.%d", level, level + 1)
        love.graphics.printf(nextText, x + 20, dotY + 12, cardW - 40, "center")
    end
end

function RunUpgrades:choiceAt(x, y)
    for i, box in ipairs(self.choiceBoxes or {}) do if x>=box.x and x<=box.x+box.w and y>=box.y and y<=box.y+box.h then return i end end
end

return RunUpgrades
