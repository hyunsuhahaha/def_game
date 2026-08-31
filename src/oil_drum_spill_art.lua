local Art={}
local spillImage,puddleImage,fireImage,spillQuads,puddleQuads,fireQuads
local FRAME_W,FRAME_H=256,200
local FRAME_COUNT=8
local SCALE=.75

local function load()
    if spillImage then return end
    spillImage=love.graphics.newImage("assets/fx/oil-drum-spill/oil-drum-spill-atlas-pixel-v2.png")
    puddleImage=love.graphics.newImage("assets/fx/oil-drum-spill/oil-puddle-atlas-pixel-v1.png")
    fireImage=love.graphics.newImage("assets/fx/oil-drum-spill/oil-fire-overlay-atlas-pixel-v1.png")
    spillImage:setFilter("nearest","nearest");puddleImage:setFilter("nearest","nearest");fireImage:setFilter("nearest","nearest")
    spillQuads={};puddleQuads={};fireQuads={}
    for frame=0,FRAME_COUNT-1 do
        local x,y=(frame%4)*FRAME_W,math.floor(frame/4)*FRAME_H
        spillQuads[frame+1]=love.graphics.newQuad(x,y,FRAME_W,FRAME_H,spillImage:getDimensions())
        puddleQuads[frame+1]=love.graphics.newQuad(x,y,FRAME_W,FRAME_H,puddleImage:getDimensions())
        fireQuads[frame+1]=love.graphics.newQuad(x,y,FRAME_W,FRAME_H,fireImage:getDimensions())
    end
end

function Art.load()load();return true end

local function fadeFor(value)
    local age=value.age or 0
    if age>(value.lifetime or 20)then return math.max(0,1-(age-(value.lifetime or 20))/.7)end
    return 1
end

function Art.drawGround(value)
    load()
    local age=value.age or 0
    local spillDuration=FRAME_COUNT*(value.frameDuration or .12)
    local frame,image,quads,originX
    if age<spillDuration then
        frame=math.min(FRAME_COUNT,math.floor(age/(value.frameDuration or .12))+1)
        image,quads,originX=spillImage,spillQuads,95
    else
        frame=math.floor(age*3)%FRAME_COUNT+1
        image,quads,originX=puddleImage,puddleQuads,128
    end
    local facing=value.facing or 1
    love.graphics.setColor(1,1,1,fadeFor(value))
    -- The generated sheet is authored pouring to the right. The barrel's
    -- lower contact point stays on the original drum foot while the puddle
    -- grows in the push/axe-hit direction.
    local scale=SCALE*(value.scale or 1)
    love.graphics.draw(image,quads[frame],math.floor(value.x+.5),math.floor(value.y+.5),0,
        scale*facing,scale,originX,185)
    love.graphics.setColor(1,1,1,1)
end

function Art.drawFire(value)
    load()
    if not value.ignited then return end
    local logicalRadius=value.radius or 105*(value.scale or 1)
    local radius=logicalRadius*.8
    local halfHeight=logicalRadius*.32
    local stepX,stepY=42,22
    local ignitionAge=value.ignitedAge or 0
    local spread=math.min(1,ignitionAge/.42)
    local pop=1+math.sin(math.min(1,ignitionAge/.42)*math.pi)*.32
    local baseFrame=math.floor(ignitionAge*8)
    love.graphics.setColor(1,1,1,fadeFor(value))
    for y=-halfHeight,halfHeight,stepY do
        local rowWidth=radius*math.sqrt(math.max(0,1-(y/halfHeight)^2))
        for x=-rowWidth,rowWidth,stepX do
            local distance=math.sqrt((x/radius)^2+(y/halfHeight)^2)
            if distance<=spread*1.12 then
                local phase=(math.floor((x+radius)/stepX)*3+math.floor((y+halfHeight)/stepY)*5)%FRAME_COUNT
                local frame=(baseFrame+phase)%FRAME_COUNT+1
                local scale=.29*pop
                love.graphics.draw(fireImage,fireQuads[frame],math.floor(value.x+x+.5),math.floor(value.y+y+.5),0,
                    scale,scale,128,184)
            end
        end
    end
    love.graphics.setColor(1,1,1,1)
end

function Art.draw(value)
    Art.drawGround(value)
    Art.drawFire(value)
end

return Art
