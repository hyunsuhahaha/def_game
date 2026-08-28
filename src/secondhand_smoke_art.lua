local Art={image=nil,quads={}}

local CELL_W,CELL_H,FRAMES,COLS=2048,1280,6,3
local WORLD_W,WORLD_H=640,400

function Art.load()
    if Art.image then return Art end
    Art.image=love.graphics.newImage("assets/fx/secondhand-smoke/secondhand-smoke-mist-atlas-pixel-v2.png")
    Art.image:setFilter("nearest","nearest")
    for index=0,FRAMES-1 do
        Art.quads[index+1]=love.graphics.newQuad((index%COLS)*CELL_W,math.floor(index/COLS)*CELL_H,CELL_W,CELL_H,Art.image:getDimensions())
    end
    return Art
end

function Art.draw(mode)
    local clouds=mode.secondhandSmokeClouds or {}
    if #clouds==0 then return end
    Art.load()
    for _,cloud in ipairs(clouds) do
        local progress=math.min(1,cloud.age/cloud.life)
        local frame=1+(math.floor(cloud.age*7)%FRAMES)
        local fade=math.min(1,cloud.age*7,(1-progress)*3.2)
        local sx,sy=WORLD_W/CELL_W,WORLD_H/CELL_H
        love.graphics.setColor(.98,1,.96,.88*fade)
        love.graphics.draw(Art.image,Art.quads[frame],math.floor(cloud.x+.5),math.floor(cloud.y+.5),0,sx,sy,CELL_W/2,CELL_H/2)
    end
    love.graphics.setColor(1,1,1,1)
end

Art.worldWidth,Art.worldHeight=WORLD_W,WORLD_H
return Art
