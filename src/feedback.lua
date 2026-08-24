local Feedback = {}
Feedback.__index = Feedback

local function makeSource(kind)
    local rate, duration = 22050, .11
    local count = math.floor(rate * duration)
    local data = love.sound.newSoundData(count, rate, 16, 1)
    for i = 0, count - 1 do
        local t, fade = i / rate, 1 - i / count
        local noise = love.math.random() * 2 - 1
        local sample
        if kind == "tree" then
            sample = (math.sin(t * 170 * math.pi * 2) * .48 + noise * .28) * fade * fade
        elseif kind == "stone" then
            sample = (math.sin(t * 410 * math.pi * 2) * .34 + noise * .42) * fade * fade
        elseif kind == "ore" then
            sample = (math.sin(t * 690 * math.pi * 2) * .42 + math.sin(t * 1030 * math.pi * 2) * .22 + noise * .2) * fade
        else
            sample = (math.sin(t * (320 + t * 1500) * math.pi * 2) * .45 + noise * .15) * fade
        end
        data:setSample(i, math.max(-1, math.min(1, sample)))
    end
    return love.audio.newSource(data, "static")
end

function Feedback.new()
    local self = setmetatable({pools = {}, cursor = {}}, Feedback)
    local ok = pcall(function()
        for _, kind in ipairs({"tree", "stone", "ore", "harvest"}) do
            self.pools[kind], self.cursor[kind] = {}, 1
            local source = makeSource(kind)
            source:setVolume(kind == "harvest" and .22 or .16)
            for i = 1, 4 do self.pools[kind][i] = source:clone() end
        end
    end)
    if not ok then self.pools = {} end
    return self
end

function Feedback:play(kind, strong)
    local pool = self.pools[kind] or self.pools.harvest
    if not pool then return end
    local index = self.cursor[kind] or 1
    local source = pool[index]
    self.cursor[kind] = index % #pool + 1
    source:stop()
    source:setPitch((strong and .88 or 1) + love.math.random() * .12)
    source:setVolume(strong and .28 or .16)
    source:play()
end

return Feedback
