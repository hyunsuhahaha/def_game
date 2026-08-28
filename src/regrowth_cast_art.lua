local RegrowthCastArt = {}

local image, quads

local function load()
    if image then return end
    image = love.graphics.newImage("assets/fx/regrowth-cast-atlas-v2.png")
    image:setFilter("nearest", "nearest")
    quads = {}
    for index = 0, 5 do
        quads[index + 1] = love.graphics.newQuad(index * 192, 0, 192, 192, 1152, 192)
    end
end

function RegrowthCastArt.draw(enemy)
    if not enemy.planterCasting then return end
    load()
    local interval = enemy.def.plantInterval or 7
    local left = math.max(0, enemy.plantTimer or interval)
    local progress = math.max(0, math.min(.999, (1.5 - left) / 1.5))
    local frame = math.floor(progress * 6) + 1
    local pulse = 1 + math.sin(progress * math.pi) * .08
    local scale = .52 * pulse
    love.graphics.push("all")
    love.graphics.setColor(1, 1, 1, .9 + progress * .1)
    love.graphics.draw(image, quads[frame], math.floor(enemy.x + .5), math.floor(enemy.y + 7.5),
        0, scale, scale, 96, 187)
    love.graphics.pop()
end

return RegrowthCastArt
