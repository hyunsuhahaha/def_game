local Art={image=nil,quads={}}

local CELL_W,CELL_H,FRAMES,COLS=3072,1920,6,2
local WORLD_W,WORLD_H=640,400
local FRAME_RATE=3.5

function Art.load()
    if Art.image then return Art end
    Art.image=love.graphics.newImage("assets/fx/secondhand-smoke/secondhand-smoke-mist-atlas-pixel-v3.png")
    Art.image:setFilter("nearest","nearest")
    for index=0,FRAMES-1 do
        Art.quads[index+1]=love.graphics.newQuad((index%COLS)*CELL_W,math.floor(index/COLS)*CELL_H,CELL_W,CELL_H,Art.image:getDimensions())
    end
    return Art
end

local function drawCloud(cloud)
    Art.load()
    local progress=math.min(1,cloud.age/cloud.life);local phase=cloud.age*FRAME_RATE
    local whole=math.floor(phase);local frame=1+(whole%FRAMES);local nextFrame=1+(frame%FRAMES)
    local blend=phase-whole;blend=blend*blend*(3-2*blend)
    local fade=math.min(1,cloud.age*7,(1-progress)*3.2);local sx,sy=WORLD_W/CELL_W,WORLD_H/CELL_H
    local currentWeight=(1-blend)^.62;local nextWeight=blend^.62
    love.graphics.setColor(.98,1,.96,.88*fade*currentWeight)
    love.graphics.draw(Art.image,Art.quads[frame],math.floor(cloud.x+.5),math.floor(cloud.y+.5),0,sx,sy,CELL_W/2,CELL_H/2)
    if nextWeight>.001 then
        love.graphics.setColor(.98,1,.96,.88*fade*nextWeight)
        love.graphics.draw(Art.image,Art.quads[nextFrame],math.floor(cloud.x+.5),math.floor(cloud.y+.5),0,sx,sy,CELL_W/2,CELL_H/2)
    end
    love.graphics.setColor(1,1,1,1)
end

function Art.draw(mode) for _,cloud in ipairs(mode.secondhandSmokeClouds or {}) do drawCloud(cloud) end end
function Art.queue(mode,queue)
    for _,value in ipairs(mode.secondhandSmokeClouds or {}) do local cloud=value
        queue[#queue+1]={x=cloud.x,y=cloud.y,anchorY=cloud.y,draw=function()drawCloud(cloud)end}
    end
end

Art.worldWidth,Art.worldHeight=WORLD_W,WORLD_H
return Art
