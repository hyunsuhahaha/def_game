local Progression = {}
Progression.__index = Progression

local nodes = {
    {id = "quick_work", branch = 1, tier = 1, angle = 190, name = "숙련된 손", max = 5, costs = {6, 9, 13, 18, 24}, desc = "모든 채집 속도 +6%", effect = "gather"},
    {id = "cargo_rig", branch = 1, tier = 2, angle = 190, name = "확장형 운반대", max = 4, costs = {9, 14, 20, 27}, desc = "가방 용량 +3", effect = "capacity", requires = {"quick_work", 2}},
    {id = "seed_vault", branch = 1, tier = 3, angle = 190, name = "보존 종자고", max = 3, costs = {13, 20, 29}, desc = "시작 씨앗 +2", effect = "seeds", requires = {"cargo_rig", 2}},
    {id = "field_route", branch = 1, tier = 4, angle = 174, name = "현장 동선", max = 1, costs = {35}, desc = "이동 속도 +10%", effect = "move", requires = {"seed_vault", 3}},
    {id = "harvest_boost", branch = 1, tier = 4, angle = 206, name = "대량 수확 기술", max = 1, costs = {35}, desc = "작물 수확량 +2", effect = "harvestBonus", requires = {"seed_vault", 3}},

    {id = "wall_base", branch = 2, tier = 1, angle = -90, name = "강화 기초", max = 5, costs = {6, 9, 13, 18, 24}, desc = "방어벽 최대 체력 +5%", effect = "wallHp"},
    {id = "repair_drill", branch = 2, tier = 2, angle = -90, name = "긴급 수리 훈련", max = 4, costs = {9, 14, 20, 27}, desc = "망치 수리량 +8", effect = "repair", requires = {"wall_base", 2}},
    {id = "material_cache", branch = 2, tier = 3, angle = -90, name = "자재 비축고", max = 3, costs = {13, 20, 29}, desc = "시작 목재·돌 +2", effect = "materials", requires = {"repair_drill", 2}},
    {id = "last_wall", branch = 2, tier = 4, angle = -90, name = "최후의 방벽", max = 1, costs = {35}, desc = "방어벽 받는 피해 -10%", effect = "wallGuard", requires = {"material_cache", 3}},

    {id = "turret_trim", branch = 3, tier = 1, angle = -20, name = "포탑 영점 조정", max = 5, costs = {6, 9, 13, 18, 24}, desc = "자동 포탑 피해 +4%", effect = "damage"},
    {id = "cooling_loop", branch = 3, tier = 2, angle = -20, name = "순환 냉각", max = 4, costs = {9, 14, 20, 27}, desc = "자동 포탑 공속 +3%", effect = "fireRate", requires = {"turret_trim", 2}},
    {id = "ore_reserve", branch = 3, tier = 3, angle = -20, name = "정제 광석 비축", max = 3, costs = {13, 20, 29}, desc = "시작 광석 +2", effect = "ore", requires = {"cooling_loop", 2}},
    {id = "salvage_code", branch = 3, tier = 4, angle = -20, name = "회수 규약", max = 1, costs = {35}, desc = "유산 부품 획득 +15%", effect = "reward", requires = {"ore_reserve", 3}},

    {id = "build_efficiency", branch = 4, tier = 1, angle = 60, name = "조립 효율", max = 5, costs = {6, 9, 13, 18, 24}, desc = "생산 시설 건설 비용 -3%", effect = "buildCost"},
    {id = "fuel_cell", branch = 4, tier = 2, angle = 60, name = "예비 연료 셀", max = 4, costs = {9, 14, 20, 27}, desc = "포탑 연료 효율 +4%", effect = "fuelEff", requires = {"build_efficiency", 2}},
    {id = "mass_production", branch = 4, tier = 3, angle = 60, name = "대량 생산 회로", max = 3, costs = {13, 20, 29}, desc = "생산 시설 산출량 +1", effect = "produceBonus", requires = {"fuel_cell", 2}},

    {id = "core_plating", branch = 5, tier = 1, angle = 130, name = "코어 장갑판", max = 5, costs = {6, 9, 13, 18, 24}, desc = "거점 코어 최대 체력 +5%", effect = "coreHp"},
    {id = "early_warning", branch = 5, tier = 2, angle = 130, name = "조기 경보망", max = 4, costs = {9, 14, 20, 27}, desc = "첫 웨이브 대비 시간 +2초", effect = "prepTime", requires = {"core_plating", 2}},
    {id = "vanguard_unit", branch = 5, tier = 3, angle = 130, name = "선봉 유닛", max = 1, costs = {30}, desc = "런 시작 시 자동 포탑 1기 무료 지급", effect = "startTurret", requires = {"early_warning", 2}}
}

