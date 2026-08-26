local Cigarette = {}

function Cigarette.load()
    local image = love.graphics.newImage("assets/characters/ingame/smoker-cigarette-pixel-v2.png")
    image:setFilter("nearest", "nearest")
    local shader = love.graphics.newShader("assets/shaders/cigarette-ember.glsl")
    local smokeShader = love.graphics.newShader("assets/shaders/cigarette-smoke.glsl")
    return {image=image, shader=shader, smokeShader=smokeShader, width=256, height=48,
        mouthX=4, mouthY=24, tipX=250, length=24}
end

function Cigarette.drawSmoke(sprite, tipX, mouthY, facing, time)
    local previous = love.graphics.getShader()
    sprite.smokeShader:send("smokeTime",time)
    sprite.smokeShader:send("smokeFacing",facing)
    love.graphics.setShader(sprite.smokeShader)
    love.graphics.setColor(1,1,1,1)
    -- Triple the plume dimensions while keeping its bottom center at the tip.
    -- The shader grid grows too, preserving the original fine pixel density.
    love.graphics.draw(sprite.image,tipX-30,mouthY-120,0,60/sprite.width,120/sprite.height)
    love.graphics.setShader(previous)
end

function Cigarette.draw(sprite, x, y, facing, time)
    local scale = sprite.length / (sprite.tipX - sprite.mouthX)
    local previous = love.graphics.getShader()
    sprite.shader:send("emberTime", time)
    love.graphics.setShader(sprite.shader)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(sprite.image,x,y,0,scale*facing,scale,sprite.mouthX,sprite.mouthY)
    love.graphics.setShader(previous)
end

return Cigarette
