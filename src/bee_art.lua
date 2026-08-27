-- Compact authored bee shared by beehives and pursuing hazard swarms.
local Art={}
local image,quads
local W,H,FRAMES=32,24,6

local function load()
    if image then return end
    image=love.graphics.newImage("assets/fx/bees/bee-flight-simple-pixel-v2.png")
    image:setFilter("nearest","nearest")
    quads={}
    for frame=0,FRAMES-1 do
        quads[frame+1]=love.graphics.newQuad(frame*W,0,W,H,image:getDimensions())
    end
end

function Art.draw(x,y,angle,wingPhase,scale)
    load()
    local frame=math.floor(wingPhase or 0)%FRAMES+1
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(image,quads[frame],math.floor(x+.5),math.floor(y+.5),angle or 0,
        scale or 1,scale or 1,17,14)
end

return Art
