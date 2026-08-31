-- Brief airborne droplets only. Settled oil is generated as randomized ground
-- pixels by oil_trail_art.lua and fire is queued as separate spot objects.
local Art={}

function Art.load()return true end

local function noise(seed,index)
    local value=math.sin(seed*12.9898+index*78.233)*43758.5453
    return value-math.floor(value)
end

function Art.drawGround(value)
    local age=value.age or 0
    local duration=.68
    if age>=duration then return end
    local p=age/duration
    local facing=value.facing or 1
    local seed=value.seed or value.drumId or 1
    for index=1,18 do
        local speed=34+noise(seed,index)*115
        local lateral=(noise(seed,index+31)-.5)*78
        local x=value.x+facing*speed*p
        local y=value.y+lateral*p*.48-math.sin(p*math.pi)*(12+noise(seed,index+77)*32)
        local size=math.max(2,math.floor((5+noise(seed,index+91)*8)*(1-p*.58)))
        local shade=index%4==0 and{.10,.12,.15,.92}or{.025,.028,.035,.94}
        love.graphics.setColor(shade)
        love.graphics.rectangle("fill",math.floor(x/2)*2,math.floor(y/2)*2,size*2,size)
        if index%3==0 then
            love.graphics.setColor(.18,.20,.24,.65*(1-p))
            love.graphics.rectangle("fill",math.floor(x/2)*2+2,math.floor(y/2)*2,size,2)
        end
    end
    love.graphics.setColor(1,1,1,1)
end

function Art.drawFire()end
function Art.draw(value)Art.drawGround(value)end
return Art
