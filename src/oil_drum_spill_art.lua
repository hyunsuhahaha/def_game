local Art={}
local spillImage,puddleImage,fireImage,spillQuads,puddleQuads,fireQuads
local FRAME_W,FRAME_H=256,200
local FRAME_COUNT=8
local SCALE=.75

local function load()
    if spillImage then return end
    spillImage=love.graphics.newImage("assets/fx/oil-drum-spill/oil-drum-spill-atlas-pixel-v2.png")
    puddleImage=love.graphics.newImage("assets/fx/oil-drum-spill/oil-puddle-atlas-pixel-v1.png")
    fireImage=love.graphics.newImage("assets/fx/oil-drum-spill/burning-oil-atlas-pixel-v1.png")
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

function Art.draw(value)
    load()
    local age=value.age or 0
    local spillDuration=FRAME_COUNT*(value.frameDuration or .12)
    local frame,image,quads,originX
    if age<spillDuration then
        frame=math.min(FRAME_COUNT,math.floor(age/(value.frameDuration or .12))+1)
        image,quads,originX=spillImage,spillQuads,95
    elseif value.ignited then
        frame=math.floor(((value.ignitedAge or age)*8))%FRAME_COUNT+1
        image,quads,originX=fireImage,fireQuads,128
    else
        frame=math.floor(age*3)%FRAME_COUNT+1
        image,quads,originX=puddleImage,puddleQuads,128
    end
    local fade=1
    if age>(value.lifetime or 20)then fade=math.max(0,1-(age-(value.lifetime or 20))/.7)end
    local facing=value.facing or 1
    love.graphics.setColor(1,1,1,fade)
    -- The generated sheet is authored pouring to the right. The barrel's
    -- lower contact point stays on the original drum foot while the puddle
    -- grows in the push/axe-hit direction.
    local scale=SCALE*(value.scale or 1)
    love.graphics.draw(image,quads[frame],math.floor(value.x+.5),math.floor(value.y+.5),0,
        scale*facing,scale,originX,185)
    love.graphics.setColor(1,1,1,1)
end

return Art
