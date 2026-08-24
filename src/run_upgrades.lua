local UI = require("src.ui")

local RunUpgrades = {}
RunUpgrades.__index = RunUpgrades

local definitions = {
    {id="auto_farm", name="자동 농기계", category="system", max=5, color={.36,.94,.42}, tags={"농업","자동화"}, desc="주기적으로 식량을 생산합니다."},
    {id="mining_drone", name="채굴 드론", category="system", max=5, color={.28,.78,1}, tags={"채광","자동화"}, desc="주기적으로 광석을 생산합니다."},
    {id="logging_bot", name="벌목 로봇", category="system", max=5, color={.9,.58,.22}, tags={"벌목","자동화"}, desc="주기적으로 목재를 생산합니다."},
    {id="hatchery", name="부화장", category="system", max=5, color={.52,1,.48}, tags={"생명","병력"}, desc="식량을 소비해 수호자를 자동 부화합니다."},
    {id="rail_turret", name="레일 포탑", category="system", max=5, color={.3,.86,1}, tags={"채광","포탑"}, desc="광석을 탄환으로 바꿔 강력한 포격을 합니다."},
    {id="repair_station", name="자동 수리소", category="system", max=5, color={1,.72,.28}, tags={"방벽","자동화"}, desc="목재와 돌로 방어벽을 자동 수리합니다."},
    {id="carrier_drone", name="운반 드론", category="system", max=3, color={.55,.9,1}, tags={"운반","자동화"}, desc="가방의 자원을 거점으로 자동 운반합니다."},
    {id="blade_turret", name="톱날 포탑", category="system", max=5, color={1,.55,.2}, tags={"벌목","포탑"}, desc="벌목량에 비례해 전선에 톱날을 발사합니다."},
    {id="battle_crops", name="전투 농장", category="system", max=5, color={.58,1,.38}, tags={"농업","방어"}, desc="재배 중인 작물이 적에게 포자를 발사합니다."},
    {id="drone_factory", name="드론 공장", category="system", max=5, color={.4,.82,1}, tags={"공장","병력"}, desc="광석으로 전투 드론을 조립합니다."},
    {id="explosive_payload", name="폭발 탄두", category="system", max=5, color={1,.42,.2}, tags={"폭발","포탑"}, desc="포탑 명중 지점에 범위 피해를 줍니다."},
    {id="chain_coil", name="연쇄 코일", category="system", max=5, color={.48,.78,1}, tags={"전기","포탑"}, desc="포탑 공격이 주변 적에게 연쇄됩니다."},

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
    {id="forest_shredder", name="산림 분쇄기", category="evolution", max=1, color={1,.55,.16}, tags={"진화","벌목"}, desc="숲을 자동 분쇄하고 거대한 톱날 폭풍을 만듭니다.", base="logging_bot", passive="high_motor"}
}

local byId = {}
for _, definition in ipairs(definitions) do byId[definition.id] = definition end

function RunUpgrades.new()
    return setmetatable({levels={}, choices={}, systemCount=0, passiveCount=0, timers={}, maxSystems=6, maxPassives=6}, RunUpgrades)
end

function RunUpgrades:level(id) return self.levels[id] or 0 end
function RunUpgrades:get(id) return byId[id] end

function RunUpgrades:isEvolutionReady(def)
    return def.category == "evolution" and self:level(def.id) == 0 and self:level(def.base) >= byId[def.base].max and self:level(def.passive) >= 1
end

function RunUpgrades:canOffer(def)
    if def.category == "evolution" then return self:isEvolutionReady(def) end
    local level = self:level(def.id)
    if level >= def.max then return false end
    if level > 0 then return true end
    if def.category == "system" then return self.systemCount < self.maxSystems end
    return self.passiveCount < self.maxPassives
end

