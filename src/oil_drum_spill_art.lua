local Art={}
local image,quads
local FRAME_W,FRAME_H=256,200
local FRAME_COUNT=8
local SCALE=.75

local function load()
    if image then return end
    image=love.graphics.newImage("assets/fx/oil-drum-spill/oil-drum-spill-atlas-pixel-v2.png")
    image:setFilter("nearest","nearest")
    quads={}
    for frame=0,FRAME_COUNT-1 do
        quads[frame+1]=love.graphics.newQuad((frame%4)*FRAME_W,math.floor(frame/4)*FRAME_H,
            FRAME_W,FRAME_H,image:getDimensions())
    end
end

function Art.load()load();return true end

function Art.draw(value)
    load()
    local age=value.age or 0
    local frame=math.min(FRAME_COUNT,math.floor(age/(value.frameDuration or .12))+1)
    local fade=1
    if age>(value.lifetime or 20)then fade=math.max(0,1-(age-(value.lifetime or 20))/.7)end
    local facing=value.facing or 1
    love.graphics.setColor(1,1,1,fade)
    -- The generated sheet is authored pouring to the right. The barrel's
    -- lower contact point stays on the original drum foot while the puddle
    -- grows in the push/axe-hit direction.
    local scale=SCALE*(value.scale or 1)
    love.graphics.draw(image,quads[frame],math.floor(value.x+.5),math.floor(value.y+.5),0,
        scale*facing,scale,95,185)
    love.graphics.setColor(1,1,1,1)
end

return Art