local byId = {}
for _, node in ipairs(nodes) do byId[node.id] = node end

local function defaults()
    local data = {currency = 0, levels = {}}
    for _, node in ipairs(nodes) do data.levels[node.id] = 0 end
    return data
end

function Progression.decode(text)
    local data = defaults()
    for key, value in (text or ""):gmatch("([%w_]+)=([%d]+)") do
        local number = math.max(0, math.floor(tonumber(value) or 0))
        if key == "currency" then data.currency = number
        elseif byId[key] then data.levels[key] = math.min(number, byId[key].max) end
    end
    return data
end

function Progression.encode(data)
    local lines = {"version=1", "currency=" .. math.floor(data.currency or 0)}
    for _, node in ipairs(nodes) do lines[#lines + 1] = node.id .. "=" .. math.floor(data.levels[node.id] or 0) end
    return table.concat(lines, "\n") .. "\n"
end

function Progression.new(memoryOnly)
    local self = setmetatable({memoryOnly = memoryOnly, file = "meta_progress.sav", data = defaults()}, Progression)
    if not memoryOnly and love.filesystem.getInfo(self.file) then
        local text = love.filesystem.read(self.file)
        if text then self.data = Progression.decode(text) end
    end
    return self
end

function Progression:save()
    if self.memoryOnly then return true end
    return love.filesystem.write(self.file, Progression.encode(self.data))
end

function Progression:getLevel(id) return self.data.levels[id] or 0 end
function Progression:getNode(id) return byId[id] end
function Progression:getNodes() return nodes end

function Progression:status(id)
    local node, level = byId[id], self:getLevel(id)
    if not node then return false, "존재하지 않는 특성" end
    if level >= node.max then return false, "최고 단계" end
    if node.requires and self:getLevel(node.requires[1]) < node.requires[2] then
        return false, byId[node.requires[1]].name .. " " .. node.requires[2] .. "단계 필요"
    end
    local cost = node.costs[level + 1]
    if self.data.currency < cost then return false, "유산 부품 " .. cost .. "개 필요" end
    return true, "구매 가능", cost
end

function Progression:buy(id)
    local ok, reason, cost = self:status(id)
    if not ok then return false, reason end
    self.data.currency = self.data.currency - cost
    self.data.levels[id] = self:getLevel(id) + 1
    self:save()
    return true, byId[id].name .. " 강화 완료"
end

function Progression:addCurrency(amount)
    amount = math.max(0, math.floor(amount or 0))
    self.data.currency = self.data.currency + amount
    self:save()
    return amount
end

function Progression:reset()
    self.data = defaults()
    self:save()
end

function Progression:effects()
    local e = {
        gather = 1, capacity = 0, seeds = 0, move = 1, wallHp = 1, repair = 0, materials = 0, wallGuard = 0,
        damage = 1, fireRate = 1, ore = 0, reward = 1, harvestBonus = 0, buildCost = 1, fuelEff = 0,
        produceBonus = 0, coreHp = 1, prepTime = 0, startTurret = false
    }
    e.gather = 1 + self:getLevel("quick_work") * .06
    e.capacity = self:getLevel("cargo_rig") * 3
    e.seeds = self:getLevel("seed_vault") * 2
    e.move = 1 + self:getLevel("field_route") * .10
    e.wallHp = 1 + self:getLevel("wall_base") * .05
    e.repair = self:getLevel("repair_drill") * 8
    e.materials = self:getLevel("material_cache") * 2
    e.wallGuard = self:getLevel("last_wall") * .10
    e.damage = 1 + self:getLevel("turret_trim") * .04
    e.fireRate = 1 + self:getLevel("cooling_loop") * .03
    e.ore = self:getLevel("ore_reserve") * 2
    e.reward = 1 + self:getLevel("salvage_code") * .15
    e.harvestBonus = self:getLevel("harvest_boost") * 2
    e.buildCost = 1 - self:getLevel("build_efficiency") * .03
    e.fuelEff = self:getLevel("fuel_cell") * .04
    e.produceBonus = self:getLevel("mass_production")
    e.coreHp = 1 + self:getLevel("core_plating") * .05
    e.prepTime = self:getLevel("early_warning") * 2
    e.startTurret = self:getLevel("vanguard_unit") > 0
    return e
end

return Progression