function RunUpgrades:rollChoices()
    local pool, evolutions = {}, {}
    for _, def in ipairs(definitions) do
        if self:canOffer(def) then
            if def.category == "evolution" then evolutions[#evolutions + 1] = def else pool[#pool + 1] = def end
        end
    end
    for i = #pool, 2, -1 do local j = love.math.random(i); pool[i], pool[j] = pool[j], pool[i] end
    self.choices = {}
    if #evolutions > 0 then self.choices[1] = evolutions[love.math.random(#evolutions)] end
    local used = {}; if self.choices[1] then used[self.choices[1].id] = true end
    for _, def in ipairs(pool) do
        if not used[def.id] and #self.choices < 3 then self.choices[#self.choices + 1], used[def.id] = def, true end
    end
    return self.choices
end

function RunUpgrades:choose(index, game)
    local def = type(index) == "number" and self.choices[index] or byId[index]
    if not def or not self:canOffer(def) then return false end
    local first = self:level(def.id) == 0
    self.levels[def.id] = self:level(def.id) + 1
    if first and def.category == "system" then self.systemCount = self.systemCount + 1 end
    if first and def.category == "passive" then self.passiveCount = self.passiveCount + 1 end
    if def.id == "cargo_frame" then game.player.capacity = game.player.capacity + 3 end
    if def.id == "field_boots" then game.player.speed = game.player.speed * 1.06 end
    if def.id == "wide_lens" then game.world.core.range = (game.world.core.range or 510) + 45 end
    if def.id == "rail_turret" then game.world:addTurret("rail", self:level(def.id)) end
    game:setNotice(def.category == "evolution" and ("시스템 진화 — " .. def.name) or (def.name .. " " .. self:level(def.id) .. "단계"), def.color[3] > .8 and "ore" or "core")
    return true
end

function RunUpgrades:speedMultiplier()
    return 1 + self:level("production_clock") * .12
end

function RunUpgrades:cropGrowthMultiplier()
    return self:level("eternal_farm") > 0 and 2.4 or 1
end

function RunUpgrades:duplicateAmount(amount)
    if self:level("recycler") > 0 and love.math.random() < self:level("recycler") * .08 then return amount * 2, true end
    return amount, false
end

local function timerReady(self, id, dt, interval)
    self.timers[id] = (self.timers[id] or interval) - dt
    if self.timers[id] > 0 then return false end
    self.timers[id] = interval
    return true
end

function RunUpgrades:update(dt, game)
    local speed = self:speedMultiplier()
    local farm = self:level("auto_farm")
    if farm > 0 and timerReady(self, "auto_farm", dt, (6.2 - farm * .45) / speed) then
        local amount = farm + (self:level("eternal_farm") > 0 and 5 or 0)
        game.food = game.food + amount; game.runStats.harvested = game.runStats.harvested + amount; game:addRunXP(math.max(1, math.floor(amount / 2))); game.world:resourcePulse(game, "plot", amount, "자동 식량")
    end
    local mining = self:level("mining_drone")
    if mining > 0 and timerReady(self, "mining_drone", dt, (7 - mining * .45) / speed) then
        local amount = mining + math.floor(self:level("super_magnet") / 2) + (self:level("planet_drill") > 0 and 4 or 0)
        game.ore = game.ore + amount; game.runStats.harvested = game.runStats.harvested + amount; game.runStats.ore = (game.runStats.ore or 0) + amount; game:addRunXP(math.max(1, math.floor(amount / 2))); game.world:resourcePulse(game, "ore", amount, "자동 광석")
        if self:level("planet_drill") > 0 then game.world:fireRail(game, 75 + mining * 18) end
    end
    local logging = self:level("logging_bot")
    if logging > 0 and timerReady(self, "logging_bot", dt, (6.6 - logging * .4) / speed) then
        local amount = logging + math.floor(self:level("high_motor") / 2) + (self:level("forest_shredder") > 0 and 4 or 0)
        game.wood = game.wood + amount; game.runStats.harvested = game.runStats.harvested + amount; game.runStats.tree = (game.runStats.tree or 0) + amount; game:addRunXP(math.max(1, math.floor(amount / 2))); game.world:resourcePulse(game, "tree", amount, "자동 목재")
    end
    local hatchery = self:level("hatchery")
    if hatchery > 0 and game.food >= 5 and #game.world.defenders < 5 + hatchery * 3 and timerReady(self, "hatchery", dt, (8 - hatchery * .55) / (1 + self:level("protein_feed") * .1)) then
        game.food = game.food - 5; game.world:spawnDefender("bio", hatchery, game)
    end
    local drones = self:level("drone_factory")
    if drones > 0 and game.ore >= 4 and #game.world.defenders < 5 + drones * 3 and timerReady(self, "drone_factory", dt, 9 - drones * .6) then
        game.ore = game.ore - 4; game.world:spawnDefender("drone", drones, game)
    end
    local rail = self:level("rail_turret")
    if rail > 0 and game.ore >= 2 and timerReady(self, "rail_turret", dt, (6.5 - rail * .45) / speed) then
        game.ore = game.ore - 2; game.world:fireRail(game, 34 + rail * 18 + self:level("super_magnet") * 7)
    end
    local repair = self:level("repair_station")
    if repair > 0 and game.world.wall.hp < game.world.wall.maxHp and game.wood >= 1 and game.stone >= 1 and timerReady(self, "repair_station", dt, math.max(2, 5.5 - repair * .55)) then
        game.wood, game.stone = game.wood - 1, game.stone - 1
        game.world.wall.hp = math.min(game.world.wall.maxHp, game.world.wall.hp + 15 + repair * 9)
        game.world:resourcePulse(game, "plot", 15 + repair * 9, "자동 수리")
    end
    local carrier = self:level("carrier_drone")
    if carrier > 0 and game.player:totalCargo() > 0 and timerReady(self, "carrier_drone", dt, math.max(2, 7 - carrier * 1.4)) then game:depositCargo("운반 드론 자동 납품") end
    local blade = self:level("blade_turret")
    if blade > 0 and timerReady(self, "blade_turret", dt, (5.8 - blade * .42) / (1 + self:level("high_motor") * .08)) then
        game.world:bladeBurst(game, 18 + blade * 11 + (self:level("forest_shredder") > 0 and 55 or 0))
    end
    local crops = self:level("battle_crops")
    if crops > 0 and timerReady(self, "battle_crops", dt, 5.2 - crops * .35) then game.world:sporeBurst(game, 14 + crops * 9) end
end

function RunUpgrades:drawSelection(game, fonts)
    local w, h = love.graphics.getDimensions()
    love.graphics.setColor(.04, .08, .075, .82); love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setFont(fonts.title); love.graphics.setColor(1,1,1); love.graphics.printf("생산 시스템 강화", 0, 62, w, "center")
    love.graphics.setFont(fonts.body); love.graphics.setColor(.75,.88,.82); love.graphics.printf("레벨 " .. game.runLevel .. " · 하나를 선택하세요", 0, 110, w, "center")
    love.graphics.setFont(fonts.small); love.graphics.setColor(.6,.72,.7); love.graphics.printf(string.format("시스템 %d/%d   ·   보조 %d/%d", self.systemCount, self.maxSystems, self.passiveCount, self.maxPassives), 0, 141, w, "center")
    local cardW, cardH, gap = 300, 360, 24
    local startX, y = w / 2 - (cardW * 3 + gap * 2) / 2, 190
    self.choiceBoxes = {}
    for i, def in ipairs(self.choices) do
        local x, level = startX + (i - 1) * (cardW + gap), self:level(def.id)
        self.choiceBoxes[i] = {x=x,y=y,w=cardW,h=cardH}
        UI.panel(x, y, cardW, cardH, {def.color[1],def.color[2],def.color[3],1}, .97)
        love.graphics.setColor(def.color); love.graphics.circle("fill", x + cardW / 2, y + 66, 38)
        love.graphics.setFont(fonts.heading); love.graphics.setColor(.035,.06,.06); love.graphics.printf(def.category == "evolution" and "진화" or (def.category == "passive" and "보조" or "시스템"), x + cardW/2 - 45, y + 55, 90, "center")
        love.graphics.setFont(fonts.heading); love.graphics.setColor(1,1,1); love.graphics.printf("["..i.."]  " .. def.name, x + 18, y + 122, cardW - 36, "center")
        love.graphics.setFont(fonts.small); love.graphics.setColor(def.color); love.graphics.printf(table.concat(def.tags, "  ·  "), x + 18, y + 159, cardW - 36, "center")
        love.graphics.setColor(.76,.84,.82); love.graphics.printf(def.desc, x + 32, y + 205, cardW - 64, "center")
        local nextText = def.category == "evolution" and "최종 진화" or string.format("Lv.%d → Lv.%d / %d", level, level + 1, def.max)
        love.graphics.setColor(.08,.14,.14,.92); love.graphics.rectangle("fill", x+28, y+292, cardW-56, 42, 6,6)
        love.graphics.setColor(1,.82,.35); love.graphics.printf(nextText, x+28, y+303, cardW-56, "center")
    end
end

function RunUpgrades:choiceAt(x, y)
    for i, box in ipairs(self.choiceBoxes or {}) do if x>=box.x and x<=box.x+box.w and y>=box.y and y<=box.y+box.h then return i end end
end

return RunUpgrades
