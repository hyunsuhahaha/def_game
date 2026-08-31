local Feedback = {}
Feedback.__index = Feedback

local function makeSource(kind)
    local rate, duration = 22050, kind=="creak" and 1.05 or kind=="tier_up" and .46 or kind=="ignite" and .19 or kind=="butt_hit" and .12 or kind=="ember_land" and .09 or .11
    local count = math.floor(rate * duration)
    local data = love.sound.newSoundData(count, rate, 16, 1)
    for i = 0, count - 1 do
        local t, fade = i / rate, 1 - i / count
        local noise = love.math.random() * 2 - 1
        local sample
        if kind == "creak" then
            local groan=math.sin((t*72+t*t*34)*math.pi*2)*.34
            local rub=math.sin((t*187+math.sin(t*19)*.7)*math.pi*2)*.12
            sample=(groan+rub+noise*.16)*(math.sin(math.min(1,t/duration)*math.pi)^.55)
        elseif kind == "grass" then
            sample = (noise * .55 + math.sin(t * 1150 * math.pi * 2) * .08) * fade * fade
        elseif kind == "ember_land" then
            local snap=math.sin((t*1180-t*t*2100)*math.pi*2)*.32
            sample=(snap+noise*.38)*fade*fade
        elseif kind == "butt_hit" then
            local tick=math.sin((t*1480-t*t*2600)*math.pi*2)*.38*math.max(0,1-t/.055)
            local thud=math.sin((t*118+t*t*70)*math.pi*2)*.34
            sample=(tick+thud+noise*.22)*fade*fade
        elseif kind == "ignite" then
            local snap=math.sin((t*760+t*t*1700)*math.pi*2)*.42*math.max(0,1-t/.055)
            local crackle=noise*(.28+.18*math.sin(t*870*math.pi*2)^2)
            local flare=math.sin((t*145+t*t*260)*math.pi*2)*.16
            sample=(snap+crackle+flare)*fade*fade
        elseif kind == "tier_up" then
            local rise=math.sin((t*(410+t*880))*math.pi*2)*.25
            local chime=math.sin(t*820*math.pi*2)*.20+math.sin(t*1230*math.pi*2)*.10
            local leaf=noise*.08*math.sin(math.min(1,t/duration)*math.pi)
            sample=(rise+chime+leaf)*fade
        elseif kind == "tree" then
            sample = (math.sin(t * 170 * math.pi * 2) * .48 + noise * .28) * fade * fade
        elseif kind == "metal" then
            local clang=math.sin((t*740-t*t*1250)*math.pi*2)*.48
            local ring=math.sin(t*1320*math.pi*2)*.22+math.sin(t*1810*math.pi*2)*.11
            sample=(clang+ring+noise*.18)*fade*fade
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
        for _, kind in ipairs({"tree", "stone", "ore", "metal", "harvest", "grass", "creak", "ember_land", "butt_hit", "ignite", "tier_up"}) do
            self.pools[kind], self.cursor[kind] = {}, 1
            local source = makeSource(kind)
            source:setVolume(kind == "harvest" and .22 or kind=="grass" and .11 or kind=="creak" and .24 or .16)
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
